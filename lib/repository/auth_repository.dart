import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/user_model.dart';
import '../services/hive_service.dart';
import '../services/shared_prefs_service.dart';
import '../core/constants/app_constants.dart';

// Providers
final hiveServiceProvider = Provider<HiveService>((ref) => HiveService());
final sharedPrefsServiceProvider = Provider<SharedPrefsService>(
  (ref) => SharedPrefsService(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    hive: ref.watch(hiveServiceProvider),
    prefs: ref.watch(sharedPrefsServiceProvider),
  );
});

class AuthRepository {
  final HiveService hive;
  final SharedPrefsService prefs;

  AuthRepository({
    required this.hive,
    required this.prefs,
  });

  /// Send OTP to phone number
  Future<bool> sendOTP(String phoneNumber) async {
    try {
      // TODO: Implement Firebase Auth phone verification
      // For now, simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // In production:
      // await FirebaseAuth.instance.verifyPhoneNumber(
      //   phoneNumber: '+880$phoneNumber',
      //   ...
      // );
      
      return true;
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  /// Verify OTP and login/register
  Future<UserModel> verifyOTP({
    required String phoneNumber,
    required String otp,
    String? name,
    String? email,
  }) async {
    try {
      // TODO: Implement Firebase Auth OTP verification
      // For now, simulate verification
      await Future.delayed(const Duration(seconds: 2));

      // Create or get user
      final user = UserModel(
        uid: DateTime.now().millisecondsSinceEpoch.toString(),
        phoneNumber: phoneNumber,
        email: email,
        name: name ?? 'User',
        language: prefs.language,
        checkinInterval: AppConstants.defaultCheckinInterval,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save user locally
      await hive.saveUser(user);
      await prefs.setUserId(user.uid);

      return user;
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  /// Register new user
  Future<UserModel> register({
    required String phoneNumber,
    required String name,
    String? email,
  }) async {
    try {
      final user = UserModel(
        uid: DateTime.now().millisecondsSinceEpoch.toString(),
        phoneNumber: phoneNumber,
        email: email,
        name: name,
        language: prefs.language,
        checkinInterval: AppConstants.defaultCheckinInterval,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await hive.saveUser(user);
      await prefs.setUserId(user.uid);

      return user;
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  /// Get current user
  UserModel? getCurrentUser() {
    return hive.getCurrentUser();
  }

  /// Check if user is logged in
  bool get isLoggedIn {
    return prefs.isLoggedIn && hive.getCurrentUser() != null;
  }

  /// Logout
  Future<void> logout() async {
    await hive.deleteUser();
    await prefs.logout();
  }

  /// Update user profile
  Future<UserModel> updateProfile(UserModel user) async {
    try {
      final updatedUser = user.copyWith(updatedAt: DateTime.now());
      await hive.updateUser(updatedUser);
      
      // TODO: Sync with Firebase
      
      return updatedUser;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}

// Removed late import