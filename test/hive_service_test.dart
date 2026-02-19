import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:are_you_okay/services/hive_service.dart';
import 'package:are_you_okay/model/user_model.dart';
import 'dart:io';

void main() {
  group('HiveService Persistence Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp();
      Hive.init(tempDir.path);
      
      // Initialize HiveService
      await HiveService().init();
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      await tempDir.delete(recursive: true);
    });

    test('saveUser and getCurrentUser works', () async {
      final user = UserModel(
        id: '123',
        email: 'test@example.com',
        name: 'Test User',
        role: 'user',
        emailVerified: true,
        createdAt: DateTime.now(),
      );

      await HiveService().saveUser(user);

      final loadedUser = HiveService().getCurrentUser();

      expect(loadedUser, isNotNull);
      expect(loadedUser?.id, equals(user.id));
      expect(loadedUser?.email, equals(user.email));
    });

    test('deleteUser removes user', () async {
      final user = UserModel(
        id: '123',
        email: 'test@example.com',
        name: 'Test User',
      );

      await HiveService().saveUser(user);
      await HiveService().deleteUser();

      final loadedUser = HiveService().getCurrentUser();

      expect(loadedUser, isNull);
    });
  });
}
