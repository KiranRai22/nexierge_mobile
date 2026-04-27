import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

/// Sugar to keep call-sites short:
///
///   Text(context.l10n.kpiIncoming)
///
/// instead of:
///
///   Text(AppLocalizations.of(context).kpiIncoming)
///
/// Always use this in widget code — `AppLocalizations.of(context)` is fine
/// inside hot loops where you cache the lookup, but this extension reads
/// better at call-sites and signals intent.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
