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
    this.onRetry,
    super.key,
  });

  final Stock stock;
  final ChartData data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final hasData = data.type == ChartType.intraday
        ? data.intraday.isNotEmpty
        : data.kLine.isNotEmpty;
    if (!hasData) {
      return _ChartEmptyState(onRetry: onRetry);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: data.type == ChartType.intraday
          ? _IntradayLineChart(stock: stock, points: data.intraday)
          : _KLineCandlestickChart(points: data.kLine),
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.surfaceInteractive,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Icon(
                Icons.query_stats_rounded,
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '暂无可用走势数据',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '行情源暂未返回该周期数据，未使用模拟走势。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textTertiary,
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('重新加载'),
              ),
            ],
          ],
        ),
      ),
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
    final colors = context.appColors;
    final trendColor = stock.percent == null || stock.percent == 0
        ? colors.flat
        : stock.percent! > 0
            ? colors.gain
            : colors.loss;
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
                      strokeColor: colors.surface,
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
              color: colors.ma5,
              barWidth: 1.4,
              isCurved: true,
              curveSmoothness: 0.14,
              preventCurveOverShooting: true,
              dotData: const FlDotData(show: false),
            ),
        ],
      ),
      duration: Duration.zero,
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
  late List<_KLinePointWithMa> _enrichedPoints;
  final Set<int> _activePointers = <int>{};
  final Map<int, double> _pointerTravel = <int, double>{};
  DateTime? _lastTapAt;
  Offset? _lastTapPosition;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _enrichedPoints = _withMovingAverages(widget.points);
  }

  @override
  void didUpdateWidget(covariant _KLineCandlestickChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.points, widget.points)) {
      _enrichedPoints = _withMovingAverages(widget.points);
    }
    if (oldWidget.points.length != widget.points.length) {
      _endIndex = null;
      _touchedIndex = null;
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
    final colors = context.appColors;
    final enriched = _enrichedPoints;
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
    final maBars = _movingAverageBars(visible, colors);
    final touchedItem = _selectedKLinePoint(visible);
    final volumeMax = visible
        .map((item) => item.point.volume)
        .where((volume) => volume > 0)
        .fold<double>(0, math.max);

    return LayoutBuilder(
      builder: (context, constraints) {
        final step = constraints.maxWidth / math.max(1, visible.length);
        final candleWidth = math.max(
          3.0,
          math.min(
            11.0,
            constraints.maxWidth / math.max(8, visible.length) * 0.58,
          ),
        );
        return MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                GestureBinding.instance.pointerSignalResolver.register(
                  event,
                  (resolvedEvent) => _zoomWithWheel(
                    (resolvedEvent as PointerScrollEvent).scrollDelta.dy,
                    enriched.length,
                  ),
                );
              }
            },
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
                            titlesData: _titlesData(
                              scheme,
                              bottomStartLabel: visible.first.point.date,
                              bottomEndLabel: visible.last.point.date,
                            ),
                            candlestickPainter: DefaultCandlestickPainter(
                              candlestickStyleProvider: (spot, _) {
                                final color = spot.close == spot.open
                                    ? colors.flat
                                    : spot.close > spot.open
                                        ? colors.gain
                                        : colors.loss;
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
                              touchSpotThreshold: math.max(
                                8,
                                candleWidth * 0.75,
                              ),
                              touchCallback: (event, response) =>
                                  _handleCandlestickTouch(
                                event,
                                response,
                                visible.length,
                              ),
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
                          duration: Duration.zero,
                        ),
                        if (maBars.isNotEmpty)
                          IgnorePointer(
                            child: LineChart(
                              LineChartData(
                                minX: 0,
                                maxX:
                                    math.max(1, visible.length - 1).toDouble(),
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
                              duration: Duration.zero,
                            ),
                          ),
                        if (maBars.isNotEmpty)
                          Positioned(
                            left: 4,
                            top: 0,
                            right: 4,
                            child: _MaLegendStrip(item: touchedItem),
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
                        selectedIndex: _touchedIndex,
                      ),
                    ),
                  ],
                ],
              ),
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
    setState(() {
      _endIndex = nextEnd;
      _touchedIndex = null;
    });
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
      _touchedIndex = null;
      _endIndex =
          (_endIndex ?? total - 1).clamp(_visibleCount - 1, total - 1).toInt();
    });
  }

  void _zoomWithWheel(double deltaY, int total) {
    if (deltaY == 0 || total <= _minVisibleCount) return;
    final step = math.max(2, (_visibleCount * 0.10).round());
    final next = (_visibleCount + (deltaY > 0 ? step : -step))
        .clamp(_minVisibleCount, math.min(_maxVisibleCount, total))
        .toInt();
    if (next == _visibleCount) return;
    setState(() {
      _visibleCount = next;
      _touchedIndex = null;
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
      _touchedIndex = null;
    });
  }

  void _handleCandlestickTouch(
    FlTouchEvent event,
    CandlestickTouchResponse? response,
    int visibleLength,
  ) {
    final touchedSpot = response?.touchedSpot;
    final nextIndex = event.isInterestedForInteractions &&
            touchedSpot != null &&
            touchedSpot.spotIndex >= 0 &&
            touchedSpot.spotIndex < visibleLength
        ? touchedSpot.spotIndex
        : null;
    if (_touchedIndex == nextIndex) return;
    setState(() => _touchedIndex = nextIndex);
  }

  _KLinePointWithMa? _selectedKLinePoint(List<_KLinePointWithMa> visible) {
    final index = _touchedIndex;
    if (index == null || index < 0 || index >= visible.length) return null;
    return visible[index];
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
    required this.selectedIndex,
  });

  final List<_KLinePointWithMa> points;
  final double maxY;
  final double barWidth;
  final int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final selected = selectedIndex != null &&
            selectedIndex! >= 0 &&
            selectedIndex! < points.length
        ? points[selectedIndex!]
        : null;
    return Stack(
      children: [
        BarChart(
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
                      width: selectedIndex == i ? barWidth * 1.28 : barWidth,
                      color: (points[i].point.close == points[i].point.open
                              ? colors.flat
                              : points[i].point.close > points[i].point.open
                                  ? colors.gain
                                  : colors.loss)
                          .withValues(
                        alpha: selectedIndex == i ? 0.72 : 0.38,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(1.5),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          duration: Duration.zero,
        ),
        if (selectedIndex != null)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _VerticalIndexGuidePainter(
                  index: selectedIndex!,
                  count: points.length,
                  color: scheme.outline.withValues(alpha: 0.42),
                  rightReservedSize: 44,
                ),
              ),
            ),
          ),
        if (selected != null)
          Positioned(
            left: 4,
            top: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceGlass,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                child: Text(
                  '量 ${_compactVolume(selected.point.volume)}',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
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

class _MaLegendStrip extends StatelessWidget {
  const _MaLegendStrip({required this.item});

  final _KLinePointWithMa? item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Wrap(
      spacing: 7,
      runSpacing: 2,
      children: [
        _MaLegendText(
          label: 'MA5',
          value: item?.ma5,
          color: colors.ma5,
        ),
        _MaLegendText(
          label: 'MA10',
          value: item?.ma10,
          color: colors.ma10,
        ),
        _MaLegendText(
          label: 'MA20',
          value: item?.ma20,
          color: colors.ma20,
        ),
        _MaLegendText(
          label: 'MA30',
          value: item?.ma30,
          color: colors.ma30,
        ),
        _MaLegendText(
          label: 'MA60',
          value: item?.ma60,
          color: colors.ma60,
        ),
      ],
    );
  }
}

class _MaLegendText extends StatelessWidget {
  const _MaLegendText({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final suffix =
        value == null || value! <= 0 ? '' : ' ${value!.toStringAsFixed(2)}';
    return Text(
      '$label$suffix',
      style: TextStyle(
        color: color,
        fontSize: 9.5,
        fontWeight: FontWeight.w900,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _VerticalIndexGuidePainter extends CustomPainter {
  const _VerticalIndexGuidePainter({
    required this.index,
    required this.count,
    required this.color,
    required this.rightReservedSize,
  });

  final int index;
  final int count;
  final Color color;
  final double rightReservedSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (count <= 0 || index < 0 || index >= count) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.9;
    final plotWidth = math.max(0.0, size.width - rightReservedSize);
    final x = count <= 1 ? plotWidth / 2 : plotWidth * index / (count - 1);
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _VerticalIndexGuidePainter oldDelegate) {
    return oldDelegate.index != index ||
        oldDelegate.count != count ||
        oldDelegate.color != color ||
        oldDelegate.rightReservedSize != rightReservedSize;
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

List<LineChartBarData> _movingAverageBars(
  List<_KLinePointWithMa> points,
  AppColors colors,
) {
  final bars = [
    _movingAverageBar(points, (point) => point.ma5, colors.ma5),
    _movingAverageBar(points, (point) => point.ma10, colors.ma10),
    _movingAverageBar(points, (point) => point.ma20, colors.ma20),
    _movingAverageBar(points, (point) => point.ma30, colors.ma30),
    _movingAverageBar(points, (point) => point.ma60, colors.ma60),
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

String _compactVolume(double value) {
  if (value >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)}B';
  if (value >= 100000000) return '${(value / 100000000).toStringAsFixed(1)}亿';
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return value.toStringAsFixed(0);
}
