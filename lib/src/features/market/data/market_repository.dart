import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/http_client.dart';
import '../domain/chart_models.dart';
import '../domain/stock.dart';
import '../domain/stock_group.dart';
import 'binance_service.dart';
import 'east_money_service.dart';
import 'yahoo_finance_service.dart';

final eastMoneyServiceProvider =
    Provider((ref) => EastMoneyService(ref.watch(dioProvider)));
final binanceServiceProvider =
    Provider((ref) => BinanceService(ref.watch(dioProvider)));
final yahooFinanceServiceProvider =
    Provider((ref) => YahooFinanceService(ref.watch(dioProvider)));

final marketRepositoryProvider = Provider((ref) {
  return MarketRepository(
    eastMoney: ref.watch(eastMoneyServiceProvider),
    binance: ref.watch(binanceServiceProvider),
    yahoo: ref.watch(yahooFinanceServiceProvider),
  );
});

class MarketRepository {
  MarketRepository({
    required EastMoneyService eastMoney,
    required BinanceService binance,
    required YahooFinanceService yahoo,
  })  : _eastMoney = eastMoney,
        _binance = binance,
        _yahoo = yahoo;

  static const _groupsKey = 'stock_groups';
  static const _activeGroupIdKey = 'active_group_id';
  static const _themeKey = 'is_dark_theme';

  final EastMoneyService _eastMoney;
  final BinanceService _binance;
  final YahooFinanceService _yahoo;
  final Map<String, ({DateTime createdAt, ChartData data})> _chartCache = {};

  List<StockGroup> get defaultGroups => const [
        StockGroup(
          id: 'default',
          name: '自选股',
          stocks: [
            Stock(code: '000001', name: '上证指数', secid: '1.000001'),
            Stock(
              code: 'BTCUSDT',
              name: 'Bitcoin',
              secid: 'BTCUSDT',
              type: StockType.crypto,
              market: Market.other,
            ),
            Stock(code: '300059', name: '东方财富', secid: '0.300059'),
          ],
        ),
      ];

  Future<List<StockGroup>> loadGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_groupsKey);
    if (raw == null || raw.isEmpty) return defaultGroups;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return defaultGroups;
      final groups = decoded
          .whereType<Map<String, dynamic>>()
          .map(StockGroup.fromJson)
          .where((group) => group.id.isNotEmpty && group.name.isNotEmpty)
          .toList();
      return groups.isEmpty ? defaultGroups : groups;
    } catch (_) {
      return defaultGroups;
    }
  }

  Future<void> saveGroups(List<StockGroup> groups) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _groupsKey,
      jsonEncode(groups.map((group) => group.toJson()).toList()),
    );
  }

  Future<String?> loadActiveGroupId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeGroupIdKey);
  }

  Future<void> saveActiveGroupId(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeGroupIdKey, groupId);
  }

  Future<bool> loadIsDark() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }

  Future<void> saveIsDark(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  Future<List<Stock>> search(String keyword, StockType type) {
    if (type == StockType.crypto) return _binance.searchCrypto(keyword);
    return _searchStocks(keyword);
  }

  Future<List<Stock>> _searchStocks(String keyword) async {
    final results = await Future.wait([
      _safeStockList(() => _eastMoney.searchStocks(keyword)),
      _safeStockList(() => _yahoo.searchStocks(keyword)),
    ]);
    final seen = <String>{};
    return [...results[0], ...results[1]]
        .where((stock) => seen.add(stock.secid))
        .toList();
  }

  Future<List<Stock>> fetchQuotes(List<Stock> stocks) async {
    if (stocks.isEmpty) return [];

    final migrated = await _migrateLegacyUsStocks(stocks);
    final eastMoneySecids = migrated
        .where(
          (stock) => stock.type == StockType.stock && !isYahooStock(stock.code),
        )
        .map((stock) => stock.secid)
        .toList();
    final cryptoSymbols = migrated
        .where((stock) => stock.type == StockType.crypto)
        .map((stock) => stock.secid)
        .toList();
    final yahooSymbols = migrated
        .where(
          (stock) => stock.type == StockType.stock && isYahooStock(stock.code),
        )
        .map((stock) => stock.code)
        .toList();

    final quoteGroups = await Future.wait([
      _safeStockList(() => _eastMoney.getStockQuotes(eastMoneySecids)),
      _safeStockList(() => _binance.getCryptoQuotes(cryptoSymbols)),
      _safeStockList(() => _yahoo.fetchQuotes(yahooSymbols)),
    ]);
    return quoteGroups.expand((quotes) => quotes).toList();
  }

  Future<ChartData> fetchChart(
    Stock stock,
    ChartType type, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${stock.type.name}:${stock.secid}:${type.name}';
    final cached = _chartCache[cacheKey];
    final maxAge = type == ChartType.intraday
        ? const Duration(seconds: 30)
        : const Duration(minutes: 10);
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.createdAt) < maxAge) {
      return cached.data;
    }

    late final ChartData data;
    if (stock.type == StockType.crypto) {
      data = await _binance.getCryptoChartData(stock.secid, type);
    } else if (type == ChartType.intraday) {
      data = ChartData(
        type: type,
        intraday: await _eastMoney.getIntradayChart(stock.secid),
      );
    } else {
      data = ChartData(
        type: type,
        kLine: await _eastMoney.getKLineChart(stock.secid, type),
      );
    }
    _chartCache[cacheKey] = (createdAt: DateTime.now(), data: data);
    return data;
  }

  Future<void> exportGroups(List<StockGroup> groups) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/moyustock_backup_${DateTime.now().toIso8601String().split('T').first}.json',
    );
    await file.writeAsString(
      const JsonEncoder.withIndent('  ')
          .convert(groups.map((group) => group.toJson()).toList()),
    );
    await Share.shareXFiles([XFile(file.path)], text: 'MoYuStock 自选股备份');
  }

  Future<List<StockGroup>> parseImportedGroups(String jsonText) async {
    final decoded = jsonDecode(jsonText);
    if (decoded is! List) {
      throw const FormatException('备份文件格式不正确：根节点必须是分组数组。');
    }
    final groups = decoded
        .whereType<Map<String, dynamic>>()
        .map(StockGroup.fromJson)
        .where((group) => group.id.isNotEmpty && group.name.isNotEmpty)
        .toList();
    if (groups.isEmpty) throw const FormatException('备份文件里没有有效分组。');
    return groups;
  }

  Future<List<Stock>> _migrateLegacyUsStocks(List<Stock> stocks) async {
    final legacy = stocks.where((stock) {
      return stock.type == StockType.stock &&
          RegExp(r'^[A-Z]+$').hasMatch(stock.code) &&
          stock.secid == stock.code;
    }).toList();
    if (legacy.isEmpty) return stocks;

    final migrated = [...stocks];
    for (final stock in legacy) {
      try {
        final matches = await _eastMoney.searchStocks(stock.code);
        Stock? match;
        for (final item in matches) {
          if (item.code == stock.code && item.market == Market.us) {
            match = item;
            break;
          }
        }
        if (match == null) continue;
        final index = migrated.indexWhere((item) => item.code == stock.code);
        if (index >= 0) {
          migrated[index] = stock.copyWith(
            secid: match.secid,
            market: Market.us,
            name: match.name,
          );
        }
      } catch (_) {
        continue;
      }
    }
    return migrated;
  }

  Future<List<Stock>> _safeStockList(
    Future<List<Stock>> Function() fetcher,
  ) async {
    try {
      return await fetcher();
    } catch (_) {
      return [];
    }
  }
}
