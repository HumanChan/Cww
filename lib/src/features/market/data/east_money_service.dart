import 'dart:convert';

import 'package:dio/dio.dart';

import '../domain/chart_models.dart';
import '../domain/stock.dart';

class EastMoneyService {
  EastMoneyService(this._dio);

  final Dio _dio;

  Market getMarketFromSecid(String secid) {
    final parts = secid.split('.');
    final prefix = parts.isEmpty ? null : parts.first;
    return switch (prefix) {
      '116' => Market.hk,
      '105' || '106' || '107' => Market.us,
      '0' || '1' => Market.cn,
      _ => Market.cn,
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
    const fields = 'f12,f14,f2,f3,f4,f15,f16,f17,f18,f6,f5,f8,f9,f23,f20,f115,f114,f10';
    final response = await _dio.get<dynamic>(
      'https://push2.eastmoney.com/api/qt/ulist.np/get',
      queryParameters: {
        'secids': secids.join(','),
        'fields': fields,
        'fltt': 2,
        'invt': 2,
      },
    );

    final root = _asMap(response.data);
    final data = root['data'];
    if (data is! Map || data['diff'] == null) return [];
    final diff = data['diff'];
    final rows = diff is List ? diff : (diff is Map ? diff.values.toList() : const []);

    return rows.whereType<Map>().map((item) {
      final code = item['f12']?.toString() ?? '';
      final matchedSecid = secids.firstWhere(
        (secid) => secid.endsWith('.$code') || secid == code,
        orElse: () => code,
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
      );
    }).toList();
  }

  Future<List<ChartPoint>> getIntradayChart(String secid) async {
    const fields = 'f51,f53,f58,f55';
    final response = await _dio.get<dynamic>(
      'https://push2.eastmoney.com/api/qt/stock/trends2/get',
      queryParameters: {
        'secid': secid,
        'fields1': 'f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13',
        'fields2': fields,
        'iscr': 0,
      },
    );

    final root = _asMap(response.data);
    final data = root['data'];
    final trends = data is Map ? data['trends'] : null;
    if (trends is! List) return [];

    return trends.whereType<String>().map((line) {
      final values = line.split(',');
      if (values.length < 4) {
        return const ChartPoint(time: '', price: 0);
      }
      final time = values[0].length >= 16 ? values[0].substring(11, 16) : values[0];
      return ChartPoint(
        time: time,
        price: _safeDouble(values[1]) ?? 0,
        volume: _safeDouble(values[2]) ?? 0,
        avg: _safeDouble(values[3]) ?? 0,
      );
    }).where((point) => point.time.isNotEmpty && point.price > 0).toList();
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

    return klines.whereType<String>().map((line) {
      final values = line.split(',');
      return KLinePoint(
        date: _at(values, 0) ?? '',
        open: _safeDouble(_at(values, 1)) ?? 0,
        close: _safeDouble(_at(values, 2)) ?? 0,
        high: _safeDouble(_at(values, 3)) ?? 0,
        low: _safeDouble(_at(values, 4)) ?? 0,
        volume: _safeDouble(_at(values, 5)) ?? 0,
      );
    }).where((point) => point.close > 0 && point.open > 0).toList();
  }
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

T? _at<T>(List<T> values, int index) {
  return index >= 0 && index < values.length ? values[index] : null;
}
