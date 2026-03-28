import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/auth_provider.dart';
import '../../routes/app_router.dart';
import '../auth/token_storage_service.dart';
import '../shared_prefs_service.dart';

const Set<String> _sessionRevocationErrorCodes = {
  'ACCOUNT_BLOCKED',
  'ACCOUNT_DELETED',
  'SESSION_REVOKED',
};

bool shouldForceLogout(DioException error) {
  final statusCode = error.response?.statusCode;
  final payload = error.response?.data;
  final errorCode =
      payload is Map<String, dynamic> ? payload['errorCode']?.toString() : null;

  return statusCode == 401 ||
      (statusCode == 403 &&
          errorCode != null &&
          _sessionRevocationErrorCodes.contains(errorCode));
}

Future<void> forceLogoutFromApi() async {
  final context = rootNavigatorKey.currentContext;
  if (context != null) {
    final container = ProviderScope.containerOf(context);
    await container.read(authProvider.notifier).logout();
    return;
  }

  await SharedPrefsService().logout();
  await TokenStorageService.clearAll();
}
