import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/user_model.dart';
import '../repository/auth_repository.dart';

// Auth State
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AuthInitial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = const AuthLoading();
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final user = await _authRepository.login(email: email, password: password);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
      // Reset to unauthenticated after error so UI can show login form again if needed
      // Or keep error state depending on UI requirement. 
      // Usually better to keep error state so UI can show snackbar and then reset.
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _authRepository.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    try {
      await _authRepository.logout();
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

// Current User Provider
final currentUserProvider = Provider<UserModel?>((ref) {
  final state = ref.watch(authProvider);
  if (state is AuthAuthenticated) {
    return state.user;
  }
  return null;
});