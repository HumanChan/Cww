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
                      'f297': '20260710',
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
    expect(snapshots.first.tradingDate, DateTime(2026, 7, 10));
    expect(snapshots.last.hasBreadth, isFalse);
    expect(snapshots.last.advancing, isNull);
  });

  test('intraday fields map time, price, volume and semantic second line',
      () async {
    final requestedFields = <String>[];
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedFields.add(options.queryParameters['fields2'].toString());
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': {
                    'trends': [
                      '2026-07-10 09:30,3500.10,12345,3499.80',
                      '2026-07-10 09:31,3501.20,23456,3500.30',
                    ],
                  },
                },
              ),
            );
          },
        ),
      );
    final service = EastMoneyService(dio);

    final stockPoints = await service.getIntradayChart('1.600000');
    final indexPoints =
        await service.getIntradayChart('1.000001', isIndex: true);

    expect(requestedFields, everyElement('f51,f53,f56,f58'));
    expect(stockPoints.first.time, '09:30');
    expect(stockPoints.first.price, 3500.10);
    expect(stockPoints.first.volume, 12345);
    expect(stockPoints.first.avg, 3499.80);
    expect(stockPoints.first.leading, isNull);
    expect(indexPoints.first.avg, isNull);
    expect(indexPoints.first.leading, 3499.80);
  });

  test('A-share limit counts cache for 60 seconds and survive refresh failure',
      () async {
    var now = DateTime(2026, 7, 10, 15);
    var poolRequests = 0;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('Topic')) {
              poolRequests++;
              if (poolRequests > 2) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.connectionError,
                  ),
                );
                return;
              }
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'data': {
                      'tc': options.path.contains('ZTPool') ? 68 : 7,
                    },
                  },
                ),
              );
              return;
            }
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': {
                    'diff': [
                      for (final stock
                          in MarketRepository.marketIndexes[Market.cn]!)
                        {
                          'f12': stock.code,
                          'f13': stock.secid.startsWith('1.') ? 1 : 0,
                          'f14': stock.name,
                          'f2': 3500,
                          'f3': 1,
                          'f104': 3000,
                          'f105': 2000,
                          'f106': 100,
                          'f297': '20260710',
                        },
                    ],
                  },
                },
              ),
            );
          },
        ),
      );
    final repository = MarketRepository(
      eastMoney: EastMoneyService(dio),
      binance: BinanceService(dio),
      yahoo: YahooFinanceService(dio),
      now: () => now,
    );

    final first = await repository.fetchMarketIndexes(Market.cn);
    final cached = await repository.fetchMarketIndexes(Market.cn);
    now = now.add(const Duration(seconds: 61));
    final staleFallback = await repository.fetchMarketIndexes(Market.cn);

    expect(first.first.limitUp, 68);
    expect(first.first.limitDown, 7);
    expect(cached.first.limitUp, 68);
    expect(staleFallback.first.limitUp, 68);
    expect(staleFallback.first.limitDown, 7);
    expect(poolRequests, 4);
  });
}
