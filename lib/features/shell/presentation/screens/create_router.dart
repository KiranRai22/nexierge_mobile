import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tickets/presentation/screens/catalog_create_screen.dart';
import '../../../tickets/presentation/screens/manual_create_screen.dart';
import '../../../tickets/presentation/screens/universal_create_screen.dart';
import '../widgets/create_new_sheet.dart';

/// Routes the user from the FAB → Create-new sheet → the chosen create flow.
/// Kept here (in the shell) so feature screens don't need to know about
/// each other's routing.
abstract class CreateRouter {
  static Future<void> openCreate(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final choice = await CreateNewSheet.show(context);
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case CreateChoice.universal:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const UniversalCreateScreen(),
          ),
        );
      case CreateChoice.catalog:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const CatalogCreateScreen(),
          ),
        );
      case CreateChoice.manual:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ManualCreateScreen(),
          ),
        );
    }
  }
}
