import 'package:flutter/material.dart';

import '../../../../../core/i18n/l10n_extension.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/typography_manager.dart';

/// Underline tab bar used at the top of the ticket detail body.
///
/// Renders two tabs (Details / Activity) with a thin selected underline
/// matching the prototype. Owned by the parent `TabController`.
class TicketDetailTabs extends StatelessWidget
    implements PreferredSizeWidget {
  final TabController controller;
  const TicketDetailTabs({super.key, required this.controller});

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final s = context.l10n;
    return Material(
      color: c.bgBase,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.borderBase, width: 1)),
        ),
        child: TabBar(
          controller: controller,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          labelPadding: const EdgeInsets.symmetric(horizontal: 12),
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 2,
          indicatorColor: c.fgBase,
          labelColor: c.fgBase,
          unselectedLabelColor: c.fgMuted,
          labelStyle: TypographyManager.textLabel.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TypographyManager.textLabel,
          tabs: [
            Tab(text: s.ticketTabDetails, height: 42),
            Tab(text: s.ticketTabActivity, height: 42),
          ],
        ),
      ),
    );
  }
}
