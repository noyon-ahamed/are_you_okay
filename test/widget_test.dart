import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:are_you_okay/presentation/screens/auth/login_screen.dart';
import 'package:are_you_okay/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:are_you_okay/services/shared_prefs_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefsService().init();
  });

  testWidgets('login screen renders primary auth content',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('Are You Okay?'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('onboarding screen renders first step CTA',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}
