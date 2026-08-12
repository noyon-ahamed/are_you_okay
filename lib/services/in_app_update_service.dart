import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_constants.dart';
import '../core/localization/app_strings.dart';
import '../core/theme/app_colors.dart';
import 'api/config_api_service.dart';

class InAppUpdateService {
  InAppUpdateService._internal();
  static final InAppUpdateService _instance = InAppUpdateService._internal();
  factory InAppUpdateService() => _instance;

  static const String _keyLastUpdatedClickedVersion =
      'last_updated_clicked_version';

  final ConfigApiService _configApi = ConfigApiService();
  bool _isCheckingOrShowing = false;

  /// Compare two version strings (e.g. "2.0.0+7" vs "2.0.0+8" or "2.0.0" vs "2.0.1")
  int compareVersions(String v1, String v2) {
    try {
      final partsV1 = v1.split('+');
      final partsV2 = v2.split('+');

      final semV1 = partsV1.first.trim();
      final semV2 = partsV2.first.trim();

      final p1 = semV1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final p2 = semV2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLength = p1.length > p2.length ? p1.length : p2.length;
      for (int i = 0; i < maxLength; i++) {
        final num1 = i < p1.length ? p1[i] : 0;
        final num2 = i < p2.length ? p2[i] : 0;
        if (num1 != num2) {
          return num1.compareTo(num2);
        }
      }

      // If semantic versions are identical, compare build number (e.g. +7 vs +8)
      final code1 = partsV1.length > 1 ? (int.tryParse(partsV1[1].trim()) ?? 0) : 0;
      final code2 = partsV2.length > 1 ? (int.tryParse(partsV2[1].trim()) ?? 0) : 0;
      return code1.compareTo(code2);
    } catch (_) {
      return 0;
    }
  }

  /// Check version from backend config & Google Play InAppUpdate API
  Future<void> checkAndShowUpdateDialog(
    BuildContext context, {
    required AppStrings strings,
  }) async {
    if (_isCheckingOrShowing) return;
    _isCheckingOrShowing = true;

    try {
      // First try official Android Google Play InAppUpdate API if on Android
      if (Platform.isAndroid) {
        try {
          final playUpdateInfo = await InAppUpdate.checkForUpdate();
          if (playUpdateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
            if (playUpdateInfo.immediateUpdateAllowed) {
              await InAppUpdate.performImmediateUpdate();
              return;
            } else if (playUpdateInfo.flexibleUpdateAllowed) {
              await InAppUpdate.startFlexibleUpdate();
              await InAppUpdate.completeFlexibleUpdate();
              return;
            }
          }
        } catch (e) {
          debugPrint('Google Play InAppUpdate check failed: $e');
        }
      }

      // Check version from backend config endpoint
      final updateData = await _configApi.getUpdateConfig();
      if (updateData == null || !context.mounted) return;

      final isAndroid = Platform.isAndroid;
      final platformKey = isAndroid ? 'android' : 'ios';

      final minVersionObj = updateData['minAppVersion'];
      final latestVersionObj = updateData['latestAppVersion'];
      final updateInfo = updateData['updateInfo'] as Map<String, dynamic>?;

      final String minVersion = minVersionObj is Map
          ? (minVersionObj[platformKey]?.toString() ?? '1.0.0')
          : '1.0.0';
      final String latestVersion = latestVersionObj is Map
          ? (latestVersionObj[platformKey]?.toString() ?? AppConstants.appVersion)
          : AppConstants.appVersion;

      String currentVersion = AppConstants.appVersion;
      try {
        final info = await PackageInfo.fromPlatform();
        if (info.version.isNotEmpty) {
          currentVersion = info.buildNumber.isNotEmpty
              ? '${info.version}+${info.buildNumber}'
              : info.version;
        }
      } catch (_) {}

      final isBelowMin = compareVersions(currentVersion, minVersion) < 0;
      final isOutdated = compareVersions(currentVersion, latestVersion) < 0;

      if (!isOutdated && !isBelowMin) {
        return;
      }

      final bool isForceUpdate =
          isBelowMin || (updateInfo?['forceUpdate'] == true);

      // Check if user already clicked "Update Now" for this specific version
      final prefs = await SharedPreferences.getInstance();
      final lastClickedVersion =
          prefs.getString(_keyLastUpdatedClickedVersion);

      if (!isForceUpdate && lastClickedVersion == latestVersion) {
        return;
      }

      if (!context.mounted) return;

      await _showUpdateBottomSheet(
        context: context,
        strings: strings,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        updateInfo: updateInfo,
        isForceUpdate: isForceUpdate,
        isAndroid: isAndroid,
        prefs: prefs,
      );
    } catch (e) {
      debugPrint('Error checking in-app update: $e');
    } finally {
      _isCheckingOrShowing = false;
    }
  }

  /// Displays modern, high-end Bottom Sheet with Close (X) Icon & In-App Update flow
  Future<void> _showUpdateBottomSheet({
    required BuildContext context,
    required AppStrings strings,
    required String currentVersion,
    required String latestVersion,
    required Map<String, dynamic>? updateInfo,
    required bool isForceUpdate,
    required bool isAndroid,
    required SharedPreferences prefs,
  }) async {
    final lang = strings.isBangla ? 'bn' : 'en';

    final titleObj = updateInfo?['title'];
    final String sheetTitle = (titleObj is Map
            ? titleObj[lang]?.toString()
            : null) ??
        strings.updateTitle;

    final notesObj = updateInfo?['releaseNotes'];
    final String releaseNotes = (notesObj is Map
            ? notesObj[lang]?.toString()
            : null) ??
        (strings.isBangla
            ? '• নতুন ফিচার ও নিরাপত্তা উন্নয়ন\n• চেক-ইন ও অ্যালার্ট সার্ভিস ফাস্ট করা হয়েছে\n• বাগ ফিক্স এবং স্টেবিলিটি ইম্প্রুভমেন্ট'
            : '• New features & security enhancements\n• Faster check-in & alert service\n• Bug fixes and stability improvements');

    final storeUrlObj = updateInfo?['storeUrl'];
    final String defaultStoreUrl = isAndroid
        ? 'https://play.google.com/store/apps/details?id=com.areyouokay.app'
        : 'https://apps.apple.com';
    final String storeUrl = (storeUrlObj is Map
            ? storeUrlObj[isAndroid ? 'android' : 'ios']?.toString()
            : null) ??
        defaultStoreUrl;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: !isForceUpdate,
      enableDrag: !isForceUpdate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      builder: (context) {
        return PopScope(
          canPop: !isForceUpdate,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.borderDark
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header Row with Icon, Title, and Close (X) Button
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF6C63FF)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.system_update_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sheetTitle,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                          fontFamily: 'HindSiliguri',
                        ),
                      ),
                    ),
                    if (!isForceUpdate)
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        tooltip: 'Close',
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Force update warning if applicable
                if (isForceUpdate)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            strings.updateForceWarning,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.warning,
                              fontFamily: 'HindSiliguri',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // What's New Title
                Text(
                  strings.updateWhatsNew,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                    fontFamily: 'HindSiliguri',
                  ),
                ),
                const SizedBox(height: 8),

                // Release Notes Card
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 150),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      releaseNotes,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        fontFamily: 'HindSiliguri',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons (Update Now & Later)
                Row(
                  children: [
                    if (!isForceUpdate) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.divider,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            strings.updateLaterBtn,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                              fontFamily: 'HindSiliguri',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await prefs.setString(
                              _keyLastUpdatedClickedVersion, latestVersion);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }

                          // 1. Try official Play Store InAppUpdate API (Direct In-App Download)
                          if (Platform.isAndroid) {
                            try {
                              final playUpdateInfo =
                                  await InAppUpdate.checkForUpdate();
                              if (playUpdateInfo.updateAvailability ==
                                  UpdateAvailability.updateAvailable) {
                                if (playUpdateInfo.immediateUpdateAllowed) {
                                  await InAppUpdate.performImmediateUpdate();
                                  return;
                                } else if (playUpdateInfo.flexibleUpdateAllowed) {
                                  await InAppUpdate.startFlexibleUpdate();
                                  await InAppUpdate.completeFlexibleUpdate();
                                  return;
                                }
                              }
                            } catch (e) {
                              debugPrint('InAppUpdate API error: $e');
                            }
                          }

                          // 2. Fallback to Play Store URL if in-app API not available
                          try {
                            final uri = Uri.parse(storeUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          } catch (e) {
                            debugPrint('Could not launch store URL: $e');
                          }
                        },
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text(
                          strings.updateNowBtn,
                          style: const TextStyle(
                            fontFamily: 'HindSiliguri',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
