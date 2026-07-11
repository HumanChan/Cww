import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  static const _actionWidth = 70.0;

  bool _isHovering = false;
  bool _isPressed = false;
  bool _hasFocus = false;
  bool _isSliding = false;
  double _slideOffset = 0;

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

    final card = Semantics(
      button: true,
      label:
          '${stock.name}，${formatPrice(stock.price, type: stock.type, symbol: symbol)}，'
          '${formatSignedPercent(stock.percent)}，点击查看详情，左滑可移除',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.986 : (_isHovering ? 1.004 : 1),
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
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  if (_slideOffset < -1) {
                    _closeActions();
                  } else {
                    widget.onTap();
                  }
                },
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StockIdentity(stock: stock, symbol: symbol),
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
                      ReorderableDragStartListener(
                        index: widget.reorderIndex,
                        child: const _DragHandle(),
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

    return AnimatedContainer(
      duration: AppDurations.standard,
      curve: AppMotionCurves.standard,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: [
          BoxShadow(
            color: colors.overlay.withValues(
              alpha: _isHovering ? 0.15 : 0.085,
            ),
            blurRadius: _isHovering ? 30 : 22,
            spreadRadius: -9,
            offset: Offset(0, _isHovering ? 13 : 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (_) {
            setState(() => _isSliding = true);
          },
          onHorizontalDragUpdate: (details) {
            setState(() {
              _slideOffset = (_slideOffset + details.delta.dx)
                  .clamp(-_actionWidth, 0)
                  .toDouble();
            });
          },
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            final shouldOpen = velocity < -260 ||
                (velocity <= 260 && _slideOffset.abs() > _actionWidth * 0.42);
            setState(() {
              _isSliding = false;
              _slideOffset = shouldOpen ? -_actionWidth : 0;
            });
          },
          onHorizontalDragCancel: () {
            setState(() {
              _isSliding = false;
              _slideOffset = 0;
            });
          },
          child: Stack(
            children: [
              Positioned(
                top: 6,
                right: 4,
                bottom: 6,
                width: _actionWidth - 8,
                child: _SwipeDeleteAction(onPressed: _handleDelete),
              ),
              AnimatedContainer(
                duration: _isSliding ? Duration.zero : AppDurations.emphasized,
                curve: Curves.easeOutCubic,
                transform: Matrix4.translationValues(_slideOffset, 0, 0),
                child: card,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _closeActions() {
    if (_slideOffset == 0) return;
    setState(() {
      _isSliding = false;
      _slideOffset = 0;
    });
  }

  Future<void> _handleDelete() async {
    final confirmed = await _confirmDelete(context);
    if (!mounted) return;
    if (confirmed) {
      await HapticFeedback.lightImpact();
      widget.onDelete();
    } else {
      _closeActions();
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final destructive = _destructiveColor(dialogContext);
        final colors = dialogContext.appColors;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceRaised,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: Border.all(color: colors.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: colors.overlay.withValues(alpha: 0.22),
                    blurRadius: 48,
                    spreadRadius: -14,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: destructive.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(
                        dimension: 54,
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: destructive,
                          size: 27,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '从当前分组移除？',
                      style: Theme.of(dialogContext)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: colors.surfaceInteractive,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.stock.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            widget.stock.code,
                            style: TextStyle(
                              color: colors.textTertiary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '仅从当前分组移除，不会影响其他分组与分组设置。',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                                height: 1.45,
                              ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: const Text('取消'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: FilledButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: destructive,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('确认移除'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    return confirmed == true;
  }
}

class _SwipeDeleteAction extends StatelessWidget {
  const _SwipeDeleteAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final destructive = _destructiveColor(context);
    return Material(
      color: destructive,
      borderRadius: BorderRadius.circular(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.md),
        splashColor: Colors.white.withValues(alpha: 0.14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 21,
            ),
            const SizedBox(height: 2),
            const Text(
              '删除',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.textPrimary,
                      fontSize: 18,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.35,
                    ),
              ),
            ),
            const SizedBox(width: 6),
            _MarketBadge(text: marketDisplayName(stock)),
          ],
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: stock.code,
                style: TextStyle(
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  letterSpacing: 0.15,
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
            fontSize: 11.5,
            height: 1.1,
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
      constraints: const BoxConstraints(minWidth: 86),
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
              fontSize: 19,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 6),
          DecoratedBox(
            decoration: BoxDecoration(
              color: trendSoft,
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(color: trendColor.withValues(alpha: 0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    switch (trend) {
                      _Trend.gain => Icons.arrow_upward_rounded,
                      _Trend.loss => Icons.arrow_downward_rounded,
                      _Trend.flat => Icons.remove_rounded,
                    },
                    size: 12,
                    color: trendColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    formatSignedPercent(stock.percent),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: trendColor,
                      fontSize: 10.5,
                      height: 1,
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

class _DragHandle extends StatefulWidget {
  const _DragHandle();

  @override
  State<_DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<_DragHandle> {
  bool _isHovering = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: '拖动排序',
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: FocusableActionDetector(
          onShowFocusHighlight: (value) => setState(() => _isFocused = value),
          child: AnimatedOpacity(
            opacity: _isHovering || _isFocused ? 0.68 : 0.28,
            duration: AppDurations.fast,
            child: SizedBox.square(
              dimension: AppControlSizes.compact,
              child: Icon(
                Icons.drag_handle_rounded,
                color: colors.textTertiary,
                size: 14,
              ),
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
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.brand,
                fontSize: 9.5,
                height: 1.1,
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

Color _destructiveColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFFF7479)
      : const Color(0xFFE5484D);
}
