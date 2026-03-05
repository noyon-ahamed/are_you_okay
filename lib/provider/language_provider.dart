import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/shared_prefs_service.dart';
import '../core/localization/app_strings.dart';

/// Provides the current language as a string: 'en' or 'bn' (default: 'en')
final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  final prefs = ref.watch(sharedPrefsServiceProvider);
  // Default to English
  final savedLang = prefs.language;
  final lang = (savedLang == 'bn') ? 'bn' : 'en';
  return LanguageNotifier(prefs, lang);
});

class LanguageNotifier extends StateNotifier<String> {
  final SharedPrefsService _prefs;

  LanguageNotifier(this._prefs, String initialLang) : super(initialLang);

  Future<void> setLanguage(String lang) async {
    await _prefs.setLanguage(lang);
    state = lang;
  }

  void toggle() {
    final newLang = state == 'en' ? 'bn' : 'en';
    setLanguage(newLang);
  }
}

/// Convenience provider for AppStrings
final stringsProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(languageProvider);
  return AppStrings(lang: lang);
});
