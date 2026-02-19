import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:are_you_okay/services/auth/token_storage_service.dart';
import 'package:are_you_okay/services/api/auth_api_service.dart';
import 'package:dio/dio.dart';

// Generate mocks if needed, but for simple services we can often just mock methods or use a wrapper.
// Since TokenStorageService uses static methods and a static FlutterSecureStorage, it is hard to mock directly without refactoring.
// However, FlutterSecureStorage has a setMockInitialValues method for testing!

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Persistence Tests', () {
    test('TokenStorageService stores and retrieves token', () async {
      // Setup mock storage
      FlutterSecureStorage.setMockInitialValues({});
      
      const token = 'test_token_123';
      
      // Save token
      await TokenStorageService.saveToken(token);
      
      // Retrieve token
      final retrievedToken = await TokenStorageService.getToken();
      
      expect(retrievedToken, equals(token));
    });

    test('isLoggedIn returns true when token exists', () async {
      FlutterSecureStorage.setMockInitialValues({'jwt_token': 'existing_token'});
      
      final isLoggedIn = await TokenStorageService.isLoggedIn();
      
      expect(isLoggedIn, isTrue);
    });

    test('isLoggedIn returns false when token does not exist', () async {
      FlutterSecureStorage.setMockInitialValues({});
      
      final isLoggedIn = await TokenStorageService.isLoggedIn();
      
      expect(isLoggedIn, isFalse);
    });

    test('deleteToken removes token', () async {
      FlutterSecureStorage.setMockInitialValues({'jwt_token': 'token_to_delete'});
      
      await TokenStorageService.deleteToken();
      
      final token = await TokenStorageService.getToken();
      expect(token, isNull);
    });
  });
}
