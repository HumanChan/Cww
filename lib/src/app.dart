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
      builder: (context, child) => _ResponsiveAppFrame(
        child: child ?? const SizedBox.shrink(),
      ),
      home: const WatchlistScreen(),
    );
  }
}

class _ResponsiveAppFrame extends StatelessWidget {
  const _ResponsiveAppFrame({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) return child;

        return Scaffold(
          backgroundColor: const Color(0xFF020617),
          body: Center(
            child: Container(
              width: 408,
              height: constraints.maxHeight.clamp(720, 860).toDouble(),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(48),
                border: Border.all(color: const Color(0xFF1E293B), width: 8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 42,
                    offset: Offset(0, 24),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    height: 24,
                    alignment: Alignment.bottomCenter,
                    color: const Color(0xFF1E293B),
                    child: Container(
                      width: 96,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F172A),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
