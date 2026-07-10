import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../application/watchlist_controller.dart';

class GroupManagerSheet extends ConsumerStatefulWidget {
  const GroupManagerSheet({super.key});

  @override
  ConsumerState<GroupManagerSheet> createState() => _GroupManagerSheetState();
}

class _GroupManagerSheetState extends ConsumerState<GroupManagerSheet> {
  bool _isImporting = false;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(watchlistControllerProvider);
    final controller = ref.read(watchlistControllerProvider.notifier);
    final colors = context.appColors;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Container(
                      width: AppControlSizes.regular,
                      height: AppControlSizes.regular,
                      decoration: BoxDecoration(
                        color: colors.brandSoft,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Icon(Icons.layers_rounded, color: colors.brand),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '管理自选分组',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          Text(
                            '拖拽调整顺序，点击名称可直接编辑',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: colors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: '新增分组',
                      onPressed: () => _showAddGroupDialog(context, controller),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Flexible(
                  child: Scrollbar(
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      buildDefaultDragHandles: false,
                      itemCount: state.groups.length,
                      onReorderItem: controller.reorderGroups,
                      proxyDecorator: (child, index, animation) =>
                          ScaleTransition(
                        scale: Tween<double>(begin: 1, end: 1.015)
                            .animate(animation),
                        child: child,
                      ),
                      itemBuilder: (context, index) {
                        final group = state.groups[index];
                        final isActive = group.id == state.activeGroupId;
                        return Padding(
                          key: ValueKey(group.id),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xxs,
                          ),
                          child: AnimatedContainer(
                            duration: AppDurations.standard,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? colors.brandSoft
                                  : colors.surfaceInteractive,
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                              border: Border.all(
                                color: isActive
                                    ? colors.brand.withValues(alpha: 0.28)
                                    : colors.borderSubtle,
                              ),
                            ),
                            child: ListTile(
                              leading: ReorderableDragStartListener(
                                index: index,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.grab,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.all(AppSpacing.xs),
                                    child: Icon(
                                      Icons.drag_indicator_rounded,
                                      color: colors.textTertiary,
                                    ),
                                  ),
                                ),
                              ),
                              title: TextFormField(
                                key: ValueKey('name_${group.id}'),
                                initialValue: group.name,
                                onChanged: (value) =>
                                    controller.renameGroup(group.id, value),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              subtitle: Text(
                                isActive
                                    ? '当前分组 · ${group.stocks.length} 个标的'
                                    : '${group.stocks.length} 个标的',
                              ),
                              trailing: IconButton(
                                tooltip: state.groups.length <= 1
                                    ? '至少保留一个分组'
                                    : '删除分组',
                                onPressed: state.groups.length <= 1
                                    ? null
                                    : () => _confirmDeleteGroup(
                                          context,
                                          controller,
                                          group.id,
                                        ),
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isImporting || _isExporting
                            ? null
                            : () => _import(context, controller),
                        icon: _isImporting
                            ? const SizedBox.square(
                                dimension: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file_rounded),
                        label: Text(_isImporting ? '导入中…' : '导入备份'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _isImporting || _isExporting
                            ? null
                            : () => _export(context, controller),
                        icon: _isExporting
                            ? const SizedBox.square(
                                dimension: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.ios_share_rounded),
                        label: Text(_isExporting ? '导出中…' : '导出备份'),
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
  }

  Future<void> _import(
    BuildContext context,
    WatchlistController controller,
  ) async {
    if (_isImporting) return;
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      final file = result?.files.single;
      if (file == null) return;
      final bytes = file.bytes;
      if (bytes == null) {
        throw const FormatException('无法读取所选文件。');
      }
      final jsonText = utf8.decode(bytes);
      await controller.importGroupsFromJson(jsonText);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导入成功，已与现有分组合并。')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _export(
    BuildContext context,
    WatchlistController controller,
  ) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      await controller.exportGroups();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('备份已准备好，请选择保存或分享方式。')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
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
            decoration: const InputDecoration(hintText: '例如：港股、ETF、短线观察'),
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

  void _confirmDeleteGroup(
    BuildContext context,
    WatchlistController controller,
    String groupId,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除分组？'),
          content: const Text('分组内的自选标的也会一起移除。'),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                controller.deleteGroup(groupId);
                Navigator.of(context).pop();
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
}
