import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../application/watchlist_controller.dart';
import 'group_manager_sheet.dart';
import 'stock_detail_screen.dart';
import 'widgets/search_panel.dart';
import 'widgets/stock_card.dart';
import '../../market/domain/stock.dart';
import '../../market/domain/stock_group.dart';

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
    final state = ref.watch(watchlistControllerProvider);
    final controller = ref.read(watchlistControllerProvider.notifier);
    final activeGroup = state.activeGroup;
    final scheme = Theme.of(context).colorScheme;

    if (!state.isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Watchlist',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                    color: scheme.onSurface,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      _CircleIconButton(
                        tooltip: state.isDark ? '浅色模式' : '深色模式',
                        onPressed: controller.toggleTheme,
                        icon: Icon(
                          state.isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const SearchPanel(),
                  const SizedBox(height: 24),
                  _GroupTabs(
                    activeGroupId: state.activeGroupId,
                    groups: state.groups,
                    onSelect: controller.setActiveGroup,
                    onAdd: () => _showAddGroupDialog(context, controller),
                    onManage: () => _showGroupManager(context),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 10),
                    _InlineError(message: state.error!),
                  ],
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: activeGroup == null || activeGroup.stocks.isEmpty
                    ? const _EmptyState()
                    : ReorderableListView.builder(
                        key: ValueKey(activeGroup.id),
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                        itemCount: activeGroup.stocks.length,
                        onReorderItem: controller.reorderStocks,
                        buildDefaultDragHandles: false,
                        proxyDecorator: (child, index, animation) {
                          return ScaleTransition(
                            scale: Tween<double>(begin: 1, end: 1.03)
                                .animate(animation),
                            child: child,
                          );
                        },
                        itemBuilder: (context, index) {
                          final stock = activeGroup.stocks[index];
                          return Padding(
                            key: ValueKey('${activeGroup.id}_${stock.secid}'),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: StockCard(
                              reorderIndex: index,
                              stock: stock,
                              isFlashing:
                                  state.flashingCodes.contains(stock.code),
                              onTap: () {
                                Navigator.of(context).push(
                                  _stockDetailRoute(stock),
                                );
                              },
                              onDelete: () =>
                                  controller.removeStock(stock.code),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupManager(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const GroupManagerSheet(),
    );
  }

  void _showAddGroupDialog(
    BuildContext context,
    WatchlistController controller,
  ) {
    final textController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新增分组'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(hintText: '分组名称'),
            onSubmitted: (_) {
              controller.addGroup(textController.text);
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                controller.addGroup(textController.text);
                Navigator.of(context).pop();
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }
}

Route<void> _stockDetailRoute(Stock stock) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, animation, secondaryAnimation) =>
        StockDetailScreen(stock: stock),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: Tween<double>(begin: 0.50, end: 1).animate(curved),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.16, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _GroupTabs extends StatelessWidget {
  const _GroupTabs({
    required this.activeGroupId,
    required this.groups,
    required this.onSelect,
    required this.onAdd,
    required this.onManage,
  });

  final String activeGroupId;
  final List<StockGroup> groups;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        children: [
          for (final group in groups) ...[
            _PillButton(
              selected: group.id == activeGroupId,
              label: group.name,
              onPressed: () => onSelect(group.id),
            ),
            const SizedBox(width: 8),
          ],
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 34,
              child: Container(
                margin: const EdgeInsets.only(left: 2),
                padding: const EdgeInsets.only(left: 12, right: 2),
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: AppPalette.slate200)),
                ),
                child: Row(
                  children: [
                    _SmallToolButton(
                      tooltip: '新增分组',
                      onPressed: onAdd,
                      icon: Icons.add_rounded,
                    ),
                    const SizedBox(width: 8),
                    _SmallToolButton(
                      tooltip: '管理分组',
                      onPressed: onManage,
                      icon: Icons.tune_rounded,
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

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
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
          color: Colors.white,
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
                  size: 20,
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

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.selected,
    required this.label,
    required this.onPressed,
  });

  final bool selected;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppPalette.blue500, AppPalette.blue600],
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.transparent : AppPalette.slate100,
          ),
          boxShadow: AppShadows.pill(selected: selected),
        ),
        child: SizedBox(
          height: 34,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onPressed,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 58),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      strutStyle: const StrutStyle(
                        fontSize: 12,
                        height: 1,
                        forceStrutHeight: true,
                      ),
                      style: TextStyle(
                        color: selected ? Colors.white : AppPalette.slate500,
                        fontSize: 12,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallToolButton extends StatelessWidget {
  const _SmallToolButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppPalette.slate100),
          boxShadow: AppShadows.control(),
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: 34,
              child: Icon(icon, size: 18, color: AppPalette.slate400),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: scheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 58,
              color: scheme.primary.withValues(alpha: 0.75),
            ),
            const SizedBox(height: 14),
            Text(
              '这个分组还没有自选',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              '用上方搜索添加股票、指数、ETF 或加密货币。',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
