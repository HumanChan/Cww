import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../chart/presentation/stock_chart_panel.dart';
import '../../../market/data/market_repository.dart';
import '../../../market/domain/chart_models.dart';
import '../../../market/domain/market_index_snapshot.dart';
import '../../../market/domain/stock.dart';

class MarketIndexBar extends StatelessWidget {
  const MarketIndexBar({
    required this.market,
    required this.snapshots,
    required this.isLoading,
    required this.error,
    super.key,
  });

  final Market? market;
  final List<MarketIndexSnapshot> snapshots;
  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      key: const ValueKey('market-index-bar'),
      height: 62,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: AppShadows.control(),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSwitcher(
        duration: AppDurations.standard,
        child: snapshots.isEmpty
            ? _IndexPlaceholder(
                key: ValueKey('${market?.name}-$isLoading-$error'),
                market: market,
                isLoading: isLoading,
                hasError: error != null,
              )
            : Row(
                key: ValueKey('indexes-${market?.name}'),
                children: [
                  for (var index = 0; index < snapshots.length; index++) ...[
                    if (index > 0)
                      VerticalDivider(
                        width: 1,
                        indent: 11,
                        endIndent: 11,
                        color: colors.borderSubtle,
                      ),
                    Expanded(
                      child: _IndexSegment(
                        snapshot: snapshots[index],
                        compact: snapshots.length > 1,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _IndexPlaceholder extends StatelessWidget {
  const _IndexPlaceholder({
    required this.market,
    required this.isLoading,
    required this.hasError,
    super.key,
  });

  final Market? market;
  final bool isLoading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceInteractive,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: SizedBox.square(
              dimension: 36,
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.brand,
                      ),
                    )
                  : Icon(
                      hasError ? Icons.cloud_off_rounded : Icons.public_rounded,
                      size: 19,
                      color: colors.textTertiary,
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading ? '正在同步主要指数' : '暂无对应市场指数',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasError ? '行情源暂未更新，稍后自动重试' : '分组为空或首项市场暂不支持',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IndexSegment extends StatelessWidget {
  const _IndexSegment({required this.snapshot, required this.compact});

  final MarketIndexSnapshot snapshot;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final stock = snapshot.index;
    final trend = stock.percent ?? 0;
    final trendColor = trend > 0
        ? colors.gain
        : trend < 0
            ? colors.loss
            : colors.flat;
    return Semantics(
      button: true,
      label:
          '${stock.name} ${formatPrice(stock.price)} ${formatSignedPercent(stock.percent)}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('index-${stock.secid}'),
          onTap: () => _showIndexDetails(context, snapshot),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : AppSpacing.md,
              vertical: 8,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              stock.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: colors.textSecondary,
                                    fontSize: compact ? 10.5 : 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          if (snapshot.isStale) ...[
                            const SizedBox(width: 3),
                            Icon(
                              Icons.schedule_rounded,
                              size: 9,
                              color: colors.warning.withValues(alpha: 0.78),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatSignedPercent(stock.percent),
                      style: TextStyle(
                        color: trendColor,
                        fontSize: compact ? 11 : 12.5,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  formatPrice(stock.price),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: compact ? 13 : 15,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showIndexDetails(BuildContext context, MarketIndexSnapshot snapshot) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.36),
    builder: (_) => _IndexDetailSheet(snapshot: snapshot),
  );
}

class _IndexDetailSheet extends ConsumerStatefulWidget {
  const _IndexDetailSheet({required this.snapshot});

  final MarketIndexSnapshot snapshot;

  @override
  ConsumerState<_IndexDetailSheet> createState() => _IndexDetailSheetState();
}

class _IndexDetailSheetState extends ConsumerState<_IndexDetailSheet> {
  late Future<ChartData> _chart;

  @override
  void initState() {
    super.initState();
    _chart = ref.read(marketRepositoryProvider).fetchIndexChart(
          widget.snapshot.index,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final snapshot = widget.snapshot;
    final stock = snapshot.index;
    final trendColor = (stock.percent ?? 0) > 0
        ? colors.gain
        : (stock.percent ?? 0) < 0
            ? colors.loss
            : colors.flat;
    final amplitude = stock.high != null &&
            stock.low != null &&
            stock.preClose != null &&
            stock.preClose != 0
        ? '${((stock.high! - stock.low!) / stock.preClose! * 100).toStringAsFixed(2)}%'
        : '--';
    final range = _rangePosition(stock);
    final metrics = <(String, String)>[
      ('昨收', formatPrice(stock.preClose)),
      ('今开', formatPrice(stock.open)),
      ('最高', formatPrice(stock.high)),
      ('最低', formatPrice(stock.low)),
      ('振幅', amplitude),
      ('日内位置', range == null ? '--' : '${(range * 100).toStringAsFixed(0)}%'),
      ('成交量', formatVolume(stock.volume)),
      ('成交额', formatAmount(stock.amount)),
      ('量比', stock.volumeRatio?.toStringAsFixed(2) ?? '--'),
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.90,
      minChildSize: 0.62,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
            boxShadow: [
              BoxShadow(
                color: colors.overlay.withValues(alpha: 0.18),
                blurRadius: 40,
                spreadRadius: -14,
                offset: const Offset(0, -12),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.borderStrong.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stock.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${stock.code} · ${_marketLabel(stock.market)}',
                              style: TextStyle(
                                color: colors.textTertiary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: '关闭',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceInteractive.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                formatPrice(stock.price),
                                style: TextStyle(
                                  color: trendColor,
                                  fontSize: 34,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: trendColor.withValues(alpha: 0.09),
                                borderRadius:
                                    BorderRadius.circular(AppRadii.full),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 5,
                                ),
                                child: Text(
                                  '${_formatSigned(stock.change)}  ${formatSignedPercent(stock.percent)}',
                                  style: TextStyle(
                                    color: trendColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          key: const ValueKey('index-intraday-chart'),
                          height: 224,
                          child: FutureBuilder<ChartData>(
                            future: _chart,
                            builder: (context, chart) {
                              if (chart.hasData &&
                                  chart.data!.intraday.length > 1) {
                                return StockChartPanel(
                                  stock: stock,
                                  data: chart.data!,
                                  isMarketIndex: true,
                                );
                              }
                              if (chart.hasError) {
                                return Center(
                                  child: Text(
                                    '分时数据暂不可用',
                                    style: TextStyle(
                                      color: colors.textTertiary,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              }
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.brand,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '今日行情',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _IndexMetricsTable(items: metrics),
                  if (snapshot.hasBreadth) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _MarketBreadthPanel(snapshot: snapshot),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(
                        snapshot.isStale
                            ? Icons.schedule_rounded
                            : Icons.update_rounded,
                        size: 14,
                        color: snapshot.isStale
                            ? colors.warning
                            : colors.textTertiary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '更新时间 ${_formatTime(snapshot.updatedAt)}${snapshot.isStale ? ' · 暂未更新' : ''}',
                        style: TextStyle(
                          color: snapshot.isStale
                              ? colors.warning
                              : colors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IndexMetricsTable extends StatelessWidget {
  const _IndexMetricsTable({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceInteractive.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var row = 0; row < 3; row++) ...[
            if (row > 0) Divider(height: 1, color: colors.borderSubtle),
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  for (var column = 0; column < 3; column++) ...[
                    if (column > 0)
                      VerticalDivider(
                        width: 1,
                        color: colors.borderSubtle,
                      ),
                    Expanded(
                      child: _IndexMetricCell(item: items[row * 3 + column]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IndexMetricCell extends StatelessWidget {
  const _IndexMetricCell({required this.item});

  final (String, String) item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.$1,
            maxLines: 1,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.$2,
              maxLines: 1,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                height: 1,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketBreadthPanel extends StatelessWidget {
  const _MarketBreadthPanel({required this.snapshot});

  final MarketIndexSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final gain = snapshot.advancing ?? 0;
    final flat = snapshot.unchanged ?? 0;
    final loss = snapshot.declining ?? 0;
    final total = gain + flat + loss;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceInteractive.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '市场涨跌分布',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Text(
                total <= 0 ? '--' : '共 $total 家',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _BreadthLegend(
                  label: '上涨',
                  value: gain,
                  color: colors.gain,
                ),
              ),
              Expanded(
                child: _BreadthLegend(
                  label: '平盘',
                  value: flat,
                  color: colors.flat,
                ),
              ),
              Expanded(
                child: _BreadthLegend(
                  label: '下跌',
                  value: loss,
                  color: colors.loss,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.full),
            child: SizedBox(
              height: 7,
              child: Row(
                children: [
                  Expanded(
                    flex: math.max(1, gain),
                    child: ColoredBox(color: colors.gain),
                  ),
                  Expanded(
                    flex: math.max(1, flat),
                    child: ColoredBox(color: colors.flat),
                  ),
                  Expanded(
                    flex: math.max(1, loss),
                    child: ColoredBox(color: colors.loss),
                  ),
                ],
              ),
            ),
          ),
          if (snapshot.index.market == Market.cn) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: colors.borderSubtle),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _LimitStat(
                    label: '涨停',
                    value: snapshot.limitUp,
                    color: colors.gain,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _LimitStat(
                    label: '跌停',
                    value: snapshot.limitDown,
                    color: colors.loss,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LimitStat extends StatelessWidget {
  const _LimitStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            value?.toString() ?? '--',
            style: TextStyle(
              color: value == null ? colors.textTertiary : color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreadthLegend extends StatelessWidget {
  const _BreadthLegend({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 18,
            height: 1,
            fontWeight: FontWeight.w900,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: context.appColors.textTertiary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

double? _rangePosition(Stock stock) {
  if (stock.low == null ||
      stock.high == null ||
      stock.price == null ||
      stock.high! <= stock.low!) {
    return null;
  }
  return ((stock.price! - stock.low!) / (stock.high! - stock.low!))
      .clamp(0, 1)
      .toDouble();
}

String _formatSigned(double? value) {
  if (value == null) return '--';
  return '${value > 0 ? '+' : ''}${value.toStringAsFixed(2)}';
}

String _marketLabel(Market market) => switch (market) {
      Market.cn => 'A股',
      Market.hk => '港股',
      Market.us => '美股',
      Market.kr => '韩股',
      Market.tw => '台股',
      Market.jp => '日股',
      Market.other => '其他',
    };

String _formatTime(DateTime? value) {
  if (value == null) return '--';
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}
