import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../market/data/market_repository.dart';
import '../../market/domain/stock.dart';
import '../../market/domain/stock_group.dart';

final watchlistControllerProvider =
    StateNotifierProvider<WatchlistController, WatchlistState>((ref) {
  final controller = WatchlistController(ref.watch(marketRepositoryProvider));
  controller.load();
  return controller;
});

enum SearchMode {
  stock,
  crypto,
}

extension SearchModeStockType on SearchMode {
  StockType get stockType {
    return switch (this) {
      SearchMode.stock => StockType.stock,
      SearchMode.crypto => StockType.crypto,
    };
  }

  String get label {
    return switch (this) {
      SearchMode.stock => '股票',
      SearchMode.crypto => '币种',
    };
  }
}

class WatchlistState {
  const WatchlistState({
    this.groups = const [],
    this.activeGroupId = 'default',
    this.isLoaded = false,
    this.isDark = false,
    this.isRefreshing = false,
    this.isSearching = false,
    this.searchMode = SearchMode.stock,
    this.searchQuery = '',
    this.searchResults = const [],
    this.searchError,
    this.error,
    this.lastUpdated,
    this.flashingCodes = const {},
  });

  final List<StockGroup> groups;
  final String activeGroupId;
  final bool isLoaded;
  final bool isDark;
  final bool isRefreshing;
  final bool isSearching;
  final SearchMode searchMode;
  final String searchQuery;
  final List<Stock> searchResults;
  final String? searchError;
  final String? error;
  final DateTime? lastUpdated;
  final Set<String> flashingCodes;

  StockGroup? get activeGroup {
    if (groups.isEmpty) return null;
    final index = groups.indexWhere((group) => group.id == activeGroupId);
    return index >= 0 ? groups[index] : groups.first;
  }

  WatchlistState copyWith({
    List<StockGroup>? groups,
    String? activeGroupId,
    bool? isLoaded,
    bool? isDark,
    bool? isRefreshing,
    bool? isSearching,
    SearchMode? searchMode,
    String? searchQuery,
    List<Stock>? searchResults,
    Object? searchError = _notSet,
    Object? error = _notSet,
    DateTime? lastUpdated,
    Set<String>? flashingCodes,
  }) {
    return WatchlistState(
      groups: groups ?? this.groups,
      activeGroupId: activeGroupId ?? this.activeGroupId,
      isLoaded: isLoaded ?? this.isLoaded,
      isDark: isDark ?? this.isDark,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSearching: isSearching ?? this.isSearching,
      searchMode: searchMode ?? this.searchMode,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      searchError:
          searchError == _notSet ? this.searchError : searchError as String?,
      error: error == _notSet ? this.error : error as String?,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      flashingCodes: flashingCodes ?? this.flashingCodes,
    );
  }
}

const _notSet = Object();

class WatchlistController extends StateNotifier<WatchlistState> {
  WatchlistController(this._repository) : super(const WatchlistState());

  final MarketRepository _repository;
  Timer? _pollTimer;
  Timer? _searchDebounce;
  Timer? _renamePersistDebounce;
  int _refreshGeneration = 0;
  bool _pollingEnabled = true;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _pollTimer?.cancel();
    _searchDebounce?.cancel();
    _renamePersistDebounce?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    final groups = await _repository.loadGroups();
    final activeGroupId = await _repository.loadActiveGroupId();
    final isDark = await _repository.loadIsDark();
    if (_isDisposed) return;

    final resolvedActiveId = groups.any((group) => group.id == activeGroupId)
        ? activeGroupId!
        : groups.first.id;
    state = state.copyWith(
      groups: groups,
      activeGroupId: resolvedActiveId,
      isDark: isDark,
      isLoaded: true,
    );
    _scheduleNextPoll(immediate: true);
  }

  void setPollingEnabled(bool enabled) {
    _pollingEnabled = enabled;
    if (!enabled) {
      _pollTimer?.cancel();
      return;
    }
    _scheduleNextPoll(immediate: true);
  }

  Future<void> refreshNow() async => _refreshQuotes();

  void toggleTheme() {
    final next = !state.isDark;
    state = state.copyWith(isDark: next);
    unawaited(_repository.saveIsDark(next));
  }

  void setActiveGroup(String groupId) {
    if (groupId == state.activeGroupId) return;
    _refreshGeneration += 1;
    state = state.copyWith(
      activeGroupId: groupId,
      isRefreshing: false,
      error: null,
    );
    unawaited(_repository.saveActiveGroupId(groupId));
    _scheduleNextPoll(immediate: true);
  }

  void addGroup(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final group = StockGroup(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmed,
      stocks: const [],
    );
    final groups = [...state.groups, group];
    state = state.copyWith(groups: groups, activeGroupId: group.id);
    _persistGroups();
    unawaited(_repository.saveActiveGroupId(group.id));
  }

  void renameGroup(String groupId, String name) {
    final groups = state.groups.map((group) {
      return group.id == groupId ? group.copyWith(name: name) : group;
    }).toList();
    state = state.copyWith(groups: groups);
    _renamePersistDebounce?.cancel();
    _renamePersistDebounce = Timer(
      const Duration(milliseconds: 380),
      _persistGroups,
    );
  }

  void deleteGroup(String groupId) {
    if (state.groups.length <= 1) return;
    if (groupId == state.activeGroupId) {
      _refreshGeneration += 1;
    }
    final groups = state.groups.where((group) => group.id != groupId).toList();
    final activeId =
        state.activeGroupId == groupId ? groups.first.id : state.activeGroupId;
    state = state.copyWith(
      groups: groups,
      activeGroupId: activeId,
      isRefreshing: false,
    );
    _persistGroups();
    unawaited(_repository.saveActiveGroupId(activeId));
  }

  void reorderGroups(int oldIndex, int newIndex) {
    final groups = [...state.groups];
    final moved = groups.removeAt(oldIndex);
    groups.insert(newIndex, moved);
    state = state.copyWith(groups: groups);
    _persistGroups();
  }

  void addStock(Stock stock) {
    final active = state.activeGroup;
    if (active == null ||
        active.stocks.any((item) => item.code == stock.code)) {
      return;
    }
    _replaceActiveStocks([...active.stocks, stock]);
    setSearchQuery('');
  }

  void removeStock(String code) {
    final active = state.activeGroup;
    if (active == null) return;
    _replaceActiveStocks(
      active.stocks.where((stock) => stock.code != code).toList(),
    );
  }

  void reorderStocks(int oldIndex, int newIndex) {
    final active = state.activeGroup;
    if (active == null) return;
    final stocks = [...active.stocks];
    final moved = stocks.removeAt(oldIndex);
    stocks.insert(newIndex, moved);
    _replaceActiveStocks(stocks);
  }

  void toggleSearchMode() {
    final next = state.searchMode == SearchMode.stock
        ? SearchMode.crypto
        : SearchMode.stock;
    _searchDebounce?.cancel();
    state = state.copyWith(
      searchMode: next,
      searchQuery: '',
      searchResults: const [],
      isSearching: false,
      searchError: null,
    );
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, searchError: null);
    _searchDebounce?.cancel();

    if (query.trim().isEmpty) {
      state = state.copyWith(searchResults: const [], isSearching: false);
      return;
    }

    state = state.copyWith(isSearching: true);
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_runSearch(query));
    });
  }

  Future<void> exportGroups() async {
    await _repository.exportGroups(state.groups);
  }

  Future<void> importGroupsFromJson(String jsonText) async {
    final imported = await _repository.parseImportedGroups(jsonText);
    final groups = [...state.groups];
    for (final group in imported) {
      final index = groups.indexWhere((existing) => existing.id == group.id);
      if (index < 0) {
        groups.add(group);
        continue;
      }
      final existing = groups[index];
      final seen = existing.stocks.map((stock) => stock.secid).toSet();
      groups[index] = existing.copyWith(
        stocks: [
          ...existing.stocks,
          ...group.stocks.where((stock) => seen.add(stock.secid)),
        ],
      );
    }
    state = state.copyWith(groups: groups);
    _persistGroups();
  }

  Future<void> _runSearch(String query) async {
    try {
      final results =
          await _repository.search(query, state.searchMode.stockType);
      if (_isDisposed || query != state.searchQuery) return;
      state = state.copyWith(
        searchResults: results,
        isSearching: false,
        searchError: null,
      );
    } catch (_) {
      if (_isDisposed || query != state.searchQuery) return;
      state = state.copyWith(
        searchResults: const [],
        isSearching: false,
        searchError: '搜索失败，请稍后重试。',
      );
    }
  }

  Future<void> _refreshQuotes() async {
    if (!state.isLoaded || state.isRefreshing || !_pollingEnabled) return;
    final active = state.activeGroup;
    if (active == null || active.stocks.isEmpty) {
      _scheduleNextPoll();
      return;
    }

    final requestGeneration = ++_refreshGeneration;
    final groupId = active.id;
    state = state.copyWith(isRefreshing: true, error: null);
    try {
      final quotes = await _repository.fetchQuotes(active.stocks);
      if (_isDisposed || requestGeneration != _refreshGeneration) return;
      if (quotes.isEmpty) {
        throw StateError('行情源未返回有效数据。');
      }

      final groupIndex =
          state.groups.indexWhere((group) => group.id == groupId);
      if (groupIndex < 0) return;
      final currentGroup = state.groups[groupIndex];
      final quoteByCode = {for (final quote in quotes) quote.code: quote};
      final flashCodes = <String>{};
      final updatedStocks = currentGroup.stocks.map((stock) {
        final quote = quoteByCode[stock.code];
        if (quote == null) return stock;
        if (quote.price != null && quote.price != stock.price) {
          flashCodes.add(stock.code);
        }
        return stock.mergeQuote(quote);
      }).toList();
      _replaceGroupStocks(groupId, updatedStocks, persist: false);
      state = state.copyWith(
        isRefreshing: false,
        lastUpdated: DateTime.now(),
        flashingCodes: flashCodes,
        error: null,
      );
      if (flashCodes.isNotEmpty) {
        Timer(const Duration(milliseconds: 520), () {
          if (!_isDisposed) state = state.copyWith(flashingCodes: const {});
        });
      }
    } catch (_) {
      if (!_isDisposed && requestGeneration == _refreshGeneration) {
        state = state.copyWith(isRefreshing: false, error: '行情刷新失败，已保留本地数据。');
      }
    } finally {
      if (requestGeneration == _refreshGeneration) {
        _scheduleNextPoll();
      }
    }
  }

  void _scheduleNextPoll({bool immediate = false}) {
    _pollTimer?.cancel();
    if (!_pollingEnabled || _isDisposed) return;
    _pollTimer =
        Timer(immediate ? Duration.zero : const Duration(seconds: 1), () {
      unawaited(_refreshQuotes());
    });
  }

  void _replaceActiveStocks(List<Stock> stocks, {bool persist = true}) {
    _replaceGroupStocks(state.activeGroupId, stocks, persist: persist);
  }

  void _replaceGroupStocks(
    String groupId,
    List<Stock> stocks, {
    bool persist = true,
  }) {
    final index = state.groups.indexWhere((group) => group.id == groupId);
    if (index < 0) return;
    final groups = [...state.groups];
    groups[index] = groups[index].copyWith(stocks: stocks);
    state = state.copyWith(groups: groups);
    if (persist) _persistGroups();
  }

  void _persistGroups() {
    unawaited(_repository.saveGroups(state.groups));
  }
}
