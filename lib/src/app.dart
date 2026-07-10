import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_tokens.dart';
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
          backgroundColor: AppPalette.shell,
          body: Stack(
            children: [
              const _AmbientWash(
                top: -200,
                left: -100,
                color: AppPalette.blue600,
              ),
              const _AmbientWash(
                right: -100,
                bottom: -200,
                color: AppPalette.cyan600,
              ),
              Center(
                child: Container(
                  width: 400,
                  height: constraints.maxHeight.clamp(720, 850).toDouble(),
                  decoration: BoxDecoration(
                    color: AppPalette.phoneFrame,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: AppPalette.phoneFrame, width: 8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 50,
                        spreadRadius: -12,
                        offset: Offset(0, 25),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(
                        height: 24,
                        alignment: Alignment.bottomCenter,
                        color: AppPalette.phoneFrame,
                        child: Container(
                          width: 96,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppPalette.phoneNotch,
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
            ],
          ),
        );
      },
    );
  }
}

class _AmbientWash extends StatelessWidget {
  const _AmbientWash({
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.color,
  });

  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 120, sigmaY: 120),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.20),
          ),
          child: const SizedBox.square(dimension: 500),
        ),
      ),
    );
  }
}
