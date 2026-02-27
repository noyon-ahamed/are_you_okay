import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../provider/auth_provider.dart';
import '../../../provider/settings_provider.dart';
import '../../../provider/checkin_provider.dart';
import '../../../provider/contact_provider.dart';
import '../../../routes/app_router.dart';
import '../../../services/api/checkin_api_service.dart';
import '../../../services/hive_service.dart';
import '../../../services/shared_prefs_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    // Watch for theme changes but not rebuild entire widget from top-down watcher
    final settings = ref.watch(settingsProvider);
    final isDark = settings.themeIsDark;
    final statusData = ref.watch(checkinStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('সেটিংস'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // ==================== Appearance ====================
          _buildSectionHeader('ডিজাইন'),
          const SizedBox(height: 8),
          _buildSettingsCard(isDark, [
            _buildSwitchTile(
              icon: Icons.dark_mode_rounded,
              iconColor: const Color(0xFF6C63FF),
              title: 'ডার্ক মোড',
              subtitle: 'অন্ধকার থিম সক্রিয় করুন',
              value: settings.themeIsDark,
              onChanged: (val) {
                ref.read(settingsProvider.notifier).setDarkMode(val);
              },
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.language_rounded,
              iconColor: const Color(0xFF00BCD4),
              title: 'ভাষা',
              subtitle: settings.language == 'bn' ? 'বাংলা' : 'English',
              onTap: () => _showLanguageDialog(),
            ),
          ]),

          const SizedBox(height: 24),

          // ==================== Safety ====================
          _buildSectionHeader('নিরাপত্তা'),
          const SizedBox(height: 8),
          _buildSettingsCard(isDark, [
            // _buildListTile(
            //   icon: Icons.local_fire_department,
            //   iconColor: Colors.deepOrange,
            //   title: 'বর্তমান স্ট্রিক',
            //   subtitle: '${statusData.streak} দিন',
            //   onTap: () {},
            // ),
            // _buildDivider(),
            _buildListTile(
              icon: Icons.timer_rounded,
              iconColor: AppColors.primary,
              title: 'চেক-ইন ইন্টারভাল',
              subtitle: 'প্রতি ${settings.checkinIntervalHours} ঘণ্টা পর',
              onTap: () => _showIntervalDialog(),
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.notifications_active_rounded,
              iconColor: const Color(0xFFFF9800),
              title: 'নোটিফিকেশন',
              subtitle: 'চেক-ইন রিমাইন্ডার পাঠান',
              value: settings.notificationsEnabled,
              onChanged: (_) {
                ref.read(settingsProvider.notifier).toggleNotifications();
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.location_on_rounded,
              iconColor: const Color(0xFF4CAF50),
              title: 'লোকেশন',
              subtitle: 'চেক-ইনে লোকেশন সংযুক্ত করুন',
              value: settings.locationEnabled,
              onChanged: (_) {
                ref.read(settingsProvider.notifier).toggleLocation();
              },
            ),
            // _buildDivider(),
            // _buildSwitchTile(
            //   icon: Icons.fingerprint_rounded,
            //   iconColor: const Color(0xFF9C27B0),
            //   title: 'বায়োমেট্রিক লক',
            //   subtitle: 'অ্যাপ খুলতে ফিঙ্গারপ্রিন্ট ব্যবহার করুন',
            //   value: settings.biometricEnabled,
            //   onChanged: (_) {
            //     ref.read(settingsProvider.notifier).toggleBiometric();
            //   },
            // ),
          ]),

          const SizedBox(height: 24),

          // ==================== Account ====================
          _buildSectionHeader('অ্যাকাউন্ট'),
          const SizedBox(height: 8),
          _buildSettingsCard(isDark, [
            _buildListTile(
              icon: Icons.person_rounded,
              iconColor: const Color(0xFF2196F3),
              title: 'প্রোফাইল',
              subtitle: 'প্রোফাইল তথ্য সম্পাদনা',
              onTap: () => context.push(Routes.profile),
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.contacts_rounded,
              iconColor: const Color(0xFF009688),
              title: 'জরুরি যোগাযোগ',
              subtitle: 'যোগাযোগ পরিচালনা',
              onTap: () => context.push(Routes.contacts),
            ),
          ]),

          const SizedBox(height: 24),

          // ==================== Data ====================
          _buildSectionHeader('ডেটা'),
          const SizedBox(height: 8),
          _buildSettingsCard(isDark, [
            _buildListTile(
              icon: Icons.download_rounded,
              iconColor: const Color(0xFF795548),
              title: 'ডেটা এক্সপোর্ট',
              subtitle: 'মুড ইতিহাস CSV ডাউনলোড',
              onTap: () => _exportMoodData(),
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.delete_forever_rounded,
              iconColor: AppColors.error,
              title: 'ক্যাশ পরিষ্কার',
              subtitle: 'স্থানীয় ডেটা পরিষ্কার করুন',
              onTap: () => _showClearDataDialog(),
            ),
          ]),

          const SizedBox(height: 24),

          // ==================== About ====================
          _buildSectionHeader('সম্পর্কে'),
          const SizedBox(height: 8),
          _buildSettingsCard(isDark, [
            _buildListTile(
              icon: Icons.info_outline_rounded,
              iconColor: const Color(0xFF607D8B),
              title: 'অ্যাপ সম্পর্কে',
              subtitle: 'ভার্সন 2.0.0',
              onTap: () {},
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.privacy_tip_outlined,
              iconColor: const Color(0xFF78909C),
              title: 'গোপনীয়তা নীতি',
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 24),

          // ==================== Logout ====================
          Container(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(),
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: Text(
                'লগআউট',
                style: TextStyle(
                  color: AppColors.error,
                  fontFamily: 'HindSiliguri',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ==================== Builders ====================

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'HindSiliguri',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: AppDecorations.cardDecoration(context: context),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 56, endIndent: 16, thickness: 0.5);
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontFamily: 'HindSiliguri',
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    )),
                if (subtitle != null)
                  Text(subtitle,
                      style: TextStyle(
                        fontFamily: 'HindSiliguri',
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      )),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontFamily: 'HindSiliguri',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      )),
                  if (subtitle != null)
                    Text(subtitle,
                        style: TextStyle(
                          fontFamily: 'HindSiliguri',
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        )),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontFamily: 'HindSiliguri',
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        )),
                    Text(subtitle,
                        style: TextStyle(
                          fontFamily: 'HindSiliguri',
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider.adaptive(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppColors.primary,
            label: '${value.round()} ঘণ্টা',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ==================== Dialogs ====================

  void _showLanguageDialog() {
    final settings = ref.read(settingsProvider);
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ভাষা নির্বাচন',
                style: TextStyle(
                  fontFamily: 'HindSiliguri',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 16),
            _buildLanguageOption('বাংলা', 'bn', settings.language == 'bn'),
            _buildLanguageOption('English', 'en', settings.language == 'en'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String label, String code, bool isSelected) {
    return ListTile(
      title: Text(label, style: TextStyle(fontFamily: 'HindSiliguri')),
      leading: Radio<String>(
        value: code,
        groupValue: isSelected ? code : null,
        onChanged: (val) {
          ref.read(settingsProvider.notifier).setLanguage(code);
          Navigator.pop(context);
        },
        activeColor: AppColors.primary,
      ),
      onTap: () {
        ref.read(settingsProvider.notifier).setLanguage(code);
        Navigator.pop(context);
      },
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ক্যাশ পরিষ্কার',
            style: TextStyle(fontFamily: 'HindSiliguri')),
        content: Text(
          'চেক-ইন, মুড এবং কন্টাক্ট ক্যাশ মুছে যাবে। আপনার অ্যাকাউন্ট এবং লগইন ডেটা নিরাপদ থাকবে।',
          style: TextStyle(fontFamily: 'HindSiliguri'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('বাতিল',
                style: TextStyle(fontFamily: 'HindSiliguri')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // 1. Clear LOCAL data first (always works, no internet needed)
                final checkInBox = await Hive.openBox('checkin_box');
                await checkInBox.clear();
                
                final contactBox = await Hive.openBox('contact_box');
                await contactBox.clear();
                
                final moodBox = await Hive.openBox('mood_box');
                await moodBox.clear();

                final moodPendingBox = await Hive.openBox('mood_pending_box');
                await moodPendingBox.clear();

                // Clear background service SharedPreferences keys
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('last_checkin_time');
                await prefs.remove('checkin_interval');

                // Invalidate providers to refresh UI
                ref.invalidate(checkinHistoryFromBackendProvider);
                ref.invalidate(checkinStatusProvider);
                ref.invalidate(contactProvider);

                // 2. Try to clear backend data (optional — skip if offline)
                try {
                  final dio = Dio();
                  final token = await SharedPrefsService.getToken();
                  if (token != null) {
                    await dio.delete(
                      '${AppConstants.apiBaseUrl}/checkin',
                      options: Options(headers: {'Authorization': 'Bearer $token'}),
                    ).timeout(const Duration(seconds: 5));
                    await dio.delete(
                      '${AppConstants.apiBaseUrl}/mood',
                      options: Options(headers: {'Authorization': 'Bearer $token'}),
                    ).timeout(const Duration(seconds: 5));
                  }
                } catch (e) {
                  // Backend clear failed (likely offline) — that's okay
                  debugPrint('Backend cache clear skipped (offline): $e');
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ক্যাশ সফলভাবে পরিষ্কার হয়েছে ✓',
                          style: TextStyle(fontFamily: 'HindSiliguri')),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ক্যাশ পরিষ্কার ব্যর্থ: $e',
                          style: TextStyle(fontFamily: 'HindSiliguri')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('পরিষ্কার করুন',
                style: TextStyle(
                    fontFamily: 'HindSiliguri', color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('লগআউট',
            style: TextStyle(fontFamily: 'HindSiliguri')),
        content: Text(
          'আপনি কি লগআউট করতে চান?',
          style: TextStyle(fontFamily: 'HindSiliguri'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('বাতিল',
                style: TextStyle(fontFamily: 'HindSiliguri')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              context.go(Routes.login);
            },
            child: Text('লগআউট',
                style: TextStyle(
                    fontFamily: 'HindSiliguri', color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showIntervalDialog() {
    final settings = ref.read(settingsProvider);
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('চেক-ইন সময়সীমা',
                style: TextStyle(
                  fontFamily: 'HindSiliguri',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 16),
            _buildIntervalOption('২৪ ঘণ্টা (দৈনিক)', 24, settings.checkinIntervalHours == 24),
            _buildIntervalOption('৪৮ ঘণ্টা (২ দিন)', 48, settings.checkinIntervalHours == 48),
            _buildIntervalOption('৭২ ঘণ্টা (৩ দিন)', 72, settings.checkinIntervalHours == 72),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalOption(String label, int value, bool isSelected) {
    return ListTile(
      title: Text(label, style: TextStyle(fontFamily: 'HindSiliguri')),
      leading: Radio<int>(
        value: value,
        groupValue: isSelected ? value : null,
        onChanged: (val) => _updateInterval(value),
        activeColor: AppColors.primary,
      ),
      onTap: () => _updateInterval(value),
    );
  }

  void _updateInterval(int value) async {
    Navigator.pop(context);
    try {
      // Sync with local provider
      ref.read(settingsProvider.notifier).setCheckinInterval(value);
      // Sync with backend API
      await CheckinApiService().setCheckInInterval(value);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ইন্টারভাল আপডেট হয়েছে ✓', style: TextStyle(fontFamily: 'HindSiliguri')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to set interval: \$e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ইন্টারভাল আপডেট ব্যর্থ হয়েছে', style: TextStyle(fontFamily: 'HindSiliguri')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _exportMoodData() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('মুড ডেটা এক্সপোর্ট হচ্ছে...', style: TextStyle(fontFamily: 'HindSiliguri')),
        backgroundColor: AppColors.primary,
      ),
    );
    try {
      final dio = Dio();
      final token = await SharedPrefsService.getToken() ?? '';
      final response = await dio.get(
        '${AppConstants.apiBaseUrl}/mood/export',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.plain,
        ),
      );

      if (response.statusCode == 200) {
        final csvData = response.data.toString();
        
        // Parse CSV string — handle quoted fields properly
        final lines = csvData.split('\n').where((line) => line.trim().isNotEmpty).toList();
        
        if (lines.isEmpty) {
          throw Exception('No mood data found');
        }

        // Parse each CSV line respecting quoted fields
        List<List<String>> parseCsv(List<String> csvLines) {
          final result = <List<String>>[];
          for (final line in csvLines) {
            final fields = <String>[];
            String current = '';
            bool inQuotes = false;
            for (int i = 0; i < line.length; i++) {
              final c = line[i];
              if (c == '"') {
                inQuotes = !inQuotes;
              } else if (c == ',' && !inQuotes) {
                fields.add(current.trim());
                current = '';
              } else {
                current += c;
              }
            }
            fields.add(current.trim());
            result.add(fields);
          }
          return result;
        }

        final tableData = parseCsv(lines);
        if (tableData.isEmpty) {
          throw Exception('No mood data to export');
        }

        // Separate headers from data
        final headers = tableData.first;
        final dataRows = tableData.length > 1 ? tableData.sublist(1) : <List<String>>[];

        // Generate PDF
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Mood History Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text('Total entries: ${dataRows.length}', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                  pw.SizedBox(height: 20),
                  if (dataRows.isEmpty)
                    pw.Text('No mood data available', style: pw.TextStyle(fontSize: 14))
                  else
                    pw.TableHelper.fromTextArray(
                      context: context,
                      headers: headers,
                      data: dataRows,
                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                      cellAlignment: pw.Alignment.centerLeft,
                      cellPadding: const pw.EdgeInsets.all(6),
                    ),
                ],
              );
            },
          ),
        );

        // Save PDF to temp directory
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/mood_history.pdf');
        await file.writeAsBytes(await pdf.save());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('মুড ডেটা সফলভাবে এক্সপোর্ট হয়েছে! ✓', style: TextStyle(fontFamily: 'HindSiliguri')),
              backgroundColor: Colors.green,
            ),
          );
          // Share the file
          await Share.shareXFiles([XFile(file.path)], text: 'Mood History Report');
        }
      } else {
        throw Exception('Export failed');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('কোনো মুড ডেটা পাওয়া যায়নি। প্রথমে কিছু মুড সেভ করুন।', style: TextStyle(fontFamily: 'HindSiliguri')),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('এক্সপোর্ট ব্যর্থ: ${e.message}', style: TextStyle(fontFamily: 'HindSiliguri')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('এক্সপোর্ট ব্যর্থ: $e', style: TextStyle(fontFamily: 'HindSiliguri')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
