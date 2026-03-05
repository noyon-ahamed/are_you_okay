/// AppStrings
/// Centralized localization strings for English and Bangla.
/// Usage: AppStrings.of(context).homeTitle
class AppStrings {
  final String lang;
  const AppStrings({required this.lang});

  bool get isBangla => lang == 'bn';

  // ===================== Common =====================
  String get appName => isBangla ? 'আপনি কি ঠিক আছেন?' : 'Are You Okay?';
  String get cancel => isBangla ? 'বাতিল' : 'Cancel';
  String get save => isBangla ? 'সংরক্ষণ করুন' : 'Save';
  String get ok => isBangla ? 'ঠিক আছে' : 'OK';
  String get confirm => isBangla ? 'নিশ্চিত করুন' : 'Confirm';
  String get yes => isBangla ? 'হ্যাঁ' : 'Yes';
  String get no => isBangla ? 'না' : 'No';
  String get loading => isBangla ? 'লোড হচ্ছে...' : 'Loading...';
  String get error => isBangla ? 'সমস্যা হয়েছে' : 'An error occurred';
  String get retry => isBangla ? 'আবার চেষ্টা করুন' : 'Retry';
  String get networkError => isBangla ? 'নেটওয়ার্ক ত্রুটি' : 'Network error';
  String get noInternet =>
      isBangla ? 'ইন্টারনেট সংযোগ নেই' : 'No internet connection';
  String get offlineMessage => isBangla
      ? 'অফলাইনে ক্যাশ করা ডেটা দেখানো হচ্ছে'
      : 'Showing cached data (offline)';

  // ===================== Navigation =====================
  String get navHome => isBangla ? 'হোম' : 'Home';
  String get navHistory => isBangla ? 'ইতিহাস' : 'History';
  String get navContacts => isBangla ? 'যোগাযোগ' : 'Contacts';
  String get navSOS => isBangla ? 'SOS' : 'SOS';
  String get navMood => isBangla ? 'মেজাজ' : 'Mood';
  String get navSettings => isBangla ? 'সেটিংস' : 'Settings';

  // ===================== Home =====================
  String get homeCheckIn => isBangla ? 'চেক-ইন করুন' : 'Check In';
  String get homeCheckinBtn => isBangla ? 'চেক-ইন' : 'Check In';
  String get homeCheckinDone =>
      isBangla ? 'আজকের চেক-ইন সম্পন্ন' : 'Check-in Done';
  String get homeLastCheckIn => isBangla ? 'শেষ চেক-ইন' : 'Last Check-in';
  String get homeNextCheckIn => isBangla ? 'পরবর্তী চেক-ইন' : 'Next Check-in';
  String get homeHoursLeft => isBangla ? 'ঘণ্টা বাকি' : 'hours left';
  String get homeCheckInDue => isBangla ? 'চেক-ইন বাকি আছে' : 'Check-in due';
  String get homeAllGood => isBangla ? 'সব ঠিক আছে' : 'All good';
  String get homeHowAreYou =>
      isBangla ? 'আপনি কেমন আছেন আজকে?' : 'How are you today?';
  String get statusSafe => isBangla ? 'নিরাপদ' : 'Safe';
  String get statusNeedCheckin =>
      isBangla ? 'চেক-ইন প্রয়োজন' : 'Needs Check-in';
  String get statusEmergency =>
      isBangla ? 'জরুরি চেক-ইন' : 'Emergency Check-in';
  String get homeCheckinRemaining => isBangla
      ? 'পরবর্তী চেক-ইনের বাকি সময়'
      : 'Time remaining for next check-in';

  String get homeQuickActions => isBangla ? 'দ্রুত অ্যাকশন' : 'Quick Actions';
  String get actionSOS => isBangla ? 'জরুরি SOS' : 'Emergency SOS';
  String get actionAIChat => isBangla ? 'AI চ্যাট' : 'AI Chat';
  String get actionContacts => isBangla ? 'যোগাযোগ' : 'Contacts';
  String get actionFakeCall => isBangla ? 'ফেক কল' : 'Fake Call';
  String get actionEarthquake => isBangla ? 'ভূমিকম্প' : 'Earthquake';
  String get actionHistory => isBangla ? 'ইতিহাস' : 'History';

  String get homeSafetyStats =>
      isBangla ? 'নিরাপত্তা পরিসংখ্যান' : 'Safety Stats';
  String get statTodayCheckin =>
      isBangla ? 'আজকের চেক-ইন' : 'Today\'s Check-in';
  String get statStreak => isBangla ? 'স্ট্রিক' : 'Streak';
  String get statLastCheckin => isBangla ? 'শেষ চেক-ইন' : 'Last Check-in';

  String get moodHowAreYou =>
      isBangla ? 'আজ আপনার মেজাজ কেমন?' : 'How is your mood today?';
  String get homeMoodSave => isBangla ? 'সেভ করুন' : 'Save';
  String get homeMoodHistory => isBangla ? 'ইতিহাস' : 'History';
  String get homeWaitCheckin =>
      isBangla ? 'পরবর্তী চেক-ইন সম্ভব:' : 'Next check-in possible:';
  String get homeWaitAfter =>
      isBangla ? 'ঘণ্টা মিনিট পর' : 'hours minutes later';
  String get homeStreakX => isBangla ? 'দিনের স্ট্রিক!' : 'day streak!';

  // Warnings / Greetings
  String get goodMorning => isBangla ? 'সুপ্রভাত 🌅' : 'Good Morning 🌅';
  String get goodAfternoon => isBangla ? 'শুভ দুপুর ☀️' : 'Good Afternoon ☀️';
  String get goodEvening => isBangla ? 'শুভ সন্ধ্যা 🌆' : 'Good Evening 🌆';
  String get goodNight => isBangla ? 'শুভ রাত্রি 🌙' : 'Good Night 🌙';

  // ===================== Check-in History =====================
  String get chHistoryTitle => isBangla ? 'চেক-ইন ইতিহাস' : 'Check-in History';
  String get chFilterAll => isBangla ? 'সব সময়' : 'All Time';
  String get chFilter7 => isBangla ? 'গত ৭ দিন' : 'Last 7 days';
  String get chFilter14 => isBangla ? 'গত ১৪ দিন' : 'Last 14 days';
  String get chErrorPrefix => isBangla ? 'ত্রুটি:' : 'Error:';
  String get chEmptyTitle =>
      isBangla ? 'কোনো হিস্ট্রি পাওয়া যায়নি' : 'No history found';
  String get chEmptyDesc => isBangla
      ? 'এই সময়কালে আপনার কোনো চেক-ইন নেই'
      : 'You have no check-ins in this period';
  String get chStatTotal => isBangla ? 'মোট' : 'Total';
  String get chStatStreak => isBangla ? 'স্ট্রিক 🔥' : 'Streak 🔥';
  String get chStatToday => isBangla ? 'আজ' : 'Today';
  String get chStatusSafe => isBangla ? 'নিরাপদ' : 'Safe';
  String get chDateToday => isBangla ? 'আজ' : 'Today';
  String get chDateYesterday => isBangla ? 'গতকাল' : 'Yesterday';

  // ===================== Mood =====================
  String get moodHistory => isBangla ? 'মেজাজের ইতিহাস' : 'Mood History';
  String get moodSave => isBangla ? 'মেজাজ সংরক্ষণ করুন' : 'Save Mood';
  String get moodNote => isBangla ? 'নোট (ঐচ্ছিক)' : 'Note (optional)';
  String get moodStatsError =>
      isBangla ? 'পরিসংখ্যান লোড করতে সমস্যা হয়েছে।' : 'Failed to load stats.';
  String get moodHistoryError =>
      isBangla ? 'ইতিহাস লোড করতে ব্যর্থ' : 'Failed to load history';
  String get moodEmpty =>
      isBangla ? 'কোনো মেজাজ রেকর্ড নেই' : 'No mood records yet';
  String get moodFilterAll => isBangla ? 'সব সময়' : 'All Time';
  String get moodFilter7 => isBangla ? 'গত ৭ দিন' : 'Last 7 days';
  String get moodFilter14 => isBangla ? 'গত ১৪ দিন' : 'Last 14 days';
  String get moodStat30Days =>
      isBangla ? 'গত ৩০ দিনের পরিসংখ্যান' : 'Last 30 days statistics';
  String get moodStatMain => isBangla ? 'প্রধান মেজাজ' : 'Main Mood';
  String get moodStatTotal => isBangla ? 'মোট এন্ট্রি' : 'Total Entries';
  String get moodEmptyHome =>
      isBangla ? 'এখনো কোনো মেজাজ সেভ করা হয়নি' : 'No mood saved yet';
  String get moodEmptyHomeDesc => isBangla
      ? 'হোম স্ক্রিন থেকে আজ আপনার মেজাজ কেমন তা সেভ করুন'
      : 'Save your mood today from the home screen';
  // Names
  String get moodHappy => isBangla ? 'খুশি' : 'Happy';
  String get moodGood => isBangla ? 'ভালো' : 'Good';
  String get moodNeutral => isBangla ? 'স্বাভাবিক' : 'Neutral';
  String get moodAnxious => isBangla ? 'উদ্বিগ্ন' : 'Anxious';
  String get moodSad => isBangla ? 'দুঃখিত' : 'Sad';

  // ===================== Settings =====================
  String get settingsTitle => isBangla ? 'সেটিংস' : 'Settings';
  // Sections
  String get settingsSecDesign => isBangla ? 'ডিজাইন' : 'Appearance';
  String get settingsSecSafety => isBangla ? 'নিরাপত্তা' : 'Safety';
  String get settingsSecLanguage => isBangla ? 'ভাষা / Language' : 'Language';
  String get settingsSecAccount => isBangla ? 'অ্যাকাউন্ট' : 'Account';
  String get settingsSecData => isBangla ? 'ডেটা' : 'Data';
  String get settingsSecAbout => isBangla ? 'সম্পর্কে' : 'About';

  // Items & Descriptions
  String get settingsDarkMode => isBangla ? 'ডার্ক মোড' : 'Dark Mode';
  String get settingsDarkModeDesc =>
      isBangla ? 'অন্ধকার থিম সক্রিয় করুন' : 'Enable dark theme';

  String get settingsLanguage => isBangla ? 'ভাষা' : 'Language';
  String get settingsLanguageBangla => isBangla ? 'বাংলা' : 'Bangla';
  String get settingsLanguageEnglish => isBangla ? 'ইংরেজি' : 'English';

  String get settingsCheckinInterval =>
      isBangla ? 'চেক-ইন সময়সীমা' : 'Check-in Interval';
  String get settingsCheckinIntervalDesc => isBangla
      ? 'এই সময়ের মধ্যে চেক-ইন না করলে সতর্কতা পাঠানো হবে'
      : 'Alert will be sent if no check-in within this period';

  String get settingsNotifications => isBangla ? 'নোটিফিকেশন' : 'Notifications';
  String get settingsNotifDesc =>
      isBangla ? 'চেক-ইন রিমাইন্ডার পাঠান' : 'Send check-in reminders';

  String get settingsLocation => isBangla ? 'লোকেশন' : 'Location';
  String get settingsLocationDesc =>
      isBangla ? 'চেক-ইনে লোকেশন সংযুক্ত করুন' : 'Attach location to check-ins';

  String get settingsProfile => isBangla ? 'প্রোফাইল' : 'Profile';
  String get settingsProfileDesc =>
      isBangla ? 'প্রোফাইল তথ্য সম্পাদনা' : 'Edit profile information';

  String get settingsEmContactsDesc =>
      isBangla ? 'যোগাযোগ পরিচালনা' : 'Manage contacts';

  String get settingsDataExport => isBangla ? 'ডেটা এক্সপোর্ট' : 'Data Export';
  String get settingsDataExportDesc =>
      isBangla ? 'মুড ইতিহাস CSV ডাউনলোড' : 'Download mood history CSV';

  String get settingsClearCache => isBangla ? 'ক্যাশ পরিষ্কার' : 'Clear Cache';
  String get settingsClearCacheDesc =>
      isBangla ? 'স্থানীয় ডেটা পরিষ্কার করুন' : 'Clear local data';

  String get settingsAboutApp => isBangla ? 'অ্যাপ সম্পর্কে' : 'About App';
  String get settingsPrivacy => isBangla ? 'গোপনীয়তা নীতি' : 'Privacy Policy';

  String get aboutAppContent => isBangla
      ? 'Are You Okay? - একটি আধুনিক মানসিক ও শারীরিক স্বাস্থ্য ট্র্যাকিং অ্যাপ্লিকেশন।\n\nএটি আপনাকে প্রতিদিন নিয়মিত চেক-ইন করতে, মেজাজ বা মুড ট্র্যাক করতে এবং যেকোনো অবহেলিত বা জরুরি অবস্থায় আপনার প্রিয়জন ও জরুরি পরিষেবাগুলোর সাথে এক ক্লিকে যোগাযোগ করতে সাহায্য করে। আমাদের লক্ষ্য হলো, একটি নিরাপদ এবং স্বাস্থ্যকর জীবনযাপনের জন্য আপনার নিত্যদিনের সঙ্গী হওয়া।'
      : 'Are You Okay? is a modern mental and physical health tracking app.\n\nIt allows you to check-in daily, track your mood, and instantly reach out to your loved ones and emergency services in critical situations. Our goal is to be your everyday companion for a safer and healthier life.';

  String get privacyPolicyContent => isBangla
      ? 'আপনার তথ্যের গোপনীয়তা আমাদের কাছে সর্বোচ্চ অগ্রাধিকার।\n\n১. ডেটা সংগ্রহ: চেক-ইন, মেজাজ এবং কন্টাক্ট ইনফরমেশন আপনার ডিভাইসে এবং আমাদের সুরক্ষিত ডেটাবেসে এনক্রিপ্ট করে রাখা হয়।\n২. নিরাপদ ব্যবহার: আপনার কোনো ব্যক্তিগত ডেটা থার্ড-পার্টি বা তৃতীয় কোনো পক্ষের কাছে বিক্রি বা শেয়ার করা হয় না।\n৩. লোকেশন এক্সেস: জরুরি SOS সার্ভিস ব্যবহারের সময় আপনার অনুমতি সাপেক্ষে লোকেশন ব্যবহার করা হয়।\n৪. নিয়ন্ত্রণ: আপনি যেকোনো সময় "ডেটা সাফ করুন" অপশন ব্যবহার করে আপনার সব তথ্য মুছে ফেলতে পারবেন।'
      : 'Your privacy is our utmost priority.\n\n1. Data Collection: Check-ins, moods, and contacts are stored securely and encrypted.\n2. Safe Usage: Your personal data is never sold or shared with third parties.\n3. Location Access: Location is only used during Emergency SOS with your permission.\n4. Control: You can delete all your data anytime using the "Clear Data" option.';

  String get settingsTheme => isBangla ? 'থিম' : 'Theme';
  String get settingsThemeLight => isBangla ? 'হালকা' : 'Light';
  String get settingsThemeDark => isBangla ? 'গাঢ়' : 'Dark';
  String get settingsThemeSystem => isBangla ? 'সিস্টেম' : 'System';

  String get settingsLogout => isBangla ? 'লগআউট' : 'Logout';
  String get settingsLogoutConfirm =>
      isBangla ? 'আপনি কি লগআউট করতে চান?' : 'Do you want to logout?';
  String get settingsClearData => isBangla ? 'ডেটা সাফ করুন' : 'Clear Data';
  String get settingsClearDataConfirm => isBangla
      ? 'চেক-ইন, মুড এবং কন্টাক্ট ক্যাশ মুছে যাবে। আপনার অ্যাকাউন্ট নিরাপদ থাকবে।'
      : 'Check-in, mood, and contact cache will be deleted. Your account is safe.';
  String get settingsClearDataSuccess =>
      isBangla ? 'স্থানীয় ডেটা মুছে ফেলা হয়েছে।' : 'Local data cleared.';
  String get settingsClearDataOfflineNote => isBangla
      ? 'অফলাইন মোডে সার্ভারের ডেটা মুছা সম্ভব হয়নি।'
      : 'Server data could not be cleared (offline).';

  String get settingsInterval3Days =>
      isBangla ? '৩ দিন (3 days) — ডিফল্ট' : '3 days — Default';
  String get settingsInterval5Days => isBangla ? '৫ দিন (5 days)' : '5 days';
  String get settingsInterval7Days => isBangla ? '৭ দিন (7 days)' : '7 days';
  String get settingsIntervalUpdated =>
      isBangla ? 'ইন্টারভাল আপডেট হয়েছে' : 'Interval updated';

  String get settingsExporting =>
      isBangla ? 'মুড ডেটা এক্সপোর্ট হচ্ছে...' : 'Exporting mood data...';
  String get settingsExportSuccess =>
      isBangla ? 'ডেটা সফলভাবে সংরক্ষিত হয়েছে' : 'Data successfully saved';
  String get settingsSelectLanguage => isBangla
      ? 'ভাষা নির্বাচন করুন / Select Language'
      : 'Select Language / ভাষা নির্বাচন করুন';

  // Dialog Actions
  String get dialogCancel => isBangla ? 'বাতিল' : 'Cancel';
  String get dialogClose => isBangla ? 'বন্ধ করুন' : 'Close';
  String get dialogClear => isBangla ? 'পরিষ্কার করুন' : 'Clear';
  String get dialogLogout => isBangla ? 'লগআউট' : 'Logout';

  // ===================== SOS =====================
  String get sosTitle => isBangla ? 'জরুরি SOS' : 'Emergency SOS';
  String get sosActivating =>
      isBangla ? 'SOS সক্রিয় হচ্ছে...' : 'Activating SOS...';
  String get sosActivated =>
      isBangla ? 'SOS সক্রিয় হয়েছে!' : 'SOS Activated!';
  String get sosAlertSent => isBangla
      ? 'আপনার জরুরি যোগাযোগকারীদের সতর্কতা পাঠানো হয়েছে'
      : 'Your emergency contacts have been alerted';
  String get sosSafe => isBangla ? 'আমি নিরাপদ' : 'I am Safe';
  String get sosCancel => isBangla ? 'বাতিল করুন' : 'Cancel';
  String get sosSelectService => isBangla
      ? 'প্রয়োজনীয় পরিষেবা নির্বাচন করুন:'
      : 'Select required services:';
  String get sosPolice => isBangla ? 'পুলিশ' : 'Police';
  String get sosFire => isBangla ? 'ফায়ার সার্ভিস' : 'Fire Service';
  String get sosAmbulance => isBangla ? 'অ্যাম্বুলেন্স' : 'Ambulance';
  String get sosSMSSent => isBangla
      ? 'SMS অ্যাপ খোলা হয়েছে। পাঠান বাটন চাপুন।'
      : 'SMS app opened. Tap Send.';
  String get sosNoContacts => isBangla
      ? 'কোনো জরুরি যোগাযোগ নেই। প্রথমে যোগাযোগ যোগ করুন।'
      : 'No emergency contacts. Please add contacts first.';
  String get sosPressHold => isBangla
      ? 'জরুরি সাহায্যের জন্য\nদীর্ঘক্ষণ চাপুন'
      : 'Hold to activate\nemergency SOS';
  String get sosNotifiedContacts => isBangla
      ? 'জন যোগাযোগকারীকে সতর্ক করা হয়েছে'
      : 'contacts have been notified';
  String get sosLocationShared =>
      isBangla ? 'লোকেশন শেয়ার করা হয়েছে' : 'Location shared';
  String get sosEmergencyNumbers =>
      isBangla ? 'জরুরি নম্বর' : 'Emergency Numbers';
  String get sosNationalEmergency =>
      isBangla ? '৯৯৯ (জাতীয় জরুরি)' : '999 (National Emergency)';

  // Missing SOS strings found during screen localization
  String get sosActiveStatus => isBangla ? 'SOS সক্রিয়!' : 'SOS Active!';
  String get sosContactsNotified => isBangla
      ? 'জন যোগাযোগকারীকে সতর্ক করা হয়েছে'
      : 'contacts have been notified';
  String get sosCurrentLocation => isBangla ? 'আমার অবস্থান:' : 'My Location:';
  String get sosLocationNotFound =>
      isBangla ? 'অবস্থান পাওয়া যায়নি' : 'Location not found';
  String get sosSmsBody =>
      isBangla ? 'জরুরি! আমি বিপদে আছি।' : 'Emergency! I am in danger.';
  String get sosPleaseHelp =>
      isBangla ? 'দয়া করে আমাকে সাহায্য করুন।' : 'Please help me.';
  String get sosSmsAppOpened => isBangla
      ? 'SMS অ্যাপ খোলা হয়েছে। পাঠান বাটন চাপুন।'
      : 'SMS app opened. Tap Send button.';
  String get sosSafeBtn => isBangla ? 'আমি নিরাপদ' : 'I am Safe';
  String get sosAddContacts =>
      isBangla ? 'জরুরি যোগাযোগ যোগ করুন' : 'Add Emergency Contacts';
  String get sosEmergencyContacts =>
      isBangla ? 'জরুরি যোগাযোগ' : 'Emergency Contacts';
  String get sosNumberNational =>
      isBangla ? '৯৯৯ (জাতীয় জরুরি)' : '999 (National Emergency)';
  String get sosNumberFire => isBangla ? 'ফায়ার সার্ভিস' : 'Fire Service';
  String get sosNumberAmbulance => isBangla ? 'অ্যাম্বুলেন্স' : 'Ambulance';

  // ===================== Contacts =====================
  String get contactsTitle => isBangla ? 'জরুরি যোগাযোগ' : 'Emergency Contacts';
  String get contactsAdd => isBangla ? 'যোগাযোগ যোগ করুন' : 'Add Contact';
  String get contactsEmpty => isBangla ? 'কোনো যোগাযোগ নেই' : 'No contacts yet';
  String get contactsEmptyDesc => isBangla
      ? 'আপনার প্রিয়জনদের জরুরি যোগাযোগ\nহিসেবে যোগ করুন'
      : 'Add loved ones as emergency contacts';
  String get contactsName => isBangla ? 'নাম' : 'Name';
  String get contactsPhone => isBangla ? 'ফোন নম্বর' : 'Phone Number';
  String get contactsEmail => isBangla ? 'ইমেইল' : 'Email';
  String get contactsRelation => isBangla ? 'সম্পর্ক' : 'Relation';
  String get contactsSavedOffline => isBangla
      ? 'অফলাইনে সংরক্ষিত। ইন্টারনেট আসলে সিঙ্ক হবে।'
      : 'Saved offline. Will sync when online.';
  String get contactsDeleteConfirm => isBangla ? 'মুছে ফেলুন' : 'Delete';
  String get contactsDeleteAsk =>
      isBangla ? 'এই যোগাযোগ মুছে ফেলতে চান?' : 'Delete this contact?';
  String get contactsDeleteBtn => isBangla ? 'মুছুন' : 'Delete';
  String get contactsEmailOptional =>
      isBangla ? 'ইমেইল অ্যাড্রেস (ঐচ্ছিক)' : 'Email Address (Optional)';
  String get contactsInfoDesc => isBangla
      ? 'জরুরি সময়ে এই যোগাযোগকারীদের SMS ও নোটিফিকেশন পাঠানো হবে। ড্র্যাগ করে অগ্রাধিকার পরিবর্তন করুন।'
      : 'These contacts will receive SMS and notifications in an emergency. Drag to reorder priority.';
  String get contactsNewContact => isBangla ? 'নতুন কন্টাক্ট' : 'New Contact';
  String get contactsNameHint =>
      isBangla ? 'ব্যক্তির নাম লিখুন' : 'Enter person\'s name';
  String get contactsNameReq => isBangla ? 'নাম প্রয়োজন' : 'Name required';
  String get contactsPhoneHint => isBangla ? '01XXXXXXXXX' : '01XXXXXXXXX';
  String get contactsPhoneReq =>
      isBangla ? 'ফোন নম্বর প্রয়োজন' : 'Phone number required';
  String get contactsPhoneInvalid =>
      isBangla ? 'সঠিক ফোন নম্বর লিখুন' : 'Enter valid phone number';
  String get contactsRelationHint => isBangla
      ? 'যেমন: বাবা, মা, ভাই, বন্ধু'
      : 'e.g. Father, Mother, Brother, Friend';
  String get contactsRelationReq =>
      isBangla ? 'সম্পর্ক উল্লেখ করুন' : 'Please mention relation';
  String get contactsPriorityLevel =>
      isBangla ? 'অগ্রাধিকার লেভেল' : 'Priority Level';
  String get contactsPriorityDesc => isBangla
      ? '১ নং অগ্রাধিকার সবচেয়ে বেশি গুরুত্বপূর্ণ।'
      : '#1 priority is the most important.';
  String get contactsNotifType =>
      isBangla ? 'বিজ্ঞপ্তির ধরণ' : 'Notification Type';
  String get contactsNotifySMS =>
      isBangla ? 'SMS এর মাধ্যমে জানান' : 'Notify via SMS';
  String get contactsNotifyApp =>
      isBangla ? 'অ্যাপ বিজ্ঞপ্তির মাধ্যমে জানান' : 'Notify via App';
  String get contactsAddedToast =>
      isBangla ? 'নতুন কন্টাক্ট যোগ করা হয়েছে।' : 'New contact added.';

  // ===================== Earthquake =====================
  String get earthquakeTitle =>
      isBangla ? 'ভূমিকম্প সতর্কতা' : 'Earthquake Alerts';
  String get earthquakeOffline =>
      isBangla ? 'ইন্টারনেট সংযোগ নেই' : 'No Internet Connection';
  String get earthquakeOfflineMessage => isBangla
      ? 'ভূমিকম্প সতর্কতা দেখতে ইন্টারনেট সংযোগ চালু করুন'
      : 'Turn on internet to see earthquake alerts';
  String get earthquakeLocPermission => isBangla
      ? 'লোকেশন পারমিশন প্রয়োজন। অনুগ্রহ করে সেটিংস থেকে অনুমতি দিন।'
      : 'Location permission required. Please allow from settings.';
  String get earthquakeSettings => isBangla ? 'সেটিংস' : 'Settings';
  String get earthquakeAlertTitle =>
      isBangla ? '⚠️ বিপদ সংকেত!' : '⚠️ Danger Alert!';
  String get earthquakeAlertMessage => isBangla
      ? 'উচ্চ মাত্রার ভূমিকম্প শনাক্ত হয়েছে! নিরাপদ স্থানে যান!'
      : 'High magnitude earthquake detected! Move to safe place!';
  String get earthquakeUnderstood => isBangla ? 'বুঝেছি' : 'Understood';
  String get earthquakeEmpty =>
      isBangla ? 'কোনো সাম্প্রতিক ভূমিকম্প নেই' : 'No recent earthquakes';
  String get earthquakeNearby =>
      isBangla ? 'আপনার কাছাকাছি (৩০০০ কি.মি)' : 'Near You (3000 km)';
  String get earthquakeGlobal => isBangla
      ? 'বিশ্বের বড় ভূমিকম্প (টপ ৫)'
      : 'Global Major Earthquakes (Top 5)';
  String get earthquakeNearbyStat => isBangla ? 'কাছাকাছি' : 'Nearby';
  String get earthquakeMaxMag => isBangla ? 'সর্বোচ্চ মাত্রা' : 'Max Magnitude';
  String get earthquakeMag45 => isBangla ? '৪.৫+ মাত্রা' : '4.5+ Magnitude';
  String get earthquakeAway => isBangla ? 'কি.মি. দূরে' : 'km away';
  String get earthquakeServerError =>
      isBangla ? 'সার্ভারে সমস্যা হয়েছে' : 'Server error';

  // ===================== Toast Messages =====================
  String get toastCheckinSuccess =>
      isBangla ? 'চেক-ইন সফল হয়েছে! ✓' : 'Check-in successful! ✓';
  String get toastCheckinFail =>
      isBangla ? 'চেক-ইন ব্যর্থ হয়েছে:' : 'Check-in failed:';
  String get toastMoodSaved => isBangla ? 'মেজাজ সেভ হয়েছে ✓' : 'Mood saved ✓';
  String get toastMoodSavedOffline => isBangla
      ? 'মেজাজ স্থানীয়ভাবে সেভ হয়েছে (ইন্টারনেট পেলে সিঙ্ক হবে) ✓'
      : 'Mood saved locally (will sync online) ✓';
  String get toastMoodWait => isBangla
      ? '⏳ প্রতি ঘণ্টায় একবার মেজাজ সেভ করতে পারবেন। আবার চেষ্টা করুন।'
      : '⏳ You can save your mood once per hour. Please wait.';
  String get toastMoodFail =>
      isBangla ? 'মেজাজ সেভ ব্যর্থ হয়েছে' : 'Failed to save mood';

  // ===================== Auth =====================
  String get loginTitle => isBangla ? 'লগইন করুন' : 'Login';
  String get loginSubtitle =>
      isBangla ? 'আপনার অ্যাকাউন্টে প্রবেশ করুন' : 'Access your account';
  String get loginEmail => isBangla ? 'ইমেইল' : 'Email';
  String get loginPassword => isBangla ? 'পাসওয়ার্ড' : 'Password';
  String get loginButton => isBangla ? 'লগইন' : 'Login';
  String get loginWrongPassword => isBangla
      ? 'আপনার পাসওয়ার্ড ভুল হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।'
      : 'Incorrect password. Please try again.';
  String get loginNoAccount =>
      isBangla ? 'অ্যাকাউন্ট নেই? রেজিস্ট্রেশন করুন' : 'No account? Register';
  String get loginForgotPass =>
      isBangla ? 'পাসওয়ার্ড ভুলে গেছেন?' : 'Forgot Password?';

  String get regTitle => isBangla ? 'নতুন অ্যাকাউন্ট' : 'New Account';
  String get regSubtitle =>
      isBangla ? 'তথ্য দিয়ে ফর্মটি পূরণ করুন' : 'Fill the form with info';
  String get regName => isBangla ? 'নাম' : 'Name';
  String get regEmail => isBangla ? 'ইমেইল' : 'Email';
  String get regPhone => isBangla ? 'ফোন নম্বর' : 'Phone Number';
  String get regPassword => isBangla ? 'পাসওয়ার্ড' : 'Password';
  String get regConfirmPass =>
      isBangla ? 'পাসওয়ার্ড নিশ্চিত করুন' : 'Confirm Password';
  String get regButton => isBangla ? 'রেজিস্ট্রেশন' : 'Register';
  String get regHaveAccount =>
      isBangla ? 'অ্যাকাউন্ট আছে? লগইন করুন' : 'Have account? Login';
  String get regSuccess =>
      isBangla ? 'রেজিস্ট্রেশন সফল হয়েছে!' : 'Registration successful!';

  String get forgotTitle =>
      isBangla ? 'পাসওয়ার্ড পুনরুদ্ধার' : 'Forgot Password';
  String get forgotSubtitle =>
      isBangla ? 'আপনার ইমেইল অ্যাড্রেস লিখুন' : 'Enter your email address';
  String get forgotSendOTP => isBangla ? 'OTP পাঠান' : 'Send OTP';
  String get forgotOTPSubtitle => isBangla
      ? 'আপনার ইমেইলে প্রেরিত কোডটি লিখুন'
      : 'Enter the code sent to your email';
  String get forgotVerifyOTP => isBangla ? 'OTP যাচাই করুন' : 'Verify OTP';
  String get forgotNewPassSubtitle =>
      isBangla ? 'নতুন পাসওয়ার্ড সেট করুন' : 'Set new password';
  String get forgotResetSuccess => isBangla
      ? 'পাসওয়ার্ড পরিবর্তন সফল হয়েছে!'
      : 'Password reset successful!';

  // ===================== Onboarding =====================
  String get onbTitle1 => isBangla ? 'আপনি কি ঠিক আছেন?' : 'Are You Okay?';
  String get onbDesc1 => isBangla
      ? 'প্রতিদিন চেক-ইন করে আপনার পরিবারকে জানান আপনি নিরাপদ আছেন।'
      : 'Let your family know you\'re safe with daily check-ins.';
  String get onbTitle2 => isBangla ? 'জরুরি SOS সেবা' : 'Emergency SOS';
  String get onbDesc2 => isBangla
      ? 'বিপদে পড়লে এক ক্লিকেই আপনার অবস্থান প্রিয়জনদের কাছে পৌঁছে যাবে।'
      : 'Share your location with loved ones instantly in danger.';
  String get onbTitle3 =>
      isBangla ? 'স্মার্ট স্বাস্থ্য সহকারী' : 'Smart Health Assistant';
  String get onbDesc3 => isBangla
      ? 'আপনার মেজাজ ট্র্যাক করুন এবং AI সহকারীর কাছ থেকে পরামর্শ নিন।'
      : 'Track your mood and get advice from AI assistant.';
  String get onbGetStarted => isBangla ? 'শুরু করুন' : 'Get Started';
  String get onbNext => isBangla ? 'পরবর্তী' : 'Next';

  // ===================== Notifications =====================
  String get notifTitle => isBangla ? 'নোটিফিকেশন' : 'Notifications';
  String get notifEmpty =>
      isBangla ? 'কোনো নতুন নোটিফিকেশন নেই' : 'No new notifications';
  String get notifMarkRead =>
      isBangla ? 'সব পঠিত হিসেবে চিহ্নিত করুন' : 'Mark all as read';
  String get notifClearAll => isBangla ? 'সব মুছে ফেলুন' : 'Clear all';

  // ===================== Profile / Edit =====================
  String get profileDefaultUser => isBangla ? 'ব্যবহারকারী' : 'User';
  String get profileTotalCheckins =>
      isBangla ? 'মোট চেক-ইন' : 'Total Check-ins';
  String get profileActiveDays => isBangla ? 'সক্রিয় দিন' : 'Active Days';
  String get profileEdit => isBangla ? 'প্রোফাইল সম্পাদনা' : 'Edit Profile';
  String get profileChangePic =>
      isBangla ? 'ছবি পরিবর্তন করুন' : 'Change Picture';
  String get profileFullName => isBangla ? 'সম্পূর্ণ নাম' : 'Full Name';
  String get profileNameHint =>
      isBangla ? 'আপনার নাম লিখুন' : 'Enter your name';
  String get profileNameReq => isBangla ? 'নাম প্রয়োজন' : 'Name required';
  String get profileEmailOpt =>
      isBangla ? 'ইমেইল (ঐচ্ছিক)' : 'Email (Optional)';
  String get profileEmailHint =>
      isBangla ? 'আপনার ইমেইল লিখুন' : 'Enter your email';
  String get profileAddress => isBangla ? 'ঠিকানা' : 'Address';
  String get profileAddressHint =>
      isBangla ? 'আপনার বর্তমান ঠিকানা লিখুন' : 'Enter your current address';
  String get profileBloodGroup => isBangla ? 'রক্তের গ্রুপ' : 'Blood Group';
  String get profileSaveInfo =>
      isBangla ? 'তথ্য সংরক্ষণ করুন' : 'Save Information';
  String get profileUpdateSuccess => isBangla
      ? 'আপনার প্রোফাইল সফলভাবে আপডেট করা হয়েছে।'
      : 'Profile updated successfully.';
  String get profileUpdateFail =>
      isBangla ? 'প্রোফাইল আপডেট ব্যর্থ:' : 'Profile update failed:';
  String get profileOfflineWarning => isBangla
      ? 'ইন্টারনেট সংযোগ নেই। প্রোফাইল আপডেট করতে ইন্টারনেট চালু করুন।'
      : 'No internet. Turn on internet to update your profile.';

  // ===================== AI Chat =====================
  String get aiChatTitle =>
      isBangla ? 'AI স্বাস্থ্য সহকারী' : 'AI Health Assistant';
  String get aiChatTyping => isBangla ? 'টাইপ করছে...' : 'Typing...';
  String get aiChatInputHint =>
      isBangla ? 'বার্তা লিখুন...' : 'Type a message...';
  String get aiChatWelcome => isBangla
      ? 'আস্সালামু আলাইকুম! আমি আপনার AI স্বাস্থ্য সহকারী। 🩺\n\nআপনার শারীরিক বা মানসিক স্বাস্থ্য সম্পর্কে যেকোনো প্রশ্ন করতে পারেন।\n\n⚠️ দ্রষ্টব্য: আমি কোনো ডাক্তার নই। গুরুতর সমস্যায় অবশ্যই ডাক্তারের পরামর্শ নিন।'
      : 'Hello! I am your AI Health Assistant. 🩺\n\nYou can ask me anything about your physical or mental health.\n\n⚠️ Note: I am not a doctor. Please consult a doctor for serious issues.';
  String get aiChatOffline => isBangla
      ? 'ইন্টারনেট সংযোগ নেই। AI সহকারী ব্যবহার করতে ইন্টারনেট চালু করুন।'
      : 'No internet connection. Turn on internet to use the AI Assistant.';
  String get aiChatError => isBangla
      ? 'দুঃখিত, একটি সমস্যা হয়েছে। ইন্টারনেট সংযোগ চেক করে আবার চেষ্টা করুন।'
      : 'Sorry, an error occurred. Please check your internet connection and try again.';

  // ===================== Fake Call =====================
  String get fcTitle => isBangla ? 'ফেক কল' : 'Fake Call';
  String get fcCallerSelection => isBangla ? 'কলার নির্বাচন' : 'Select Caller';
  String get fcCallerFriend => isBangla ? 'বন্ধু' : 'Friend';
  String get fcCallerMom => isBangla ? 'মা' : 'Mom';
  String get fcCallerDad => isBangla ? 'বাবা' : 'Dad';
  String get fcCallerBoss => isBangla ? 'বস' : 'Boss';
  String get fcCallerPolice => isBangla ? 'পুলিশ' : 'Police';
  String get fcCustomCaller => isBangla ? 'অথবা কাস্টম' : 'Or Custom';
  String get fcCallerName => isBangla ? 'কলারের নাম' : 'Caller Name';
  String get fcCallerNumber => isBangla ? 'কলারের নম্বর' : 'Caller Number';
  String get fcDelay => isBangla ? 'বিলম্ব' : 'Delay';
  String get fcSecondsLiteral => isBangla ? 'সেকেন্ড' : 'Seconds';
  String get fcSecondsLater =>
      isBangla ? 'সেকেন্ড পরে কল আসবে' : 'Seconds later call will arrive';
  String get fcStartCall => isBangla ? 'ফেক কল শুরু' : 'Start Fake Call';
  String get fcCallIncoming =>
      isBangla ? 'সেকেন্ড পরে কল আসবে...' : 'seconds until call arrives...';
  String get fcAccept => isBangla ? 'গ্রহণ' : 'Accept';
  String get fcDecline => isBangla ? 'হটান' : 'Decline';
  String get fcMissedCall => isBangla ? 'মিসড কল' : 'Missed Call';
  String get fcCallBack => isBangla ? 'কল ব্যাক' : 'Call Back';
}
