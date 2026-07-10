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
  bool _isPressed = false;
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final stock = widget.stock;
    final trend = _trendOf(stock.percent);
    final trendColor = switch (trend) {
      _Trend.gain => colors.gain,
      _Trend.loss => colors.loss,
      _Trend.flat => colors.flat,
    };
    final trendSoft = switch (trend) {
      _Trend.gain => colors.gainSoft,
      _Trend.loss => colors.lossSoft,
      _Trend.flat => colors.surfaceInteractive,
    };
    final backgroundColor = widget.isFlashing
        ? colors.brandSoft
        : _isPressed
            ? colors.surfaceInteractive
            : colors.surface;
    final borderColor = _hasFocus
        ? colors.focusRing
        : _isHovering
            ? colors.borderStrong
            : colors.borderSubtle;
    final symbol = currencySymbol(stock);

    return Semantics(
      button: true,
      label:
          '${stock.name}，${formatPrice(stock.price, type: stock.type, symbol: symbol)}，'
          '${formatSignedPercent(stock.percent)}，点击查看详情',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.992 : 1,
          duration: AppDurations.fast,
          curve: AppMotionCurves.standard,
          child: AnimatedContainer(
            duration: AppDurations.standard,
            curve: AppMotionCurves.standard,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: borderColor,
                width: _hasFocus ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.overlay.withValues(
                    alpha: _isHovering ? 0.11 : 0.055,
                  ),
                  blurRadius: _isHovering ? 26 : 18,
                  spreadRadius: -10,
                  offset: Offset(0, _isHovering ? 12 : 7),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onTap,
                onLongPress: () => _confirmDelete(context),
                onHover: (value) {
                  if (_isHovering != value) {
                    setState(() => _isHovering = value);
                  }
                },
                onHighlightChanged: (value) {
                  if (_isPressed != value) {
                    setState(() => _isPressed = value);
                  }
                },
                onFocusChange: (value) {
                  if (_hasFocus != value) {
                    setState(() => _hasFocus = value);
                  }
                },
                hoverColor: Colors.transparent,
                focusColor: Colors.transparent,
                splashColor: colors.brand.withValues(alpha: 0.08),
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StockIdentity(
                          stock: stock,
                          symbol: symbol,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StockQuote(
                        stock: stock,
                        symbol: symbol,
                        trend: trend,
                        trendColor: trendColor,
                        trendSoft: trendSoft,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 88,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _DeleteButton(
                              onPressed: () => _confirmDelete(context),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            ReorderableDragStartListener(
                              index: widget.reorderIndex,
                              child: const _DragHandle(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: const Text('移除自选？'),
        content: Text('将 ${widget.stock.name} 从当前分组中移除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onDelete();
  }
}

class _StockIdentity extends StatelessWidget {
  const _StockIdentity({required this.stock, required this.symbol});

  final Stock stock;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                stock.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            _MarketBadge(text: marketDisplayName(stock)),
            if (stock.type == StockType.crypto) ...[
              const SizedBox(width: AppSpacing.xxs),
              const _MarketBadge(text: '币'),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: stock.code,
                style: TextStyle(
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
              TextSpan(
                text:
                    '  ·  成交额 $symbol${formatAmount(stock.amount, type: stock.type)}',
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _StockQuote extends StatelessWidget {
  const _StockQuote({
    required this.stock,
    required this.symbol,
    required this.trend,
    required this.trendColor,
    required this.trendSoft,
  });

  final Stock stock;
  final String symbol;
  final _Trend trend;
  final Color trendColor;
  final Color trendSoft;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatPrice(stock.price, type: stock.type, symbol: symbol),
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: trendColor,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          DecoratedBox(
            decoration: BoxDecoration(
              color: trendSoft,
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    switch (trend) {
                      _Trend.gain => Icons.arrow_upward_rounded,
                      _Trend.loss => Icons.arrow_downward_rounded,
                      _Trend.flat => Icons.remove_rounded,
                    },
                    size: 13,
                    color: trendColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    formatSignedPercent(stock.percent),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: trendColor,
                      fontWeight: FontWeight.w900,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: '移除自选',
      child: IconButton(
        onPressed: onPressed,
        constraints: const BoxConstraints.tightFor(
          width: AppControlSizes.small,
          height: AppControlSizes.small,
        ),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          foregroundColor: colors.textTertiary,
          hoverColor: colors.lossSoft,
          focusColor: colors.lossSoft,
          highlightColor: colors.lossSoft,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
        icon: const Icon(Icons.delete_outline_rounded, size: 20),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: '拖动排序',
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceInteractive,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: SizedBox.square(
            dimension: AppControlSizes.small,
            child: Icon(
              Icons.drag_indicator_rounded,
              color: colors.textTertiary,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketBadge extends StatelessWidget {
  const _MarketBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.brandSoft,
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 2,
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.brand,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}

enum _Trend { gain, loss, flat }

_Trend _trendOf(double? percent) {
  if (percent == null || percent == 0) return _Trend.flat;
  return percent > 0 ? _Trend.gain : _Trend.loss;
}
