import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../main.dart' show appNavigatorKey;
import '../services/connectivity_service.dart';

/// Listens to [connectivityStatusProvider] and shows/dismisses the offline
/// dialog automatically. Mount this once, high in the tree.
class ConnectivityGate extends ConsumerStatefulWidget {
  const ConnectivityGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends ConsumerState<ConnectivityGate> {
  bool _dialogOpen = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<ConnectivityStatus>>(connectivityStatusProvider,
        (_, next) {
      final status = next.valueOrNull;
      if (status == null) return;
      if (status == ConnectivityStatus.offline && !_dialogOpen) {
        _dialogOpen = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _showDialog());
      } else if (status == ConnectivityStatus.online && _dialogOpen) {
        _dialogOpen = false;
        final nav = appNavigatorKey.currentState;
        if (nav != null && nav.canPop()) nav.pop();
      }
    });
    return widget.child;
  }

  Future<void> _showDialog() async {
    final navContext = appNavigatorKey.currentContext;
    if (navContext == null) {
      _dialogOpen = false;
      return;
    }
    await showDialog<void>(
      context: navContext,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const _NoInternetDialog(),
    );
    _dialogOpen = false;
  }
}

class _NoInternetDialog extends StatelessWidget {
  const _NoInternetDialog();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.wifiOff,
                size: 56,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                l.noInternetTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.noInternetBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
