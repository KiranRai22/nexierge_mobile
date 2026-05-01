import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/unified_theme_manager.dart';
import '../../../../../core/theme/typography_manager.dart';
import '../../../domain/entities/ticket_form_options.dart';
import '../../providers/ticket_form_options_provider.dart';

/// Bottom sheet for selecting a department. Returns the [HotelDepartment.id] or null.
class DepartmentPickerSheet {
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DepartmentSheetBody(),
    );
  }
}

class _DepartmentSheetBody extends ConsumerWidget {
  const _DepartmentSheetBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.themeColors;
    final asyncOptions = ref.watch(ticketFormOptionsProvider);

    return Container(
      decoration: BoxDecoration(
        color: c.bgBase,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.55,
          child: Column(
            children: [
              const _Handle(),
              const _Header(),
              Expanded(
                child: asyncOptions.when(
                  data: (options) => _DepartmentList(
                    departments: options.departments,
                    onPick: (id) => Navigator.of(context).pop(id),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                  error: (e, _) => _ErrorView(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(ticketFormOptionsProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartmentList extends StatelessWidget {
  final List<HotelDepartment> departments;
  final ValueChanged<String> onPick;
  const _DepartmentList({required this.departments, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    if (departments.isEmpty) {
      return Center(
        child: Text(
          context.l10n.emptyState,
          style: TypographyManager.bodyMedium.copyWith(color: c.fgSubtle),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: departments.length,
      itemBuilder: (_, i) {
        final d = departments[i];
        return _DepartmentCell(department: d, onTap: () => onPick(d.id));
      },
    );
  }
}

class _DepartmentCell extends StatelessWidget {
  final HotelDepartment department;
  final VoidCallback onTap;
  const _DepartmentCell({required this.department, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.bgBase,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.borderBase),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    department.name,
                    style: TypographyManager.bodyLarge.copyWith(
                      color: c.fgBase,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();
  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: c.borderBase,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.createDepartmentSheetTitle,
              style: TypographyManager.titleMedium.copyWith(
                color: c.fgBase,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            color: c.fgMuted,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.themeColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TypographyManager.bodySmall.copyWith(color: c.fgError),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}
