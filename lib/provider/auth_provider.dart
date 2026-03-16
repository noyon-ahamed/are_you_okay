import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/user_model.dart';
import '../repository/auth_repository.dart';
import '../services/socket_service.dart';
import '../services/hive_service.dart';
import '../provider/language_provider.dart';
import '../services/api/auth_api_service.dart';
import '../services/api/mood_api_service.dart';
import '../services/notification_service.dart';
import '../services/shared_prefs_service.dart';
import '../services/auth/token_storage_service.dart';
import '../provider/checkin_provider.dart';
import '../provider/contact_provider.dart';
import '../provider/mood_provider.dart';

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
      if (state is! AuthAuthenticated) return;

      final authApi = AuthApiService();
      final response = await authApi.getProfile();
      final userMap = response['user'] as Map<String, dynamic>?;
      if (!mounted) return;
      if (userMap != null) {
        final updatedUser = UserModel.fromJson(userMap);
        final hive = HiveService();
        await hive.saveUser(updatedUser);
        await _syncLocalSettings(userMap);
        Future.microtask(() {
          if (!mounted) return;
          if (state is AuthAuthenticated) {
            state = AuthAuthenticated(updatedUser);
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to background sync profile: $e');
      if (!mounted) return;
      if (e is DioException) {
        if (e.response?.statusCode == 401 && state is AuthAuthenticated) {
          debugPrint(
              'Detected invalid session via background sync. Logging out.');
          logout();
        }
      }
    }
  }

  Future<void> login({required String email, required String password}) async {
    debugPrint('AuthNotifier: Starting login for $email');
    state = const AuthLoading();
    try {
      debugPrint('AuthNotifier: Calling repository.login');
      final user =
          await _authRepository.login(email: email, password: password);
      debugPrint('AuthNotifier: Repository login success for ${user.email}');

      if (!mounted) return;
      state = AuthAuthenticated(user);
      _socketService.init();
      debugPrint(
          'AuthNotifier: State set to Authenticated, socket initialized');

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _syncProfileQuietly();
      });
    } catch (e) {
      debugPrint('AuthNotifier: Login error: $e');
      state = AuthError(e.toString());
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    debugPrint('AuthNotifier: Starting registration for $email');
    state = const AuthLoading();
    try {
      await _authRepository.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      debugPrint('AuthNotifier: Registration success');
      if (!mounted) return;
      state = const AuthUnauthenticated();
    } catch (e) {
      debugPrint('AuthNotifier: Registration error: $e');
      state = AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    debugPrint('AuthNotifier: logout started');

    // ✅ Step 1: সংযোগ বিচ্ছিন্ন ও token clear
    _socketService.disconnect();
    try {
      await TokenStorageService.clearAll();
      await SharedPrefsService().logout();
      await _authRepository.logout();
    } catch (e) {
      debugPrint('AuthNotifier: Error during early logout: $e');
    }

    // ✅ Step 2: সব persistent data clear — invalidate এর আগে অবশ্যই
    try {
      await HiveService().clearAllData();
      await MoodApiService().clearCache(); // mood SharedPrefs cache clear
      await SharedPrefsService().clearAccountData();
      await LocalNotificationService().cancelAllNotifications();
      await _ref.read(languageProvider.notifier).setLanguage('en');
      debugPrint('AuthNotifier: All data cleared');
    } catch (e) {
      debugPrint('AuthNotifier: Error during data cleanup: $e');
    }

    // ✅ Step 3: Unauthenticated set করো — router /login এ নিয়ে যাবে
    if (mounted) {
      state = const AuthUnauthenticated();
    }
    debugPrint('AuthNotifier: State set to Unauthenticated');

    // ✅ Step 4: data clear হওয়ার পর microtask এ invalidate
    // এতে নতুন provider bootstrap করলে empty cache পাবে
    Future.microtask(() {
      _ref.invalidate(checkinStatusProvider);
      _ref.invalidate(checkinHistoryFromBackendProvider);
      _ref.invalidate(moodHistoryProvider);
      _ref.invalidate(moodStatsProvider);
      _ref.invalidate(contactProvider);
      debugPrint('AuthNotifier: All providers invalidated');
    });
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
        Future.microtask(() {
          if (!mounted) return;
          if (state is AuthAuthenticated) {
            state = AuthAuthenticated(updatedUser);
          }
        });
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
          Future.microtask(() {
            if (!mounted) return;
            state = AuthAuthenticated(updatedUser);
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to update profile: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    debugPrint('AuthNotifier: deleteAccount started');
    state = const AuthLoading();
    try {
      await LocalNotificationService().cancelAllNotifications();

      final api = AuthApiService();
      await api.deleteAccount();

      final hive = HiveService();
      await hive.clearAllData();
      await hive.clearCheckInsAndMoodsOnly();
      await hive.clearContacts();

      await MoodApiService().clearCache();
      await SharedPrefsService().clearAccountData();

      await _authRepository.logout();
      _socketService.disconnect();
      await _ref.read(languageProvider.notifier).setLanguage('en');

      Future.microtask(() {
        _ref.invalidate(checkinStatusProvider);
        _ref.invalidate(checkinHistoryFromBackendProvider);
        _ref.invalidate(moodHistoryProvider);
        _ref.invalidate(moodStatsProvider);
        _ref.invalidate(contactProvider);
      });

      debugPrint('AuthNotifier: account deleted, data cleared');
      if (!mounted) return;
      state = const AuthUnauthenticated();
    } catch (e) {
      debugPrint('AuthNotifier: deleteAccount error: $e');
      if (!mounted) return;
      state = AuthError(e.toString());
      rethrow;
    }
  }

  Future<void> refreshProfile() async {
    try {
      if (state is! AuthAuthenticated) return;

      final api = AuthApiService();
      final profileData = await api.getProfile();

      if (!mounted || state is! AuthAuthenticated) return;

      final userData = profileData['user'] as Map<String, dynamic>?;
      if (userData != null) {
        final user = UserModel.fromJson(userData);
        final hive = HiveService();
        await hive.saveUser(user);
        _syncLocalSettings(userData);
        Future.microtask(() {
          if (!mounted) return;
          if (state is AuthAuthenticated) {
            state = AuthAuthenticated(user);
          }
        });
      }
    } catch (e) {
      debugPrint('AuthNotifier: Failed to refresh profile: $e');
      if (!mounted) return;
      if (e is DioException && e.response?.statusCode == 401) {
        if (state is AuthAuthenticated) {
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
