import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
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
    final previewIntraday =
        data.type == ChartType.intraday && data.intraday.isEmpty;
    final intradayPoints =
        previewIntraday ? _previewIntradayPoints(stock) : data.intraday;
    final hasData = data.type == ChartType.intraday
        ? intradayPoints.isNotEmpty
        : data.kLine.isNotEmpty;
    if (!hasData) {
      return Center(
        child: Text(
          '暂无图表数据',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
      child: data.type == ChartType.intraday
          ? Stack(
              children: [
                _IntradayLineChart(stock: stock, points: intradayPoints),
                if (previewIntraday) const _PreviewBadge(),
              ],
            )
          : _KLineCandlestickChart(points: data.kLine),
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 2,
      right: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppPalette.slate200),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(
            '预览走势',
            style: TextStyle(
              color: AppPalette.slate400,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

List<ChartPoint> _previewIntradayPoints(Stock stock) {
  final baseline = stock.preClose ?? stock.open ?? stock.price ?? 100;
  if (baseline <= 0) return const [];
  final target = stock.price ?? baseline * (stock.isUp ? 1.018 : 0.982);
  final direction = target >= baseline ? 1.0 : -1.0;
  final trough = baseline * (1 - direction * 0.024);
  final points = <ChartPoint>[];
  var avg = baseline;

  for (var i = 0; i < 60; i++) {
    final t = i / 59;
    late final double price;
    if (t < 0.36) {
      final local = t / 0.36;
      price =
          _lerp(baseline, trough, local) + math.sin(i * 1.7) * baseline * 0.004;
    } else if (t < 0.66) {
      final local = (t - 0.36) / 0.30;
      price = _lerp(trough, target, Curves.easeOutCubic.transform(local)) +
          math.sin(i * 1.1) * baseline * 0.003;
    } else {
      final local = (t - 0.66) / 0.34;
      price = _lerp(target * (1 - direction * 0.004), target, local);
    }
    avg = avg + (price - avg) * 0.075;
    points.add(
      ChartPoint(
        time: i == 0
            ? '09:30'
            : i == 59
                ? '15:00'
                : '',
        price: price,
        avg: avg,
        volume: 800000 + math.sin(i * 0.9).abs() * 2800000,
      ),
    );
  }
  return points;
}

double _lerp(double start, double end, double t) {
  return start + (end - start) * t.clamp(0, 1);
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
        titlesData: _titlesData(
          scheme,
          bottomStartLabel: points.first.time,
          bottomEndLabel: points.last.time,
        ),
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
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: scheme.outline.withValues(alpha: 0.42),
                  strokeWidth: 0.9,
                  dashArray: [4, 4],
                ),
                FlDotData(
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 3.4,
                      color: barData.color ?? trendColor,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
              );
            }).toList();
          },
          getTouchLineEnd: (barData, spotIndex) => double.infinity,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            tooltipBorderRadius: BorderRadius.circular(12),
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            maxContentWidth: 156,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final index = spot.x.round().clamp(0, points.length - 1);
                final point = points[index];
                if (spot.barIndex != 0) return null;
                final avg = point.avg == null || point.avg! <= 0
                    ? '--'
                    : point.avg!.toStringAsFixed(2);
                return LineTooltipItem(
                  '${point.time}\n'
                  '价格 ${point.price.toStringAsFixed(2)}\n'
                  '均价 $avg\n'
                  '成交量 ${_compactVolume(point.volume ?? 0)}',
                  TextStyle(
                    color: scheme.onInverseSurface,
                    fontSize: 10.5,
                    height: 1.32,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.left,
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

class _KLineCandlestickChart extends StatefulWidget {
  const _KLineCandlestickChart({
    required this.points,
  });

  final List<KLinePoint> points;

  @override
  State<_KLineCandlestickChart> createState() => _KLineCandlestickChartState();
}

class _KLineCandlestickChartState extends State<_KLineCandlestickChart> {
  static const _defaultVisibleCount = 60;
  static const _minVisibleCount = 18;
  static const _maxVisibleCount = 160;
  static const _tapSlop = 10.0;
  static const _doubleTapSlop = 36.0;
  static const _doubleTapTimeout = Duration(milliseconds: 360);

  int _visibleCount = _defaultVisibleCount;
  int? _endIndex;
  int _scaleStartVisibleCount = _defaultVisibleCount;
  double _dragRemainder = 0;
  final Set<int> _activePointers = <int>{};
  final Map<int, double> _pointerTravel = <int, double>{};
  DateTime? _lastTapAt;
  Offset? _lastTapPosition;

  @override
  void didUpdateWidget(covariant _KLineCandlestickChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points.length != widget.points.length) {
      _endIndex = null;
      _visibleCount = _visibleCount
          .clamp(
            _minVisibleCount,
            math.min(
              _maxVisibleCount,
              math.max(_minVisibleCount, widget.points.length),
            ),
          )
          .toInt();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enriched = _withMovingAverages(widget.points);
    final visible = _visibleWindow(enriched);
    final candleSpots = [
      for (var i = 0; i < visible.length; i++)
        CandlestickSpot(
          x: i.toDouble(),
          open: visible[i].point.open,
          high: visible[i].point.high,
          low: visible[i].point.low,
          close: visible[i].point.close,
        ),
    ];
    final values = visible
        .expand(
          (point) => [
            point.point.high,
            point.point.low,
            point.ma5,
            point.ma10,
            point.ma20,
            point.ma30,
            point.ma60,
          ],
        )
        .whereType<double>()
        .where((value) => value > 0)
        .toList();
    final (minY, maxY) = _paddedDomain(values, 0.06);
    final candleWidth =
        math.max(3.0, math.min(10.0, 280 / math.max(8, visible.length) * 0.62));
    final maBars = _movingAverageBars(visible);
    final volumeMax = visible
        .map((item) => item.point.volume)
        .where((volume) => volume > 0)
        .fold<double>(0, math.max);

    return LayoutBuilder(
      builder: (context, constraints) {
        final step = constraints.maxWidth / math.max(1, visible.length);
        return Listener(
          onPointerDown: (event) {
            _activePointers.add(event.pointer);
            _pointerTravel[event.pointer] = 0;
            _dragRemainder = 0;
          },
          onPointerMove: (event) {
            _pointerTravel[event.pointer] =
                (_pointerTravel[event.pointer] ?? 0) + event.delta.distance;
            if (_activePointers.length != 1) return;
            if (event.kind == PointerDeviceKind.mouse &&
                (event.buttons & kPrimaryMouseButton) == 0) {
              return;
            }
            _panWindow(event.delta.dx, step);
          },
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerCancel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: _resetWindow,
            onScaleStart: (_) {
              _scaleStartVisibleCount = _visibleCount;
              _dragRemainder = 0;
            },
            onScaleUpdate: (details) {
              if (details.pointerCount > 1 ||
                  (details.scale - 1).abs() >= 0.04) {
                _zoomWindow(details.scale, enriched.length);
              }
            },
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      CandlestickChart(
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
                              final color =
                                  _trendColor(spot.close >= spot.open);
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
                              tooltipPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              maxContentWidth: 190,
                              getTooltipColor: (_) => scheme.inverseSurface,
                              tooltipBorderRadius: BorderRadius.circular(12),
                              getTooltipItems: (_, spot, spotIndex) {
                                final index =
                                    spotIndex.clamp(0, visible.length - 1);
                                final item = visible[index];
                                final point = item.point;
                                return CandlestickTooltipItem(
                                  '${point.date}\n'
                                  '开 ${spot.open.toStringAsFixed(2)}  高 ${spot.high.toStringAsFixed(2)}\n'
                                  '低 ${spot.low.toStringAsFixed(2)}  收 ${spot.close.toStringAsFixed(2)}\n'
                                  '量 ${_compactVolume(point.volume)}\n'
                                  '${_maTooltipLine(item)}',
                                  textStyle: TextStyle(
                                    color: scheme.onInverseSurface,
                                    fontSize: 10.5,
                                    height: 1.32,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  textAlign: TextAlign.left,
                                );
                              },
                            ),
                          ),
                        ),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      ),
                      if (maBars.isNotEmpty)
                        IgnorePointer(
                          child: LineChart(
                            LineChartData(
                              minX: 0,
                              maxX: math.max(1, visible.length - 1).toDouble(),
                              minY: minY,
                              maxY: maxY,
                              clipData: const FlClipData.all(),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              titlesData: const FlTitlesData(show: false),
                              lineTouchData:
                                  const LineTouchData(enabled: false),
                              lineBarsData: maBars,
                            ),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                      if (maBars.isNotEmpty)
                        Positioned(
                          left: 4,
                          top: 0,
                          child: Wrap(
                            spacing: 7,
                            children: const [
                              _MaLegend(
                                label: 'MA5',
                                color: Color(0xFFF59E0B),
                              ),
                              _MaLegend(
                                label: 'MA10',
                                color: Color(0xFF3B82F6),
                              ),
                              _MaLegend(
                                label: 'MA20',
                                color: Color(0xFFA855F7),
                              ),
                              _MaLegend(
                                label: 'MA30',
                                color: Color(0xFF22C55E),
                              ),
                              _MaLegend(
                                label: 'MA60',
                                color: Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (volumeMax > 0) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 46,
                    child: _KLineVolumeChart(
                      points: visible,
                      maxY: volumeMax * 1.12,
                      barWidth: math.max(1.6, math.min(4.8, step * 0.48)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<_KLinePointWithMa> _visibleWindow(List<_KLinePointWithMa> points) {
    if (points.isEmpty) return const [];
    final count = _visibleCount
        .clamp(
          math.min(_minVisibleCount, points.length),
          math.min(_maxVisibleCount, points.length),
        )
        .toInt();
    final end = (_endIndex ?? points.length - 1)
        .clamp(count - 1, points.length - 1)
        .toInt();
    final start = end - count + 1;
    return points.sublist(start, end + 1);
  }

  void _panWindow(double deltaX, double step) {
    if (widget.points.length <= _visibleCount) return;
    _dragRemainder += deltaX;
    final threshold = math.max(3.0, step);
    final moved = (_dragRemainder / threshold).truncate();
    if (moved == 0) return;
    _dragRemainder -= moved * threshold;
    _shiftWindow(-moved);
  }

  void _shiftWindow(int candleDelta) {
    final total = widget.points.length;
    if (total == 0) return;
    final count = _visibleCount
        .clamp(
          math.min(_minVisibleCount, total),
          math.min(_maxVisibleCount, total),
        )
        .toInt();
    final currentEnd =
        (_endIndex ?? total - 1).clamp(count - 1, total - 1).toInt();
    final nextEnd =
        (currentEnd + candleDelta).clamp(count - 1, total - 1).toInt();
    if (nextEnd == currentEnd) return;
    setState(() => _endIndex = nextEnd);
  }

  void _zoomWindow(double scale, int total) {
    if (total <= _minVisibleCount || (scale - 1).abs() < 0.04) return;
    final next = (_scaleStartVisibleCount / scale)
        .round()
        .clamp(
          _minVisibleCount,
          math.min(_maxVisibleCount, total),
        )
        .toInt();
    if (next == _visibleCount) return;
    setState(() {
      _visibleCount = next;
      _endIndex =
          (_endIndex ?? total - 1).clamp(_visibleCount - 1, total - 1).toInt();
    });
  }

  void _resetWindow() {
    setState(() {
      _visibleCount = _defaultVisibleCount
          .clamp(
            _minVisibleCount,
            math.min(
              _maxVisibleCount,
              math.max(_minVisibleCount, widget.points.length),
            ),
          )
          .toInt();
      _endIndex = null;
      _dragRemainder = 0;
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    final wasSinglePointer = _activePointers.length == 1;
    final travel = _pointerTravel[event.pointer] ?? double.infinity;
    _handlePointerCancel(event);
    if (!wasSinglePointer || travel > _tapSlop) return;
    _registerTap(event.localPosition);
  }

  void _handlePointerCancel(PointerEvent event) {
    _activePointers.remove(event.pointer);
    _pointerTravel.remove(event.pointer);
  }

  void _registerTap(Offset position) {
    final now = DateTime.now();
    final lastTapAt = _lastTapAt;
    final lastTapPosition = _lastTapPosition;
    final isDoubleTap = lastTapAt != null &&
        now.difference(lastTapAt) <= _doubleTapTimeout &&
        lastTapPosition != null &&
        (position - lastTapPosition).distance <= _doubleTapSlop;

    if (isDoubleTap) {
      _lastTapAt = null;
      _lastTapPosition = null;
      _resetWindow();
      return;
    }

    _lastTapAt = now;
    _lastTapPosition = position;
  }
}

class _KLineVolumeChart extends StatelessWidget {
  const _KLineVolumeChart({
    required this.points,
    required this.maxY,
    required this.barWidth,
  });

  final List<_KLinePointWithMa> points;
  final double maxY;
  final double barWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        alignment: BarChartAlignment.spaceBetween,
        groupsSpace: 0,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              maxIncluded: false,
              minIncluded: false,
              getTitlesWidget: (value, meta) {
                if (value <= 0) return const SizedBox.shrink();
                return Text(
                  _compactVolume(value),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: const BarTouchData(enabled: false),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: math.max(0, points[i].point.volume),
                  width: barWidth,
                  color:
                      _trendColor(points[i].point.close >= points[i].point.open)
                          .withValues(alpha: 0.38),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(1.5)),
                ),
              ],
            ),
        ],
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }
}

class _KLinePointWithMa {
  const _KLinePointWithMa({
    required this.point,
    this.ma5,
    this.ma10,
    this.ma20,
    this.ma30,
    this.ma60,
  });

  final KLinePoint point;
  final double? ma5;
  final double? ma10;
  final double? ma20;
  final double? ma30;
  final double? ma60;
}

class _MaLegend extends StatelessWidget {
  const _MaLegend({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

List<_KLinePointWithMa> _withMovingAverages(List<KLinePoint> points) {
  double? averageAt(int index, int days) {
    if (index < days - 1) return null;
    var sum = 0.0;
    for (var i = 0; i < days; i++) {
      sum += points[index - i].close;
    }
    return sum / days;
  }

  return [
    for (var i = 0; i < points.length; i++)
      _KLinePointWithMa(
        point: points[i],
        ma5: averageAt(i, 5),
        ma10: averageAt(i, 10),
        ma20: averageAt(i, 20),
        ma30: averageAt(i, 30),
        ma60: averageAt(i, 60),
      ),
  ];
}

List<LineChartBarData> _movingAverageBars(List<_KLinePointWithMa> points) {
  final bars = [
    _movingAverageBar(points, (point) => point.ma5, const Color(0xFFF59E0B)),
    _movingAverageBar(points, (point) => point.ma10, const Color(0xFF3B82F6)),
    _movingAverageBar(points, (point) => point.ma20, const Color(0xFFA855F7)),
    _movingAverageBar(points, (point) => point.ma30, const Color(0xFF22C55E)),
    _movingAverageBar(points, (point) => point.ma60, const Color(0xFF94A3B8)),
  ];
  return bars.whereType<LineChartBarData>().toList();
}

LineChartBarData? _movingAverageBar(
  List<_KLinePointWithMa> points,
  double? Function(_KLinePointWithMa point) selector,
  Color color,
) {
  final spots = <FlSpot>[];
  for (var i = 0; i < points.length; i++) {
    final value = selector(points[i]);
    if (value == null || value <= 0) continue;
    spots.add(FlSpot(i.toDouble(), value));
  }
  if (spots.length < 2) return null;
  return LineChartBarData(
    spots: spots,
    color: color,
    barWidth: 1.05,
    isCurved: true,
    curveSmoothness: 0.12,
    preventCurveOverShooting: true,
    dotData: const FlDotData(show: false),
    isStrokeCapRound: true,
  );
}

String _maTooltipLine(_KLinePointWithMa item) {
  String value(double? input) {
    if (input == null || input <= 0) return '--';
    return input.toStringAsFixed(2);
  }

  return 'MA5 ${value(item.ma5)}  MA10 ${value(item.ma10)}\n'
      'MA20 ${value(item.ma20)}  MA60 ${value(item.ma60)}';
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

FlTitlesData _titlesData(
  ColorScheme scheme, {
  String? bottomStartLabel,
  String? bottomEndLabel,
}) {
  final axisTextStyle = TextStyle(
    color: scheme.onSurfaceVariant.withValues(alpha: 0.82),
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );

  return FlTitlesData(
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 44,
        maxIncluded: false,
        minIncluded: false,
        getTitlesWidget: (value, meta) {
          return Text(value.toStringAsFixed(2), style: axisTextStyle);
        },
      ),
    ),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: bottomStartLabel != null || bottomEndLabel != null,
        reservedSize: 20,
        interval: 1,
        getTitlesWidget: (value, meta) {
          final isStart = (value - meta.min).abs() < 0.01;
          final isEnd = (value - meta.max).abs() < 0.01;
          final label = isStart
              ? bottomStartLabel
              : isEnd
                  ? bottomEndLabel
                  : null;
          if (label == null || label.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(label, style: axisTextStyle),
          );
        },
      ),
    ),
  );
}

(double, double) _paddedDomain(List<double> values, double factor) {
  if (values.isEmpty) return (0, 1);
  final minValue = values.reduce(math.min);
  final maxValue = values.reduce(math.max);
  final padding = (maxValue - minValue).abs() < 0.0001
      ? maxValue.abs() * 0.02 + 1
      : (maxValue - minValue) * factor;
  return (minValue - padding, maxValue + padding);
}

Color _trendColor(bool isUp) {
  return isUp ? const Color(0xFF2563EB) : const Color(0xFF475569);
}

String _compactVolume(double value) {
  if (value >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)}B';
  if (value >= 100000000) return '${(value / 100000000).toStringAsFixed(1)}亿';
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return value.toStringAsFixed(0);
}
