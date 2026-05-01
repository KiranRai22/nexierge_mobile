import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tickets/presentation/screens/create_screen.dart';
import '../widgets/create_new_sheet.dart';

/// FAB → CreateNewSheet (bottom sheet) → CreateScreen (tab pre-selected).
abstract class CreateRouter {
  static Future<void> openCreate(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final choice = await CreateNewSheet.show(context);
    if (choice == null || !context.mounted) return;

    final tab = switch (choice) {
      CreateChoice.universal => CreateTab.universal,
      CreateChoice.catalog => CreateTab.catalog,
      CreateChoice.manual => CreateTab.manual,
    };

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateScreen(initialTab: tab),
      ),
    );
  }
}
