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
      themeAnimationDuration: AppDurations.emphasized,
      themeAnimationCurve: AppMotionCurves.standard,
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
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppBreakpoints.medium) {
          return ColoredBox(color: colors.canvas, child: child);
        }

        final isExpanded = constraints.maxWidth >= AppBreakpoints.expanded;
        final isShort = constraints.maxHeight < 720;
        final horizontalInset = isExpanded ? AppSpacing.xxl : 0.0;
        final verticalInset = isShort ? AppSpacing.xs : AppSpacing.xl;

        return ColoredBox(
          color: colors.canvasMuted,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [
                            Color(0xFF020617),
                            Color(0xFF0A1020),
                            Color(0xFF07141B),
                          ]
                        : const [
                            Color(0xFFEAF1FF),
                            Color(0xFFF4F7FC),
                            Color(0xFFEAF8F8),
                          ],
                  ),
                ),
              ),
              _AmbientWash(
                center: const Alignment(-0.92, -0.88),
                color: colors.brand,
                opacity: isDark ? 0.18 : 0.13,
              ),
              _AmbientWash(
                center: const Alignment(0.94, 0.90),
                color: colors.info,
                opacity: isDark ? 0.13 : 0.10,
              ),
              SafeArea(
                minimum: EdgeInsets.symmetric(
                  horizontal: horizontalInset,
                  vertical: verticalInset,
                ),
                child: LayoutBuilder(
                  builder: (context, frameConstraints) {
                    final radius = frameConstraints.maxHeight < 480
                        ? AppRadii.md
                        : AppRadii.xxl;
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppBreakpoints.maxContentWidth,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: frameConstraints.maxHeight,
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: colors.canvas,
                              borderRadius: BorderRadius.circular(radius),
                              border: Border.all(color: colors.borderSubtle),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.34 : 0.13,
                                  ),
                                  blurRadius: 40,
                                  spreadRadius: -10,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
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
    required this.center,
    required this.color,
    required this.opacity,
  });

  final Alignment center;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: center,
              radius: 1.05,
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0),
              ],
              stops: const [0, 0.72],
            ),
          ),
        ),
      ),
    );
  }
}
