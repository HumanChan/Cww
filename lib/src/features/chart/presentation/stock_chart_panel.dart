import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../market/domain/chart_models.dart';
import '../../market/domain/stock.dart';

class StockChartPanel extends StatelessWidget {
  const StockChartPanel({
    required this.stock,
    required this.data,
    super.key,
  });

  final Stock stock;
  final ChartData data;

  @override
  Widget build(BuildContext context) {
    final hasData = data.type == ChartType.intraday ? data.intraday.isNotEmpty : data.kLine.isNotEmpty;
    if (!hasData) {
      return Center(
        child: Text(
          '暂无图表数据',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
      child: data.type == ChartType.intraday
          ? _IntradayLineChart(stock: stock, points: data.intraday)
          : _KLineCandlestickChart(points: data.kLine),
    );
  }
}

class _IntradayLineChart extends StatelessWidget {
  const _IntradayLineChart({
    required this.stock,
    required this.points,
  });

  final Stock stock;
  final List<ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trendColor = _trendColor(stock.isUp);
    final priceSpots = <FlSpot>[];
    final avgSpots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      priceSpots.add(FlSpot(i.toDouble(), point.price));
      final avg = point.avg;
      if (avg != null && avg > 0) avgSpots.add(FlSpot(i.toDouble(), avg));
    }

    final values = [
      ...points.map((point) => point.price),
      ...points.map((point) => point.avg).whereType<double>(),
      if (stock.preClose != null) stock.preClose!,
    ].where((value) => value > 0).toList();
    final (minY, maxY) = _paddedDomain(values, 0.08);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(1, points.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: _gridData(scheme),
        borderData: FlBorderData(show: false),
        titlesData: _titlesData(scheme),
        extraLinesData: stock.preClose == null
            ? const ExtraLinesData()
            : ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: stock.preClose!,
                    color: scheme.outlineVariant,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ],
              ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            tooltipBorderRadius: BorderRadius.circular(12),
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final index = spot.x.round().clamp(0, points.length - 1);
                final point = points[index];
                final label = spot.barIndex == 0 ? '价格' : '均价';
                return LineTooltipItem(
                  '${point.time}\n$label ${spot.y.toStringAsFixed(2)}',
                  TextStyle(
                    color: scheme.onInverseSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: priceSpots,
            color: trendColor,
            barWidth: 2.2,
            isCurved: true,
            curveSmoothness: 0.18,
            preventCurveOverShooting: true,
            isStrokeCapRound: true,
            isStrokeJoinRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  trendColor.withValues(alpha: 0.24),
                  trendColor.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          if (avgSpots.length > 1)
            LineChartBarData(
              spots: avgSpots,
              color: const Color(0xFFF59E0B),
              barWidth: 1.4,
              isCurved: true,
              curveSmoothness: 0.14,
              preventCurveOverShooting: true,
              dotData: const FlDotData(show: false),
            ),
        ],
      ),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }
}

class _KLineCandlestickChart extends StatelessWidget {
  const _KLineCandlestickChart({
    required this.points,
  });

  final List<KLinePoint> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = points.length > 72 ? points.sublist(points.length - 72) : points;
    final candleSpots = [
      for (var i = 0; i < visible.length; i++)
        CandlestickSpot(
          x: i.toDouble(),
          open: visible[i].open,
          high: visible[i].high,
          low: visible[i].low,
          close: visible[i].close,
        ),
    ];
    final values = visible.expand((point) => [point.high, point.low]).where((value) => value > 0).toList();
    final (minY, maxY) = _paddedDomain(values, 0.06);
    final candleWidth = math.max(3.0, math.min(10.0, 280 / math.max(8, visible.length) * 0.62));

    return CandlestickChart(
      CandlestickChartData(
        candlestickSpots: candleSpots,
        minX: 0,
        maxX: math.max(1, visible.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: _gridData(scheme),
        borderData: FlBorderData(show: false),
        titlesData: _titlesData(scheme),
        candlestickPainter: DefaultCandlestickPainter(
          candlestickStyleProvider: (spot, _) {
            final color = _trendColor(spot.close >= spot.open);
            return CandlestickStyle(
              lineColor: color,
              lineWidth: 1.2,
              bodyStrokeColor: color,
              bodyStrokeWidth: 1,
              bodyFillColor: color.withValues(alpha: 0.92),
              bodyWidth: candleWidth,
              bodyRadius: 2,
            );
          },
        ),
        candlestickTouchData: CandlestickTouchData(
          touchTooltipData: CandlestickTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipColor: (_) => scheme.inverseSurface,
            tooltipBorderRadius: BorderRadius.circular(12),
            getTooltipItems: (_, spot, spotIndex) {
              final index = spotIndex.clamp(0, visible.length - 1);
              final point = visible[index];
              return CandlestickTooltipItem(
                '${point.date}\n开 ${spot.open.toStringAsFixed(2)}  收 ${spot.close.toStringAsFixed(2)}',
                textStyle: TextStyle(
                  color: scheme.onInverseSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ),
      ),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }
}

FlGridData _gridData(ColorScheme scheme) {
  return FlGridData(
    drawVerticalLine: false,
    getDrawingHorizontalLine: (_) => FlLine(
      color: scheme.outlineVariant.withValues(alpha: 0.55),
      strokeWidth: 0.8,
    ),
  );
}

FlTitlesData _titlesData(ColorScheme scheme) {
  return FlTitlesData(
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 44,
        maxIncluded: false,
        minIncluded: false,
        getTitlesWidget: (value, meta) => Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
    bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  );
}

(double, double) _paddedDomain(List<double> values, double factor) {
  if (values.isEmpty) return (0, 1);
  final minValue = values.reduce(math.min);
  final maxValue = values.reduce(math.max);
  final padding = (maxValue - minValue).abs() < 0.0001 ? maxValue.abs() * 0.02 + 1 : (maxValue - minValue) * factor;
  return (minValue - padding, maxValue + padding);
}

Color _trendColor(bool isUp) {
  return isUp ? const Color(0xFF2563EB) : const Color(0xFF475569);
}
