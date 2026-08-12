import 'dart:io';
import 'package:flutter/material.dart';
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

  /// Compare two semantic version strings (e.g. "1.0.0" vs "1.0.1")
  /// Returns:
  /// - negative if v1 < v2
  /// - 0 if v1 == v2
  /// - positive if v1 > v2
  int compareVersions(String v1, String v2) {
    try {
      final cleanV1 = v1.split('+').first.trim();
      final cleanV2 = v2.split('+').first.trim();

      final parts1 = cleanV1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final parts2 = cleanV2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLength = parts1.length > parts2.length ? parts1.length : parts2.length;
      for (int i = 0; i < maxLength; i++) {
        final num1 = i < parts1.length ? parts1[i] : 0;
        final num2 = i < parts2.length ? parts2[i] : 0;
        if (num1 != num2) {
          return num1.compareTo(num2);
        }
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Check version from backend config and display in-app update dialog if needed
  Future<void> checkAndShowUpdateDialog(
    BuildContext context, {
    required AppStrings strings,
  }) async {
    if (_isCheckingOrShowing) return;
    _isCheckingOrShowing = true;

    try {
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

      const String currentVersion = AppConstants.appVersion;

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
        // User already clicked Update Now for this version; skip until a newer version comes
        return;
      }

      if (!context.mounted) return;

      await _showUpdateDialog(
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

  Future<void> _showUpdateDialog({
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

    // Parse custom release notes/title or use default localized strings
    final titleObj = updateInfo?['title'];
    final String dialogTitle = (titleObj is Map
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

    return showDialog<void>(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (context) {
        return PopScope(
          canPop: !isForceUpdate,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon & Title Header
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF6C63FF)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.system_update_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dialogTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                              fontFamily: 'HindSiliguri',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'v$latestVersion',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${strings.updateCurrentVersion}: v$currentVersion',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Force update warning or What's New banner
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
                const SizedBox(height: 6),

                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SingleChildScrollView(
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

                // Action Buttons
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Store clicked version so we don't nag again for this version once updated
                          await prefs.setString(
                              _keyLastUpdatedClickedVersion, latestVersion);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          strings.updateNowBtn,
                          style: const TextStyle(
                            fontFamily: 'HindSiliguri',
                            fontWeight: FontWeight.bold,
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
