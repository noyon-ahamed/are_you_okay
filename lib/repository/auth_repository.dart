import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/user_model.dart';
import '../services/api/auth_api_service.dart';
import '../services/auth/token_storage_service.dart';
import '../services/hive_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(hiveServiceProvider),
    AuthApiService(),
  );
});

class AuthRepository {
  final HiveService _hiveService;
  final AuthApiService _apiService;

  AuthRepository(this._hiveService, this._apiService);

  Future<UserModel> login(
      {required String email, required String password}) async {
    final response = await _apiService.login(email: email, password: password);
    final user = UserModel.fromJson(response['user']);
    await _hiveService.saveUser(user);
    await _syncSettingsFromUserPayload(response['user'] as Map<String, dynamic>?);
    return user;
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    final response = await _apiService.register(
      email: email,
      password: password,
      name: name,
      phone: phone,
    );
    final user = UserModel.fromJson(response['user']);
    await _hiveService.saveUser(user);
    await _syncSettingsFromUserPayload(response['user'] as Map<String, dynamic>?);
    return user;
  }

  Future<void> logout() async {
    await _apiService.logout();
    await _hiveService.deleteUser();
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      // Hive cache থেকে check করো — কোনো network call নেই
      final user = _hiveService.getCurrentUser();
      if (user != null) return user;

      // Hive এ নেই, token আছে কিনা check করো (local storage — fast)
      final hasToken = await TokenStorageService.isLoggedIn()
          .timeout(const Duration(seconds: 1), onTimeout: () => false);

      // Token থাকলে authenticated হিসেবে treat করো
      // Profile sync auth_provider এর _syncProfileQuietly() করবে background এ
      if (hasToken) return UserModel.empty();

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? profilePicture,
  }) async {
    final response = await _apiService.updateProfile(
      name: name,
      phone: phone,
      profilePicture: profilePicture,
    );
    final user = UserModel.fromJson(response);
    await _hiveService.saveUser(user);
    return user;
  }

  Future<void> forgotPassword(String email) async {
    await _apiService.forgotPassword(email);
  }

  Future<void> _syncSettingsFromUserPayload(Map<String, dynamic>? payload) async {
    final settings = payload?['settings'] as Map<String, dynamic>?;
    if (settings == null) return;

    final current = _hiveService.getSettings();
    await _hiveService.saveSettings(
      current.copyWith(
        notificationsEnabled: settings['notificationEnabled'] as bool? ??
            current.notificationsEnabled,
        language: settings['language']?.toString() ?? current.language,
        earthquakeCountry:
            settings['earthquakeCountry']?.toString() ?? current.earthquakeCountry,
      ),
    );
  }
}
