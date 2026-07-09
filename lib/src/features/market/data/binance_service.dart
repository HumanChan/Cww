import 'package:dio/dio.dart';

import '../domain/chart_models.dart';
import '../domain/stock.dart';
import 'top_crypto_pairs.dart';

class BinanceService {
  BinanceService(this._dio);

  final Dio _dio;

  static const _baseUrl = 'https://data-api.binance.vision/api/v3';

  Future<List<Stock>> searchCrypto(String keyword) async {
    final value = keyword.trim().toUpperCase();
    if (value.isEmpty) return [];

    final localMatches = topCryptoPairs
        .where((pair) => pair.$1.contains(value) || pair.$2.toUpperCase().contains(value))
        .map(
          (pair) => Stock(
            code: pair.$1,
            name: pair.$2,
            secid: pair.$1,
            type: StockType.crypto,
            market: Market.other,
          ),
        )
        .toList();
    if (localMatches.isNotEmpty) return localMatches;

    if (value.length < 3) return [];
    final symbol = value.endsWith('USDT') ? value : '${value}USDT';
    try {
      final response = await _dio.get<dynamic>('$_baseUrl/ticker/price', queryParameters: {'symbol': symbol});
      if (response.statusCode == 200) {
        return [
          Stock(
            code: symbol,
            name: symbol.replaceAll('USDT', '/USDT'),
            secid: symbol,
            type: StockType.crypto,
            market: Market.other,
          ),
        ];
      }
    } catch (_) {
      return [];
    }
    return [];
  }

  Future<List<Stock>> getCryptoQuotes(List<String> symbols) async {
    if (symbols.isEmpty) return [];
    final results = await Future.wait(
      symbols.map((symbol) async {
        try {
          final response = await _dio.get<dynamic>(
            '$_baseUrl/ticker/24hr',
            queryParameters: {'symbol': symbol},
          );
          final data = response.data;
          if (data is! Map) return null;
          return Stock(
            code: data['symbol']?.toString() ?? symbol,
            name: (data['symbol']?.toString() ?? symbol).replaceAll('USDT', ''),
            secid: symbol,
            type: StockType.crypto,
            market: Market.other,
            price: _safeDouble(data['lastPrice']),
            percent: _safeDouble(data['priceChangePercent']),
            change: _safeDouble(data['priceChange']),
            high: _safeDouble(data['highPrice']),
            low: _safeDouble(data['lowPrice']),
            open: _safeDouble(data['openPrice']),
            preClose: _safeDouble(data['prevClosePrice']),
            amount: _safeDouble(data['quoteVolume']),
            volume: _safeDouble(data['volume']),
          );
        } catch (_) {
          return null;
        }
      }),
    );
    return results.whereType<Stock>().toList();
  }

  Future<ChartData> getCryptoChartData(String symbol, ChartType type) async {
    final interval = switch (type) {
      ChartType.intraday => '1m',
      ChartType.dayK => '1d',
      ChartType.weekK => '1w',
      ChartType.monthK => '1M',
    };
    final response = await _dio.get<dynamic>(
      '$_baseUrl/klines',
      queryParameters: {
        'symbol': symbol,
        'interval': interval,
        'limit': type == ChartType.intraday ? 240 : 200,
      },
    );
    final rows = response.data is List ? response.data as List : const [];

    if (type == ChartType.intraday) {
      return ChartData(
        type: type,
        intraday: rows.whereType<List>().map((row) {
          final millis = row.first is int ? row.first as int : int.tryParse(row.first.toString()) ?? 0;
          final date = DateTime.fromMillisecondsSinceEpoch(millis);
          return ChartPoint(
            time:
                '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
            price: _safeDouble(_at(row, 4)) ?? 0,
            avg: _safeDouble(_at(row, 4)) ?? 0,
            volume: _safeDouble(_at(row, 5)) ?? 0,
          );
        }).where((point) => point.price > 0).toList(),
      );
    }

    return ChartData(
      type: type,
      kLine: rows.whereType<List>().map((row) {
        final millis = row.first is int ? row.first as int : int.tryParse(row.first.toString()) ?? 0;
        final date = DateTime.fromMillisecondsSinceEpoch(millis).toIso8601String().split('T').first;
        return KLinePoint(
          date: date,
          open: _safeDouble(_at(row, 1)) ?? 0,
          high: _safeDouble(_at(row, 2)) ?? 0,
          low: _safeDouble(_at(row, 3)) ?? 0,
          close: _safeDouble(_at(row, 4)) ?? 0,
          volume: _safeDouble(_at(row, 5)) ?? 0,
        );
      }).where((point) => point.close > 0 && point.open > 0).toList(),
    );
  }
}

double? _safeDouble(Object? value) {
  if (value == null || value == '-' || value == '') return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

Object? _at(List<dynamic> values, int index) {
  return index >= 0 && index < values.length ? values[index] : null;
}
