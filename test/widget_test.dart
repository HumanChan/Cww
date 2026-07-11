import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cww_flutter/src/app.dart';

void main() {
  testWidgets('自选列表启动烟测', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MoYuStockApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('存为王'), findsOneWidget);
    expect(find.text('GD'), findsOneWidget);
  });

  testWidgets('分组管理面板包含清晰的操作分区', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MoYuStockApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('分组管理'), findsOneWidget);
    expect(find.text('新建分组'), findsOneWidget);
    expect(find.text('分组顺序'), findsOneWidget);
    expect(find.text('数据与备份'), findsOneWidget);
  });
}
