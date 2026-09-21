import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/core/theme/app_theme.dart';
import 'package:shared_household_planner/features/onboarding/domain/services/onboarding_service.dart';
import 'package:shared_household_planner/features/onboarding/presentation/pages/onboarding_screen.dart';

// ─── Test Localizations ───────────────────────────────────────────────────────

class _TestLoc extends AppLocalizations {
  _TestLoc() : super(const Locale('en'));

  static const _dict = {
    'onboarding_slide1_title': 'Split Bills Effortlessly',
    'onboarding_slide1_desc': 'Track shared expenses, split costs fairly among housemates, and never argue about money again.',
    'onboarding_slide2_title': 'Project-based Budgeting',
    'onboarding_slide2_desc': 'Organize expenses by projects — trips, households, events. Keep every budget neat and separated.',
    'onboarding_slide3_title': 'Smart Debt Settlement',
    'onboarding_slide3_desc': 'Instantly see who owes whom and how much. One-tap settlement tracking for stress-free paybacks.',
    'onboarding_slide4_title': '100% Offline & Private',
    'onboarding_slide4_desc': 'Your data stays on your device. No cloud, no subscriptions — just privacy and full control.',
    'onboarding_skip': 'Skip',
    'onboarding_next': 'Next',
    'onboarding_get_started': 'Get Started',
    'onboarding_language_switch': 'EN | VI',
  };

  @override
  String translate(String key) => _dict[key] ?? key;
}

class _TestLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async => _TestLoc();

  @override
  bool shouldReload(_TestLocDelegate old) => false;
}

Widget _buildApp({
  bool darkMode = false,
  VoidCallback? onFinish,
  bool showFallbackIcon = false,
}) {
  final langProvider = LanguageProvider();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>.value(value: langProvider),
    ],
    child: MaterialApp(
      theme: darkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      localizationsDelegates: const [
        _TestLocDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('vi')],
      home: OnboardingScreen(
        onFinish: onFinish,
        showFallbackIcon: showFallbackIcon,
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    OnboardingService.clearTestOverride();
  });

  group('AC 1 & AC 2: Asset Files and pubspec.yaml Verification', () {
    test('1.1 slide1_split_bills.jpg exists in assets directory', () {
      final file = File('assets/images/onboarding/slide1_split_bills.jpg');
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(0));
    });

    test('1.2 slide2_project_budget.jpg exists in assets directory', () {
      final file = File('assets/images/onboarding/slide2_project_budget.jpg');
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(0));
    });

    test('1.3 slide3_smart_debt.jpg exists in assets directory', () {
      final file = File('assets/images/onboarding/slide3_smart_debt.jpg');
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(0));
    });

    test('1.4 slide4_offline_private.jpg exists in assets directory', () {
      final file = File('assets/images/onboarding/slide4_offline_private.jpg');
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(0));
    });

    test('2.1 pubspec.yaml contains assets/images/onboarding/ path', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec.contains('assets/images/onboarding/'), isTrue);
    });
  });

  group('AC 3: Slide Models and Asset Path Reference', () {
    test('3.1 Exactly 4 slides defined in OnboardingScreen.slides', () {
      expect(OnboardingScreen.slides.length, equals(4));
    });

    test('3.2 Slide 1 references slide1_split_bills.jpg', () {
      final s = OnboardingScreen.slides[0];
      expect(s.imageAsset, equals('assets/images/onboarding/slide1_split_bills.jpg'));
      expect(s.titleKey, equals('onboarding_slide1_title'));
    });

    test('3.3 Slide 2 references slide2_project_budget.jpg', () {
      final s = OnboardingScreen.slides[1];
      expect(s.imageAsset, equals('assets/images/onboarding/slide2_project_budget.jpg'));
      expect(s.titleKey, equals('onboarding_slide2_title'));
    });

    test('3.4 Slide 3 references slide3_smart_debt.jpg', () {
      final s = OnboardingScreen.slides[2];
      expect(s.imageAsset, equals('assets/images/onboarding/slide3_smart_debt.jpg'));
      expect(s.titleKey, equals('onboarding_slide3_title'));
    });

    test('3.5 Slide 4 references slide4_offline_private.jpg', () {
      final s = OnboardingScreen.slides[3];
      expect(s.imageAsset, equals('assets/images/onboarding/slide4_offline_private.jpg'));
      expect(s.titleKey, equals('onboarding_slide4_title'));
    });
  });

  group('AC 4: Image Rendering per Slide', () {
    testWidgets('4.1 Slide 1 renders onboardingImage_0 with proper fit', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final imgFinder = find.byKey(const Key('onboardingImage_0'));
      expect(imgFinder, findsOneWidget);
      final img = tester.widget<Image>(imgFinder);
      expect(img.fit, equals(BoxFit.cover));
    });

    testWidgets('4.2 Advancing to slide 2 renders onboardingImage_1', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboardingNextButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboardingImage_1')), findsOneWidget);
    });

    testWidgets('4.3 Advancing to slide 3 renders onboardingImage_2', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      for (int i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const Key('onboardingNextButton')));
        await tester.pumpAndSettle();
      }

      expect(find.byKey(const Key('onboardingImage_2')), findsOneWidget);
    });

    testWidgets('4.4 Advancing to slide 4 renders onboardingImage_3', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('onboardingNextButton')));
        await tester.pumpAndSettle();
      }

      expect(find.byKey(const Key('onboardingImage_3')), findsOneWidget);
    });
  });

  group('AC 5: Fallback Mechanism', () {
    testWidgets('5.1 Fallback icon container renders when showFallbackIcon is true', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildApp(showFallbackIcon: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboardingFallbackIcon_0')), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_rounded), findsOneWidget);
    });

    testWidgets('5.2 Fallback icons persist through all slides when active', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildApp(showFallbackIcon: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboardingNextButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboardingFallbackIcon_1')), findsOneWidget);
      expect(find.byIcon(Icons.folder_special_rounded), findsOneWidget);
    });
  });

  group('AC 6 & AC 8: Dark and Light Theme Styling & Contrast', () {
    testWidgets('6.1 OnboardingScreen with image assets renders cleanly in light theme', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildApp(darkMode: false));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboardingImage_0')), findsOneWidget);
      expect(find.text('Split Bills Effortlessly'), findsOneWidget);
      expect(find.byKey(const Key('onboardingNextButton')), findsOneWidget);
    });

    testWidgets('8.1 OnboardingScreen with image assets renders cleanly in dark theme', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildApp(darkMode: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboardingImage_0')), findsOneWidget);
      expect(find.text('Split Bills Effortlessly'), findsOneWidget);
      expect(find.byKey(const Key('onboardingNextButton')), findsOneWidget);
    });
  });

  group('AC 7: Navigation & Gestures with Image Assets', () {
    testWidgets('7.1 Swipe gestures navigate slides smoothly with images loaded', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Drag left to advance to slide 2
      await tester.drag(find.byKey(const Key('onboardingPageView')), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Project-based Budgeting'), findsOneWidget);
      expect(find.byKey(const Key('onboardingImage_1')), findsOneWidget);
    });

    testWidgets('7.2 Final slide allows completing onboarding with Get Started', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool completed = false;
      await tester.pumpWidget(_buildApp(onFinish: () => completed = true));
      await tester.pumpAndSettle();

      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('onboardingNextButton')));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byKey(const Key('onboardingGetStartedButton')));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });
  });
}
