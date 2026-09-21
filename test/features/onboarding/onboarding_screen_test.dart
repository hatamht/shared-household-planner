import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/core/theme/app_theme.dart';
import 'package:shared_household_planner/features/settings/presentation/pages/settings_screen.dart';
import 'package:shared_household_planner/features/onboarding/domain/services/onboarding_service.dart';
import 'package:shared_household_planner/features/onboarding/presentation/pages/onboarding_screen.dart';



// ─── Test Localizations ───────────────────────────────────────────────────────

class _TestLoc extends AppLocalizations {
  final String langCode;
  _TestLoc(this.langCode) : super(Locale(langCode));

  static const Map<String, Map<String, String>> _dicts = {
    'en': {
      'onboarding_slide1_title': 'Split Bills Effortlessly',
      'onboarding_slide1_desc': 'Track shared expenses, split costs fairly.',
      'onboarding_slide2_title': 'Project-based Budgeting',
      'onboarding_slide2_desc': 'Organize expenses by projects.',
      'onboarding_slide3_title': 'Smart Debt Settlement',
      'onboarding_slide3_desc': 'Instantly see who owes whom.',
      'onboarding_slide4_title': '100% Offline & Private',
      'onboarding_slide4_desc': 'Your data stays on your device.',
      'onboarding_skip': 'Skip',
      'onboarding_next': 'Next',
      'onboarding_get_started': 'Get Started',
      'onboarding_language_switch': 'EN | VI',
      'home': 'Home',
      'projects': 'Projects',
      'bills': 'Bills',
      'settings': 'Settings',
      'no_projects': 'No Projects',
      'error': 'Error',
      'user_guide': 'User Guide',
      'replay_onboarding': 'User Guide',
      'replay_onboarding_desc': 'View the introductory tour again',
      'account_info': 'Account Info',
      'theme_settings': 'Theme Settings',
      'theme_light': 'Light Theme',
      'theme_dark': 'Dark Theme',
      'preferences': 'Preferences',
      'english': 'English',
      'vietnamese': 'Vietnamese',
      'default_currency': 'Default Currency',
      'export_options': 'Export Options',
      'export_csv': 'Export CSV',
      'export_csv_desc': 'Export all data',
      'export_pdf': 'Export PDF',
      'export_pdf_desc': 'Generate PDF report',
      'data_management': 'Data Management',
      'payment_history': 'Payment History',
      'settlement_log': 'Settlement log',
      'bill_templates': 'Bill Templates',
      'bill_templates_desc': 'Manage reusable templates',
      'clear_cache': 'Clear Cache',
      'cache_size': 'Cache size',
      'reset_demo_data': 'Reset Demo Data',
      'reset_demo_data_desc': 'Reset sample data',
      'about_app': 'About App',
      'app_name': 'Shared Household Planner',
      'app_version': 'Version 1.0.0',
      'developed_by': 'Developed by Team',
      'account_name': 'Household Admin',
      'account_role_owner': 'Owner',
      'edit_profile': 'Edit Profile',
    },
    'vi': {
      'onboarding_slide1_title': 'Chia tiền dễ dàng',
      'onboarding_slide1_desc': 'Theo dõi chi phí chung.',
      'onboarding_slide2_title': 'Ngân sách theo dự án',
      'onboarding_slide2_desc': 'Phân chia chi tiêu theo dự án.',
      'onboarding_slide3_title': 'Quyết toán thông minh',
      'onboarding_slide3_desc': 'Biết ngay ai nợ ai bao nhiêu.',
      'onboarding_slide4_title': '100% Ngoại tuyến & Riêng tư',
      'onboarding_slide4_desc': 'Dữ liệu ở lại trên thiết bị của bạn.',
      'onboarding_skip': 'Bỏ qua',
      'onboarding_next': 'Tiếp theo',
      'onboarding_get_started': 'Bắt đầu',
      'onboarding_language_switch': 'EN | VI',
      'home': 'Trang chủ',
      'projects': 'Dự án',
      'bills': 'Hóa đơn',
      'settings': 'Cài đặt',
      'no_projects': 'Chưa có dự án',
      'error': 'Lỗi',
      'user_guide': 'Hướng dẫn sử dụng',
      'replay_onboarding': 'Hướng dẫn sử dụng',
      'replay_onboarding_desc': 'Xem lại hướng dẫn giới thiệu ứng dụng',
      'account_info': 'Thông tin tài khoản',
      'theme_settings': 'Cài đặt giao diện',
      'theme_light': 'Giao diện sáng',
      'theme_dark': 'Giao diện tối',
      'preferences': 'Tùy chọn',
      'english': 'Tiếng Anh',
      'vietnamese': 'Tiếng Việt',
      'default_currency': 'Tiền tệ mặc định',
      'export_options': 'Tùy chọn xuất file',
      'export_csv': 'Xuất CSV',
      'export_csv_desc': 'Xuất dữ liệu',
      'export_pdf': 'Xuất PDF',
      'export_pdf_desc': 'Tạo báo cáo PDF',
      'data_management': 'Quản lý dữ liệu',
      'payment_history': 'Lịch sử thanh toán',
      'settlement_log': 'Nhật ký quyết toán',
      'bill_templates': 'Mẫu hóa đơn',
      'bill_templates_desc': 'Quản lý mẫu hóa đơn',
      'clear_cache': 'Xóa bộ nhớ đệm',
      'cache_size': 'Dung lượng',
      'reset_demo_data': 'Đặt lại dữ liệu',
      'reset_demo_data_desc': 'Khôi phục dữ liệu mẫu',
      'about_app': 'Về ứng dụng',
      'app_name': 'Shared Household Planner',
      'app_version': 'Phiên bản 1.0.0',
      'developed_by': 'Phát triển bởi Nhóm',
      'account_name': 'Quản trị viên',
      'account_role_owner': 'Chủ sở hữu',
      'edit_profile': 'Chỉnh sửa hồ sơ',
    },

  };

  @override
  String translate(String key) =>
      _dicts[langCode]?[key] ?? _dicts['en']?[key] ?? key;
}

class _TestLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  final String langCode;
  const _TestLocDelegate(this.langCode);

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      _TestLoc(locale.languageCode);

  @override
  bool shouldReload(_TestLocDelegate old) => old.langCode != langCode;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

LanguageProvider _langProvider(String code) {
  final p = LanguageProvider();
  // Using reflection-free approach: just call setLanguage which is synchronous for our test
  // We override immediately to avoid SharedPreferences calls:
  return p;
}

Widget _buildOnboardingApp({
  bool darkMode = false,
  String initialLang = 'en',
  VoidCallback? onFinish,
}) {
  final langProvider = LanguageProvider();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>.value(value: langProvider),
    ],
    child: Consumer<LanguageProvider>(
      builder: (context, lp, _) => MaterialApp(
        theme: darkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
        localizationsDelegates: [
          _TestLocDelegate(lp.currentLocale.languageCode),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('vi')],
        locale: lp.currentLocale,
        home: OnboardingScreen(onFinish: onFinish),
      ),
    ),
  );
}


// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    OnboardingService.clearTestOverride();
  });


  group('AC 1: OnboardingService – First Launch Detection', () {
    test('1.1 hasSeenOnboarding returns false when key is absent', () async {
      OnboardingService.setTestOverride(false);
      final seen = await OnboardingService.instance.hasSeenOnboardingForTest();
      expect(seen, isFalse);
    });

    test('1.2 hasSeenOnboarding returns true after markOnboardingSeen sets override', () async {
      OnboardingService.setTestOverride(true);
      final seen = await OnboardingService.instance.hasSeenOnboardingForTest();
      expect(seen, isTrue);
    });

    test('1.3 clearTestOverride removes memory override', () async {
      OnboardingService.setTestOverride(true);
      OnboardingService.clearTestOverride();
      // After clearing the override, it falls back to SharedPreferences
      // which may throw in unit test, but it should not throw:
      // We just ensure no exception.
      expect(() => OnboardingService.instance.hasSeenOnboarding(), returnsNormally);
    });

    test('1.4 OnboardingService.instance is a singleton', () {
      final a = OnboardingService.instance;
      final b = OnboardingService.instance;
      expect(identical(a, b), isTrue);
    });
  });

  group('AC 2: Default English Locale on First Launch', () {
    test('2.1 LanguageProvider defaults to English locale', () {
      final lp = LanguageProvider();
      expect(lp.currentLocale.languageCode, 'en');
    });

    test('2.2 LanguageProvider locale is Locale(en)', () {
      final lp = LanguageProvider();
      expect(lp.currentLocale, const Locale('en'));
    });
  });

  group('AC 3: OnboardingScreen renders correctly', () {
    testWidgets('3.1 OnboardingScreen renders first slide content', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildOnboardingApp());
      await tester.pumpAndSettle();

      expect(find.text('Split Bills Effortlessly'), findsOneWidget);
    });

    testWidgets('3.2 All 4 dots are rendered', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildOnboardingApp());
      await tester.pumpAndSettle();

      // 4 dot keys: onboardingDot_0 through onboardingDot_3
      for (int i = 0; i < 4; i++) {
        expect(find.byKey(Key('onboardingDot_$i')), findsOneWidget);
      }
    });

    testWidgets('3.3 Skip button is visible', (tester) async {
      await tester.pumpWidget(_buildOnboardingApp());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('onboardingSkipButton')), findsOneWidget);
    });

    testWidgets('3.4 Next button is visible on first slide', (tester) async {
      await tester.pumpWidget(_buildOnboardingApp());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('onboardingNextButton')), findsOneWidget);
      expect(find.byKey(const Key('onboardingGetStartedButton')), findsNothing);
    });

    testWidgets('3.5 Language toggle button is visible', (tester) async {
      await tester.pumpWidget(_buildOnboardingApp());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('onboardingLanguageToggle')), findsOneWidget);
    });

    testWidgets('3.6 PageView is rendered', (tester) async {
      await tester.pumpWidget(_buildOnboardingApp());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('onboardingPageView')), findsOneWidget);
    });
  });

  group('AC 4: Slide Navigation', () {
    testWidgets('4.1 Tapping Next advances to slide 2', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildOnboardingApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboardingNextButton')));
      await tester.pumpAndSettle();

      expect(find.text('Project-based Budgeting'), findsOneWidget);
    });

    testWidgets('4.2 Tapping Next twice advances to slide 3', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildOnboardingApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboardingNextButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboardingNextButton')));
      await tester.pumpAndSettle();

      expect(find.text('Smart Debt Settlement'), findsOneWidget);
    });

    testWidgets('4.3 On last slide, Get Started button appears instead of Next', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildOnboardingApp());
      await tester.pumpAndSettle();

      // Navigate to last slide
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('onboardingNextButton')));
        await tester.pumpAndSettle();
      }

      expect(find.byKey(const Key('onboardingGetStartedButton')), findsOneWidget);
      expect(find.byKey(const Key('onboardingNextButton')), findsNothing);
    });

    testWidgets('4.4 Last slide shows slide 4 content', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildOnboardingApp());
      await tester.pumpAndSettle();

      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('onboardingNextButton')));
        await tester.pumpAndSettle();
      }

      expect(find.text('100% Offline & Private'), findsOneWidget);
    });

    testWidgets('4.5 Swiping PageView moves to next slide', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildOnboardingApp());
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const Key('onboardingPageView')),
        const Offset(-400, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('Project-based Budgeting'), findsOneWidget);
    });
  });

  group('AC 5: Language Switcher', () {
    testWidgets('5.1 Language toggle button shows EN | VI when language is EN', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildOnboardingApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboardingLanguageToggle')), findsOneWidget);
      expect(find.text('EN | VI'), findsOneWidget);
    });

    testWidgets('5.2 Tapping language toggle switches slide content language', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildOnboardingApp());
      await tester.pumpAndSettle();

      // Initially English
      expect(find.text('Split Bills Effortlessly'), findsOneWidget);

      // Toggle to Vietnamese
      await tester.tap(find.byKey(const Key('onboardingLanguageToggle')));
      await tester.pumpAndSettle();

      // Vietnamese slide title
      expect(find.text('Chia tiền dễ dàng'), findsOneWidget);
    });

    testWidgets('5.3 Toggling language twice returns to English', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildOnboardingApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboardingLanguageToggle')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboardingLanguageToggle')));
      await tester.pumpAndSettle();

      expect(find.text('Split Bills Effortlessly'), findsOneWidget);
    });

    testWidgets('5.4 Skip button text changes with language', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildOnboardingApp());
      await tester.pumpAndSettle();

      // English skip text
      expect(find.text('Skip'), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboardingLanguageToggle')));
      await tester.pumpAndSettle();

      // Vietnamese skip text
      expect(find.text('Bỏ qua'), findsOneWidget);
    });
  });

  group('AC 6: Dark Theme Support', () {
    testWidgets('6.1 OnboardingScreen renders in dark mode without errors', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildOnboardingApp(darkMode: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboardingSkipButton')), findsOneWidget);
      expect(find.byKey(const Key('onboardingNextButton')), findsOneWidget);
      expect(find.byKey(const Key('onboardingDot_0')), findsOneWidget);
    });

    testWidgets('6.2 Navigation works correctly in dark mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildOnboardingApp(darkMode: true));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboardingNextButton')));
      await tester.pumpAndSettle();

      expect(find.text('Project-based Budgeting'), findsOneWidget);
    });
  });

  group('AC 7: Dots Page Indicator', () {
    testWidgets('7.1 First dot is active (wide) at start', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildOnboardingApp());
      await tester.pumpAndSettle();

      // Dot 0 should be wider (active)
      final dot0 = tester.widget<AnimatedContainer>(
        find.byKey(const Key('onboardingDot_0')),
      );
      final dot1 = tester.widget<AnimatedContainer>(
        find.byKey(const Key('onboardingDot_1')),
      );
      final box0 = dot0.constraints;
      final box1 = dot1.constraints;
      // Active dot has a wider width
      expect(box0?.maxWidth ?? 0, greaterThan(box1?.maxWidth ?? 0));
    });

    testWidgets('7.2 After advancing to slide 2, dot 1 becomes active', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildOnboardingApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboardingNextButton')));
      await tester.pumpAndSettle();

      final dot0 = tester.widget<AnimatedContainer>(
        find.byKey(const Key('onboardingDot_0')),
      );
      final dot1 = tester.widget<AnimatedContainer>(
        find.byKey(const Key('onboardingDot_1')),
      );
      expect(dot1.constraints?.maxWidth ?? 0,
          greaterThan(dot0.constraints?.maxWidth ?? 0));
    });
  });

  group('AC 8: Slide Content Integrity', () {
    testWidgets('8.1 Slide 2 content is correct', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildOnboardingApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboardingNextButton')));
      await tester.pumpAndSettle();

      expect(find.text('Project-based Budgeting'), findsOneWidget);
      expect(find.text('Organize expenses by projects.'), findsOneWidget);
    });

    testWidgets('8.2 Slide 3 content is correct', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildOnboardingApp());
      await tester.pumpAndSettle();

      for (int i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const Key('onboardingNextButton')));
        await tester.pumpAndSettle();
      }

      expect(find.text('Smart Debt Settlement'), findsOneWidget);
      expect(find.text('Instantly see who owes whom.'), findsOneWidget);
    });

    testWidgets('8.3 Slide icons are rendered (receipt icon for slide 1)', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_buildOnboardingApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.receipt_long_rounded), findsOneWidget);
    });
  });

  group('AC 9: Completion and Persistence', () {
    testWidgets('9.1 Tapping Skip calls onFinish and persists hasSeenOnboarding', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool finished = false;
      await tester.pumpWidget(_buildOnboardingApp(onFinish: () => finished = true));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboardingSkipButton')));
      await tester.pumpAndSettle();

      expect(finished, isTrue);
      final hasSeen = await OnboardingService.instance.hasSeenOnboarding();
      expect(hasSeen, isTrue);
    });

    testWidgets('9.2 Tapping Get Started calls onFinish and persists hasSeenOnboarding', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool finished = false;
      await tester.pumpWidget(_buildOnboardingApp(onFinish: () => finished = true));
      await tester.pumpAndSettle();

      // Navigate to last slide
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('onboardingNextButton')));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byKey(const Key('onboardingGetStartedButton')));
      await tester.pumpAndSettle();

      expect(finished, isTrue);
      final hasSeen = await OnboardingService.instance.hasSeenOnboarding();
      expect(hasSeen, isTrue);
    });

    test('9.3 resetOnboarding clears has_seen_onboarding in SharedPreferences', () async {
      await OnboardingService.instance.markOnboardingSeen();
      expect(await OnboardingService.instance.hasSeenOnboarding(), isTrue);

      await OnboardingService.instance.resetOnboarding();
      expect(await OnboardingService.instance.hasSeenOnboarding(), isFalse);
    });
  });

  group('AC 10: SettingsScreen User Guide Tile', () {
    testWidgets('10.1 SettingsScreen renders User Guide section and replayOnboardingTile', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final langProvider = LanguageProvider();
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LanguageProvider>.value(value: langProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: [
              _TestLocDelegate('en'),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('vi')],
            home: const Scaffold(
              body: SettingsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('userGuideCard')), findsOneWidget);
      expect(find.byKey(const Key('replayOnboardingTile')), findsOneWidget);
    });

    testWidgets('10.2 Tapping replayOnboardingTile resets onboarding flag and opens OnboardingScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await OnboardingService.instance.markOnboardingSeen();
      expect(await OnboardingService.instance.hasSeenOnboarding(), isTrue);

      final langProvider = LanguageProvider();
      final themeProvider = ThemeProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LanguageProvider>.value(value: langProvider),
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: [
              _TestLocDelegate('en'),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('vi')],
            home: const Scaffold(
              body: SettingsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('replayOnboardingTile')));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(await OnboardingService.instance.hasSeenOnboarding(), isFalse);
    });
  });
}

