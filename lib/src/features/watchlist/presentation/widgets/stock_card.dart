import 'package:flutter/material.dart';

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
    final trendColor = isUp ? const Color(0xFF2563EB) : const Color(0xFF475569);
    final symbol = currencySymbol(stock);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: widget.isFlashing
              ? const Color(0xFFEFF6FF)
              : Colors.white.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
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
                                        color: const Color(0xFF0F172A),
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
                          const SizedBox(height: 7),
                          Text(
                            '${stock.code}  Turnover $symbol${formatAmount(stock.amount, type: stock.type)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
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
                        const SizedBox(height: 6),
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
                              vertical: 3,
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
                              color: const Color(0xFF94A3B8),
                            )
                          : ReorderableDragStartListener(
                              key: const ValueKey('drag'),
                              index: widget.reorderIndex,
                              child: const Icon(
                                Icons.drag_indicator_rounded,
                                color: Color(0xFFCBD5E1),
                                size: 24,
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
    final resolved = color ?? const Color(0xFF3B82F6);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: resolved.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: resolved,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
        ),
      ),
    );
  }
}
