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

    final media = MediaQuery.of(context);
    final maxHeight = (media.size.height * 0.9).clamp(0.0, 780.0);
    final busy = _isImporting || _isExporting;

    return AnimatedPadding(
      duration: AppDurations.standard,
      curve: AppMotionCurves.standard,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 720, maxHeight: maxHeight),
          child: Material(
            color: colors.canvas,
            clipBehavior: Clip.antiAlias,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [colors.brand, colors.brandHover],
                            ),
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            boxShadow: [
                              BoxShadow(
                                color: colors.brand.withValues(alpha: 0.22),
                                blurRadius: 18,
                                offset: const Offset(0, 7),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.layers_rounded,
                            color: colors.onBrand,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '分组管理',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '编辑名称或拖动排序，调整你的关注结构',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: colors.textTertiary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: '关闭',
                          onPressed: Navigator.of(context).pop,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: FilledButton.icon(
                      onPressed: () => _showAddGroupDialog(context, controller),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('新建分组'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '分组顺序',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.touch_app_rounded,
                          size: 15,
                          color: colors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '按住拖动图标排序',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.textTertiary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Expanded(
                    child: Scrollbar(
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.xs,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        buildDefaultDragHandles: false,
                        itemCount: state.groups.length,
                        onReorderItem: controller.reorderGroups,
                        proxyDecorator: (child, index, animation) {
                          return ScaleTransition(
                            scale: Tween<double>(begin: 1, end: 1.02).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: AppMotionCurves.standard,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              elevation: 10,
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                              child: child,
                            ),
                          );
                        },
                        itemBuilder: (context, index) {
                          final group = state.groups[index];
                          final isActive = group.id == state.activeGroupId;
                          return _GroupManagerRow(
                            key: ValueKey(group.id),
                            index: index,
                            groupId: group.id,
                            name: group.name,
                            isActive: isActive,
                            canDelete: state.groups.length > 1,
                            onRename: (value) =>
                                controller.renameGroup(group.id, value),
                            onActivate: () =>
                                controller.setActiveGroup(group.id),
                            onDelete: () => _confirmDeleteGroup(
                              context,
                              controller,
                              group.id,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border(
                        top: BorderSide(color: colors.borderSubtle),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '数据与备份',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: busy
                                      ? null
                                      : () => _import(context, controller),
                                  icon: _isImporting
                                      ? const SizedBox.square(
                                          dimension: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.file_download_rounded),
                                  label: Text(
                                    _isImporting ? '导入中…' : '导入备份',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(46),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: FilledButton.tonalIcon(
                                  onPressed: busy
                                      ? null
                                      : () => _export(context, controller),
                                  icon: _isExporting
                                      ? const SizedBox.square(
                                          dimension: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.ios_share_rounded),
                                  label: Text(
                                    _isExporting ? '导出中…' : '导出备份',
                                  ),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(46),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
      final result = await FilePicker.pickFiles(
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
              icon: const Icon(Icons.create_new_folder_rounded),
              title: const Text('新建分组'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '用清晰的主题整理长期关注的市场与标的。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appColors.textTertiary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: textController,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: '分组名称',
                      hintText: '例如：港股、ETF、短线观察',
                      errorText: validationMessage,
                      prefixIcon: const Icon(Icons.bookmark_outline_rounded),
                    ),
                    onChanged: (_) {
                      if (validationMessage != null) {
                        setDialogState(() => validationMessage = null);
                      }
                    },
                    onSubmitted: (_) => submit(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                FilledButton.icon(
                  onPressed: submit,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('创建'),
                ),
              ],
            );
          },
        );
      },
    );
    textController.dispose();
  }

  void _confirmDeleteGroup(
    BuildContext context,
    WatchlistController controller,
    String groupId,
  ) {
    final colors = context.appColors;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: Icon(Icons.delete_outline_rounded, color: colors.gain),
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
              style: FilledButton.styleFrom(
                backgroundColor: colors.gain,
                foregroundColor: Colors.white,
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
}

class _GroupManagerRow extends StatelessWidget {
  const _GroupManagerRow({
    required this.index,
    required this.groupId,
    required this.name,
    required this.isActive,
    required this.canDelete,
    required this.onRename,
    required this.onActivate,
    required this.onDelete,
    super.key,
  });

  final int index;
  final String groupId;
  final String name;
  final bool isActive;
  final bool canDelete;
  final ValueChanged<String> onRename;
  final VoidCallback onActivate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: AnimatedContainer(
        duration: AppDurations.standard,
        curve: AppMotionCurves.standard,
        decoration: BoxDecoration(
          color: isActive ? colors.brandSoft : colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: isActive
                ? colors.brand.withValues(alpha: 0.34)
                : colors.borderSubtle,
          ),
          boxShadow: isActive ? AppShadows.pill(selected: true) : const [],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Semantics(
                  button: true,
                  label: '拖动$name调整顺序',
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Container(
                      width: 40,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isActive
                            ? colors.brand.withValues(alpha: 0.12)
                            : colors.surfaceInteractive,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        color: isActive ? colors.brand : colors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      key: ValueKey('name_$groupId'),
                      initialValue: name,
                      onChanged: onRename,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 3),
                    AnimatedSwitcher(
                      duration: AppDurations.fast,
                      child: isActive
                          ? Container(
                              key: const ValueKey('active'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.brand.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppRadii.full),
                              ),
                              child: Text(
                                '当前分组',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: colors.brand,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            )
                          : Text(
                              '点击名称直接编辑',
                              key: const ValueKey('editable'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: colors.textTertiary),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _GroupRowAction(
                tooltip: isActive ? '当前分组' : '设为当前分组',
                icon: isActive
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: colors.brand,
                background: isActive
                    ? colors.brand.withValues(alpha: 0.12)
                    : colors.surfaceInteractive,
                onPressed: isActive ? null : onActivate,
              ),
              const SizedBox(width: 4),
              _GroupRowAction(
                tooltip: canDelete ? '删除分组' : '至少保留一个分组',
                icon: Icons.delete_outline_rounded,
                color: canDelete ? colors.gain : colors.textTertiary,
                background:
                    canDelete ? colors.gainSoft : colors.surfaceInteractive,
                onPressed: canDelete ? onDelete : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupRowAction extends StatelessWidget {
  const _GroupRowAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.background,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: SizedBox.square(
            dimension: 38,
            child: Icon(icon, size: 19, color: color),
          ),
        ),
      ),
    );
  }
}
