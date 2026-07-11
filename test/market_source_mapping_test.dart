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

  test('primary market index mappings and US order are stable', () {
    expect(
      MarketRepository.marketIndexes[Market.cn]!.map((stock) => stock.secid),
      ['1.000001', '1.000688', '0.399006'],
    );
    expect(MarketRepository.marketIndexes[Market.hk]!.single.secid, '100.HSI');
    expect(MarketRepository.marketIndexes[Market.kr]!.single.secid, '100.KS11');
    expect(MarketRepository.marketIndexes[Market.tw]!.single.secid, '100.TWII');
    expect(
      MarketRepository.marketIndexes[Market.us]!.map((stock) => stock.secid),
      ['100.NDX', '100.DJIA', '100.SPX'],
    );
  });

  test('index breadth parses real values and treats overseas zeros as missing',
      () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'data': {
                  'diff': [
                    {
                      'f12': '000001',
                      'f13': 1,
                      'f14': '上证指数',
                      'f2': 3500.5,
                      'f3': 1.2,
                      'f4': 41.5,
                      'f104': 3200,
                      'f105': 1800,
                      'f106': 120,
                      'f124': 1700000000,
                    },
                    {
                      'f12': 'HSI',
                      'f13': 100,
                      'f14': '恒生指数',
                      'f2': 24000,
                      'f3': -0.4,
                      'f4': -96,
                      'f104': 0,
                      'f105': 0,
                      'f106': 0,
                      'f124': 1700000000,
                    },
                  ],
                },
              },
            ),
          );
        },
      ),
    );
    final snapshots = await EastMoneyService(dio).getIndexSnapshots([
      MarketRepository.marketIndexes[Market.cn]!.first,
      MarketRepository.marketIndexes[Market.hk]!.single,
    ]);

    expect(snapshots.first.hasBreadth, isTrue);
    expect(snapshots.first.advancing, 3200);
    expect(snapshots.last.hasBreadth, isFalse);
    expect(snapshots.last.advancing, isNull);
  });
}
