import 'dart:convert';

import 'package:dio/dio.dart';

import '../domain/chart_models.dart';
import '../domain/market_index_snapshot.dart';
import '../domain/stock.dart';

const _eastMoneyQuoteToken = 'fa5fd1943c7b386f172d6893dbfba10b';
const _eastMoneyPoolToken = '7eea3edcaed734bea9cbfc24409ed989';
const _stockDepthFields = 'f11,f12,f13,f14,f15,f16,f17,f18,f19,f20,'
    'f31,f32,f33,f34,f35,f36,f37,f38,f39,f40,'
    'f59,f60,f152,f191,f192,f531,f532';

class EastMoneyService {
  EastMoneyService(this._dio);

  final Dio _dio;

  Market getMarketFromSecid(String secid) {
    final parts = secid.split('.');
    final prefix = parts.isEmpty ? null : parts.first;
    return switch (prefix) {
      '116' => Market.hk,
      '105' || '106' || '107' => Market.us,
      '176' => Market.jp,
      '177' => Market.kr,
      '178' => Market.tw,
      '0' || '1' => Market.cn,
      _ => Market.other,
    };
  }

  Future<List<Stock>> searchStocks(String keyword) async {
    if (keyword.trim().isEmpty) return [];
    final response = await _dio.get<dynamic>(
      'https://searchapi.eastmoney.com/api/suggest/get',
      queryParameters: {
        'input': keyword.trim(),
        'type': 14,
        'count': 30,
      },
    );

    final root = _asMap(response.data);
    final rows = root['QuotationCodeTable'] is Map
        ? (root['QuotationCodeTable'] as Map)['Data']
        : null;
    if (rows is! List) return [];

    final seen = <String>{};
    final stocks = <Stock>[];
    for (final row in rows.whereType<Map>()) {
      final code = row['Code']?.toString() ?? '';
      final name = row['Name']?.toString() ?? code;
      if (code.isEmpty) continue;

      var marketPrefix = '0';
      if (code.startsWith('6') || code.startsWith('9')) marketPrefix = '1';
      final quoteId = row['QuoteID']?.toString();
      final secid = quoteId == null || quoteId.isEmpty
          ? '$marketPrefix.$code'
          : quoteId.replaceAll('|', '.');
      if (!seen.add(secid)) continue;

      stocks.add(
        Stock(
          code: code,
          name: name,
          secid: secid,
          market: getMarketFromSecid(secid),
        ),
      );
    }
    return stocks;
  }

  Future<List<Stock>> getStockQuotes(List<String> secids) async {
    if (secids.isEmpty) return [];
    const fields =
        'f12,f13,f14,f2,f3,f4,f15,f16,f17,f18,f6,f5,f8,f9,f23,f20,f115,f114,f10,f31,f32';
    final queryParameters = {
      'secids': secids.join(','),
      'fields': fields,
      'fltt': 2,
      'invt': 2,
    };
    Map<String, dynamic> root;
    try {
      final response = await _dio.get<dynamic>(
        'https://push2.eastmoney.com/api/qt/ulist.np/get',
        queryParameters: queryParameters,
      );
      root = _asMap(response.data);
      if (!_hasQuoteRows(root)) throw StateError('Empty primary quote data');
    } catch (_) {
      final response = await _dio.get<dynamic>(
        'https://push2delay.eastmoney.com/api/qt/ulist.np/get',
        queryParameters: queryParameters,
      );
      root = _asMap(response.data);
    }
    final data = root['data'];
    if (data is! Map || data['diff'] == null) return [];
    final diff = data['diff'];
    final rows =
        diff is List ? diff : (diff is Map ? diff.values.toList() : const []);

    return rows.whereType<Map>().map((item) {
      final code = item['f12']?.toString() ?? '';
      final marketId = item['f13']?.toString();
      final returnedSecid = marketId == null ? null : '$marketId.$code';
      final matchedSecid = secids.firstWhere(
        (secid) => secid == returnedSecid,
        orElse: () => secids.firstWhere(
          (secid) => secid.endsWith('.$code') || secid == code,
          orElse: () => code,
        ),
      );
      return Stock(
        code: code,
        name: item['f14']?.toString() ?? code,
        secid: matchedSecid,
        market: getMarketFromSecid(matchedSecid),
        price: _safeDouble(item['f2']),
        percent: _safeDouble(item['f3']),
        change: _safeDouble(item['f4']),
        high: _safeDouble(item['f15']),
        low: _safeDouble(item['f16']),
        open: _safeDouble(item['f17']),
        preClose: _safeDouble(item['f18']),
        amount: _safeDouble(item['f6']),
        volume: _safeDouble(item['f5']),
        turnoverRate: _safeDouble(item['f8']),
        peDynamic: _safeDouble(item['f9']),
        pb: _safeDouble(item['f23']),
        marketCap: _safeDouble(item['f20']),
        peTTM: _safeDouble(item['f115']),
        peStatic: _safeDouble(item['f114']),
        volumeRatio: _safeDouble(item['f10']),
        marketDepth: _bestQuoteDepth(item),
      );
    }).toList();
  }

  Future<List<MarketIndexSnapshot>> getIndexSnapshots(
    List<Stock> indexes,
  ) async {
    if (indexes.isEmpty) return [];
    const fields =
        'f12,f13,f14,f2,f3,f4,f5,f6,f10,f15,f16,f17,f18,f104,f105,f106,f124,f297';
    final queryParameters = {
      'secids': indexes.map((index) => index.secid).join(','),
      'fields': fields,
      'fltt': 2,
      'invt': 2,
    };
    Map<String, dynamic> root;
    try {
      final response = await _dio.get<dynamic>(
        'https://push2.eastmoney.com/api/qt/ulist.np/get',
        queryParameters: queryParameters,
      );
      root = _asMap(response.data);
      if (!_hasQuoteRows(root)) throw StateError('Empty primary index data');
    } catch (_) {
      final response = await _dio.get<dynamic>(
        'https://push2delay.eastmoney.com/api/qt/ulist.np/get',
        queryParameters: queryParameters,
      );
      root = _asMap(response.data);
    }

    final data = root['data'];
    if (data is! Map || data['diff'] == null) return [];
    final diff = data['diff'];
    final rows =
        diff is List ? diff : (diff is Map ? diff.values.toList() : const []);
    final templates = {for (final index in indexes) index.secid: index};

    return rows.whereType<Map>().map((item) {
      final code = item['f12']?.toString() ?? '';
      final marketId = item['f13']?.toString();
      final returnedSecid = marketId == null ? '' : '$marketId.$code';
      final template = templates[returnedSecid] ??
          indexes.firstWhere(
            (index) => index.code == code,
            orElse: () => Stock(
              code: code,
              name: item['f14']?.toString() ?? code,
              secid: returnedSecid,
              market: getMarketFromSecid(returnedSecid),
            ),
          );
      final advancing = _safeInt(item['f104']);
      final declining = _safeInt(item['f105']);
      final unchanged = _safeInt(item['f106']);
      final hasBreadth = advancing != null &&
          declining != null &&
          unchanged != null &&
          (advancing > 0 || declining > 0 || unchanged > 0);
      final updatedSeconds = _safeInt(item['f124']);
      final tradingDate = _parseTradingDate(item['f297']);
      final index = template.copyWith(
        name: template.name.isEmpty
            ? item['f14']?.toString() ?? template.code
            : template.name,
        price: _safeDouble(item['f2']),
        percent: _safeDouble(item['f3']),
        change: _safeDouble(item['f4']),
        volume: _safeDouble(item['f5']),
        amount: _safeDouble(item['f6']),
        volumeRatio: _safeDouble(item['f10']),
        high: _safeDouble(item['f15']),
        low: _safeDouble(item['f16']),
        open: _safeDouble(item['f17']),
        preClose: _safeDouble(item['f18']),
      );
      return MarketIndexSnapshot(
        index: index,
        advancing: hasBreadth ? advancing : null,
        declining: hasBreadth ? declining : null,
        unchanged: hasBreadth ? unchanged : null,
        tradingDate: tradingDate,
        updatedAt: updatedSeconds == null || updatedSeconds <= 0
            ? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(updatedSeconds * 1000),
        isAvailable: index.price != null,
      );
    }).toList();
  }

  Future<MarketDepth> getMarketDepth(String secid) async {
    final response = await _dio.get<dynamic>(
      'https://push2.eastmoney.com/api/qt/stock/get',
      queryParameters: {
        'secid': secid,
        'fields': _stockDepthFields,
        'fltt': 1,
        'invt': 2,
        'ut': _eastMoneyQuoteToken,
        'dect': 1,
      },
    );

    final root = _asMap(response.data);
    final data = root['data'];
    if (data is! Map) return const MarketDepth();
    return _stockDepthFromRealtime(data);
  }

  Future<List<ChartPoint>> getIntradayChart(
    String secid, {
    bool isIndex = false,
  }) async {
    const fields = 'f51,f53,f56,f58';
    final queryParameters = {
      'secid': secid,
      'fields1': 'f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13',
      'fields2': fields,
      'iscr': 0,
    };
    Map<String, dynamic> root;
    try {
      final response = await _dio.get<dynamic>(
        'https://push2.eastmoney.com/api/qt/stock/trends2/get',
        queryParameters: queryParameters,
      );
      root = _asMap(response.data);
      if (!_hasTrendRows(root)) throw StateError('Empty primary trend data');
    } catch (_) {
      final response = await _dio.get<dynamic>(
        'https://push2delay.eastmoney.com/api/qt/stock/trends2/get',
        queryParameters: queryParameters,
      );
      root = _asMap(response.data);
    }
    final data = root['data'];
    final trends = data is Map ? data['trends'] : null;
    if (trends is! List) return [];

    return trends
        .whereType<String>()
        .map((line) {
          final values = line.split(',');
          if (values.length < 4) {
            return const ChartPoint(time: '', price: 0);
          }
          final time =
              values[0].length >= 16 ? values[0].substring(11, 16) : values[0];
          return ChartPoint(
            time: time,
            price: _safeDouble(values[1]) ?? 0,
            volume: _safeDouble(values[2]) ?? 0,
            avg: isIndex ? null : _safeDouble(values[3]),
            leading: isIndex ? _safeDouble(values[3]) : null,
          );
        })
        .where((point) => point.time.isNotEmpty && point.price > 0)
        .toList();
  }

  Future<MarketLimitStats> getMarketLimitStats(DateTime tradingDate) async {
    final date = '${tradingDate.year.toString().padLeft(4, '0')}'
        '${tradingDate.month.toString().padLeft(2, '0')}'
        '${tradingDate.day.toString().padLeft(2, '0')}';

    Future<int?> fetchCount(String endpoint) async {
      final response = await _dio.get<dynamic>(
        'https://push2ex.eastmoney.com/$endpoint',
        queryParameters: {
          'ut': _eastMoneyPoolToken,
          'dpt': 'wz.ztzt',
          'Pageindex': 0,
          'pagesize': 1,
          'sort': 'fbt:asc',
          'date': date,
        },
      );
      final root = _asMap(response.data);
      final data = root['data'];
      return data is Map ? _safeInt(data['tc']) : null;
    }

    final counts = await Future.wait([
      fetchCount('getTopicZTPool'),
      fetchCount('getTopicDTPool'),
    ]);
    return MarketLimitStats(limitUp: counts[0], limitDown: counts[1]);
  }

  Future<List<KLinePoint>> getKLineChart(String secid, ChartType type) async {
    final period = switch (type) {
      ChartType.weekK => 102,
      ChartType.monthK => 103,
      _ => 101,
    };

    final response = await _dio.get<dynamic>(
      'https://push2his.eastmoney.com/api/qt/stock/kline/get',
      queryParameters: {
        'secid': secid,
        'fields1': 'f1,f2,f3,f4,f5,f6',
        'fields2': 'f51,f52,f53,f54,f55,f56',
        'klt': period,
        'fqt': 1,
        'end': 20500101,
        'lmt': 200,
      },
    );

    final root = _asMap(response.data);
    final data = root['data'];
    final klines = data is Map ? data['klines'] : null;
    if (klines is! List) return [];

    return klines
        .whereType<String>()
        .map((line) {
          final values = line.split(',');
          return KLinePoint(
            date: _at(values, 0) ?? '',
            open: _safeDouble(_at(values, 1)) ?? 0,
            close: _safeDouble(_at(values, 2)) ?? 0,
            high: _safeDouble(_at(values, 3)) ?? 0,
            low: _safeDouble(_at(values, 4)) ?? 0,
            volume: _safeDouble(_at(values, 5)) ?? 0,
          );
        })
        .where((point) => point.close > 0 && point.open > 0)
        .toList();
  }
}

bool _hasQuoteRows(Map<String, dynamic> root) {
  final data = root['data'];
  if (data is! Map) return false;
  final diff = data['diff'];
  return diff is List && diff.isNotEmpty || diff is Map && diff.isNotEmpty;
}

bool _hasTrendRows(Map<String, dynamic> root) {
  final data = root['data'];
  return data is Map &&
      data['trends'] is List &&
      (data['trends'] as List).isNotEmpty;
}

Map<String, dynamic> _asMap(Object? data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is String && data.isNotEmpty) {
    final decoded = jsonDecode(data);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  }
  return const {};
}

double? _safeDouble(Object? value) {
  if (value == null || value == '-' || value == '') return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

MarketDepth _bestQuoteDepth(Map item) {
  return MarketDepth.bestQuote(
    bidPrice: _safeDouble(item['f31']),
    askPrice: _safeDouble(item['f32']),
    updatedAt: DateTime.now(),
  );
}

MarketDepth _stockDepthFromRealtime(Map item) {
  final bids = _stockDepthLevels(
    item,
    const [
      (priceField: 'f19', volumeField: 'f20'),
      (priceField: 'f17', volumeField: 'f18'),
      (priceField: 'f15', volumeField: 'f16'),
      (priceField: 'f13', volumeField: 'f14'),
      (priceField: 'f11', volumeField: 'f12'),
    ],
  );
  final asks = _stockDepthLevels(
    item,
    const [
      (priceField: 'f39', volumeField: 'f40'),
      (priceField: 'f37', volumeField: 'f38'),
      (priceField: 'f35', volumeField: 'f36'),
      (priceField: 'f33', volumeField: 'f34'),
      (priceField: 'f31', volumeField: 'f32'),
    ],
  );

  return MarketDepth(
    bids: bids,
    asks: asks,
    isFullDepth: bids.length > 1 || asks.length > 1,
    orderRatio: _scaledValue(item, 'f191', 'f152'),
    orderDiff: _safeDouble(item['f192']),
    updatedAt: DateTime.now(),
  );
}

List<MarketDepthLevel> _stockDepthLevels(
  Map item,
  List<({String priceField, String volumeField})> fields,
) {
  return fields
      .map((field) {
        final price = _scaledPrice(item, field.priceField);
        if (price == null || price <= 0) return null;
        final volume = _safeDouble(item[field.volumeField]);
        return MarketDepthLevel(
          price: price,
          volume: volume == null || volume <= 0 ? null : volume,
        );
      })
      .whereType<MarketDepthLevel>()
      .toList();
}

double? _scaledPrice(Map item, String field) {
  final raw = _safeDouble(item[field]);
  if (raw == null) return null;
  return _scaleByDecimals(raw, _safeInt(item['f59']) ?? 2);
}

double? _scaledValue(Map item, String field, String decimalsField) {
  final raw = _safeDouble(item[field]);
  if (raw == null) return null;
  return _scaleByDecimals(raw, _safeInt(item[decimalsField]) ?? 0);
}

double _scaleByDecimals(double value, int decimals) {
  var divisor = 1.0;
  for (var i = 0; i < decimals; i++) {
    divisor *= 10;
  }
  return value / divisor;
}

int? _safeInt(Object? value) {
  if (value == null || value == '-' || value == '') return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _parseTradingDate(Object? value) {
  final raw = value?.toString() ?? '';
  if (raw.length != 8) return null;
  final year = int.tryParse(raw.substring(0, 4));
  final month = int.tryParse(raw.substring(4, 6));
  final day = int.tryParse(raw.substring(6, 8));
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

T? _at<T>(List<T> values, int index) {
  return index >= 0 && index < values.length ? values[index] : null;
}
