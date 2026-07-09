import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/watchlist/application/watchlist_controller.dart';
import 'features/watchlist/presentation/watchlist_screen.dart';

class MoYuStockApp extends ConsumerWidget {
  const MoYuStockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(
      watchlistControllerProvider.select((state) => state.isDark),
    );

    return MaterialApp(
      title: 'MoYuStock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const WatchlistScreen(),
    );
  }
}
