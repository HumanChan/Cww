import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/watchlist_controller.dart';
import 'group_manager_sheet.dart';
import 'stock_detail_screen.dart';
import 'widgets/search_panel.dart';
import 'widgets/stock_card.dart';
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
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
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
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              state.lastUpdated == null
                                  ? '等待首次行情刷新'
                                  : '已更新 ${_formatUpdateTime(state.lastUpdated!)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (state.isRefreshing)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      IconButton.filledTonal(
                        tooltip: '手动刷新',
                        onPressed: controller.refreshNow,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: state.isDark ? '浅色模式' : '深色模式',
                        onPressed: controller.toggleTheme,
                        icon: Icon(state.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const SearchPanel(),
                  const SizedBox(height: 14),
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
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                        itemCount: activeGroup.stocks.length,
                        onReorder: controller.reorderStocks,
                        proxyDecorator: (child, index, animation) {
                          return ScaleTransition(
                            scale: Tween<double>(begin: 1, end: 1.03).animate(animation),
                            child: child,
                          );
                        },
                        itemBuilder: (context, index) {
                          final stock = activeGroup.stocks[index];
                          return Padding(
                            key: ValueKey('${activeGroup.id}_${stock.secid}'),
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: StockCard(
                              stock: stock,
                              isFlashing: state.flashingCodes.contains(stock.code),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => StockDetailScreen(stock: stock),
                                  ),
                                );
                              },
                              onDelete: () => controller.removeStock(stock.code),
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

  void _showAddGroupDialog(BuildContext context, WatchlistController controller) {
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
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final group = groups[index];
                final selected = group.id == activeGroupId;
                return ChoiceChip(
                  selected: selected,
                  label: Text(group.name),
                  onSelected: (_) => onSelect(group.id),
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                  selectedColor: scheme.primary,
                  backgroundColor: scheme.surfaceContainerHighest.withOpacity(0.55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: '新增分组',
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 6),
          IconButton.filledTonal(
            tooltip: '管理分组',
            onPressed: onManage,
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
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
        color: scheme.errorContainer.withOpacity(0.45),
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onErrorContainer),
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
            Icon(Icons.auto_awesome_rounded, size: 58, color: scheme.primary.withOpacity(0.75)),
            const SizedBox(height: 14),
            Text(
              '这个分组还没有自选',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              '用上方搜索添加股票、指数、ETF 或加密货币。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatUpdateTime(DateTime time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
}
