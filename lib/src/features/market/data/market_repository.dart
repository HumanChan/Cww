import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          id: 'gd',
          name: 'GD',
          stocks: [
            Stock(
              code: '603986',
              name: '兆易创新',
              secid: '1.603986',
              price: 663.49,
              percent: 10,
              preClose: 603.17,
              open: 633,
              high: 663.49,
              low: 630,
              amount: 37654000000,
            ),
            Stock(
              code: '03986',
              name: '兆易创新',
              secid: '116.03986',
              market: Market.hk,
              price: 940.50,
              percent: 21.75,
              amount: 4576000000,
            ),
            Stock(
              code: '688766',
              name: '普冉股份',
              secid: '1.688766',
              price: 762.07,
              percent: 9.81,
              amount: 8557000000,
            ),
            Stock(
              code: '001309',
              name: '德明利',
              secid: '0.001309',
              price: 860.48,
              percent: -2.34,
              amount: 1234000000,
            ),
            Stock(
              code: '688981',
              name: '中芯国际',
              secid: '1.688981',
              price: 45.67,
              percent: 5.43,
              amount: 21000000000,
            ),
          ],
        ),
        StockGroup(
          id: 'chip',
          name: 'Chip',
          stocks: [
            Stock(code: '603986', name: '兆易创新', secid: '1.603986'),
            Stock(code: '688766', name: '普冉股份', secid: '1.688766'),
            Stock(code: '688981', name: '中芯国际', secid: '1.688981'),
            Stock(code: '001309', name: '德明利', secid: '0.001309'),
          ],
        ),
        StockGroup(
          id: 'hk',
          name: 'HK',
          stocks: [
            Stock(
              code: '00700',
              name: '腾讯控股',
              secid: '116.00700',
              market: Market.hk,
            ),
            Stock(
              code: '09988',
              name: '阿里巴巴-W',
              secid: '116.09988',
              market: Market.hk,
            ),
            Stock(
              code: '03690',
              name: '美团-W',
              secid: '116.03690',
              market: Market.hk,
            ),
          ],
        ),
        StockGroup(
          id: 'us',
          name: 'US',
          stocks: [
            Stock(
              code: 'AAPL',
              name: 'Apple',
              secid: 'AAPL',
              market: Market.us,
            ),
            Stock(
              code: 'MSFT',
              name: 'Microsoft',
              secid: 'MSFT',
              market: Market.us,
            ),
            Stock(
              code: 'NVDA',
              name: 'NVIDIA',
              secid: 'NVDA',
              market: Market.us,
            ),
          ],
        ),
        StockGroup(
          id: 'kr',
          name: 'KR',
          stocks: [
            Stock(
              code: '005930.KS',
              name: 'Samsung',
              secid: '005930.KS',
              market: Market.kr,
            ),
            Stock(
              code: '000660.KS',
              name: 'SK Hynix',
              secid: '000660.KS',
              market: Market.kr,
            ),
          ],
        ),
        StockGroup(
          id: 'tw',
          name: 'TW',
          stocks: [
            Stock(
              code: '2330.TW',
              name: 'TSMC',
              secid: '2330.TW',
              market: Market.tw,
            ),
            Stock(
              code: '2317.TW',
              name: 'Hon Hai',
              secid: '2317.TW',
              market: Market.tw,
            ),
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
      if (_isLegacyDefaultSeed(groups)) return defaultGroups;
      return groups.isEmpty ? defaultGroups : groups;
    } catch (_) {
      return defaultGroups;
    }
  }

  bool _isLegacyDefaultSeed(List<StockGroup> groups) {
    if (groups.length == 1) {
      final group = groups.single;
      return group.id == 'default' && _isLegacyGeneralSeed(group.stocks);
    }

    const seededIds = ['gd', 'chip', 'hk', 'us', 'kr', 'tw'];
    if (groups.length != seededIds.length) return false;
    for (var i = 0; i < seededIds.length; i++) {
      if (groups[i].id != seededIds[i]) return false;
    }
    return _isLegacyGeneralSeed(groups.first.stocks);
  }

  bool _isLegacyGeneralSeed(List<Stock> stocks) {
    if (stocks.length > 5) return false;
    const legacyCodes = {'000001', 'BTCUSDT', '300059', '600519', '00700'};
    final codes = stocks.map((stock) => stock.code).toSet();
    return codes.isNotEmpty && codes.every(legacyCodes.contains);
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

  Future<MarketDepth> fetchMarketDepth(Stock stock) async {
    try {
      if (stock.type == StockType.crypto) {
        final depth = await _binance.getOrderBook(stock.secid, limit: 5);
        return depth.hasData ? depth : stock.marketDepth;
      }
      if (isYahooStock(stock.code)) return stock.marketDepth;

      final depth = await _eastMoney.getMarketDepth(stock.secid);
      return depth.hasData ? depth : stock.marketDepth;
    } catch (_) {
      return stock.marketDepth;
    }
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
    final date = DateTime.now().toIso8601String().split('T').first;
    final json = const JsonEncoder.withIndent('  ').convert(
      groups.map((group) => group.toJson()).toList(),
    );
    final file = XFile.fromData(
      Uint8List.fromList(utf8.encode(json)),
      mimeType: 'application/json',
      name: 'moyustock_backup_$date.json',
    );
    await Share.shareXFiles([file], text: 'MoYuStock 自选股备份');
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
