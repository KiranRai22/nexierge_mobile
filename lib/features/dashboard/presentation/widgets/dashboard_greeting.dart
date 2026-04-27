import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/typography_manager.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../tickets/domain/models/department.dart';

/// Time-of-day-aware greeting block: bold line + meta line with date,
/// time and (optionally) the operator's home department.
class DashboardGreeting extends StatelessWidget {
  final String firstName;
  final Department? deptHint;
  final DateTime now;

  const DashboardGreeting({
    super.key,
    required this.firstName,
    required this.now,
    this.deptHint,
  });

  String _greeting(AppLocalizations s) {
    final h = now.hour;
    if (h < 12) return s.dashboardGreetingMorning(firstName);
    if (h < 18) return s.dashboardGreetingAfternoon(firstName);
    return s.dashboardGreetingEvening(firstName);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = context.appColors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.EEEE(locale).format(now);
    final time = DateFormat.jm(locale).format(now);
    final meta = deptHint == null
        ? '$date · $time'
        : '$date · $time · ${deptHint!.label(s)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting(s),
          style: TypographyManager.headlineSmall.copyWith(
            color: c.fgBase,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          meta,
          style: TypographyManager.bodyMedium.copyWith(color: c.fgSubtle),
        ),
      ],
    );
  }
}
