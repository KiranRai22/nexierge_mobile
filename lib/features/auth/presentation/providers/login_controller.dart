import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/login_credentials.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_session_controller.dart';

// Re-export so callers (incl. existing widgets) can keep importing the
// controller and still see the [LoginMode] enum from the domain layer.
export '../../domain/entities/login_credentials.dart' show LoginMode;

/// UI state for the login screen. Mode-specific input is held in widget
/// `TextEditingController`s so the user's typing isn't reset on every
/// rebuild — the controller only owns the parts that actually drive UI
/// (chosen mode, password visibility, submission status).
class LoginUiState {
  final LoginMode mode;
  final bool obscurePassword;

  /// Result of the last submit. Stays put until the user types again.
  /// `AsyncData<AuthSession>` on success, `AsyncError` on failure,
  /// `AsyncLoading` while in flight, `AsyncData<null>` when idle.
  final AsyncValue<AuthSession?> submission;

  const LoginUiState({
    this.mode = LoginMode.email,
    this.obscurePassword = true,
    this.submission = const AsyncData<AuthSession?>(null),
  });

  LoginUiState copyWith({
    LoginMode? mode,
    bool? obscurePassword,
    AsyncValue<AuthSession?>? submission,
  }) {
    return LoginUiState(
      mode: mode ?? this.mode,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      submission: submission ?? this.submission,
    );
  }

  bool get isSubmitting => submission.isLoading;
}

/// Login screen controller. Riverpod's `AsyncNotifier` is the right shape
/// (per `riverpod-guidelines`) because every submission is an async
/// network call whose state the UI must reflect.
class LoginController extends AutoDisposeNotifier<LoginUiState> {
  late AuthRepository _repo;

  @override
  LoginUiState build() {
    _repo = ref.read(authRepositoryProvider);
    return const LoginUiState();
  }

  // ---------------------------------------------------------------------------
  // UI state
  // ---------------------------------------------------------------------------

  void selectMode(LoginMode mode) {
    if (state.mode == mode) return;
    // Spec §4.1 / §15.1: switching tabs must clear mode-specific
    // validation/API errors but must NOT submit. `submission` is the
    // last-error vehicle here, so reset it to idle on toggle.
    state = state.copyWith(
      mode: mode,
      submission: const AsyncData<AuthSession?>(null),
    );
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  /// Called from `onChanged` — if the user starts typing again after a
  /// failed submit, hide the inline error / toast.
  void clearLastError() {
    if (state.submission is AsyncError) {
      state = state.copyWith(submission: const AsyncData<AuthSession?>(null));
    }
  }

  // ---------------------------------------------------------------------------
  // Submission
  // ---------------------------------------------------------------------------

  Future<AuthSession?> submit(LoginCredentials credentials) async {
    if (state.isSubmitting) return null; // §8: no double submit

    state = state.copyWith(submission: const AsyncLoading());
    try {
      final session = await _repo.signIn(credentials);
      state = state.copyWith(submission: AsyncData(session));
      // Publishing the session flips the global auth provider, which the
      // root widget watches to swap LoginScreen → HomeShell. No imperative
      // navigation here — that previously raced with widget disposal.
      await ref
          .read(authSessionControllerProvider.notifier)
          .setSession(session);
      return session;
    } on AuthException catch (e, st) {
      state = state.copyWith(submission: AsyncError(e, st));
      return null;
    } catch (e, st) {
      // Transport-level (`AppException`) and any other unexpected errors.
      state = state.copyWith(submission: AsyncError(e, st));
      return null;
    }
  }
}

final loginControllerProvider =
    AutoDisposeNotifierProvider<LoginController, LoginUiState>(
  LoginController.new,
);
