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

  @override
  void initState() {
    super.initState();
    _chartFuture = _loadChart();
  }

  @override
  Widget build(BuildContext context) {
    final watchlistState = ref.watch(watchlistControllerProvider);
    final stock = _latestStock(watchlistState);
    final trendColor = stock.isUp ? AppPalette.blue600 : AppPalette.slate600;
    final symbol = currencySymbol(stock);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  _DetailCircleButton(
                    tooltip: '返回',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          stock.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: AppPalette.text,
                                    letterSpacing: 0,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                formatPrice(
                                  stock.price,
                                  type: stock.type,
                                  symbol: symbol,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                      color: trendColor,
                                      fontSize: 31,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: trendColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: trendColor.withValues(
                                    alpha: stock.isUp ? 0.16 : 0.12,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                child: Text(
                                  formatSignedPercent(stock.percent),
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            _StatsGrid(stock: stock),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _ChartTabs(
                selected: _chartType,
                onSelected: (type) {
                  setState(() {
                    _chartType = type;
                    _chartFuture = _loadChart();
                  });
                },
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: FutureBuilder<ChartData>(
                future: _chartFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return _ChartError(
                      onRetry: () =>
                          setState(() => _chartFuture = _loadChart()),
                    );
                  }
                  return StockChartPanel(
                    stock: stock,
                    data: snapshot.data!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<ChartData> _loadChart() {
    final stock = _latestStock(ref.read(watchlistControllerProvider));
    return ref.read(marketRepositoryProvider).fetchChart(stock, _chartType);
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

class _DetailCircleButton extends StatelessWidget {
  const _DetailCircleButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.86),
          shape: BoxShape.circle,
          border: Border.all(color: AppPalette.slate200),
          boxShadow: AppShadows.control(),
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: 40,
              child: IconTheme(
                data: const IconThemeData(
                  color: AppPalette.slate500,
                  size: 21,
                ),
                child: icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stock});

  final Stock stock;

  @override
  Widget build(BuildContext context) {
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
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _showAllMetrics(context, stock, symbol, amplitude),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
                boxShadow: AppShadows.card(),
              ),
              padding: const EdgeInsets.all(20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.35,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.$1,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppPalette.slate400,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppPalette.slate800,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  );
                },
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

class _MetricsSheet extends StatelessWidget {
  const _MetricsSheet({
    required this.stock,
    required this.symbol,
    required this.amplitude,
  });

  final Stock stock;
  final String symbol;
  final String amplitude;

  @override
  Widget build(BuildContext context) {
    final trendColor =
        stock.isUp ? const Color(0xFF2563EB) : const Color(0xFF475569);
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
            tone: _priceTone(stock.open, stock.preClose),
          ),
          _MetricItem(
            '最高',
            formatPrice(stock.high, type: stock.type, symbol: symbol),
            tone: _priceTone(stock.high, stock.preClose),
          ),
          _MetricItem(
            '最低',
            formatPrice(stock.low, type: stock.type, symbol: symbol),
            tone: _priceTone(stock.low, stock.preClose),
          ),
          _MetricItem(
            '涨跌额',
            formatPrice(stock.change, type: stock.type, symbol: symbol),
            tone: stock.change == null
                ? null
                : stock.change! >= 0
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF475569),
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
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF475569),
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
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stock.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F172A),
                                  ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${stock.code} · ${marketDisplayName(stock)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatPrice(
                          stock.price,
                          type: stock.type,
                          symbol: symbol,
                        ),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: trendColor,
                          fontWeight: FontWeight.w900,
                          fontFeatures: const [
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: trendColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          child: Text(
                            formatSignedPercent(stock.percent),
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
                ],
              ),
              const SizedBox(height: 18),
              for (final section in sections) ...[
                _MetricSection(section: section),
                if (section != sections.last) const SizedBox(height: 14),
              ],
              const SizedBox(height: 14),
              Text(
                '实时行情数据仅供参考，请以交易所实际数据为准。',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color? _priceTone(double? value, double? baseline) {
    if (value == null || baseline == null) return null;
    if (value > baseline) return const Color(0xFF2563EB);
    if (value < baseline) return const Color(0xFF475569);
    return null;
  }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFF334155),
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 9),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: section.items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.72,
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
          ),
          itemBuilder: (context, index) {
            final item = section.items[index];
            return DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: double.infinity,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.value,
                            maxLines: 1,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color: item.tone ?? const Color(0xFF0F172A),
                              fontWeight: FontWeight.w900,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final type in ChartType.values) ...[
          _ChartTabButton(
            label: type.label,
            selected: selected == type,
            onPressed: () => onSelected(type),
          ),
          if (type != ChartType.values.last) const SizedBox(width: 8),
        ],
      ],
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
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppPalette.slate700, AppPalette.slate800],
              )
            : null,
        color: selected ? null : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? Colors.transparent : AppPalette.slate100,
        ),
        boxShadow: AppShadows.pill(
          selected: selected,
          selectedColor: AppPalette.slate800,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 58),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : AppPalette.slate500,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
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
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text('图表加载失败', style: TextStyle(color: scheme.onSurfaceVariant)),
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
