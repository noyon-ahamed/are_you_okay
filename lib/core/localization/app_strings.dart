import '../constants/app_constants.dart';

/// AppStrings
/// Centralized localization strings for English and Bangla.
/// Usage: AppStrings.of(context).homeTitle
class AppStrings {
  final String lang;
  const AppStrings({required this.lang});

  bool get isBangla => lang == 'bn';

  // ===================== Common =====================
  String get appName => isBangla ? 'আপনি কি ঠিক আছেন?' : 'Are You Okay?';
  String get appTagline => isBangla
      ? 'আপনার নিরাপত্তা, আমাদের দায়িত্ব'
      : 'Your safety, our responsibility';
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

  String get validationRequired => isBangla ? 'প্রয়োজন' : 'required';
  String get validationEmailInvalid =>
      isBangla ? 'সঠিক ইমেইল লিখুন' : 'Enter valid email';
  String get validationPassLength =>
      isBangla ? 'কমপক্ষে ৬ অক্ষর প্রয়োজন' : 'At least 6 characters required';
  String get validationPassMatch =>
      isBangla ? 'পাসওয়ার্ড মিলছে না' : 'Passwords do not match';
  String get validationPhoneReq =>
      isBangla ? 'ফোন নম্বর প্রয়োজন' : 'Phone number required';

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
  String get moodHappy => isBangla ? 'চমৎকার' : 'Great';
  String get moodGood => isBangla ? 'ভালো' : 'Good';
  String get moodNeutral => isBangla ? 'ঠিকঠাক' : 'Neutral';
  String get moodSad => isBangla ? 'খারাপ' : 'Sad';
  String get moodAnxious => isBangla ? 'চিন্তিত' : 'Anxious';

  List<String> get moodLabels => [
        moodHappy,
        moodGood,
        moodNeutral,
        moodSad,
        moodAnxious,
      ];

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
      isBangla ? 'ইতিহাস ডাউনলোড' : 'Download history';

  String get settingsClearCache => isBangla ? 'ক্যাশ পরিষ্কার' : 'Clear Cache';
  String get settingsClearCacheDesc =>
      isBangla ? 'স্থানীয় ডেটা পরিষ্কার করুন' : 'Clear local data';

  String get settingsAboutApp => isBangla ? 'অ্যাপ সম্পর্কে' : 'About App';
  String get settingsPrivacy => isBangla ? 'গোপনীয়তা নীতি' : 'Privacy Policy';
  String get settingsDeleteAccount =>
      isBangla ? 'অ্যাকাউন্ট মুছে ফেলুন' : 'Delete Account';
  String get settingsDeleteAccountDesc => isBangla
      ? 'আপনার সব তথ্য চিরতরে মুছে ফেলুন'
      : 'Permanently delete your account';

  String get aboutAppContent => isBangla
      ? 'Are You Okay? - আপনার অল-ইন-ওয়ান সুরক্ষা এবং সুস্বাস্থ্য সঙ্গী।\n\nপ্রধান বৈশিষ্ট্যসমূহ:\n• নিয়মিত সুরক্ষা চেক-ইন এবং স্ট্রিক ট্র্যাকিং\n• তাৎক্ষণিক SOS অ্যালার্ট ও লোকেশন শেয়ারিং\n• AI স্বাস্থ্য সহকারী (মানসিক ও শারীরিক পরামর্শ)\n• মেজাজ এবং মানসিক স্বাস্থ্যের বিস্তারিত ইতিহাস\n• রিয়েল-টাইম ভূমিকম্প সতর্কতা (USGS ডেটা)\n• ফেক কল (অসুরক্ষিত পরিস্থিতিতে আত্মরক্ষার জন্য)\n• প্রফেশনাল হেলথ রিপোর্ট (PDF) এক্সপোর্ট\n\nআমাদের লক্ষ্য হলো আধুনিক টেকনোলজির মাধ্যমে আপনার এবং আপনার প্রিয়জনদের জীবনকে নিরাপদ ও সহজ করা।'
      : 'Are You Okay? - Your all-in-one safety and wellness companion.\n\nKey Features:\n• Regular Safety Check-ins & Streak Tracking\n• Instant SOS Alerts & Location Sharing\n• AI Health Assistant (Mental & Physical advice)\n• Detailed Mood & Mental Health History\n• Real-time Earthquake Alerts (USGS Data)\n• Fake Call (For safety in uncomfortable situations)\n• Professional Health Reports (PDF) Export\n\nOur mission is to use modern technology to keep you and your loved ones safe and healthy every day.';

  String get privacyPolicyContent => isBangla
      ? 'আপনার তথ্যের গোপনীয়তা এবং নিরাপত্তা আমাদের কাছে সর্বোচ্চ অগ্রাধিকার।\n\n১. ডেটা সংগ্রহ: আপনার প্রোফাইল, চেক-ইন, মুড এবং AI চ্যাট হিস্ট্রি আমাদের এনক্রিপ্টেড সার্ভারে সুরক্ষিত থাকে।\n২. লোকেশন এক্সেস: শুধুমাত্র SOS অ্যালার্ট এবং ভূমিকম্প সতর্কতার নির্ভুলতার জন্য আপনার অনুমতি সাপেক্ষে লোকেশন ব্যবহার করা হয়।\n৩. নিরাপদ ব্যবহার: আমরা কখনই আপনার ব্যক্তিগত তথ্য তৃতীয় পক্ষের কাছে বিক্রি বা শেয়ার করি না।\n৪. ডেটা নিয়ন্ত্রণ: আপনি যেকোনো সময় লোকাল ক্যাশ সাফ করতে পারেন অথবা "Account Delete" অপশন ব্যবহার করে সার্ভার থেকে আপনার সমস্ত তথ্য চিরতরে মুছে ফেলতে পারেন।\n৫. নিরাপত্তা: আপনার সমস্ত সেনসিটিভ ডেটা ইন্ডাস্ট্রি-স্ট্যান্ডার্ড এনক্রিপশন প্রোটোকল দ্বারা সুরক্ষিত।'
      : 'Your privacy and security are our highest priorities.\n\n1. Data Collection: Your profile, check-ins, moods, and AI chat history are securely stored on our encrypted servers.\n2. Location Usage: Location data is only accessed with your permission for SOS alerts and accurate earthquake warnings.\n3. Safe Usage: We never sell or share your personal information with third parties.\n4. Data Control: You can clear local cache anytime or use the "Delete Account" option to permanently wipe all your data from our servers.\n5. Security: All sensitive data is protected using industry-standard encryption protocols.';

  String get settingsTheme => isBangla ? 'থিম' : 'Theme';
  String get settingsThemeLight => isBangla ? 'হালকা' : 'Light';
  String get settingsThemeDark => isBangla ? 'গাঢ়' : 'Dark';
  String get settingsThemeSystem => isBangla ? 'সিস্টেম' : 'System';

  String get settingsLogout => isBangla ? 'লগআউট' : 'Logout';
  String get settingsLogoutConfirm =>
      isBangla ? 'আপনি কি লগআউট করতে চান?' : 'Do you want to logout?';
  String get settingsClearData => isBangla ? 'ডেটা সাফ করুন' : 'Clear Data';
  String get settingsClearDataConfirm => isBangla
      ? 'চেক-ইন, মুড, কন্টাক্ট এবং নোটিফিকেশন ক্যাশ মুছে যাবে। আপনার অ্যাকাউন্ট নিরাপদ থাকবে।'
      : 'Check-in, mood, contacts, and notification cache will be deleted. Your account is safe.';
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

  String get settingsVoiceSOS => isBangla ? 'ভয়েস SOS (চিৎকার শনাক্তকরণ)' : 'Voice SOS (Scream Detection)';
  String get settingsVoiceSOSDesc => isBangla 
      ? 'খুব জোরে চিৎকার করলে এটি অটোমেটিক SOS অ্যালার্ট চালু করবে' 
      : 'Triggers SOS automatically if a loud scream is detected';
  String get settingsVoiceSOSPermission => isBangla
      ? 'এই ফিচারের জন্য মাইক্রোফোন পারমিশন প্রয়োজন'
      : 'Microphone permission is required for this feature';

  String get settingsVoiceSOSPopupTitle => isBangla
      ? 'মাইক্রোফোন অ্যাক্সেস'
      : 'Microphone Access';

  String get settingsVoiceSOSPopupBody => isBangla
      ? 'ভয়েস SOS জরুরি অবস্থায় চিৎকার শনাক্ত করতে মাইক্রোফোন ব্যবহার করে। আপনার গোপনীয়তা আমাদের কাছে গুরুত্বপূর্ণ; অ্যাপটি শুধু শব্দের উচ্চতা পরীক্ষা করে, কোনো ভয়েস রেকর্ড বা সেভ করে না।'
      : 'Voice SOS uses the microphone to detect loud screams in emergency situations. Your privacy is important; the app only listens for volume levels and does not record or store your voice.';

  // Dialog Actions
  String get dialogCancel => isBangla ? 'বাতিল' : 'Cancel';
  String get dialogClose => isBangla ? 'বন্ধ করুন' : 'Close';
  String get dialogClear => isBangla ? 'পরিষ্কার করুন' : 'Clear';
  String get dialogLogout => isBangla ? 'লগআউট' : 'Logout';
  String get settingsDeleteAccountConfirm =>
      isBangla ? 'অ্যাকাউন্ট মুছুন' : 'Delete Account';
  String get settingsDeleteAccountWarning => isBangla
      ? 'আপনি কি নিশ্চিত? আপনার সব ডেটা চিরতরে মুছে যাবে এবং এটি ফিরে পাওয়া সম্ভব নয়।'
      : 'Are you sure? All your data will be permanently deleted and this cannot be undone.';

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
  String get contactsEmailMissedAlert => isBangla
      ? 'ইমেইল (চেক-ইন মিস করলে অ্যালার্ট পাবে)'
      : 'Email (will get alert if check-in missed)';
  String get contactsNewContact => isBangla ? 'নতুন কন্টাক্ট' : 'New Contact';
  String get contactsNameHint =>
      isBangla ? 'যার সাথে যোগাযোগ করা হবে তার পূর্ণ নাম লিখুন' : 'Enter the full name of your trusted contact';
  String get contactsNameReq => isBangla ? 'নাম প্রয়োজন' : 'Name required';
  String get contactsPhoneHint => isBangla
      ? '১১ সংখ্যার নম্বর লিখুন, যেমন 017XXXXXXXX'
      : 'Enter an 11-digit number, e.g. 017XXXXXXXX';
  String get contactsPhoneReq =>
      isBangla ? 'ফোন নম্বর প্রয়োজন' : 'Phone number required';
  String get contactsPhoneInvalid =>
      isBangla ? 'সঠিক ফোন নম্বর লিখুন' : 'Enter valid phone number';
  String get contactsRelationHint => isBangla
      ? 'যেমন: মা, বাবা, ভাই, বোন, বন্ধু'
      : 'e.g. Mother, Father, Sister, Brother, Friend';
  String get contactsRelationReq =>
      isBangla ? 'সম্পর্ক উল্লেখ করুন' : 'Please mention relation';
  String get contactsPriorityLevel =>
      isBangla ? 'অগ্রাধিকার লেভেল' : 'Priority Level';
  String get contactsPriorityDesc => isBangla
      ? '১ নং অগ্রাধিকার সবচেয়ে বেশি গুরুত্বপূর্ণ।'
      : '#1 priority is the most important.';
  String get contactsNotifType =>
      isBangla ? 'অ্যালার্ট পাঠানোর মাধ্যম' : 'Alert Methods';
  String get contactsNotifySMS =>
      isBangla ? 'SMS এর মাধ্যমে জানান' : 'Notify via SMS';
  String get contactsNotifyEmail =>
      isBangla ? 'ইমেইলের মাধ্যমে জানান' : 'Notify via Email';
  String get contactsAddedToast =>
      isBangla ? 'নতুন কন্টাক্ট যোগ করা হয়েছে।' : 'New contact added.';
  String get contactsLimitTitle =>
      isBangla ? 'কন্টাক্ট সীমা পূর্ণ' : 'Contact limit reached';
  String contactsLimitMessage([int max = AppConstants.maxEmergencyContacts]) =>
      isBangla
          ? 'আপনি সর্বোচ্চ $max টি জরুরি কন্টাক্ট যোগ করতে পারবেন।'
          : 'You can add up to $max emergency contacts only.';
  String contactsCounterLabel(int count,
          [int max = AppConstants.maxEmergencyContacts]) =>
      isBangla ? '$count / $max কন্টাক্ট যোগ করা হয়েছে' : '$count / $max contacts added';
  String get contactsReminderTitle => isBangla
      ? 'জরুরি কন্টাক্ট যোগ করুন'
      : 'Add emergency contacts';
  String get contactsReminderMessage => isBangla
      ? 'আপনার নিরাপত্তার জন্য কমপক্ষে একটি জরুরি কন্টাক্ট যোগ করা দরকার। এখনই যোগ করলে SOS ও missed check-in alert দ্রুত পাঠানো যাবে।'
      : 'For your safety, please add at least one emergency contact. This helps SOS and missed check-in alerts reach someone quickly.';
  String get contactsReminderAdd =>
      isBangla ? 'এখন যোগ করুন' : 'Add';
  String get contactsReminderLater =>
      isBangla ? 'পরে' : 'Later';
  String get contactsFormIntro => isBangla
      ? 'বিশ্বস্ত মানুষের তথ্য দিন। সর্বোচ্চ ৫টি কন্টাক্ট যোগ করা যাবে।'
      : 'Add trusted people here. You can save up to 5 contacts.';

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
  String get earthquakeNearbyStat => isBangla ? 'কাছাকাছি' : 'Nearby';
  String get earthquakeTabNear => isBangla ? 'আপনার কাছে' : 'Near You';
  String earthquakeTabNearWithRadius([int radiusKm = 3000]) =>
      isBangla ? 'আপনার কাছে ($radiusKm km)' : 'Near You ($radiusKm km)';
  String get earthquakeTabGlobal =>
      isBangla ? 'শীর্ষ ৫ বৈশ্বিক' : 'Top 5 Global';
  String get earthquakeMaxMag => isBangla ? 'সর্বোচ্চ মাত্রা' : 'Max Magnitude';
  String get earthquakeMag45 => isBangla ? '৪.৫+ মাত্রা' : '4.5+ Magnitude';
  String get earthquakeAway => isBangla ? 'কি.মি. দূরে' : 'km away';
  String get earthquakeServerError =>
      isBangla ? 'সার্ভারে সমস্যা হয়েছে' : 'Server error';
  String get earthquakeCachedData => isBangla
      ? 'নতুন ডাটা আনার সময় আপাতত সর্বশেষ সংরক্ষিত ভূমিকম্প তথ্য দেখানো হচ্ছে।'
      : 'Showing the last saved earthquake data while refreshing.';
  String get earthquakeLocTitle => isBangla ? 'লোকেশন চালু করুন' : 'Turn on location';
  String get earthquakeLocBody => isBangla
      ? 'ভূমিকম্প স্ক্রিন দেখতে হলে লোকেশন অন এবং পারমিশন দেয়া লাগবে। এতে আপনার দেশ, Near You, আর সতর্কবার্তা ঠিকমতো কাজ করবে।'
      : 'Earthquake alerts need location access to show your country, Near You data, and send accurate alerts.';
  String get earthquakeTabCountry => isBangla ? 'দেশ' : 'Country';
  String earthquakeCountryRecent(String country) => isBangla
      ? '$country দেশের সাম্প্রতিক ভূমিকম্প'
      : 'Recent earthquakes in $country';
  String earthquakeNearMeRecent(int radius) => isBangla
      ? '$radius কিমির মধ্যে থাকা ভূমিকম্প কাছেরটি আগে দেখানো হচ্ছে'
      : 'Showing earthquakes within $radius km, closest first';
  String get earthquakeGlobalRecent => isBangla ? 'বিশ্বজুড়ে বড় ভূমিকম্প' : 'Major earthquakes worldwide';

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
  String get loginUserNotFound => isBangla
      ? 'এই ইমেইল দিয়ে কোনো অ্যাকাউন্ট পাওয়া যায়নি। অনুগ্রহ করে সঠিক ইমেইল দিন বা রেজিস্টার করুন।'
      : 'No account found with this email. Please check your email or register.';
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
  String get forgotOtpSent => isBangla
      ? 'আপনার ইমেইলে একটি OTP পাঠানো হয়েছে'
      : 'An OTP has been sent to your email';
  String get forgotOtpVerified =>
      isBangla ? 'OTP যাচাই সফল হয়েছে!' : 'OTP verified successfully!';
  String get forgotOtpInvalid =>
      isBangla ? 'ভুল বা মেয়াদোত্তীর্ণ OTP কোড' : 'Invalid or expired OTP code';
  String get forgotNewPassword => isBangla ? 'নতুন পাসওয়ার্ড' : 'New Password';
  String get forgotResetButton =>
      isBangla ? 'পাসওয়ার্ড রিসেট করুন' : 'Reset Password';
  String get forgotOtpCode => isBangla ? 'OTP কোড' : 'OTP Code';
  String get forgotOtpHint => isBangla ? '৬ সংখ্যার কোড' : '6-digit code';
  String get forgotResendOtp => isBangla ? 'আবার OTP পাঠান' : 'Resend OTP';
  String get forgotRemembered => isBangla ? 'মনে পড়েছে? ' : 'Remembered? ';

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
  String get onbSkip => isBangla ? 'এড়িয়ে যান' : 'Skip';
  String get onbStatDailySafety =>
      isBangla ? 'দৈনিক সেফটি চেক' : 'Daily safety check';
  String get onbStatRealtimeLocation =>
      isBangla ? 'রিয়েল-টাইম লোকেশন' : 'Real-time location';
  String get onbStatEmergencySupport =>
      isBangla ? 'জরুরি সাহায্য' : 'Emergency support';
  String get onbSafetyOneTap => isBangla
      ? 'আপনার নিরাপত্তা সবসময় পাশে থাকবে'
      : 'Your safety stays one tap away';
  String get onbFeatureCheckin => isBangla ? 'চেক-ইন' : 'Check-in';
  String get onbFeatureAlerts => isBangla ? 'সতর্কতা' : 'Alerts';

  // ===================== Notifications =====================
  String get notifTitleDefault => isBangla ? 'সতর্কতা' : 'Alert';
  String get notifEarthquakeTitle =>
      isBangla ? 'ভূমিকম্প সতর্কতা' : 'Earthquake Alert';
  String get notifEmergencyTitle =>
      isBangla ? 'জরুরি সতর্কতা' : 'Emergency Alert';
  String get notifTitle => isBangla ? 'নোটিফিকেশন' : 'Notifications';
  String get notifEmpty =>
      isBangla ? 'কোনো নতুন নোটিফিকেশন নেই' : 'No new notifications';
  String get notifMarkRead =>
      isBangla ? 'সব পঠিত হিসেবে চিহ্নিত করুন' : 'Mark all as read';
  String get notifClearAll => isBangla ? 'সব মুছে ফেলুন' : 'Clear all';
  String get notifSettingsTitle =>
      isBangla ? 'বিজ্ঞপ্তি সেটিংস' : 'Notification Settings';
  String get notifPushTitle =>
      isBangla ? 'পুশ বিজ্ঞপ্তি' : 'Push Notifications';
  String get notifPushSubtitle => isBangla
      ? 'অ্যাপের মাধ্যমে সরাসরি আপডেট পান'
      : 'Get updates directly in the app';
  String get notifSmsTitle => isBangla ? 'SMS অ্যালার্ট' : 'SMS Alerts';
  String get notifSmsSubtitle => isBangla
      ? 'জরুরি অবস্থায় SMS পাঠাতে অনুমতি দিন'
      : 'Allow SMS alerts during emergencies';
  String get notifWellnessTitle =>
      isBangla ? 'ওয়েলনেস রিমাইন্ডার' : 'Wellness Reminders';
  String get notifWellnessSubtitle => isBangla
      ? 'প্রতিদিন সকালে আপনার খোঁজ নেওয়ার জন্য'
      : 'Daily reminder to check on your wellbeing';
  String get notifEmergencyAlertsTitle =>
      isBangla ? 'জরুরি অ্যালার্ট' : 'Emergency Alerts';
  String get notifEmergencyAlertsSubtitle => isBangla
      ? 'গুরুত্বপূর্ণ সুরক্ষা অ্যালার্ট গ্রহণ করুন'
      : 'Receive critical safety alerts';

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
  String get aiChatClear => isBangla ? 'চ্যাট মুছুন' : 'Clear chat';
  String get aiChatDisclaimer => isBangla
      ? 'এটি সাধারণ তথ্যের জন্য। গুরুতর সমস্যায় ডাক্তারের কাছে যান।'
      : 'This is general information only. For serious issues, consult a doctor.';
  List<String> get aiChatSuggestions => isBangla
      ? const [
          '🤕 মাথাব্যথা হচ্ছে',
          '😴 ঘুম হচ্ছে না',
          '😔 মন খারাপ লাগছে',
          '🤒 জ্বর হলে কী করব?',
          '💊 ওষুধ খাওয়ার নিয়ম',
          '🧘 স্ট্রেস কমানোর উপায়',
          '🏃 ব্যায়ামের পরামর্শ',
          '🍎 সুষম খাদ্যতালিকা',
        ]
      : const [
          '🤕 I have a headache',
          '😴 I cannot sleep',
          '😔 I feel low',
          '🤒 What should I do for fever?',
          '💊 How should I take medicine?',
          '🧘 Ways to reduce stress',
          '🏃 Exercise advice',
          '🍎 Balanced diet tips',
        ];

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
  String get fcNotificationPermissionRationale => isBangla
      ? 'কল স্ক্রিন দেখানোর জন্য নোটিফিকেশন পারমিশন প্রয়োজন।'
      : 'Notification permission is required to show the call screen.';
  String get fcNotificationPermissionSettings => isBangla
      ? 'ফেক কল পেতে সেটিংস থেকে নোটিফিকেশন পারমিশন দিন।'
      : 'Please allow notification permission from settings to receive fake calls.';

  // ===================== Splash =====================
  String get splashLoading => isBangla ? 'লোড হচ্ছে...' : 'Loading...';

  // ===================== Extra / Missing =====================
  String get commonOptional => isBangla ? 'ঐচ্ছিক' : 'Optional';
  String get regNameHint => isBangla ? 'আপনার নাম' : 'Your name';
  String get regPassHint =>
      isBangla ? 'কমপক্ষে ৬ অক্ষর' : 'At least 6 characters';
  String get loginNoAccountText =>
      isBangla ? 'অ্যাকাউন্ট নেই? ' : 'No account? ';
  String get regHaveAccountText =>
      isBangla ? 'অ্যাকাউন্ট আছে? ' : 'Have account? ';

  // Notification Channels
  String get channelEmergencyTitle =>
      isBangla ? 'জরুরি সতর্কতা' : 'Emergency Alert';
  String get channelEmergencyDesc => isBangla
      ? 'জরুরি সতর্কতা এবং SOS বিজ্ঞপ্তি'
      : 'Emergency alerts and SOS notifications';
  String get channelCheckinTitle =>
      isBangla ? 'চেক-ইন রিমাইন্ডার' : 'Check-in Reminder';
  String get channelCheckinDesc =>
      isBangla ? 'চেক-ইন করার জন্য রিমাইন্ডার' : 'Reminders for checking in';
  String get channelEarthquakeTitle =>
      isBangla ? 'ভূমিকম্প সাইরেন' : 'Earthquake Siren';
  String get channelEarthquakeDesc => isBangla
      ? 'কাছাকাছি ভূমিকম্পের জন্য সাইরেন সতর্কতা'
      : 'Siren alerts for nearby earthquakes';
  String get channelGeneralTitle => isBangla ? 'তথ্য আপডেট' : 'Info Updates';
  String get channelGeneralDesc =>
      isBangla ? 'সাধারণ তথ্য এবং আপডেট' : 'General info and updates';

  // Offline Sync & Background Alerts
  String get notifMissedCheckinTitle =>
      isBangla ? '🚨 চেক-ইন মিস করেছেন!' : '🚨 Check-in Missed!';
  String get notifMissedCheckinBody => isBangla
      ? 'আপনার চেক-ইনের সময় পার হয়ে গেছে। অনুগ্রহ করে এখনই চেক-ইন করুন যাতে আপনার জরুরি যোগাযোগদের সতর্ক করা না হয়।'
      : 'Your check-in deadline has passed. Please check in now to avoid alerting your emergency contacts.';
  String get notifMissedCheckinHistory => isBangla
      ? 'আপনার চেক-ইনের সময় পার হয়ে গেছে। অনুগ্রহ করে এখনই চেক-ইন করুন।'
      : 'Your check-in deadline has passed. Please check in now.';
  String get notifMissedDeadlineTitle =>
      isBangla ? 'চেক-ইন ডেডলাইন পার হয়েছে' : 'Check-in Deadline Passed';
  String get notifMissedDeadlineBody => isBangla
      ? 'আপনি অনেকক্ষণ ধরে অ্যাপে আসেননি। অনুগ্রহ করে চেক-ইন করুন।'
      : 'You haven\'t used the app in a while. Please check in.';
}
