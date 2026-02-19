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

  Future<UserModel> login({required String email, required String password}) async {
    final response = await _apiService.login(email: email, password: password);
    final user = UserModel.fromJson(response['user']);
    await _hiveService.saveUser(user);
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
    return user;
  }

  Future<void> logout() async {
    await _apiService.logout();
    await _hiveService.deleteUser();
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      // First check in-memory
      var user = _hiveService.getCurrentUser();
      if (user != null) return user;

      // If not in memory but we have token, fetch from API
      final hasToken = await TokenStorageService.isLoggedIn()
          .timeout(const Duration(seconds: 2), onTimeout: () => false);

      if (hasToken) {
        final response = await _apiService.getProfile();
        user = UserModel.fromJson(response);
        await _hiveService.saveUser(user); // Cache it
        return user;
      }
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
}