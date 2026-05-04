import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexierge/main.dart';

void main() {
  testWidgets('App smoke test — renders without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    // One extra pump lets the first batch of async providers resolve.
    // We deliberately avoid pumpAndSettle: MyApp keeps a socket lifecycle
    // listener alive (xanoSocketLifecycleProvider), so animations/timers
    // never quiesce — pumpAndSettle would time out forever.
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
