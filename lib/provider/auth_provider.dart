import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/user_model.dart';
import '../repository/auth_repository.dart';
import '../services/socket_service.dart';
import '../services/hive_service.dart';
import '../provider/language_provider.dart';
import '../services/api/auth_api_service.dart';

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

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final SocketService _socketService;
  final Ref _ref;
 
  AuthNotifier(this._authRepository, this._socketService, this._ref)
      : super(const AuthInitial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        state = AuthAuthenticated(user);
        _socketService.init();
        // empty user হলে background এ full profile fetch করো
        if (user.isEmpty) {
          _syncProfileQuietly();
        }
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
        await _syncLocalSettings(userMap);
        if (mounted && state is AuthAuthenticated) {
          state = AuthAuthenticated(updatedUser);
        }
      }
    } catch (e) {
      debugPrint('Failed to background sync profile: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 401 && state is AuthAuthenticated) {
          debugPrint('Detected invalid session via background sync. Logging out.');
          logout();
        }
      }
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final user =
          await _authRepository.login(email: email, password: password);
      state = AuthAuthenticated(user);
      _socketService.init();
      // Small delay so the token is fully persisted before background sync
      Future.delayed(const Duration(milliseconds: 500), _syncProfileQuietly);
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
      _socketService.init();
      Future.delayed(const Duration(milliseconds: 500), _syncProfileQuietly);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    try {
      await _authRepository.logout();
      _socketService.disconnect();
      // Ensure language resets to English for the next user/session
      await _ref.read(languageProvider.notifier).setLanguage('en');
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

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

      final userMap = result['user'] as Map<String, dynamic>?;
      if (userMap != null) {
        final updatedUser = UserModel.fromJson(userMap);
        final hive = HiveService();
        await hive.saveUser(updatedUser);
        await _syncLocalSettings(userMap);
        if (mounted && state is AuthAuthenticated) {
          state = AuthAuthenticated(updatedUser);
        }
      } else {
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
          final hive = HiveService();
          await hive.saveUser(updatedUser);
          state = AuthAuthenticated(updatedUser);
        }
      }
    } catch (e) {
      debugPrint('Failed to update profile: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    state = const AuthLoading();
    try {
      final api = AuthApiService();
      await api.deleteAccount();
      await _authRepository.logout(); // Reuse logout to clear tokens/Hive
      _socketService.disconnect();
      // Ensure language resets to English for the next session
      await _ref.read(languageProvider.notifier).setLanguage('en');
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthError(e.toString());
      rethrow;
    }
  }

  Future<void> refreshProfile() async {
    try {
      final api = AuthApiService();
      final profileData = await api.getProfile();
      final userData = profileData['user'] as Map<String, dynamic>?;
      if (userData != null) {
        final user = UserModel.fromJson(userData);
        final hive = HiveService();
        await hive.saveUser(user);
        await _syncLocalSettings(userData);
        state = AuthAuthenticated(user);
      }
    } catch (e) {
      debugPrint('Failed to refresh profile: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          debugPrint('Detected invalid session via profile refresh. Logging out.');
          logout();
        }
      }
    }
  }

  Future<void> _syncLocalSettings(Map<String, dynamic> userData) async {
    final remoteSettings = userData['settings'] as Map<String, dynamic>?;
    if (remoteSettings == null) return;

    final hive = HiveService();
    final current = hive.getSettings();
    await hive.saveSettings(
      current.copyWith(
        notificationsEnabled: remoteSettings['notificationEnabled'] as bool? ??
            current.notificationsEnabled,
        smsAlerts: remoteSettings['smsAlerts'] as bool? ?? current.smsAlerts,
        wellnessReminders: remoteSettings['wellnessReminders'] as bool? ??
            current.wellnessReminders,
        emergencyAlerts: remoteSettings['emergencyAlerts'] as bool? ??
            current.emergencyAlerts,
        language: remoteSettings['language']?.toString() ?? current.language,
        earthquakeCountry: remoteSettings['earthquakeCountry']?.toString() ??
            current.earthquakeCountry,
      ),
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(socketServiceProvider),
    ref,
  );
});

final currentUserProvider = Provider<UserModel?>((ref) {
  final state = ref.watch(authProvider);
  if (state is AuthAuthenticated) {
    return state.user;
  }
  return null;
});
