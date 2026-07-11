import 'package:cww_flutter/src/features/market/data/binance_service.dart';
import 'package:cww_flutter/src/features/market/data/east_money_service.dart';
import 'package:cww_flutter/src/features/market/data/market_repository.dart';
import 'package:cww_flutter/src/features/market/data/yahoo_finance_service.dart';
import 'package:cww_flutter/src/features/market/domain/stock.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EastMoney market prefixes include Korea and Taiwan', () {
    final service = EastMoneyService(Dio());

    expect(service.getMarketFromSecid('177.005930'), Market.kr);
    expect(service.getMarketFromSecid('178.2330'), Market.tw);
  });

  test('Korean and Taiwan defaults use browser-compatible quote ids', () {
    final dio = Dio();
    final repository = MarketRepository(
      eastMoney: EastMoneyService(dio),
      binance: BinanceService(dio),
      yahoo: YahooFinanceService(dio),
    );

    final koreanStocks =
        repository.defaultGroups.firstWhere((group) => group.id == 'kr').stocks;
    final taiwanStocks =
        repository.defaultGroups.firstWhere((group) => group.id == 'tw').stocks;

    expect(koreanStocks.map((stock) => stock.secid), [
      '177.005930',
      '177.000660',
    ]);
    expect(taiwanStocks.map((stock) => stock.secid), [
      '178.2330',
      '178.2317',
    ]);
    expect(isYahooStock('005930.KS'), isFalse);
    expect(isYahooStock('2330.TW'), isFalse);
  });
}
