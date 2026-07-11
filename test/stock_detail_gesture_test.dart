import 'package:cww_flutter/src/core/theme/app_theme.dart';
import 'package:cww_flutter/src/features/market/data/binance_service.dart';
import 'package:cww_flutter/src/features/market/data/east_money_service.dart';
import 'package:cww_flutter/src/features/market/data/market_repository.dart';
import 'package:cww_flutter/src/features/market/data/yahoo_finance_service.dart';
import 'package:cww_flutter/src/features/market/domain/chart_models.dart';
import 'package:cww_flutter/src/features/market/domain/market_index_snapshot.dart';
import 'package:cww_flutter/src/features/market/domain/stock.dart';
import 'package:cww_flutter/src/features/market/domain/stock_group.dart';
import 'package:cww_flutter/src/features/watchlist/presentation/stock_detail_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  testWidgets('390x844 详情首屏展示报价、8 项概览和完整图表', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketRepositoryProvider.overrideWithValue(_FakeMarketRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const StockDetailScreen(
            stock: _FakeMarketRepository.stock,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('detail-fixed-layout')), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-scroll-layout')), findsNothing);
    expect(find.byKey(const ValueKey('detail-header')), findsOneWidget);
    for (final label in const [
      '昨收',
      '今开',
      '最高',
      '最低',
      '振幅',
      '量比',
      '成交额',
      '换手率',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    final chart = find.byKey(const ValueKey('detail-chart-card'));
    expect(chart, findsOneWidget);
    expect(tester.getBottomRight(chart).dy, lessThanOrEqualTo(844));
    expect(tester.takeException(), isNull);
  });

  testWidgets('375x667 详情安全降级为可滚动布局', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketRepositoryProvider.overrideWithValue(_FakeMarketRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const StockDetailScreen(
            stock: _FakeMarketRepository.stock,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('detail-scroll-layout')), findsOneWidget);
    expect(find.byKey(const ValueKey('detail-fixed-layout')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('详情页没有返回按钮并支持从左侧右滑返回', (tester) async {
    final repository = _FakeMarketRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const StockDetailScreen(
                        stock: _FakeMarketRepository.stock,
                      ),
                    ),
                  );
                },
                child: const Text('打开详情'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开详情'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    expect(find.text('测试股票'), findsOneWidget);

    final gesture = await tester.startGesture(const Offset(4, 360));
    await gesture.moveTo(const Offset(100, 360));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('打开详情'), findsOneWidget);
    expect(find.text('测试股票'), findsNothing);
  });

  testWidgets('详情页滚动位于顶部时支持下拉返回', (tester) async {
    final repository = _FakeMarketRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [marketRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const StockDetailScreen(
                      stock: _FakeMarketRepository.stock,
                    ),
                  ),
                ),
                child: const Text('打开详情'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开详情'));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(const Offset(190, 140));
    await gesture.moveTo(const Offset(190, 275));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('打开详情'), findsOneWidget);
    expect(find.text('测试股票'), findsNothing);
  });

  testWidgets('K线区域多指缩放不触发详情页下拉并能改变可见窗口', (tester) async {
    final repository = _FakeMarketRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [marketRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const StockDetailScreen(
            stock: _FakeMarketRepository.stock,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('日K'));
    await tester.pumpAndSettle();

    final surface = find.byKey(const ValueKey('kline-interaction-surface'));
    expect(surface, findsOneWidget);
    await tester.ensureVisible(surface);
    await tester.pumpAndSettle();
    final center = tester.getCenter(surface);
    final before = tester
        .widget<CandlestickChart>(find.byType(CandlestickChart))
        .data
        .candlestickSpots
        .length;

    final first = await tester.startGesture(center + const Offset(-10, 0));
    final second = await tester.startGesture(
      center + const Offset(10, 0),
      pointer: 2,
    );
    await first.moveTo(center + const Offset(-10, 60));
    await tester.pump();

    final slide = tester.widget<AnimatedSlide>(
      find.byKey(const ValueKey('detail-page-vertical-slide')),
    );
    expect(slide.offset, Offset.zero);

    await second.moveTo(center + const Offset(10, -60));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pumpAndSettle();

    final after = tester
        .widget<CandlestickChart>(find.byType(CandlestickChart))
        .data
        .candlestickSpots
        .length;
    expect(after, lessThan(before));
    expect(find.text('测试股票'), findsOneWidget);
  });
}

class _FakeMarketRepository extends MarketRepository {
  _FakeMarketRepository()
      : super(
          eastMoney: EastMoneyService(Dio()),
          binance: BinanceService(Dio()),
          yahoo: YahooFinanceService(Dio()),
        );

  static const stock = Stock(
    code: '600000',
    name: '测试股票',
    secid: '1.600000',
    price: 10,
    preClose: 9.8,
    percent: 2.04,
  );

  @override
  Future<List<StockGroup>> loadGroups() async {
    return const [
      StockGroup(id: 'test', name: 'Test', stocks: [stock]),
    ];
  }

  @override
  Future<String?> loadActiveGroupId() async => 'test';

  @override
  Future<bool> loadIsDark() async => false;

  @override
  Future<List<Stock>> fetchQuotes(List<Stock> stocks) async => stocks;

  @override
  Future<List<MarketIndexSnapshot>> fetchMarketIndexes(Market market) async =>
      [];

  @override
  Future<ChartData> fetchChart(
    Stock stock,
    ChartType type, {
    bool forceRefresh = false,
  }) async {
    if (type == ChartType.intraday) {
      return const ChartData(
        type: ChartType.intraday,
        intraday: [
          ChartPoint(time: '09:30', price: 9.9),
          ChartPoint(time: '15:00', price: 10),
        ],
      );
    }
    return ChartData(
      type: type,
      kLine: List.generate(100, (index) {
        final price = 10 + index * 0.05;
        return KLinePoint(
          date: 'D${index.toString().padLeft(3, '0')}',
          open: price,
          close: price + 0.02,
          high: price + 0.08,
          low: price - 0.06,
          volume: 1000 + index * 10,
        );
      }),
    );
  }

  @override
  Future<void> saveActiveGroupId(String groupId) async {}

  @override
  Future<void> saveGroups(List<StockGroup> groups) async {}
}
