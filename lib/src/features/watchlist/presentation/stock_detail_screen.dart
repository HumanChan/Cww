import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../chart/presentation/stock_chart_panel.dart';
import '../../market/data/market_repository.dart';
import '../../market/domain/chart_models.dart';
import '../../market/domain/stock.dart';
import '../application/watchlist_controller.dart';

class StockDetailScreen extends ConsumerStatefulWidget {
  const StockDetailScreen({
    required this.stock,
    super.key,
  });

  final Stock stock;

  @override
  ConsumerState<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends ConsumerState<StockDetailScreen> {
  ChartType _chartType = ChartType.intraday;
  late Future<ChartData> _chartFuture;
  Timer? _chartRefreshTimer;
  bool _chartRefreshInFlight = false;
  double? _edgeSwipeStartX;
  double _edgeSwipeDistance = 0;

  @override
  void initState() {
    super.initState();
    _chartFuture = _loadChart();
    _chartRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshIntradayChart(),
    );
  }

  @override
  void dispose() {
    _chartRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stock = ref.watch(
      watchlistControllerProvider.select(_latestStock),
    );
    final colors = context.appColors;
    final trendColor = _stockTrendColor(stock, colors);
    final symbol = currencySymbol(stock);
    final swipeProgress = (_edgeSwipeDistance / 180).clamp(0.0, 1.0);

    final page = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (event.position.dx > 44) return;
        setState(() {
          _edgeSwipeStartX = event.position.dx;
          _edgeSwipeDistance = 0;
        });
      },
      onPointerMove: (event) {
        final startX = _edgeSwipeStartX;
        if (startX == null) return;
        setState(() {
          _edgeSwipeDistance =
              (event.position.dx - startX).clamp(0, 180).toDouble();
        });
      },
      onPointerUp: (_) => _finishEdgeSwipe(),
      onPointerCancel: (_) => _resetEdgeSwipe(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: _edgeSwipeDistance <= 0
              ? const []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                colors.brandSoft.withValues(alpha: 0.46),
                colors.canvas,
                colors.canvas,
              ],
              stops: const [0, 0.36, 1],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop =
                    constraints.maxWidth >= AppBreakpoints.desktop &&
                        constraints.maxHeight >= 520;
                return isDesktop
                    ? _buildDesktopLayout(
                        context,
                        stock,
                        symbol,
                        trendColor,
                        constraints,
                      )
                    : _buildCompactLayout(
                        context,
                        stock,
                        symbol,
                        trendColor,
                        constraints,
                      );
              },
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: colors.surfaceInteractive,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: colors.surfaceInteractive),
          AnimatedSlide(
            duration: _edgeSwipeStartX == null
                ? const Duration(milliseconds: 180)
                : Duration.zero,
            curve: Curves.easeOutCubic,
            offset: Offset(0, swipeProgress * 0.055),
            child: AnimatedScale(
              duration: _edgeSwipeStartX == null
                  ? const Duration(milliseconds: 180)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              scale: 1 - swipeProgress * 0.035,
              alignment: Alignment.bottomCenter,
              child: page,
            ),
          ),
        ],
      ),
    );
  }

  void _finishEdgeSwipe() {
    final shouldPop = _edgeSwipeStartX != null && _edgeSwipeDistance >= 64;
    final navigator = Navigator.of(context);
    if (shouldPop && navigator.canPop()) {
      _edgeSwipeStartX = null;
      navigator.pop();
      return;
    }
    _resetEdgeSwipe();
  }

  void _resetEdgeSwipe() {
    if (!mounted) return;
    setState(() {
      _edgeSwipeStartX = null;
      _edgeSwipeDistance = 0;
    });
  }

  Widget _buildCompactLayout(
    BuildContext context,
    Stock stock,
    String symbol,
    Color trendColor,
    BoxConstraints constraints,
  ) {
    final chartHeight = _chartPanelHeight(constraints.maxHeight);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailHeader(
              stock: stock,
              symbol: symbol,
              trendColor: trendColor,
            ),
            _StatsGrid(stock: stock),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SizedBox(
                height: chartHeight,
                child: _buildChartCard(context, stock),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    Stock stock,
    String symbol,
    Color trendColor,
    BoxConstraints constraints,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          _DetailHeader(
            stock: stock,
            symbol: symbol,
            trendColor: trendColor,
            isDesktop: true,
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: constraints.maxWidth.clamp(280, 340).toDouble(),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _StatsGrid(
                          stock: stock,
                          horizontalPadding: 0,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _SessionRangeCard(stock: stock, symbol: symbol),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(child: _buildChartCard(context, stock)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, Stock stock) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: AppShadows.card(elevated: true),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final title = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '行情走势',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          if (_chartType == ChartType.intraday) ...[
                            const SizedBox(width: AppSpacing.xs),
                            const _ChartLiveBadge(),
                          ],
                        ],
                      ),
                      if (_chartType != ChartType.intraday) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '拖拽平移 · 滚轮缩放 · 双击复位',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.textTertiary,
                                  ),
                        ),
                      ],
                    ],
                  );
                  final tabs = _ChartTabs(
                    selected: _chartType,
                    onSelected: _selectChartType,
                  );
                  if (constraints.maxWidth < 620) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        const SizedBox(height: AppSpacing.md),
                        tabs,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: title),
                      const SizedBox(width: AppSpacing.md),
                      tabs,
                    ],
                  );
                },
              ),
            ),
            Divider(height: 1, color: colors.borderSubtle),
            Expanded(
              child: FutureBuilder<ChartData>(
                future: _chartFuture,
                builder: (context, snapshot) {
                  final child = switch (snapshot.connectionState) {
                    ConnectionState.done
                        when snapshot.hasData && !snapshot.hasError =>
                      StockChartPanel(
                        key: ValueKey(_chartType),
                        stock: stock,
                        data: snapshot.data!,
                        onRetry: _retryChart,
                      ),
                    ConnectionState.done => _ChartError(onRetry: _retryChart),
                    _ => const _ChartLoading(),
                  };
                  return AnimatedSwitcher(
                    duration: AppDurations.standard,
                    switchInCurve: AppMotionCurves.standard,
                    child: child,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectChartType(ChartType type) {
    if (type == _chartType) return;
    setState(() {
      _chartType = type;
      _chartFuture = _loadChart();
    });
  }

  void _retryChart() {
    setState(() => _chartFuture = _loadChart(forceRefresh: true));
  }

  double _chartPanelHeight(double viewportHeight) {
    final minHeight = _chartType == ChartType.intraday ? 380.0 : 420.0;
    final targetHeight = _chartType == ChartType.intraday ? 460.0 : 500.0;
    return (viewportHeight - 250).clamp(minHeight, targetHeight).toDouble();
  }

  Future<ChartData> _loadChart({bool forceRefresh = false}) {
    final stock = _latestStock(ref.read(watchlistControllerProvider));
    return ref.read(marketRepositoryProvider).fetchChart(
          stock,
          _chartType,
          forceRefresh: forceRefresh,
        );
  }

  Future<void> _refreshIntradayChart() async {
    if (!mounted || _chartType != ChartType.intraday || _chartRefreshInFlight) {
      return;
    }
    _chartRefreshInFlight = true;
    try {
      final data = await _loadChart(forceRefresh: true);
      if (!mounted || _chartType != ChartType.intraday) return;
      setState(() => _chartFuture = SynchronousFuture(data));
    } catch (_) {
      // Keep the last successful chart visible during a transient refresh error.
    } finally {
      _chartRefreshInFlight = false;
    }
  }

  Stock _latestStock(WatchlistState state) {
    for (final group in state.groups) {
      for (final item in group.stocks) {
        if (item.secid == widget.stock.secid ||
            item.code == widget.stock.code) {
          return item;
        }
      }
    }
    return widget.stock;
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.stock,
    required this.symbol,
    required this.trendColor,
    this.isDesktop = false,
  });

  final Stock stock;
  final String symbol;
  final Color trendColor;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final price = formatPrice(stock.price, type: stock.type, symbol: symbol);
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stock.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontFamily: 'PingFang SC',
                fontFamilyFallback: AppTypographyTokens.fontFamilyFallback,
                fontSize: 22,
                height: 1.05,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.65,
              ),
        ),
        const SizedBox(height: 5),
        Text(
          '${stock.code}  ·  ${marketDisplayName(stock)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
    final quote = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          price,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: trendColor,
            fontSize: isDesktop ? 32 : 25,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 6),
        _TrendChip(stock: stock, color: trendColor),
      ],
    );

    if (!isDesktop) {
      final mobilePanel = DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceGlass,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: AppShadows.card(elevated: true),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 14, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              identity,
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: trendColor,
                        fontSize: 31,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.9,
                        fontFeatures: const [
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _TrendChip(stock: stock, color: trendColor),
                ],
              ),
            ],
          ),
        ),
      );
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: mobilePanel,
      );
    }

    final content = Row(
      children: [
        if (isDesktop) ...[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.brand, colors.info],
              ),
              borderRadius: BorderRadius.circular(AppRadii.md),
              boxShadow: [
                BoxShadow(
                  color: colors.brand.withValues(alpha: 0.24),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(Icons.candlestick_chart_rounded, color: colors.onBrand),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(child: identity),
        SizedBox(width: isDesktop ? AppSpacing.xl : AppSpacing.sm),
        Flexible(child: quote),
      ],
    );

    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceGlass,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: AppShadows.card(elevated: true),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? AppSpacing.md : AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: content,
      ),
    );

    return panel;
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.stock, required this.color});

  final Stock stock;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              stock.percent == null || stock.percent == 0
                  ? Icons.trending_flat_rounded
                  : stock.percent! > 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
              size: 13,
              color: color,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              '${_formatSignedChange(stock)}  ${formatSignedPercent(stock.percent)}',
              style: TextStyle(
                color: color,
                fontSize: 11,
                height: 1,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLoading extends StatelessWidget {
  const _ChartLoading();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.full),
            child: LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: colors.surfaceInteractive,
              color: colors.brand,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceInteractive.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Center(
                child: Text(
                  '正在加载行情走势…',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLiveBadge extends StatelessWidget {
  const _ChartLiveBadge();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.infoSoft,
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 6, color: colors.info),
            const SizedBox(width: 4),
            Text(
              '实时 · 5s',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.info,
                    fontSize: 9.5,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.stock,
    this.horizontalPadding = AppSpacing.lg,
  });

  final Stock stock;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final symbol = currencySymbol(stock);
    final amplitude = stock.high != null &&
            stock.low != null &&
            stock.preClose != null &&
            stock.preClose != 0
        ? '${(((stock.high! - stock.low!) / stock.preClose!) * 100).toStringAsFixed(2)}%'
        : '--';
    final items = [
      ('昨收', formatPrice(stock.preClose, type: stock.type, symbol: symbol)),
      ('今开', formatPrice(stock.open, type: stock.type, symbol: symbol)),
      ('最高', formatPrice(stock.high, type: stock.type, symbol: symbol)),
      ('最低', formatPrice(stock.low, type: stock.type, symbol: symbol)),
      ('振幅', amplitude),
      ('量比', stock.volumeRatio?.toStringAsFixed(2) ?? '--'),
      ('成交额', '$symbol${formatAmount(stock.amount, type: stock.type)}'),
      (
        '换手率',
        stock.turnoverRate == null
            ? '--'
            : '${stock.turnoverRate!.toStringAsFixed(2)}%',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            onTap: () => _showAllMetrics(context, stock, symbol, amplitude),
            child: Container(
              decoration: BoxDecoration(
                color: colors.surfaceRaised,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: Border.all(color: colors.borderSubtle),
                boxShadow: AppShadows.card(elevated: true),
              ),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '行情概览',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                      Text(
                        '查看全部',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: colors.brand,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: colors.brand,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _OverviewMetricTable(items: items),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAllMetrics(
    BuildContext context,
    Stock stock,
    String symbol,
    String amplitude,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _MetricsSheet(
        stock: stock,
        symbol: symbol,
        amplitude: amplitude,
      ),
    );
  }
}

class _OverviewMetricTable extends StatelessWidget {
  const _OverviewMetricTable({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceInteractive.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        children: [
          for (var row = 0; row < 2; row++) ...[
            if (row > 0) Divider(height: 1, color: colors.borderSubtle),
            Row(
              children: [
                for (var column = 0; column < 4; column++)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: column == 3
                            ? null
                            : Border(
                                right: BorderSide(color: colors.borderSubtle),
                              ),
                      ),
                      child: _OverviewMetricCell(item: items[row * 4 + column]),
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

class _OverviewMetricCell extends StatelessWidget {
  const _OverviewMetricCell({required this.item});

  final (String, String) item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.$1,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                  fontSize: 10.5,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.$2,
              maxLines: 1,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
                fontSize: 14,
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

class _SessionRangeCard extends StatelessWidget {
  const _SessionRangeCard({required this.stock, required this.symbol});

  final Stock stock;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final low = stock.low;
    final high = stock.high;
    final price = stock.price;
    final hasRange = low != null &&
        high != null &&
        price != null &&
        high > low &&
        price.isFinite;
    final progress = hasRange
        ? ((price - low) / (high - low)).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final trend = _stockTrendColor(stock, colors);
    final rows = [
      (
        '涨跌额',
        formatPrice(stock.change, type: stock.type, symbol: symbol),
      ),
      (
        '成交额',
        '$symbol${formatAmount(stock.amount, type: stock.type)}',
      ),
      (
        '换手率',
        stock.turnoverRate == null
            ? '--'
            : '${stock.turnoverRate!.toStringAsFixed(2)}%',
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: AppShadows.card(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '今日区间',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.full),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                color: trend,
                backgroundColor: colors.surfaceInteractive,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '最低 ${formatPrice(low, type: stock.type, symbol: symbol)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Text(
                  '最高 ${formatPrice(high, type: stock.type, symbol: symbol)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: colors.borderSubtle),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.$1,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textTertiary,
                            ),
                      ),
                    ),
                    Text(
                      row.$2,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricsSheet extends ConsumerStatefulWidget {
  const _MetricsSheet({
    required this.stock,
    required this.symbol,
    required this.amplitude,
  });

  final Stock stock;
  final String symbol;
  final String amplitude;

  @override
  ConsumerState<_MetricsSheet> createState() => _MetricsSheetState();
}

class _MetricsSheetState extends ConsumerState<_MetricsSheet> {
  late Future<MarketDepth> _depthFuture;

  @override
  void initState() {
    super.initState();
    _depthFuture = _loadDepth();
  }

  @override
  Widget build(BuildContext context) {
    final stock = widget.stock;
    final symbol = widget.symbol;
    final amplitude = widget.amplitude;
    final colors = context.appColors;
    final trendColor = _stockTrendColor(stock, colors);
    final sections = [
      _MetricSectionData(
        title: '价格区间',
        items: [
          _MetricItem(
            '昨收',
            formatPrice(stock.preClose, type: stock.type, symbol: symbol),
          ),
          _MetricItem(
            '今开',
            formatPrice(stock.open, type: stock.type, symbol: symbol),
            tone: _priceTone(stock.open, stock.preClose, colors),
          ),
          _MetricItem(
            '最高',
            formatPrice(stock.high, type: stock.type, symbol: symbol),
            tone: _priceTone(stock.high, stock.preClose, colors),
          ),
          _MetricItem(
            '最低',
            formatPrice(stock.low, type: stock.type, symbol: symbol),
            tone: _priceTone(stock.low, stock.preClose, colors),
          ),
          _MetricItem(
            '涨跌额',
            formatPrice(stock.change, type: stock.type, symbol: symbol),
            tone: stock.change == null
                ? null
                : stock.change! >= 0
                    ? colors.gain
                    : colors.loss,
          ),
          _MetricItem('振幅', amplitude),
        ],
      ),
      _MetricSectionData(
        title: '成交活跃',
        items: [
          _MetricItem('成交量', formatVolume(stock.volume)),
          _MetricItem(
            '成交额',
            '$symbol${formatAmount(stock.amount, type: stock.type)}',
          ),
          _MetricItem(
            '换手率',
            stock.turnoverRate == null
                ? '--'
                : '${stock.turnoverRate!.toStringAsFixed(2)}%',
          ),
          _MetricItem(
            '量比',
            stock.volumeRatio?.toStringAsFixed(2) ?? '--',
            tone: stock.volumeRatio == null
                ? null
                : stock.volumeRatio! >= 1
                    ? colors.gain
                    : colors.loss,
          ),
        ],
      ),
      _MetricSectionData(
        title: '估值信息',
        items: [
          _MetricItem('市盈(动)', stock.peDynamic?.toStringAsFixed(2) ?? '--'),
          _MetricItem('市盈(静)', stock.peStatic?.toStringAsFixed(2) ?? '--'),
          _MetricItem('市盈TTM', stock.peTTM?.toStringAsFixed(2) ?? '--'),
          _MetricItem('市净率', stock.pb?.toStringAsFixed(2) ?? '--'),
          _MetricItem(
            '总市值',
            '$symbol${formatAmount(stock.marketCap, type: stock.type)}',
          ),
          _MetricItem('市场', marketDisplayName(stock)),
        ],
      ),
    ];

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.brandSoft.withValues(alpha: 0.72),
                      colors.surfaceRaised,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(color: colors.borderSubtle),
                  boxShadow: AppShadows.card(),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stock.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: colors.textPrimary,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.45,
                                  ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${stock.code} · ${marketDisplayName(stock)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colors.textTertiary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatPrice(
                              stock.price,
                              type: stock.type,
                              symbol: symbol,
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                              color: trendColor,
                              fontSize: 23,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            '${_formatSignedChange(stock)}  ${formatSignedPercent(stock.percent)}',
                            style: TextStyle(
                              color: trendColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FutureBuilder<MarketDepth>(
                future: _depthFuture,
                initialData: stock.hasMarketDepth ? stock.marketDepth : null,
                builder: (context, snapshot) {
                  final depth = snapshot.data ?? const MarketDepth();
                  return _DepthBookSection(
                    depth: depth,
                    stock: stock,
                    symbol: symbol,
                    isLoading:
                        snapshot.connectionState != ConnectionState.done &&
                            !depth.hasData,
                  );
                },
              ),
              const SizedBox(height: 14),
              for (final section in sections) ...[
                _MetricSection(section: section),
                if (section != sections.last) const SizedBox(height: 12),
              ],
              const SizedBox(height: 14),
              Text(
                '实时行情数据仅供参考，请以交易所实际数据为准。',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color? _priceTone(double? value, double? baseline, AppColors colors) {
    if (value == null || baseline == null) return null;
    if (value > baseline) return colors.gain;
    if (value < baseline) return colors.loss;
    return null;
  }

  Future<MarketDepth> _loadDepth() async {
    final depth =
        await ref.read(marketRepositoryProvider).fetchMarketDepth(widget.stock);
    return depth.hasData ? depth : widget.stock.marketDepth;
  }
}

class _DepthBookSection extends StatelessWidget {
  const _DepthBookSection({
    required this.depth,
    required this.stock,
    required this.symbol,
    required this.isLoading,
  });

  final MarketDepth depth;
  final Stock stock;
  final String symbol;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final title = depth.isFullDepth ? '五档盘口' : '最佳报价';
    final hasOrderMetrics = depth.orderRatio != null || depth.orderDiff != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: 8),
            if (isLoading)
              const SizedBox.square(
                dimension: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 9),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceInteractive,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _DepthSideColumn(
                        label: '买盘',
                        prefix: '买',
                        levels: depth.bids,
                        tone: colors.gain,
                        stock: stock,
                        symbol: symbol,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DepthSideColumn(
                        label: '卖盘',
                        prefix: '卖',
                        levels: depth.asks,
                        tone: colors.loss,
                        stock: stock,
                        symbol: symbol,
                      ),
                    ),
                  ],
                ),
                if (hasOrderMetrics) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (depth.orderRatio != null)
                        _DepthStatChip(
                          label: '委比',
                          value: _formatOrderRatio(depth.orderRatio),
                          tone: _depthMetricTone(depth.orderRatio, colors),
                        ),
                      if (depth.orderDiff != null)
                        _DepthStatChip(
                          label: '委差',
                          value: _formatSignedDepthVolume(
                            depth.orderDiff,
                            stock.type,
                          ),
                          tone: _depthMetricTone(depth.orderDiff, colors),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DepthSideColumn extends StatelessWidget {
  const _DepthSideColumn({
    required this.label,
    required this.prefix,
    required this.levels,
    required this.tone,
    required this.stock,
    required this.symbol,
  });

  final String label;
  final String prefix;
  final List<MarketDepthLevel> levels;
  final Color tone;
  final Stock stock;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final visible = levels.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tone,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        if (visible.isEmpty)
          const _DepthEmpty()
        else
          for (var i = 0; i < visible.length; i++) ...[
            _DepthRow(
              label: '$prefix${i + 1}',
              level: visible[i],
              tone: tone,
              stock: stock,
              symbol: symbol,
            ),
            if (i != visible.length - 1) const SizedBox(height: 7),
          ],
      ],
    );
  }
}

class _DepthRow extends StatelessWidget {
  const _DepthRow({
    required this.label,
    required this.level,
    required this.tone,
    required this.stock,
    required this.symbol,
  });

  final String label;
  final MarketDepthLevel level;
  final Color tone;
  final Stock stock;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatPrice(level.price, type: stock.type, symbol: symbol),
              maxLines: 1,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tone,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 44,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              _formatDepthVolume(level.volume, stock.type),
              maxLines: 1,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DepthEmpty extends StatelessWidget {
  const _DepthEmpty();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Text(
      '--',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.textTertiary,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _DepthStatChip extends StatelessWidget {
  const _DepthStatChip({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceGlass,
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: tone.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: 5),
            Text(
              value,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tone,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDepthVolume(double? volume, StockType type) {
  if (volume == null || volume.isNaN) return '--';
  if (type == StockType.crypto) {
    if (volume < 1) return volume.toStringAsFixed(4);
    if (volume < 10) return volume.toStringAsFixed(3);
    if (volume < 100) return volume.toStringAsFixed(2);
    return formatAmount(volume, type: StockType.crypto);
  }
  return formatVolume(volume);
}

String _formatOrderRatio(double? ratio) {
  if (ratio == null || ratio.isNaN) return '--';
  final sign = ratio > 0 ? '+' : '';
  return '$sign${ratio.toStringAsFixed(2)}%';
}

String _formatSignedDepthVolume(double? volume, StockType type) {
  if (volume == null || volume.isNaN) return '--';
  final sign = volume > 0 ? '+' : '';
  return '$sign${_formatDepthVolume(volume, type)}';
}

Color _depthMetricTone(double? value, AppColors colors) {
  if (value == null || value < 0) return colors.loss;
  return colors.gain;
}

Color _stockTrendColor(Stock stock, AppColors colors) {
  final percent = stock.percent;
  if (percent == null || percent == 0) return colors.flat;
  return percent > 0 ? colors.gain : colors.loss;
}

String _formatSignedChange(Stock stock) {
  final change = stock.change;
  if (change == null || change.isNaN) return '--';
  final sign = change > 0
      ? '+'
      : change < 0
          ? '-'
          : '';
  final value = formatPrice(
    change.abs(),
    type: stock.type,
    symbol: currencySymbol(stock),
  );
  return '$sign$value';
}

class _MetricSectionData {
  const _MetricSectionData({
    required this.title,
    required this.items,
  });

  final String title;
  final List<_MetricItem> items;
}

class _MetricItem {
  const _MetricItem(
    this.label,
    this.value, {
    this.tone,
  });

  final String label;
  final String value;
  final Color? tone;
}

class _MetricSection extends StatelessWidget {
  const _MetricSection({required this.section});

  final _MetricSectionData section;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceInteractive.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            children: [
              for (var row = 0;
                  row < (section.items.length / 2).ceil();
                  row++) ...[
                if (row > 0) Divider(height: 1, color: colors.borderSubtle),
                Row(
                  children: [
                    Expanded(
                      child: _CompactMetricCell(
                        item: section.items[row * 2],
                      ),
                    ),
                    SizedBox(
                      height: 38,
                      child: VerticalDivider(
                        width: 1,
                        color: colors.borderSubtle,
                      ),
                    ),
                    Expanded(
                      child: row * 2 + 1 < section.items.length
                          ? _CompactMetricCell(
                              item: section.items[row * 2 + 1],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactMetricCell extends StatelessWidget {
  const _CompactMetricCell({required this.item});

  final _MetricItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                item.value,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: item.tone ?? colors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartTabs extends StatelessWidget {
  const _ChartTabs({
    required this.selected,
    required this.onSelected,
  });

  final ChartType selected;
  final ValueChanged<ChartType> onSelected;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final type in ChartType.values) ...[
            _ChartTabButton(
              label: type.label,
              selected: selected == type,
              onPressed: () => onSelected(type),
            ),
            if (type != ChartType.values.last)
              const SizedBox(width: AppSpacing.xxs),
          ],
        ],
      ),
    );
  }
}

class _ChartTabButton extends StatelessWidget {
  const _ChartTabButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.brand, colors.brandHover],
              )
            : null,
        color: selected ? null : colors.surfaceInteractive,
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(
          color: selected ? Colors.transparent : colors.borderSubtle,
        ),
        boxShadow: AppShadows.pill(
          selected: selected,
          selectedColor: colors.brand,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.full),
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? colors.onBrand : colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartError extends StatelessWidget {
  const _ChartError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, color: colors.textTertiary),
          const SizedBox(height: 8),
          Text(
            '图表加载失败',
            style: TextStyle(color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
