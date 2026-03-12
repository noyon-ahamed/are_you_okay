import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/earthquake_countries.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../provider/auth_provider.dart';
import '../../../provider/settings_provider.dart';
import '../../../provider/checkin_provider.dart';
import '../../../routes/app_router.dart';
import '../../../services/api/checkin_api_service.dart';
import '../../../services/shared_prefs_service.dart';
import '../../../provider/language_provider.dart';
import '../../../core/localization/app_strings.dart';
import '../../../services/location_service.dart';

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
    final earthquakeCountryOverride =
        ref.watch(earthquakeCountryOverrideProvider);
    final displayedCountry =
        earthquakeCountryOverride ?? settings.earthquakeCountry.trim();
    final isDark = settings.themeIsDark;
    ref.watch(checkinStatusProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.settingsTitle),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // ==================== Appearance ====================
          _buildSectionHeader(s.settingsSecDesign),
          const SizedBox(height: 8),
          _buildSettingsCard(isDark, [
            _buildSwitchTile(
              icon: Icons.dark_mode_rounded,
              iconColor: const Color(0xFF6C63FF),
              title: s.settingsDarkMode,
              subtitle: s.settingsDarkModeDesc,
              value: settings.themeIsDark,
              onChanged: (val) {
                ref.read(settingsProvider.notifier).setDarkMode(val);
              },
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.language_rounded,
              iconColor: const Color(0xFF00BCD4),
              title: s.settingsSecLanguage,
              subtitle: s.isBangla
                  ? s.settingsLanguageBangla
                  : s.settingsLanguageEnglish,
              onTap: () => _showLanguageDialog(),
            ),
          ]),

          const SizedBox(height: 24),

          // ==================== Safety ====================
          _buildSectionHeader(s.settingsSecSafety),
          const SizedBox(height: 8),
          _buildSettingsCard(isDark, [
            _buildListTile(
              icon: Icons.timer_rounded,
              iconColor: AppColors.primary,
              title: s.settingsCheckinInterval,
              subtitle: _intervalLabel(settings.checkinIntervalDays, s),
              onTap: () => _showIntervalDialog(),
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.notifications_active_rounded,
              iconColor: const Color(0xFFFF9800),
              title: s.settingsNotifications,
              subtitle: s.settingsNotifDesc,
              value: settings.notificationsEnabled,
              onChanged: (_) {
                ref.read(settingsProvider.notifier).toggleNotifications();
              },
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.public_rounded,
              iconColor: const Color(0xFFE53935),
              title: s.isBangla
                  ? 'ভূমিকম্প মনিটর দেশ'
                  : 'Earthquake Watch Country',
              subtitle: s.isBangla
                  ? displayedCountry.isEmpty
                      ? 'কোনো ডিফল্ট দেশ সেভ নেই, স্ক্রিনে ঢুকলে বর্তমান লোকেশন অনুযায়ী দেখাবে'
                      : '$displayedCountry দেখাবে${earthquakeCountryOverride != null ? ' (এই সেশন)' : ''}'
                  : displayedCountry.isEmpty
                      ? 'No default country saved. The earthquake screen will use your current location.'
                      : 'Showing $displayedCountry${earthquakeCountryOverride != null ? ' for this session' : ''}',
              onTap: _showEarthquakeCountryDialog,
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.location_on_rounded,
              iconColor: const Color(0xFF4CAF50),
              title: s.settingsLocation,
              subtitle: s.settingsLocationDesc,
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

          // ==================== Account ====================
          _buildSectionHeader(s.settingsSecAccount),
          const SizedBox(height: 8),
          _buildSettingsCard(isDark, [
            _buildListTile(
              icon: Icons.person_rounded,
              iconColor: const Color(0xFF2196F3),
              title: s.settingsProfile,
              subtitle: s.settingsProfileDesc,
              onTap: () => context.push(Routes.profile),
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.contacts_rounded,
              iconColor: const Color(0xFF009688),
              title: s.contactsTitle,
              subtitle: s.settingsEmContactsDesc,
              onTap: () => context.push(Routes.contacts),
            ),
          ]),

          const SizedBox(height: 24),

          // ==================== Data ====================
          _buildSectionHeader(s.settingsSecData),
          const SizedBox(height: 8),
          _buildSettingsCard(isDark, [
            _buildListTile(
              icon: Icons.download_rounded,
              iconColor: const Color(0xFF795548),
              title: s.settingsDataExport,
              subtitle: s.settingsDataExportDesc,
              onTap: () => _exportMoodData(),
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.delete_forever_rounded,
              iconColor: AppColors.error,
              title: s.settingsClearCache,
              subtitle: s.settingsClearCacheDesc,
              onTap: () => _showClearDataDialog(),
            ),
          ]),

          const SizedBox(height: 24),

          // ==================== About ====================
          _buildSectionHeader(s.settingsSecAbout),
          const SizedBox(height: 8),
          _buildSettingsCard(isDark, [
            _buildListTile(
              icon: Icons.info_outline_rounded,
              iconColor: const Color(0xFF607D8B),
              title: s.settingsAboutApp,
              subtitle: 'Version ${AppConstants.appVersion}',
              onTap: () => context.push(Routes.aboutApp),
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.privacy_tip_outlined,
              iconColor: const Color(0xFF78909C),
              title: s.settingsPrivacy,
              onTap: () => context.push(Routes.privacyPolicy),
            ),
          ]),

          const SizedBox(height: 24),

          // ==================== Logout ====================
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(),
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: Text(
                s.settingsLogout,
                style: const TextStyle(
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
        style: const TextStyle(
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
    return const Divider(height: 1, indent: 56, endIndent: 16, thickness: 0.5);
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
              // ignore: deprecated_member_use
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
                    style: const TextStyle(
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
            // ignore: deprecated_member_use
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
                // ignore: deprecated_member_use
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
                      style: const TextStyle(
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

  // ==================== Dialogs ====================

  void _showClearDataDialog() {
    final s = ref.read(stringsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.settingsClearCache,
            style: const TextStyle(fontFamily: 'HindSiliguri')),
        content: Text(
          s.settingsClearDataConfirm,
          style: const TextStyle(fontFamily: 'HindSiliguri'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.dialogCancel,
                style: const TextStyle(fontFamily: 'HindSiliguri')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performClearData();
            },
            child: Text(s.dialogClear,
                style: const TextStyle(
                    fontFamily: 'HindSiliguri', color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showEarthquakeCountryDialog() {
    final s = ref.read(stringsProvider);
    final currentCountry = ref.read(earthquakeCountryOverrideProvider) ??
        ref.read(settingsProvider).earthquakeCountry;
    final isDark = ref.read(settingsProvider).themeIsDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        final searchController = TextEditingController();
        var selectedCountry = currentCountry;
        var isDetecting = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchController.text.trim().toLowerCase();
            final filteredCountries = EarthquakeCountries.supported
                .where((country) => country.toLowerCase().contains(query))
                .toList();

            Future<void> selectCountry(String country) async {
              setModalState(() {
                selectedCountry = country;
              });
              ref.read(earthquakeCountryOverrideProvider.notifier).state =
                  country;
              if (!mounted) return;
              Navigator.of(this.context).pop();
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(
                    s.isBangla
                        ? 'এই সেশনের জন্য $country দেখানো হবে'
                        : '$country will be shown for this session',
                    style: const TextStyle(fontFamily: 'HindSiliguri'),
                  ),
                ),
              );
            }

            Future<void> autoDetectCountry() async {
              setModalState(() {
                isDetecting = true;
              });
              final locationService = ref.read(locationServiceProvider);
              final position = await locationService.getCurrentLocation(
                accuracy: LocationAccuracy.medium,
              );
              if (position == null) {
                if (!mounted) return;
                setModalState(() {
                  isDetecting = false;
                });
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      s.isBangla
                          ? 'লোকেশন পাওয়া যায়নি। ম্যানুয়ালি দেশ বাছাই করুন।'
                          : 'Could not detect your location. Choose a country manually.',
                      style: const TextStyle(fontFamily: 'HindSiliguri'),
                    ),
                  ),
                );
                return;
              }

              final detectedCountry =
                  await locationService.getCountryFromCoordinates(
                latitude: position.latitude,
                longitude: position.longitude,
              );
              setModalState(() {
                isDetecting = false;
              });

              if (detectedCountry == null ||
                  !EarthquakeCountries.supported.contains(detectedCountry)) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      s.isBangla
                          ? 'আপনার দেশ শনাক্ত করা যায়নি। ম্যানুয়ালি বেছে নিন।'
                          : 'Your country could not be detected. Please choose manually.',
                      style: const TextStyle(fontFamily: 'HindSiliguri'),
                    ),
                  ),
                );
                return;
              }

              ref.read(earthquakeCountryOverrideProvider.notifier).state = null;
              await ref
                  .read(settingsProvider.notifier)
                  .setEarthquakeCountry(detectedCountry);
              if (!mounted) return;
              Navigator.of(this.context).pop();
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(
                    s.isBangla
                        ? 'বর্তমান লোকেশন থেকে $detectedCountry সেট করা হয়েছে'
                        : 'Set to your current country: $detectedCountry',
                    style: const TextStyle(fontFamily: 'HindSiliguri'),
                  ),
                ),
              );
            }

            return SafeArea(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.82,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF171717) : const Color(0xFFF8F7F3),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white24
                                : Colors.black12,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        s.isBangla
                            ? 'ভূমিকম্প মনিটর দেশ'
                            : 'Earthquake Watch Country',
                        style: TextStyle(
                          fontFamily: 'HindSiliguri',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.isBangla
                            ? 'লোকেশন থেকে অটো ধরতে পারেন, না হলে সার্চ করে দেশ বেছে নিন। ওই দেশ আলাদা ট্যাবে দেখাবে।'
                            : 'Auto-detect from your location or search and choose a country. That country gets its own tab.',
                        style: TextStyle(
                          fontFamily: 'HindSiliguri',
                          fontSize: 13,
                          height: 1.5,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? const [Color(0xFF1B2B25), Color(0xFF1E1E1E)]
                                : const [Color(0xFFE7F4EE), Color(0xFFF8F7F3)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.public_rounded,
                                  color: AppColors.primary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.isBangla ? 'এখন নির্বাচিত' : 'Currently selected',
                                    style: TextStyle(
                                      fontFamily: 'HindSiliguri',
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    selectedCountry.isEmpty
                                        ? (s.isBangla
                                            ? 'এখনো কোনো দেশ সেভ নেই'
                                            : 'No country saved yet')
                                        : selectedCountry,
                                    style: TextStyle(
                                      fontFamily: 'HindSiliguri',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: isDetecting ? null : autoDetectCountry,
                              icon: isDetecting
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.my_location_rounded,
                                      size: 16),
                              label: Text(
                                s.isBangla ? 'অটো' : 'Auto',
                                style: const TextStyle(fontFamily: 'HindSiliguri'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: searchController,
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          hintText: s.isBangla
                              ? 'দেশ সার্চ করুন'
                              : 'Search country',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor:
                              isDark ? const Color(0xFF202020) : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    searchController.clear();
                                    setModalState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: Container(
                          decoration: AppDecorations.cardDecoration(
                            context: context,
                            borderRadius: 20,
                          ),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            itemCount: filteredCountries.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final country = filteredCountries[index];
                              final isSelected = selectedCountry == country;
                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withValues(alpha: 0.14)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.location_searching_rounded,
                                    color: isSelected
                                        ? AppColors.primary
                                        : Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  country,
                                  style: const TextStyle(
                                    fontFamily: 'HindSiliguri',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  s.isBangla
                                      ? '$country দেশের ভূমিকম্প আগে দেখাবে'
                                      : 'Prioritize earthquakes from $country',
                                  style: TextStyle(
                                    fontFamily: 'HindSiliguri',
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.arrow_forward_rounded,
                                        color: AppColors.primary)
                                    : null,
                                onTap: () => selectCountry(country),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _performClearData() async {
    final s = ref.read(stringsProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Check connectivity first
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    final isOnline = result != ConnectivityResult.none;

    if (!isOnline) {
      // Offline — show 2nd dialog with offline option
      if (!mounted) return;
      _showOfflineClearDialog(s, scaffoldMessenger);
      return;
    }

    // Online — clear local + server
    await _doClearData(
      clearServer: true,
      scaffoldMessenger: scaffoldMessenger,
      s: s,
    );
  }

  void _showOfflineClearDialog(
      AppStrings s, ScaffoldMessengerState scaffoldMessenger) {
    final isDark = ref.read(settingsProvider).themeIsDark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: Colors.orange, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.isBangla ? 'ইন্টারনেট নেই' : 'No Internet',
                style: const TextStyle(
                  fontFamily: 'HindSiliguri',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          s.isBangla
              ? 'Server-এর ডেটা মুছতে ইন্টারনেট দরকার।\n\nআপনি চাইলে এখন শুধু ডিভাইসের ডেটা মুছুন — ইন্টারনেট চালু হলে server থেকেও স্বয়ংক্রিয়ভাবে মোছা হবে।'
              : 'Internet is required to clear server data.\n\nYou can clear device data now — server data will be automatically cleared when internet is restored.',
          style: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black87,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.dialogCancel,
                style: const TextStyle(fontFamily: 'HindSiliguri')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _doClearData(
                clearServer: false,
                scaffoldMessenger: scaffoldMessenger,
                s: s,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              s.isBangla ? 'ডিভাইসে মুছুন' : 'Clear on Device',
              style: const TextStyle(fontFamily: 'HindSiliguri'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doClearData({
    required bool clearServer,
    required ScaffoldMessengerState scaffoldMessenger,
    required AppStrings s,
  }) async {
    try {
      // 1. Always clear local Hive data
      final checkInBox = await Hive.openBox('checkin_box');
      await checkInBox.clear();

      // Contacts should NOT be cleared as per user request
      // final contactBox = await Hive.openBox('contact_box');
      // await contactBox.clear();

      final moodBox = await Hive.openBox('mood_box');
      await moodBox.clear();

      final moodPendingBox = await Hive.openBox('mood_pending_box');
      await moodPendingBox.clear();

      // 2. Clear relevant SharedPreferences keys
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_checkin_time');
      await prefs.remove(AppConstants.keyLastCheckin);
      await prefs.remove(AppConstants.keyCheckinInterval);
      await prefs.remove('mood_history_cache');
      await prefs.remove('mood_stats_cache');

      if (clearServer) {
        // Online path — try to clear server immediately
        bool serverCleared = false;
        try {
          final dio = Dio();
          final token = await SharedPrefsService.getToken();
          if (token != null) {
            await dio
                .delete(
                  '${AppConstants.apiBaseUrl}/checkin',
                  options: Options(headers: {'Authorization': 'Bearer $token'}),
                )
                .timeout(const Duration(seconds: 5));
            await dio
                .delete(
                  '${AppConstants.apiBaseUrl}/mood',
                  options: Options(headers: {'Authorization': 'Bearer $token'}),
                )
                .timeout(const Duration(seconds: 5));
            await dio
                .delete(
                  '${AppConstants.apiBaseUrl}/notification',
                  options: Options(headers: {'Authorization': 'Bearer $token'}),
                )
                .timeout(const Duration(seconds: 5));
            serverCleared = true;
          }
        } catch (e) {
          debugPrint('Backend cache clear failed (online path): $e');
        }

        // If server clear failed even online, queue it for retry
        if (!serverCleared) {
          final prefsService = ref.read(sharedPrefsServiceProvider);
          await prefsService.setPendingServerClear(true);
        }

        // 3. Invalidate providers AFTER server is cleared
        ref.invalidate(checkinHistoryFromBackendProvider);
        ref.invalidate(checkinStatusProvider);
        ref.invalidate(userStatsFromBackendProvider);
        // ref.invalidate(contactProvider); // Do not invalidate contacts

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                serverCleared
                    ? '${s.settingsClearDataSuccess} ✓'
                    : '${s.settingsClearDataSuccess} ✓ (${s.settingsClearDataOfflineNote})',
                style: const TextStyle(fontFamily: 'HindSiliguri'),
              ),
              backgroundColor: serverCleared ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        // Offline path — mark pending server clear for background sync
        final prefsService = ref.read(sharedPrefsServiceProvider);
        await prefsService.setPendingServerClear(true);

        // 3. Invalidate providers for offline mode
        ref.invalidate(checkinHistoryFromBackendProvider);
        ref.invalidate(checkinStatusProvider);
        ref.invalidate(userStatsFromBackendProvider);

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              content: Row(
                children: [
                  const Icon(Icons.sync_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.isBangla
                          ? 'ডিভাইসের ডেটা মোছা হয়েছে। ইন্টারনেট চালু হলে server থেকেও মোছা হবে।'
                          : 'Device data cleared. Server data will sync when internet is restored.',
                      style: const TextStyle(fontFamily: 'HindSiliguri'),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('${s.settingsClearCache} Error: $e',
                style: const TextStyle(fontFamily: 'HindSiliguri')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLanguageDialog() {
    final currentLang = ref.read(languageProvider);
    final s = ref.read(stringsProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.settingsSelectLanguage,
              style: const TextStyle(
                fontFamily: 'HindSiliguri',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildLangOption('English', 'en', currentLang),
            const Divider(),
            _buildLangOption('বাংলা (Bangla)', 'bn', currentLang),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLangOption(String label, String code, String currentLang) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontFamily: 'HindSiliguri')),
      trailing: currentLang == code
          ? const Icon(Icons.check_circle, color: Colors.green)
          : null,
      onTap: () {
        ref.read(languageProvider.notifier).setLanguage(code);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              code == 'bn'
                  ? 'ভাষা বাংলায় পরিবর্তিত হয়েছে'
                  : 'Language changed to English',
              style: const TextStyle(fontFamily: 'HindSiliguri'),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    final s = ref.read(stringsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.settingsLogout,
            style: const TextStyle(fontFamily: 'HindSiliguri')),
        content: Text(
          s.settingsLogoutConfirm,
          style: const TextStyle(fontFamily: 'HindSiliguri'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.dialogCancel,
                style: const TextStyle(fontFamily: 'HindSiliguri')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              context.go(Routes.login);
            },
            child: Text(s.settingsLogout,
                style: const TextStyle(
                    fontFamily: 'HindSiliguri', color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showIntervalDialog() {
    final settings = ref.read(settingsProvider);
    final s = ref.read(stringsProvider);
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.settingsCheckinInterval,
                style: const TextStyle(
                  fontFamily: 'HindSiliguri',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 4),
            Text(
              s.settingsCheckinIntervalDesc,
              style: TextStyle(
                fontFamily: 'HindSiliguri',
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 16),
            // 3 days — default
            _buildIntervalOption(
                s.settingsInterval3Days, 3, settings.checkinIntervalDays == 3),
            _buildIntervalOption(
                s.settingsInterval5Days, 5, settings.checkinIntervalDays == 5),
            _buildIntervalOption(
                s.settingsInterval7Days, 7, settings.checkinIntervalDays == 7),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalOption(String label, int value, bool isSelected) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontFamily: 'HindSiliguri')),
      leading: Radio<int>(
        value: value,
        // ignore: deprecated_member_use
        groupValue: isSelected ? value : null,
        // ignore: deprecated_member_use
        onChanged: (val) => _updateInterval(value),
        activeColor: AppColors.primary,
      ),
      onTap: () => _updateInterval(value),
    );
  }

  /// Convert interval days to a human-readable Bangla label
  String _intervalLabel(int days, AppStrings s) {
    switch (days) {
      case 3:
        return s.settingsInterval3Days;
      case 5:
        return s.settingsInterval5Days;
      case 7:
        return s.settingsInterval7Days;
      default:
        return '$days ${s.isBangla ? 'দিন' : 'days'}';
    }
  }

  void _updateInterval(int value) async {
    Navigator.pop(context);

    // Always save locally first (this never fails)
    ref.read(settingsProvider.notifier).setCheckinInterval(value);

    if (mounted) {
      final s = ref.read(stringsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.settingsIntervalUpdated,
              style: const TextStyle(fontFamily: 'HindSiliguri')),
          backgroundColor: AppColors.success,
        ),
      );
    }

    // Try to sync with backend silently (don't block UI)
    try {
      await CheckinApiService().setCheckInInterval(value);
    } catch (e) {
      debugPrint('Backend interval sync skipped: $e');
    }
  }

  void _exportMoodData() async {
    final s = ref.read(stringsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.settingsExporting,
            style: const TextStyle(fontFamily: 'HindSiliguri')),
        backgroundColor: AppColors.primary,
      ),
    );
    try {
      final dio = Dio();
      final token = await SharedPrefsService.getToken() ?? '';
      // 1. Fetch Mood Data
      final moodResponse = await dio.get(
        '${AppConstants.apiBaseUrl}/mood/export',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.plain,
        ),
      );

      // 2. Fetch Check-in Data
      String? checkinCsv;
      try {
        final checkinResponse = await dio.get(
          '${AppConstants.apiBaseUrl}/checkin/export',
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
            responseType: ResponseType.plain,
          ),
        );
        if (checkinResponse.statusCode == 200) {
          checkinCsv = checkinResponse.data.toString();
        }
      } catch (e) {
        debugPrint('No check-in data or error fetching check-in export: $e');
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

      List<List<String>> moodTableData = [];
      if (moodResponse.statusCode == 200) {
        final moodCsv = moodResponse.data.toString();
        final moodLines = moodCsv
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
        moodTableData = parseCsv(moodLines);
      }

      // Parse Check-in Data if available
      List<List<String>>? checkinTableData;
      if (checkinCsv != null) {
        final checkinLines = checkinCsv
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
        if (checkinLines.isNotEmpty) {
          checkinTableData = parseCsv(checkinLines);
        }
      }

      // Generate PDF
      final pdf = pw.Document();

      // --- MOOD PAGE ---
      if (moodTableData.isNotEmpty) {
        final moodHeaders = moodTableData.first;
        final moodRows = moodTableData.length > 1
            ? moodTableData.sublist(1)
            : <List<String>>[];

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) {
              return [
                pw.Header(
                  level: 0,
                  child: pw.Text('Mood History Report',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Total mood entries: ${moodRows.length}',
                    style: const pw.TextStyle(
                        fontSize: 12, color: PdfColors.grey600)),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  context: context,
                  headers: moodHeaders,
                  data: moodRows,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.grey300),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellPadding: const pw.EdgeInsets.all(6),
                ),
              ];
            },
          ),
        );
      }

      // --- CHECK-IN PAGE ---
      if (checkinTableData != null && checkinTableData.isNotEmpty) {
        final checkinHeaders = checkinTableData.first;
        final checkinRows = checkinTableData.length > 1
            ? checkinTableData.sublist(1)
            : <List<String>>[];

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) {
              return [
                pw.Header(
                  level: 0,
                  child: pw.Text('Check-in History Report',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Total check-in entries: ${checkinRows.length}',
                    style: const pw.TextStyle(
                        fontSize: 12, color: PdfColors.grey600)),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  context: context,
                  headers: checkinHeaders,
                  data: checkinRows,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.blue100),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellPadding: const pw.EdgeInsets.all(6),
                ),
              ];
            },
          ),
        );
      }

      // Check if any data was added to the PDF
      if (moodTableData.isEmpty &&
          (checkinTableData == null || checkinTableData.isEmpty)) {
        throw Exception('No mood or check-in data found to export');
      }

      // Save PDF to temp directory
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/are_you_okay_report.pdf');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.settingsExportSuccess} ✓',
                style: const TextStyle(fontFamily: 'HindSiliguri')),
            backgroundColor: Colors.green,
          ),
        );
        // Share the file
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(file.path)],
            text: 'Are You Okay - Data Export Report');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.moodEmpty,
                  style: const TextStyle(fontFamily: 'HindSiliguri')),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${s.moodHistoryError}: ${e.message}',
                  style: const TextStyle(fontFamily: 'HindSiliguri')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.moodHistoryError}: $e',
                style: const TextStyle(fontFamily: 'HindSiliguri')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
