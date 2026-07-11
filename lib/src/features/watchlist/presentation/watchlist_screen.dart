import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../market/domain/stock.dart';
import '../../market/domain/stock_group.dart';
import '../../market/domain/market_index_snapshot.dart';
import '../application/watchlist_controller.dart';
import 'group_manager_sheet.dart';
import 'stock_detail_screen.dart';
import 'widgets/search_panel.dart';
import 'widgets/market_index_bar.dart';
import 'widgets/stock_card.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final enabled = state == AppLifecycleState.resumed;
    ref.read(watchlistControllerProvider.notifier).setPollingEnabled(enabled);
  }

  @override
  Widget build(BuildContext context) {
    final isLoaded = ref.watch(
      watchlistControllerProvider.select((state) => state.isLoaded),
    );
    final colors = context.appColors;

    if (!isLoaded) {
      return Scaffold(
        backgroundColor: colors.canvas,
        body: const SafeArea(child: _WatchlistLoadingSkeleton()),
      );
    }

    final groups = ref.watch(
      watchlistControllerProvider.select((state) => state.groups),
    );
    final activeGroupId = ref.watch(
      watchlistControllerProvider.select((state) => state.activeGroupId),
    );
    final isDark = ref.watch(
      watchlistControllerProvider.select((state) => state.isDark),
    );
    final isRefreshing = ref.watch(
      watchlistControllerProvider.select((state) => state.isRefreshing),
    );
    final error = ref.watch(
      watchlistControllerProvider.select((state) => state.error),
    );
    final lastUpdated = ref.watch(
      watchlistControllerProvider.select((state) => state.lastUpdated),
    );
    final flashingCodes = ref.watch(
      watchlistControllerProvider.select((state) => state.flashingCodes),
    );
    final indexes = ref.watch(
      watchlistControllerProvider.select((state) => state.indexes),
    );
    final indexMarket = ref.watch(
      watchlistControllerProvider.select((state) => state.indexMarket),
    );
    final isIndexLoading = ref.watch(
      watchlistControllerProvider.select((state) => state.isIndexLoading),
    );
    final indexError = ref.watch(
      watchlistControllerProvider.select((state) => state.indexError),
    );
    final activeGroup = _resolveActiveGroup(groups, activeGroupId);
    final controller = ref.read(watchlistControllerProvider.notifier);

    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shared = _WatchlistViewData(
              groups: groups,
              activeGroupId: activeGroupId,
              activeGroup: activeGroup,
              isDark: isDark,
              isRefreshing: isRefreshing,
              error: error,
              lastUpdated: lastUpdated,
              flashingCodes: flashingCodes,
              indexes: indexes,
              indexMarket: indexMarket,
              isIndexLoading: isIndexLoading,
              indexError: indexError,
              onSelectGroup: controller.setActiveGroup,
              onAddGroup: () => _showAddGroupDialog(context, controller),
              onManageGroups: () => _showGroupManager(context),
              onSearch: () => _showSearch(context),
              onRefresh: controller.refreshNow,
              onToggleTheme: controller.toggleTheme,
              onReorder: controller.reorderStocks,
              onDelete: controller.removeStock,
              onOpenStock: (stock) {
                Navigator.of(context).push(_stockDetailRoute(stock));
              },
            );

            if (constraints.maxWidth >= AppBreakpoints.desktop) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppBreakpoints.maxContentWidth,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: constraints.maxHeight,
                    child: _DesktopWatchlistLayout(data: shared),
                  ),
                ),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: SizedBox(
                  width: double.infinity,
                  height: constraints.maxHeight,
                  child: _CompactWatchlistLayout(data: shared),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showGroupManager(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder: (_) => const GroupManagerSheet(),
    );
  }

  void _showSearch(BuildContext context) {
    final controller = ref.read(watchlistControllerProvider.notifier);
    controller.clearSearch();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder: (_) => const StockSearchSheet(),
    ).whenComplete(controller.clearSearch);
  }

  Future<void> _showAddGroupDialog(
    BuildContext context,
    WatchlistController controller,
  ) async {
    final textController = TextEditingController();
    String? validationMessage;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void submit() {
              final name = textController.text.trim();
              if (name.isEmpty) {
                setDialogState(() => validationMessage = '请输入分组名称');
                return;
              }
              controller.addGroup(name);
              Navigator.of(dialogContext).pop();
            }

            return AlertDialog(
              title: const Text('新建分组'),
              content: TextField(
                controller: textController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: '例如：长期关注、港股、ETF',
                  errorText: validationMessage,
                ),
                onChanged: (_) {
                  if (validationMessage != null) {
                    setDialogState(() => validationMessage = null);
                  }
                },
                onSubmitted: (_) => submit(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: submit,
                  child: const Text('创建'),
                ),
              ],
            );
          },
        );
      },
    );
    textController.dispose();
  }
}

StockGroup? _resolveActiveGroup(
  List<StockGroup> groups,
  String activeGroupId,
) {
  if (groups.isEmpty) return null;
  for (final group in groups) {
    if (group.id == activeGroupId) return group;
  }
  return groups.first;
}

class _WatchlistViewData {
  const _WatchlistViewData({
    required this.groups,
    required this.activeGroupId,
    required this.activeGroup,
    required this.isDark,
    required this.isRefreshing,
    required this.error,
    required this.lastUpdated,
    required this.flashingCodes,
    required this.indexes,
    required this.indexMarket,
    required this.isIndexLoading,
    required this.indexError,
    required this.onSelectGroup,
    required this.onAddGroup,
    required this.onManageGroups,
    required this.onSearch,
    required this.onRefresh,
    required this.onToggleTheme,
    required this.onReorder,
    required this.onDelete,
    required this.onOpenStock,
  });

  final List<StockGroup> groups;
  final String activeGroupId;
  final StockGroup? activeGroup;
  final bool isDark;
  final bool isRefreshing;
  final String? error;
  final DateTime? lastUpdated;
  final Set<String> flashingCodes;
  final List<MarketIndexSnapshot> indexes;
  final Market? indexMarket;
  final bool isIndexLoading;
  final String? indexError;
  final ValueChanged<String> onSelectGroup;
  final VoidCallback onAddGroup;
  final VoidCallback onManageGroups;
  final VoidCallback onSearch;
  final Future<void> Function() onRefresh;
  final VoidCallback onToggleTheme;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<String> onDelete;
  final ValueChanged<Stock> onOpenStock;
}

class _DesktopWatchlistLayout extends StatelessWidget {
  const _DesktopWatchlistLayout({required this.data});

  final _WatchlistViewData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 264,
            child: _DesktopSidebar(data: data),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.appColors.canvasMuted,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: Border.all(color: context.appColors.borderSubtle),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.xl),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xxl,
                        AppSpacing.xxl,
                        AppSpacing.xxl,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          _WatchlistHeader(data: data, expanded: true),
                          const SizedBox(height: AppSpacing.xl),
                          MarketIndexBar(
                            market: data.indexMarket,
                            snapshots: data.indexes,
                            isLoading: data.isIndexLoading,
                            error: data.indexError,
                          ),
                          if (data.error != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _InlineError(
                              message: data.error!,
                              onRetry: data.onRefresh,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: _WatchlistBody(
                        data: data,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xxl,
                          0,
                          AppSpacing.xxl,
                          AppSpacing.xxl,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({required this.data});

  final _WatchlistViewData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: colors.overlay.withValues(alpha: 0.07),
            blurRadius: 32,
            spreadRadius: -16,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BrandLockup(),
            const SizedBox(height: AppSpacing.xxxl),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '我的分组',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                _CompactIconButton(
                  tooltip: '新建分组',
                  icon: Icons.add_rounded,
                  onPressed: data.onAddGroup,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.separated(
                itemCount: data.groups.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final group = data.groups[index];
                  return _SidebarGroupItem(
                    group: group,
                    selected: group.id == data.activeGroupId,
                    onPressed: () => data.onSelectGroup(group.id),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: data.onManageGroups,
              icon: const Icon(Icons.tune_rounded),
              label: const Text('管理分组与备份'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppControlSizes.regular),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return const _StorageKingLogo(expanded: true);
  }
}

class _SidebarGroupItem extends StatelessWidget {
  const _SidebarGroupItem({
    required this.group,
    required this.selected,
    required this.onPressed,
  });

  final StockGroup group;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: selected ? colors.brandSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.md),
        hoverColor: colors.surfaceInteractive,
        focusColor: colors.brandSoft,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: selected ? colors.brand : colors.textTertiary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  group.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: selected ? colors.brand : colors.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactWatchlistLayout extends StatelessWidget {
  const _CompactWatchlistLayout({required this.data});

  final _WatchlistViewData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Column(
            children: [
              _WatchlistHeader(data: data, expanded: false),
              const SizedBox(height: AppSpacing.lg),
              MarketIndexBar(
                market: data.indexMarket,
                snapshots: data.indexes,
                isLoading: data.isIndexLoading,
                error: data.indexError,
              ),
              const SizedBox(height: AppSpacing.md),
              _GroupTabs(
                activeGroupId: data.activeGroupId,
                groups: data.groups,
                onSelect: data.onSelectGroup,
                onAdd: data.onAddGroup,
              ),
              if (data.error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _InlineError(
                  message: data.error!,
                  onRetry: data.onRefresh,
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _WatchlistBody(
            data: data,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
          ),
        ),
      ],
    );
  }
}

class _WatchlistHeader extends StatelessWidget {
  const _WatchlistHeader({required this.data, required this.expanded});

  final _WatchlistViewData data;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final heading = _StorageKingLogo(expanded: expanded);

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderActionButton(
          tooltip: '刷新行情',
          label: expanded ? '刷新' : null,
          icon: data.isRefreshing ? null : Icons.refresh_rounded,
          isLoading: data.isRefreshing,
          onPressed: data.isRefreshing ? null : data.onRefresh,
        ),
        const SizedBox(width: AppSpacing.xs),
        _HeaderActionButton(
          tooltip: '搜索添加',
          icon: Icons.search_rounded,
          onPressed: data.onSearch,
        ),
        const SizedBox(width: AppSpacing.xs),
        _HeaderActionButton(
          tooltip: data.isDark ? '切换浅色模式' : '切换深色模式',
          icon: data.isDark
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined,
          onPressed: data.onToggleTheme,
        ),
        const SizedBox(width: AppSpacing.xs),
        _HeaderActionButton(
          tooltip: '管理分组',
          label: expanded ? '管理' : null,
          icon: Icons.tune_rounded,
          onPressed: data.onManageGroups,
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: heading),
            const SizedBox(width: AppSpacing.md),
            actions,
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _LiveStatusPill(isRefreshing: data.isRefreshing),
            Text(
              '上次更新 ${_formatUpdatedAt(data.lastUpdated)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textTertiary,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StorageKingLogo extends StatelessWidget {
  const _StorageKingLogo({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final markSize = expanded ? 46.0 : 42.0;
    return Semantics(
      label: '存为王品牌标识',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: markSize,
            height: markSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.brand, colors.brandHover],
              ),
              borderRadius: BorderRadius.circular(markSize * 0.3),
              boxShadow: [
                BoxShadow(
                  color: colors.brand.withValues(alpha: 0.26),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: CustomPaint(
              painter: const _StorageCrownMarkPainter(),
            ),
          ),
          SizedBox(width: expanded ? AppSpacing.sm : 10),
          Text(
            '存为王',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.brand,
                  fontFamily: 'PingFang SC',
                  fontFamilyFallback: AppTypographyTokens.fontFamilyFallback,
                  fontSize: expanded ? 27 : 25,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
          ),
        ],
      ),
    );
  }
}

class _StorageCrownMarkPainter extends CustomPainter {
  const _StorageCrownMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.96);

    final crown = Path()
      ..moveTo(size.width * 0.2, size.height * 0.42)
      ..lineTo(size.width * 0.31, size.height * 0.23)
      ..lineTo(size.width * 0.49, size.height * 0.4)
      ..lineTo(size.width * 0.68, size.height * 0.2)
      ..lineTo(size.width * 0.8, size.height * 0.42);
    canvas.drawPath(crown, stroke);

    final layers = [
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.48,
        size.width * 0.6,
        size.height * 0.1,
      ),
      Rect.fromLTWH(
        size.width * 0.25,
        size.height * 0.64,
        size.width * 0.5,
        size.height * 0.1,
      ),
    ];
    for (final layer in layers) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          layer,
          Radius.circular(size.width * 0.05),
        ),
        fill,
      );
    }
    canvas.drawCircle(
      Offset(size.width * 0.68, size.height * 0.69),
      size.width * 0.022,
      Paint()..color = const Color(0xFF2563EB),
    );
  }

  @override
  bool shouldRepaint(covariant _StorageCrownMarkPainter oldDelegate) => false;
}

class _LiveStatusPill extends StatelessWidget {
  const _LiveStatusPill({required this.isRefreshing});

  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tone = isRefreshing ? colors.info : colors.gain;
    final soft = isRefreshing ? colors.infoSoft : colors.gainSoft;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: soft,
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
            if (isRefreshing)
              SizedBox.square(
                dimension: 8,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: tone,
                ),
              )
            else
              Icon(Icons.circle, size: 7, color: tone),
            const SizedBox(width: AppSpacing.xs),
            Text(
              isRefreshing ? '正在刷新' : '实时行情',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: tone,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.tooltip,
    required this.onPressed,
    this.icon,
    this.label,
    this.isLoading = false,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final content = isLoading
        ? SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.brand,
            ),
          )
        : Icon(icon, size: 20);

    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: AppShadows.control(),
        ),
        child: Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            side: BorderSide(color: colors.border),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppRadii.md),
            hoverColor: colors.surfaceInteractive,
            focusColor: colors.brandSoft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AppControlSizes.regular,
                minHeight: AppControlSizes.regular,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: label == null ? AppSpacing.sm : AppSpacing.md,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconTheme(
                      data: IconThemeData(color: colors.textSecondary),
                      child: content,
                    ),
                    if (label != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        label!,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WatchlistBody extends StatelessWidget {
  const _WatchlistBody({required this.data, required this.padding});

  final _WatchlistViewData data;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final activeGroup = data.activeGroup;
    if (activeGroup == null || activeGroup.stocks.isEmpty) {
      return RefreshIndicator(
        onRefresh: data.onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: padding,
                child: _EmptyState(
                  onAdd: data.onSearch,
                  onImport: data.onManageGroups,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: data.onRefresh,
      child: ReorderableListView.builder(
        key: ValueKey(activeGroup.id),
        padding: padding,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: activeGroup.stocks.length,
        onReorderItem: data.onReorder,
        buildDefaultDragHandles: false,
        proxyDecorator: (child, index, animation) {
          return ScaleTransition(
            scale: Tween<double>(begin: 1, end: 1.015).animate(
              CurvedAnimation(
                parent: animation,
                curve: AppMotionCurves.standard,
              ),
            ),
            child: Material(color: Colors.transparent, child: child),
          );
        },
        itemBuilder: (context, index) {
          final stock = activeGroup.stocks[index];
          return Padding(
            key: ValueKey('${activeGroup.id}_${stock.secid}'),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 240 + index.clamp(0, 6) * 25),
              curve: Curves.easeOutCubic,
              child: StockCard(
                reorderIndex: index,
                stock: stock,
                isFlashing: data.flashingCodes.contains(stock.code),
                onTap: () => data.onOpenStock(stock),
                onDelete: () => data.onDelete(stock.code),
              ),
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GroupTabs extends StatelessWidget {
  const _GroupTabs({
    required this.activeGroupId,
    required this.groups,
    required this.onSelect,
    required this.onAdd,
  });

  final String activeGroupId;
  final List<StockGroup> groups;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppControlSizes.small,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: groups.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          if (index == groups.length) {
            return _CompactIconButton(
              tooltip: '新建分组',
              icon: Icons.add_rounded,
              onPressed: onAdd,
            );
          }
          final group = groups[index];
          return _GroupPill(
            selected: group.id == activeGroupId,
            label: group.name,
            onPressed: () => onSelect(group.id),
          );
        },
      ),
    );
  }
}

class _GroupPill extends StatelessWidget {
  const _GroupPill({
    required this.selected,
    required this.label,
    required this.onPressed,
  });

  final bool selected;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: selected ? colors.brand : colors.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? colors.brand : colors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.full),
        onTap: onPressed,
        hoverColor: selected ? colors.brandHover : colors.surfaceInteractive,
        focusColor: selected ? colors.brandHover : colors.brandSoft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? colors.onBrand : colors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactIconButton extends StatelessWidget {
  const _CompactIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.surface,
        shape: CircleBorder(side: BorderSide(color: colors.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          hoverColor: colors.surfaceInteractive,
          focusColor: colors.brandSoft,
          child: SizedBox.square(
            dimension: AppControlSizes.small,
            child: Icon(icon, size: 20, color: colors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.warning.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, size: 18, color: colors.warning),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd, required this.onImport});

  final VoidCallback onAdd;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.brandSoft,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: 72,
                    child: Icon(
                      Icons.add_chart_rounded,
                      size: 34,
                      color: colors.brand,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  '这个分组还是空的',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '搜索并添加股票、指数、ETF 或加密货币，开始构建你的关注列表。',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('搜索添加'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onImport,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('导入备份'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WatchlistLoadingSkeleton extends StatelessWidget {
  const _WatchlistLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= AppBreakpoints.desktop;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (desktop) ...[
                    const SizedBox(
                      width: 264,
                      child: _SkeletonPanel(showRows: true),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  const Expanded(child: _SkeletonPanel(showRows: true)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonPanel extends StatelessWidget {
  const _SkeletonPanel({required this.showRows});

  final bool showRows;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SkeletonBar(width: 132, height: 26),
              const SizedBox(height: AppSpacing.sm),
              const _SkeletonBar(width: 210, height: 14),
              const SizedBox(height: AppSpacing.xxl),
              const _SkeletonBar(width: double.infinity, height: 48),
              if (showRows) ...[
                const SizedBox(height: AppSpacing.xl),
                for (var index = 0; index < 4; index++) ...[
                  const _SkeletonBar(width: double.infinity, height: 92),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.48, end: 0.86),
      duration: AppDurations.slow,
      curve: AppMotionCurves.standard,
      builder: (context, opacity, _) {
        return Opacity(
          opacity: opacity,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: context.appColors.surfaceInteractive,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
          ),
        );
      },
    );
  }
}

Route<void> _stockDetailRoute(Stock stock) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 360),
    opaque: false,
    barrierColor: Colors.black.withValues(alpha: 0.08),
    pageBuilder: (context, animation, secondaryAnimation) =>
        StockDetailScreen(stock: stock),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) {
          if (animation.status == AnimationStatus.reverse) {
            final value = Curves.easeInCubic.transform(animation.value);
            return Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(
                  0,
                  (1 - value) * MediaQuery.sizeOf(context).height * 1.04,
                ),
                child: child,
              ),
            );
          }
          final value = Curves.easeOutQuart.transform(animation.value);
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.965 + 0.035 * value,
              alignment: const Alignment(0, 0.12),
              child: Transform.translate(
                offset: Offset(
                  0,
                  (1 - value) * MediaQuery.sizeOf(context).height * 0.22,
                ),
                child: child,
              ),
            ),
          );
        },
      );
    },
  );
}

String _formatUpdatedAt(DateTime? value) {
  if (value == null) return '等待首次更新';
  final local = value.toLocal();
  String twoDigits(int input) => input.toString().padLeft(2, '0');
  return '${twoDigits(local.hour)}:${twoDigits(local.minute)}:'
      '${twoDigits(local.second)}';
}
