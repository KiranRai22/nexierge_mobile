import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tickets/presentation/screens/create_screen.dart';
import '../widgets/create_new_sheet.dart';

/// FAB → CreateNewSheet (bottom sheet) → CreateScreen (tab pre-selected).
///
/// Returns `true` when the user actually created a ticket (so the caller can
/// switch to the Tickets tab and refresh). Returns `false` if cancelled.
abstract class CreateRouter {
  static Future<bool> openCreate(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final choice = await CreateNewSheet.show(context);
    if (choice == null || !context.mounted) return false;

    final tab = switch (choice) {
      CreateChoice.universal => CreateTab.universal,
      CreateChoice.catalog => CreateTab.catalog,
      CreateChoice.manual => CreateTab.manual,
    };

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CreateScreen(initialTab: tab),
      ),
    );
    return result == true;
  }
}
