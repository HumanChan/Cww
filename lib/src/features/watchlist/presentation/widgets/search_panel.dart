import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../application/watchlist_controller.dart';

class SearchPanel extends ConsumerStatefulWidget {
  const SearchPanel({super.key});

  @override
  ConsumerState<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends ConsumerState<SearchPanel> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(watchlistControllerProvider);
    if (_controller.text != state.searchQuery) {
      _controller.value = TextEditingValue(
        text: state.searchQuery,
        selection: TextSelection.collapsed(offset: state.searchQuery.length),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.control(),
          ),
          child: TextField(
            controller: _controller,
            onChanged:
                ref.read(watchlistControllerProvider.notifier).setSearchQuery,
            textInputAction: TextInputAction.search,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.text,
                  fontWeight: FontWeight.w600,
                ),
            decoration: InputDecoration(
              hintText: state.searchMode == SearchMode.stock
                  ? 'Search stocks...'
                  : 'Search crypto...',
              hintStyle: const TextStyle(
                color: AppPalette.slate400,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppPalette.slate200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppPalette.blue500),
              ),
              prefixIconConstraints: const BoxConstraints.tightFor(
                width: 42,
                height: 42,
              ),
              prefixIcon: IconButton(
                tooltip:
                    '切换到${state.searchMode == SearchMode.stock ? '币种' : '股票'}搜索',
                constraints: const BoxConstraints.tightFor(
                  width: 42,
                  height: 42,
                ),
                padding: EdgeInsets.zero,
                onPressed: ref
                    .read(watchlistControllerProvider.notifier)
                    .toggleSearchMode,
                icon: Icon(
                  state.searchMode == SearchMode.stock
                      ? Icons.search_rounded
                      : Icons.currency_bitcoin,
                  size: 19,
                  color: state.searchMode == SearchMode.stock
                      ? AppPalette.slate400
                      : Colors.orange,
                ),
              ),
              suffixIconConstraints: const BoxConstraints.tightFor(
                width: 42,
                height: 42,
              ),
              suffixIcon: state.isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: state.searchResults.isEmpty
              ? const SizedBox.shrink()
              : Container(
                  key: const ValueKey('search-results'),
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10),
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.55),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: state.searchResults.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: scheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                    itemBuilder: (context, index) {
                      final stock = state.searchResults[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          stock.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle:
                            Text('${stock.code} · ${marketDisplayName(stock)}'),
                        trailing: const Icon(Icons.add_circle_outline_rounded),
                        onTap: () => ref
                            .read(watchlistControllerProvider.notifier)
                            .addStock(stock),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
