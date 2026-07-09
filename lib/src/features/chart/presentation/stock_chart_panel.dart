import 'dart:math' as math;

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
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 18),
      child: CustomPaint(
        painter: data.type == ChartType.intraday
            ? _IntradayPainter(
                points: data.intraday,
                preClose: stock.preClose,
                isUp: stock.isUp,
                colorScheme: Theme.of(context).colorScheme,
              )
            : _KLinePainter(
                points: data.kLine,
                colorScheme: Theme.of(context).colorScheme,
              ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _IntradayPainter extends CustomPainter {
  _IntradayPainter({
    required this.points,
    required this.preClose,
    required this.isUp,
    required this.colorScheme,
  });

  final List<ChartPoint> points;
  final double? preClose;
  final bool isUp;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTWH(42, 12, size.width - 84, size.height - 42);
    if (chart.width <= 0 || chart.height <= 0) return;
    _drawGrid(canvas, chart, colorScheme);

    final values = [
      ...points.map((point) => point.price),
      ...points.map((point) => point.avg).whereType<double>(),
      if (preClose != null) preClose!,
    ].where((value) => value > 0).toList();
    if (values.isEmpty) return;
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final padding = (maxValue - minValue).abs() < 0.0001 ? maxValue * 0.02 : (maxValue - minValue) * 0.08;
    final low = minValue - padding;
    final high = maxValue + padding;
    final trend = isUp ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

    Offset mapPoint(int index, double price) {
      final x = chart.left + chart.width * index / math.max(1, points.length - 1);
      final y = chart.bottom - ((price - low) / (high - low)) * chart.height;
      return Offset(x, y);
    }

    final pricePath = Path();
    for (var i = 0; i < points.length; i++) {
      final offset = mapPoint(i, points[i].price);
      if (i == 0) {
        pricePath.moveTo(offset.dx, offset.dy);
      } else {
        pricePath.lineTo(offset.dx, offset.dy);
      }
    }

    final fillPath = Path.from(pricePath)
      ..lineTo(chart.right, chart.bottom)
      ..lineTo(chart.left, chart.bottom)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [trend.withOpacity(0.20), trend.withOpacity(0.0)],
      ).createShader(chart);
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(
      pricePath,
      Paint()
        ..color = trend
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final avgPath = Path();
    var hasAvg = false;
    for (var i = 0; i < points.length; i++) {
      final avg = points[i].avg;
      if (avg == null || avg <= 0) continue;
      final offset = mapPoint(i, avg);
      if (!hasAvg) {
        avgPath.moveTo(offset.dx, offset.dy);
        hasAvg = true;
      } else {
        avgPath.lineTo(offset.dx, offset.dy);
      }
    }
    if (hasAvg) {
      canvas.drawPath(
        avgPath,
        Paint()
          ..color = const Color(0xFFEAB308)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }

    if (preClose != null && preClose! > low && preClose! < high) {
      final y = chart.bottom - ((preClose! - low) / (high - low)) * chart.height;
      _drawDashedLine(canvas, Offset(chart.left, y), Offset(chart.right, y), colorScheme.outlineVariant);
    }
    _drawAxisLabels(canvas, chart, high, low, colorScheme);
  }

  @override
  bool shouldRepaint(covariant _IntradayPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.preClose != preClose || oldDelegate.isUp != isUp;
  }
}

class _KLinePainter extends CustomPainter {
  _KLinePainter({
    required this.points,
    required this.colorScheme,
  });

  final List<KLinePoint> points;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTWH(42, 12, size.width - 84, size.height - 42);
    if (chart.width <= 0 || chart.height <= 0) return;
    _drawGrid(canvas, chart, colorScheme);

    final visible = points.length > 72 ? points.sublist(points.length - 72) : points;
    final values = visible.expand((point) => [point.high, point.low]).where((value) => value > 0).toList();
    if (values.isEmpty) return;

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final padding = (maxValue - minValue).abs() < 0.0001 ? maxValue * 0.02 : (maxValue - minValue) * 0.06;
    final low = minValue - padding;
    final high = maxValue + padding;
    final step = chart.width / visible.length;
    final candleWidth = math.max(3.0, math.min(12.0, step * 0.62));

    double yOf(double price) => chart.bottom - ((price - low) / (high - low)) * chart.height;

    for (var i = 0; i < visible.length; i++) {
      final point = visible[i];
      final x = chart.left + step * i + step / 2;
      final isUp = point.close >= point.open;
      final color = isUp ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
      final paint = Paint()..color = color;
      canvas.drawLine(
        Offset(x, yOf(point.high)),
        Offset(x, yOf(point.low)),
        paint..strokeWidth = 1,
      );
      final top = math.min(yOf(point.open), yOf(point.close));
      final bottom = math.max(yOf(point.open), yOf(point.close));
      final rect = Rect.fromLTRB(
        x - candleWidth / 2,
        top,
        x + candleWidth / 2,
        math.max(top + 1, bottom),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
        paint,
      );
    }

    _drawMa(canvas, chart, visible, low, high, 5, const Color(0xFFEAB308));
    _drawMa(canvas, chart, visible, low, high, 10, const Color(0xFF3B82F6));
    _drawMa(canvas, chart, visible, low, high, 20, const Color(0xFFA855F7));
    _drawMa(canvas, chart, visible, low, high, 30, const Color(0xFF16A34A));
    _drawMa(canvas, chart, visible, low, high, 60, const Color(0xFF94A3B8));
    _drawAxisLabels(canvas, chart, high, low, colorScheme);
  }

  void _drawMa(
    Canvas canvas,
    Rect chart,
    List<KLinePoint> visible,
    double low,
    double high,
    int days,
    Color color,
  ) {
    if (visible.length < days) return;
    final step = chart.width / visible.length;
    final path = Path();
    var started = false;
    for (var i = 0; i < visible.length; i++) {
      if (i < days - 1) continue;
      var sum = 0.0;
      for (var j = 0; j < days; j++) {
        sum += visible[i - j].close;
      }
      final avg = sum / days;
      final x = chart.left + step * i + step / 2;
      final y = chart.bottom - ((avg - low) / (high - low)) * chart.height;
      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }
    if (!started) return;
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.15
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _KLinePainter oldDelegate) => oldDelegate.points != points;
}

void _drawGrid(Canvas canvas, Rect chart, ColorScheme scheme) {
  final paint = Paint()
    ..color = scheme.outlineVariant.withOpacity(0.45)
    ..strokeWidth = 0.7;
  for (var i = 0; i <= 4; i++) {
    final y = chart.top + chart.height * i / 4;
    canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), paint);
  }
  for (var i = 0; i <= 4; i++) {
    final x = chart.left + chart.width * i / 4;
    canvas.drawLine(Offset(x, chart.top), Offset(x, chart.bottom), paint);
  }
}

void _drawAxisLabels(Canvas canvas, Rect chart, double high, double low, ColorScheme scheme) {
  final style = TextStyle(
    color: scheme.onSurfaceVariant,
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );
  for (final entry in [(high, chart.top), (((high + low) / 2), chart.center.dy), (low, chart.bottom - 12)]) {
    final painter = TextPainter(
      text: TextSpan(text: entry.$1.toStringAsFixed(2), style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 40);
    painter.paint(canvas, Offset(0, entry.$2));
  }
}

void _drawDashedLine(Canvas canvas, Offset start, Offset end, Color color) {
  const dashWidth = 6.0;
  const dashSpace = 4.0;
  final paint = Paint()
    ..color = color
    ..strokeWidth = 1;
  var distance = 0.0;
  final total = (end - start).distance;
  while (distance < total) {
    final from = Offset.lerp(start, end, distance / total)!;
    final to = Offset.lerp(start, end, math.min(1, (distance + dashWidth) / total))!;
    canvas.drawLine(from, to, paint);
    distance += dashWidth + dashSpace;
  }
}
