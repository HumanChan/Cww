import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/watchlist_controller.dart';

class GroupManagerSheet extends ConsumerWidget {
  const GroupManagerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(watchlistControllerProvider);
    final controller = ref.read(watchlistControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '管理分组',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: '新增分组',
                  onPressed: () => _showAddGroupDialog(context, controller),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: state.groups.length,
                onReorder: controller.reorderGroups,
                itemBuilder: (context, index) {
                  final group = state.groups[index];
                  return Padding(
                    key: ValueKey(group.id),
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.drag_indicator_rounded),
                        title: TextFormField(
                          initialValue: group.name,
                          onChanged: (value) => controller.renameGroup(group.id, value),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        subtitle: Text('${group.stocks.length} 个标的'),
                        trailing: IconButton(
                          tooltip: '删除分组',
                          onPressed: state.groups.length <= 1
                              ? null
                              : () => _confirmDeleteGroup(context, controller, group.id),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _import(context, controller),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('导入'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      await controller.exportGroups();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已打开系统分享面板导出备份。')),
                        );
                      }
                    },
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('导出'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _import(BuildContext context, WatchlistController controller) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return;

    try {
      final path = file.path;
      final jsonText = file.bytes != null
          ? utf8.decode(file.bytes!)
          : path == null
              ? throw const FormatException('无法读取所选文件。')
              : await File(path).readAsString();
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
    }
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

  void _confirmDeleteGroup(BuildContext context, WatchlistController controller, String groupId) {
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
