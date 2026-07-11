import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../market/domain/stock.dart';
import '../../application/watchlist_controller.dart';

class SearchPanel extends ConsumerStatefulWidget {
  const SearchPanel({this.focusNode, super.key});

  final FocusNode? focusNode;

  @override
  ConsumerState<SearchPanel> createState() => _SearchPanelState();
}

class StockSearchSheet extends ConsumerStatefulWidget {
  const StockSearchSheet({super.key});

  @override
  ConsumerState<StockSearchSheet> createState() => _StockSearchSheetState();
}

class _StockSearchSheetState extends ConsumerState<StockSearchSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode(debugLabel: 'bottom-stock-search');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(watchlistControllerProvider);
    final colors = context.appColors;
    final activeCodes =
        state.activeGroup?.stocks.map((stock) => stock.code).toSet() ??
            const <String>{};
    if (_controller.text != state.searchQuery) {
      _controller.value = TextEditingValue(
        text: state.searchQuery,
        selection: TextSelection.collapsed(offset: state.searchQuery.length),
      );
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.78,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.xl),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.overlay.withValues(alpha: 0.2),
                blurRadius: 42,
                spreadRadius: -16,
                offset: const Offset(0, -12),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.borderStrong.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '搜索并添加',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭搜索',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  key: const ValueKey('bottom-search-field'),
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: ref
                      .read(watchlistControllerProvider.notifier)
                      .setSearchQuery,
                  decoration: InputDecoration(
                    hintText: '股票、指数、ETF 或加密货币',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: state.isSearching
                        ? Padding(
                            padding: const EdgeInsets.all(14),
                            child: SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.brand,
                              ),
                            ),
                          )
                        : state.searchQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: '清空',
                                onPressed: () => ref
                                    .read(watchlistControllerProvider.notifier)
                                    .clearSearch(),
                                icon: const Icon(Icons.close_rounded),
                              ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: state.searchQuery.trim().isEmpty
                      ? const _SearchMessage(
                          icon: Icons.manage_search_rounded,
                          title: '查找全球行情',
                          description: '输入名称或代码，添加成功后可以继续搜索下一只。',
                        )
                      : _SearchSheetResults(
                          isSearching: state.isSearching,
                          results: state.searchResults,
                          searchError: state.searchError,
                          activeCodes: activeCodes,
                          onRetry: () => ref
                              .read(watchlistControllerProvider.notifier)
                              .setSearchQuery(_controller.text),
                          onSelect: _selectResult,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectResult(Stock stock, bool alreadyAdded) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (alreadyAdded) {
      messenger.showSnackBar(SnackBar(content: Text('${stock.name} 已在当前分组中')));
      return;
    }
    ref.read(watchlistControllerProvider.notifier).addStock(stock);
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
    messenger.showSnackBar(
      SnackBar(
        content: Text('已将 ${stock.name} 添加到当前分组，可继续搜索'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SearchSheetResults extends StatelessWidget {
  const _SearchSheetResults({
    required this.isSearching,
    required this.results,
    required this.searchError,
    required this.activeCodes,
    required this.onRetry,
    required this.onSelect,
  });

  final bool isSearching;
  final List<Stock> results;
  final String? searchError;
  final Set<String> activeCodes;
  final VoidCallback onRetry;
  final void Function(Stock stock, bool alreadyAdded) onSelect;

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return const _SearchMessage(
        icon: Icons.search_rounded,
        title: '正在搜索',
        description: '正在从行情源查找匹配标的…',
        showProgress: true,
      );
    }
    if (searchError != null) {
      return _SearchMessage(
        icon: Icons.cloud_off_rounded,
        title: '搜索暂时不可用',
        description: searchError!,
        actionLabel: '重新搜索',
        onAction: onRetry,
      );
    }
    if (results.isEmpty) {
      return const _SearchMessage(
        icon: Icons.search_off_rounded,
        title: '没有找到匹配结果',
        description: '换个名称或代码再试试。',
      );
    }
    final colors = context.appColors;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '搜索结果',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            Text(
              '${results.length} 条',
              style: TextStyle(color: colors.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: ListView.separated(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: results.length,
            separatorBuilder: (_, __) => Divider(color: colors.borderSubtle),
            itemBuilder: (context, index) {
              final stock = results[index];
              final added = activeCodes.contains(stock.code);
              return _SearchResultTile(
                stock: stock,
                alreadyAdded: added,
                onPressed: () => onSelect(stock, added),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchPanelState extends ConsumerState<SearchPanel> {
  final TextEditingController _textController = TextEditingController();
  final OverlayPortalController _portalController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();

  late FocusNode _focusNode;
  late bool _ownsFocusNode;
  double _overlayWidth = 320;

  @override
  void initState() {
    super.initState();
    _attachFocusNode(widget.focusNode);
  }

  @override
  void didUpdateWidget(covariant SearchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _detachFocusNode();
      _attachFocusNode(widget.focusNode);
    }
  }

  @override
  void dispose() {
    _detachFocusNode();
    _textController.dispose();
    super.dispose();
  }

  void _attachFocusNode(FocusNode? node) {
    _ownsFocusNode = node == null;
    _focusNode = node ?? FocusNode(debugLabel: 'stock-search-field');
    _focusNode.addListener(_handleFocusChange);
  }

  void _detachFocusNode() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus && _textController.text.trim().isNotEmpty) {
      _showOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(
      watchlistControllerProvider.select((state) => state.searchQuery),
    );
    final isSearching = ref.watch(
      watchlistControllerProvider.select((state) => state.isSearching),
    );
    final results = ref.watch(
      watchlistControllerProvider.select((state) => state.searchResults),
    );
    final searchError = ref.watch(
      watchlistControllerProvider.select((state) => state.searchError),
    );
    final activeCodesKey = ref.watch(
      watchlistControllerProvider.select(
        (state) =>
            state.activeGroup?.stocks
                .map((stock) => stock.code)
                .join('\u0000') ??
            '',
      ),
    );
    final activeCodes = activeCodesKey.isEmpty
        ? const <String>{}
        : activeCodesKey.split('\u0000').toSet();

    _synchronizeText(query);
    _scheduleOverlaySync(query.trim().isNotEmpty);

    return _buildSearchAnchor(
      context,
      query: query,
      isSearching: isSearching,
      results: results,
      searchError: searchError,
      activeCodes: activeCodes,
    );
  }

  Widget _buildSearchAnchor(
    BuildContext context, {
    required String query,
    required bool isSearching,
    required List<Stock> results,
    required String? searchError,
    required Set<String> activeCodes,
  }) {
    final colors = context.appColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        _overlayWidth = constraints.maxWidth;
        return OverlayPortal(
          controller: _portalController,
          overlayChildBuilder: (overlayContext) {
            return Positioned(
              width: _overlayWidth,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(0, AppSpacing.xs),
                child: _SearchResultsOverlay(
                  query: query,
                  isSearching: isSearching,
                  results: results,
                  searchError: searchError,
                  activeCodes: activeCodes,
                  onRetry: _retrySearch,
                  onSelect: _selectResult,
                ),
              ),
            );
          },
          child: CompositedTransformTarget(
            link: _layerLink,
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  _clearSearch(unfocus: true);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                cursorColor: colors.brand,
                onTap: () {
                  if (_textController.text.trim().isNotEmpty) _showOverlay();
                },
                onChanged: _handleQueryChanged,
                onSubmitted: (_) {
                  if (_textController.text.trim().isNotEmpty) _showOverlay();
                },
                decoration: InputDecoration(
                  hintText: '搜索股票、指数、ETF 或加密货币',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                  filled: true,
                  fillColor: colors.surface,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colors.textTertiary,
                    size: 21,
                  ),
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: AppControlSizes.regular,
                    minHeight: AppControlSizes.regular,
                  ),
                  suffixIcon: _SearchFieldSuffix(
                    isSearching: isSearching,
                    showClear: query.isNotEmpty,
                    onClear: () => _clearSearch(unfocus: false),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide(color: colors.focusRing, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _synchronizeText(String query) {
    if (_textController.text == query) return;
    _textController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
  }

  void _scheduleOverlaySync(bool shouldShow) {
    if (shouldShow == _portalController.isShowing) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (shouldShow) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
    });
  }

  void _showOverlay() {
    if (!_portalController.isShowing) _portalController.show();
  }

  void _hideOverlay() {
    if (_portalController.isShowing) _portalController.hide();
  }

  void _handleQueryChanged(String query) {
    ref.read(watchlistControllerProvider.notifier).setSearchQuery(query);
    if (query.trim().isEmpty) {
      _hideOverlay();
    } else {
      _showOverlay();
    }
  }

  void _clearSearch({required bool unfocus}) {
    _textController.clear();
    ref.read(watchlistControllerProvider.notifier).setSearchQuery('');
    _hideOverlay();
    if (unfocus) _focusNode.unfocus();
  }

  void _retrySearch() {
    final query = _textController.text;
    if (query.trim().isEmpty) return;
    ref.read(watchlistControllerProvider.notifier).setSearchQuery(query);
    _showOverlay();
  }

  void _selectResult(Stock stock, bool alreadyAdded) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (alreadyAdded) {
      messenger.showSnackBar(
        SnackBar(content: Text('${stock.name} 已在当前分组中')),
      );
      return;
    }

    ref.read(watchlistControllerProvider.notifier).addStock(stock);
    _textController.clear();
    _hideOverlay();
    _focusNode.unfocus();
    messenger.showSnackBar(
      SnackBar(
        content: Text('已将 ${stock.name} 添加到当前分组'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SearchFieldSuffix extends StatelessWidget {
  const _SearchFieldSuffix({
    required this.isSearching,
    required this.showClear,
    required this.onClear,
  });

  final bool isSearching;
  final bool showClear;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (!isSearching && !showClear) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSearching)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: SizedBox.square(
              dimension: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.brand,
              ),
            ),
          ),
        if (showClear)
          IconButton(
            tooltip: '清除搜索',
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
            iconSize: 19,
            color: colors.textTertiary,
          ),
      ],
    );
  }
}

class _SearchResultsOverlay extends StatelessWidget {
  const _SearchResultsOverlay({
    required this.query,
    required this.isSearching,
    required this.results,
    required this.searchError,
    required this.activeCodes,
    required this.onRetry,
    required this.onSelect,
  });

  final String query;
  final bool isSearching;
  final List<Stock> results;
  final String? searchError;
  final Set<String> activeCodes;
  final VoidCallback onRetry;
  final void Function(Stock stock, bool alreadyAdded) onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 360),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.overlay.withValues(alpha: 0.18),
              blurRadius: 36,
              spreadRadius: -12,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isSearching) {
      return const _SearchMessage(
        icon: Icons.search_rounded,
        title: '正在搜索',
        description: '正在从行情源查找匹配标的…',
        showProgress: true,
      );
    }

    if (searchError != null) {
      return _SearchMessage(
        icon: Icons.cloud_off_rounded,
        title: '搜索暂时不可用',
        description: searchError!,
        actionLabel: '重新搜索',
        onAction: onRetry,
      );
    }

    if (results.isEmpty) {
      return _SearchMessage(
        icon: Icons.manage_search_rounded,
        title: '没有找到匹配结果',
        description: '换个名称或代码试试，例如“腾讯”或“00700”。',
      );
    }

    final colors = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '搜索结果',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Text(
                '${results.length} 条',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colors.borderSubtle),
        Flexible(
          child: Scrollbar(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              shrinkWrap: true,
              itemCount: results.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
                color: colors.borderSubtle,
              ),
              itemBuilder: (context, index) {
                final stock = results[index];
                final alreadyAdded = activeCodes.contains(stock.code);
                return _SearchResultTile(
                  stock: stock,
                  alreadyAdded: alreadyAdded,
                  onPressed: () => onSelect(stock, alreadyAdded),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Text(
            '按 Esc 可关闭搜索',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.stock,
    required this.alreadyAdded,
    required this.onPressed,
  });

  final Stock stock;
  final bool alreadyAdded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      label: alreadyAdded ? '${stock.name}，已在当前分组' : '添加 ${stock.name} 到当前分组',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          hoverColor: colors.surfaceInteractive,
          focusColor: colors.brandSoft,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.brandSoft,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: SizedBox.square(
                    dimension: AppControlSizes.small,
                    child: Icon(
                      stock.type == StockType.crypto
                          ? Icons.currency_bitcoin_rounded
                          : Icons.show_chart_rounded,
                      color: colors.brand,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${stock.code} · ${marketDisplayName(stock)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textTertiary,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: alreadyAdded
                        ? colors.surfaceInteractive
                        : colors.brandSoft,
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          alreadyAdded
                              ? Icons.check_rounded
                              : Icons.add_rounded,
                          size: 16,
                          color:
                              alreadyAdded ? colors.textTertiary : colors.brand,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          alreadyAdded ? '已添加' : '添加',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: alreadyAdded
                                        ? colors.textTertiary
                                        : colors.brand,
                                    fontWeight: FontWeight.w800,
                                  ),
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
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.title,
    required this.description,
    this.showProgress = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool showProgress;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showProgress)
            SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: colors.brand,
              ),
            )
          else
            Icon(icon, size: 30, color: colors.textTertiary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  height: 1.45,
                ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
