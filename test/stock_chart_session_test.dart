import 'package:cww_flutter/src/core/theme/app_theme.dart';
import 'package:cww_flutter/src/features/chart/presentation/stock_chart_panel.dart';
import 'package:cww_flutter/src/features/market/domain/chart_models.dart';
import 'package:cww_flutter/src/features/market/domain/stock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('A股分时轴使用含午休的交易时段', (tester) async {
    await _pumpChart(
      tester,
      const Stock(
        code: '600000',
        name: '浦发银行',
        secid: '1.600000',
        market: Market.cn,
        preClose: 10,
      ),
      const [
        ChartPoint(time: '09:30', price: 10.1),
        ChartPoint(time: '11:30', price: 10.2),
        ChartPoint(time: '13:00', price: 10.2),
        ChartPoint(time: '15:00', price: 10.3),
      ],
    );

    expect(find.text('09:30'), findsOneWidget);
    expect(find.text('15:00'), findsOneWidget);
  });

  testWidgets('港股分时轴止于香港收盘时间', (tester) async {
    await _pumpChart(
      tester,
      const Stock(
        code: '00700',
        name: '腾讯控股',
        secid: '116.00700',
        market: Market.hk,
        preClose: 100,
      ),
      const [
        ChartPoint(time: '09:30', price: 101),
        ChartPoint(time: '16:00', price: 102),
      ],
    );

    expect(find.text('09:30'), findsOneWidget);
    expect(find.text('16:00'), findsOneWidget);
  });

  testWidgets('韩股分时轴使用韩国本地交易时间', (tester) async {
    await _pumpChart(
      tester,
      const Stock(
        code: '005930.KS',
        name: '三星电子',
        secid: '177.005930',
        market: Market.kr,
        preClose: 100,
      ),
      const [
        ChartPoint(time: '08:00', price: 101),
        ChartPoint(time: '14:30', price: 102),
      ],
    );

    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('15:30'), findsOneWidget);
  });

  testWidgets('台股分时轴止于本地收盘时间', (tester) async {
    await _pumpChart(
      tester,
      const Stock(
        code: '2330.TW',
        name: '台积电',
        secid: '178.2330',
        market: Market.tw,
        preClose: 100,
      ),
      const [
        ChartPoint(time: '09:00', price: 101),
        ChartPoint(time: '13:30', price: 102),
        ChartPoint(time: '15:00', price: 102),
      ],
    );

    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('13:30'), findsOneWidget);
    expect(find.text('15:00'), findsNothing);
  });

  testWidgets('美股分时轴显示纽约常规交易时段', (tester) async {
    await _pumpChart(
      tester,
      const Stock(
        code: 'AAPL',
        name: 'Apple',
        secid: '105.AAPL',
        market: Market.us,
        preClose: 100,
      ),
      const [
        ChartPoint(time: '21:30', price: 101),
        ChartPoint(time: '04:00', price: 102),
      ],
    );

    expect(find.text('09:30'), findsOneWidget);
    expect(find.text('16:00'), findsOneWidget);
  });

  testWidgets('日股分时轴使用日本本地交易时间', (tester) async {
    await _pumpChart(
      tester,
      const Stock(
        code: '7203',
        name: '丰田汽车',
        secid: '176.7203',
        market: Market.jp,
        preClose: 100,
      ),
      const [
        ChartPoint(time: '08:00', price: 101),
        ChartPoint(time: '10:30', price: 102),
        ChartPoint(time: '11:30', price: 102),
        ChartPoint(time: '14:30', price: 103),
      ],
    );

    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('15:30'), findsOneWidget);
  });

  testWidgets('价格纵轴只显示顶部中间和底部三档', (tester) async {
    await _pumpChart(
      tester,
      const Stock(
        code: '600000',
        name: '浦发银行',
        secid: '1.600000',
        market: Market.cn,
        preClose: 10,
      ),
      const [
        ChartPoint(time: '09:30', price: 10),
        ChartPoint(time: '11:30', price: 10.5),
        ChartPoint(time: '15:00', price: 11),
      ],
    );

    final priceLabels = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .where((text) => RegExp(r'^\d+\.\d{2}$').hasMatch(text))
        .toList();
    expect(priceLabels, hasLength(3));
  });
}

Future<void> _pumpChart(
  WidgetTester tester,
  Stock stock,
  List<ChartPoint> points,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SizedBox(
          width: 520,
          height: 320,
          child: StockChartPanel(
            stock: stock,
            data: ChartData(type: ChartType.intraday, intraday: points),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
