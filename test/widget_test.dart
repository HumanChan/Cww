import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cww_flutter/src/app.dart';
import 'package:cww_flutter/src/features/market/data/binance_service.dart';
import 'package:cww_flutter/src/features/market/data/east_money_service.dart';
import 'package:cww_flutter/src/features/market/data/market_repository.dart';
import 'package:cww_flutter/src/features/market/data/yahoo_finance_service.dart';
import 'package:cww_flutter/src/features/market/domain/chart_models.dart';
import 'package:cww_flutter/src/features/market/domain/market_index_snapshot.dart';
import 'package:cww_flutter/src/features/market/domain/stock.dart';
import 'package:cww_flutter/src/features/watchlist/presentation/widgets/market_index_bar.dart';
import 'package:dio/dio.dart';

void main() {
  testWidgets('自选列表启动烟测', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MoYuStockApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('存为王'), findsOneWidget);
    expect(find.text('GD'), findsOneWidget);
  });

  testWidgets('分组管理面板包含清晰的操作分区', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MoYuStockApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('分组管理'), findsOneWidget);
    expect(find.text('新建分组'), findsOneWidget);
    expect(find.text('分组顺序'), findsOneWidget);
    expect(find.text('数据与备份'), findsOneWidget);
  });

  testWidgets('首页搜索按钮打开底部搜索面板', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MoYuStockApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byKey(const ValueKey('bottom-search-field')), findsNothing);
    await tester.tap(find.byTooltip('搜索添加'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('搜索并添加'), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-search-field')), findsOneWidget);
  });

  testWidgets('指数详情面板在窄屏无布局溢出', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const snapshot = MarketIndexSnapshot(
      index: Stock(
        code: '000001',
        name: '上证指数',
        secid: '1.000001',
        price: 3996.16,
        change: -40.43,
        percent: -1,
        preClose: 4036.59,
        open: 4031.54,
        high: 4074.83,
        low: 3995.81,
        volume: 627000000,
        amount: 1560000000000,
        volumeRatio: 1.14,
      ),
      advancing: 1542,
      unchanged: 40,
      declining: 763,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketRepositoryProvider.overrideWithValue(
            _WidgetTestMarketRepository(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: MarketIndexBar(
                market: Market.cn,
                snapshots: [snapshot],
                isLoading: false,
                error: null,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('index-1.000001')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('今日行情'), findsOneWidget);
    expect(find.text('市场涨跌分布'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _WidgetTestMarketRepository extends MarketRepository {
  _WidgetTestMarketRepository()
      : super(
          eastMoney: EastMoneyService(Dio()),
          binance: BinanceService(Dio()),
          yahoo: YahooFinanceService(Dio()),
        );

  @override
  Future<ChartData> fetchChart(
    Stock stock,
    ChartType type, {
    bool forceRefresh = false,
  }) async {
    return const ChartData(
      type: ChartType.intraday,
      intraday: [
        ChartPoint(time: '09:30', price: 4030),
        ChartPoint(time: '15:00', price: 3996.16),
      ],
    );
  }
}
