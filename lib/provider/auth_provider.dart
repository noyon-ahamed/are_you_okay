import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/user_model.dart';
import '../repository/auth_repository.dart';
import '../services/api/auth_api_service.dart';
import '../services/socket_service.dart';
import '../services/hive_service.dart';

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
  final SocketService _socketService;

  AuthNotifier(this._authRepository, this._socketService) : super(const AuthInitial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = const AuthLoading();
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        state = AuthAuthenticated(user);
        _socketService.init(); // Connect socket
        _syncProfileQuietly();
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> _syncProfileQuietly() async {
    try {
      final authApi = AuthApiService();
      final response = await authApi.getProfile();
      final userMap = response['user'] as Map<String, dynamic>?;
      if (userMap != null) {
        final updatedUser = UserModel.fromJson(userMap);
        final hive = HiveService();
        await hive.saveUser(updatedUser);
        if (mounted && state is AuthAuthenticated) {
          state = AuthAuthenticated(updatedUser);
        }
      }
    } catch (e) {
      debugPrint('Failed to background sync profile: $e');
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final user = await _authRepository.login(email: email, password: password);
      state = AuthAuthenticated(user);
      _socketService.init(); // Connect socket
    } catch (e) {
      state = AuthError(e.toString());
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
      _socketService.init(); // Connect socket
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    try {
      await _authRepository.logout();
      _socketService.disconnect(); // Disconnect socket
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Update profile on backend and locally
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? profilePicture,
    String? address,
    String? bloodGroup,
  }) async {
    try {
      final api = AuthApiService();
      final result = await api.updateProfile(
        name: name,
        phone: phone,
        profilePicture: profilePicture,
        address: address,
        bloodGroup: bloodGroup,
      );

      // Update local user model
      final currentState = state;
      if (currentState is AuthAuthenticated) {
        final updatedUser = currentState.user.copyWith(
          name: name ?? currentState.user.name,
          phone: phone ?? currentState.user.phone,
          profilePicture: profilePicture ?? currentState.user.profilePicture,
          address: address ?? currentState.user.address,
          bloodGroup: bloodGroup ?? currentState.user.bloodGroup,
          updatedAt: DateTime.now(),
        );
        // Save to Hive
        final hive = HiveService();
        await hive.saveUser(updatedUser);
        state = AuthAuthenticated(updatedUser);
      }
    } catch (e) {
      debugPrint('Failed to update profile: $e');
      rethrow;
    }
  }

  /// Refresh profile from backend
  Future<void> refreshProfile() async {
    try {
      final api = AuthApiService();
      final profileData = await api.getProfile();
      final userData = profileData['user'] as Map<String, dynamic>?;
      if (userData != null) {
        final user = UserModel.fromJson(userData);
        final hive = HiveService();
        await hive.saveUser(user);
        state = AuthAuthenticated(user);
      }
    } catch (e) {
      debugPrint('Failed to refresh profile: $e');
    }
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(socketServiceProvider),
  );
});

// Current User Provider
final currentUserProvider = Provider<UserModel?>((ref) {
  final state = ref.watch(authProvider);
  if (state is AuthAuthenticated) {
    return state.user;
  }
  return null;
});