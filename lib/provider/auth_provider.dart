import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../model/user_model.dart';
import '../repository/auth_repository.dart';

part 'auth_provider.freezed.dart';

// Auth State
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(UserModel user) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(String message) = _Error;
}

// Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AuthState.initial()) {
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    final user = _authRepository.getCurrentUser();
    if (user != null && _authRepository.isLoggedIn) {
      state = AuthState.authenticated(user);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> sendOTP(String phoneNumber) async {
    try {
      state = const AuthState.loading();
      await _authRepository.sendOTP(phoneNumber);
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> verifyOTP({
    required String phoneNumber,
    required String otp,
    String? name,
    String? email,
  }) async {
    try {
      state = const AuthState.loading();
      final user = await _authRepository.verifyOTP(
        phoneNumber: phoneNumber,
        otp: otp,
        name: name,
        email: email,
      );
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> register({
    required String phoneNumber,
    required String name,
    String? email,
  }) async {
    try {
      state = const AuthState.loading();
      final user = await _authRepository.register(
        phoneNumber: phoneNumber,
        name: name,
        email: email,
      );
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      state = const AuthState.loading();
      await _authRepository.logout();
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> updateProfile(UserModel user) async {
    try {
      final updated = await _authRepository.updateProfile(user);
      state = AuthState.authenticated(updated);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  UserModel? get currentUser {
    return state.maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );
  }

  bool get isAuthenticated {
    return state is _Authenticated;
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

// Convenience provider for current user
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider.notifier).currentUser;
});