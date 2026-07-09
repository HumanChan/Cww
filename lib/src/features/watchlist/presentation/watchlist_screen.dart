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
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                        ),
                      ),
                    ],
                  ),
                  if (state.lastUpdated != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '已更新 ${_formatUpdateTime(state.lastUpdated!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const SearchPanel(),
                  const SizedBox(height: 18),
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
                        padding: const EdgeInsets.fromLTRB(24, 6, 24, 32),
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
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: StockCard(
                              reorderIndex: index,
                              stock: stock,
                              isFlashing:
                                  state.flashingCodes.contains(stock.code),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        StockDetailScreen(stock: stock),
                                  ),
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
      height: 42,
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
                return _PillButton(
                  selected: selected,
                  label: group.name,
                  onPressed: () => onSelect(group.id),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 10),
            padding: const EdgeInsets.only(left: 10),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Color(0xFFE2E8F0))),
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
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(
          side: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 40,
            child: IconTheme(
              data: const IconThemeData(color: Color(0xFF64748B), size: 21),
              child: icon,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              )
            : null,
        color: selected ? null : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? Colors.transparent : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: selected
                ? const Color(0x332563EB)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: selected ? 10 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w900,
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
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(
          side: BorderSide(color: Color(0xFFF1F5F9)),
        ),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 36,
            child: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
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

String _formatUpdateTime(DateTime time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
}
