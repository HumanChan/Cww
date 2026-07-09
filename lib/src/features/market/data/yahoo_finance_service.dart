import 'package:dio/dio.dart';

import '../domain/stock.dart';

class YahooFinanceService {
  YahooFinanceService(this._dio);

  final Dio _dio;

  Future<List<Stock>> searchStocks(String keyword) async {
    if (keyword.trim().isEmpty) return [];
    try {
      final response = await _dio.get<dynamic>(
        'https://query1.finance.yahoo.com/v1/finance/search',
        queryParameters: {
          'q': keyword.trim(),
          'quotesCount': 10,
          'newsCount': 0,
        },
      );
      final data = response.data;
      if (data is! Map || data['quotes'] is! List) return [];
      return (data['quotes'] as List)
          .whereType<Map>()
          .where((quote) {
            final type = quote['quoteType']?.toString();
            return type == 'EQUITY' || type == 'ETF' || type == 'INDEX';
          })
          .map((quote) {
            final symbol = quote['symbol']?.toString() ?? '';
            return Stock(
              code: symbol,
              name: quote['shortname']?.toString() ?? quote['longname']?.toString() ?? symbol,
              secid: symbol,
              market: _marketFromSymbol(symbol, quote['exchange']?.toString()),
            );
          })
          .where((stock) => stock.code.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Stock>> fetchQuotes(List<String> symbols) async {
    if (symbols.isEmpty) return [];
    try {
      final response = await _dio.get<dynamic>(
        'https://query1.finance.yahoo.com/v7/finance/quote',
        queryParameters: {'symbols': symbols.join(',')},
      );
      final data = response.data;
      final quoteResponse = data is Map ? data['quoteResponse'] : null;
      final rows = quoteResponse is Map ? quoteResponse['result'] : null;
      if (rows is! List) return [];
      return rows.whereType<Map>().map(_mapYahooQuote).toList();
    } catch (_) {
      return [];
    }
  }
}

Stock _mapYahooQuote(Map quote) {
  final symbol = quote['symbol']?.toString() ?? '';
  final price = _safeDouble(quote['regularMarketPrice']);
  final volume = _safeDouble(quote['regularMarketVolume']);
  return Stock(
    code: symbol,
    name: quote['shortName']?.toString() ?? quote['longName']?.toString() ?? symbol,
    secid: symbol,
    market: _marketFromSymbol(symbol, quote['exchange']?.toString()),
    price: price,
    change: _safeDouble(quote['regularMarketChange']),
    percent: _safeDouble(quote['regularMarketChangePercent']),
    high: _safeDouble(quote['regularMarketDayHigh']),
    low: _safeDouble(quote['regularMarketDayLow']),
    open: _safeDouble(quote['regularMarketOpen']),
    preClose: _safeDouble(quote['regularMarketPreviousClose']),
    volume: volume,
    amount: price != null && volume != null ? price * volume : null,
    marketCap: _safeDouble(quote['marketCap']),
    peTTM: _safeDouble(quote['trailingPE']),
    peDynamic: _safeDouble(quote['forwardPE']),
    pb: _safeDouble(quote['priceToBook']),
  );
}

bool isYahooStock(String code) {
  return RegExp(r'\.(KS|TW|T|HK)$').hasMatch(code);
}

Market _marketFromSymbol(String symbol, String? exchange) {
  if (symbol.endsWith('.KS')) return Market.kr;
  if (symbol.endsWith('.TW')) return Market.tw;
  if (symbol.endsWith('.HK')) return Market.hk;
  if (symbol.endsWith('.T')) return Market.jp;
  if (symbol.endsWith('.SS') || symbol.endsWith('.SZ')) return Market.cn;
  if (exchange != null && exchange.isNotEmpty) return Market.us;
  return Market.us;
}

double? _safeDouble(Object? value) {
  if (value == null || value == '-' || value == '') return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
