import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../market/domain/stock.dart';

class StockCard extends StatefulWidget {
  const StockCard({
    required this.reorderIndex,
    required this.stock,
    required this.isFlashing,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final int reorderIndex;
  final Stock stock;
  final bool isFlashing;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<StockCard> createState() => _StockCardState();
}

class _StockCardState extends State<StockCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final stock = widget.stock;
    final trendColor = isUp ? AppPalette.blue600 : AppPalette.slate600;
    final symbol = currencySymbol(stock);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: widget.isFlashing
              ? AppPalette.blue50
              : Colors.white.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
          boxShadow: AppShadows.card(elevated: _isHovering),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: widget.onTap,
              onLongPress: () => _confirmDelete(context),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  stock.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: AppPalette.text,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _Badge(text: marketDisplayName(stock)),
                              if (stock.type == StockType.crypto) ...[
                                const SizedBox(width: 4),
                                const _Badge(text: 'C', color: Colors.orange),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),
                          RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                color: AppPalette.slate500,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                              children: [
                                TextSpan(
                                  text: stock.code,
                                  style: const TextStyle(
                                    color: AppPalette.slate400,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '  Turnover $symbol${formatAmount(stock.amount, type: stock.type)}',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatPrice(
                            stock.price,
                            type: stock.type,
                            symbol: symbol,
                          ),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: trendColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 4),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: trendColor.withValues(
                              alpha: stock.isUp ? 0.10 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            child: Text(
                              formatSignedPercent(stock.percent),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                color: trendColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: _isHovering
                          ? IconButton(
                              key: const ValueKey('delete'),
                              tooltip: '删除',
                              onPressed: () => _confirmDelete(context),
                              icon: const Icon(Icons.delete_outline_rounded),
                              color: AppPalette.slate400,
                            )
                          : ReorderableDragStartListener(
                              key: const ValueKey('drag'),
                              index: widget.reorderIndex,
                              child: const Icon(
                                Icons.drag_indicator_rounded,
                                color: AppPalette.slate300,
                                size: 22,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get isUp => widget.stock.isUp;

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除自选？'),
        content: Text('将 ${widget.stock.name} 从当前分组移除。'),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    this.color,
  });

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? AppPalette.blue500;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: resolved.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: resolved,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
        ),
      ),
    );
  }
}
