import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:shared_household_planner/core/services/cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/core/theme/app_theme.dart';
import 'package:shared_household_planner/features/home/presentation/pages/home_screen.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_project_by_id_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/export/presentation/pages/export_data_screen.dart';
import 'package:shared_household_planner/features/settings/presentation/pages/settings_screen.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/statistics/presentation/pages/statistics_screen.dart';

class _MockSettingsLoc extends AppLocalizations {
  _MockSettingsLoc(super.locale);

  static const _en = <String, String>{
    'app_name': 'Shared Household Planner',
    'projects': 'Projects',
    'requests': 'Requests',
    'statistics': 'Statistics',
    'settings': 'Settings',
    'theme_settings': 'Theme Settings',
    'theme_light': 'Light Theme',
    'theme_dark': 'Dark Theme',
    'language': 'Language',
    'english': 'English',
    'vietnamese': 'Vietnamese',
    'account_info': 'Account Info',
    'account_name': 'Household Admin',
    'account_role_owner': 'Owner',
    'edit_profile': 'Edit Profile',
    'preferences': 'Preferences',
    'default_currency': 'Default Currency',
    'data_management': 'Data Management',
    'clear_cache': 'Clear Cache',
    'cache_cleared': 'Cache cleared successfully',
    'cache_size': 'Cache size: 1.2 MB',
    'reset_demo_data': 'Reset Demo Data',
    'reset_demo_data_desc': 'Restore initial sample projects and expenses',
    'data_reset_success': 'Sample data reset successfully',
    'confirm_delete': 'Confirm Delete',
    'cancel': 'Cancel',
    'export_options': 'Export Options',
    'export_options_desc': 'Export your expenses for offline backup or sharing',
    'export_csv': 'Export to CSV',
    'export_pdf': 'Export to PDF',
    'export_csv_desc': 'Spreadsheet-friendly transaction records',
    'export_pdf_desc': 'Formatted printable expense report',
    'export_coming_soon': 'Export feature will be available shortly',
    'about_app': 'About App',
    'app_version': 'Version 1.0.0 (Build 42)',
    'developed_by': 'SimSoft Studio',
    'statistics_charts': 'Statistics & Charts',
    'all_projects': 'All Projects',
    'overview': 'Overview',
    'no_stats_data': 'No expense data for this period',
    'export_data': 'Export Data',
    'export_format': 'Export Format',
    'scope': 'Scope',
    'select_date_range': 'Select Date Range',
    'all_time': 'All Time',
    'this_month': 'This Month',
    'last_month': 'Last Month',
    'custom_range': 'Custom Range',
    'start_date': 'Start Date',
    'end_date': 'End Date',
    'settlement_summary': 'Settlement Summary',
    'settlement_formula': 'Formula: net = paid - owed',
    'bills_count': 'Total Bills',
    'total_amount': 'Total Amount',
    'export_and_share': 'Export & Share',
    'export_file': 'Export File',
  };

  static const _vi = <String, String>{
    'app_name': 'Trình quản lý hộ gia đình',
    'projects': 'Dự án',
    'requests': 'Yêu cầu',
    'statistics': 'Thống kê',
    'settings': 'Cài đặt',
    'theme_settings': 'Cài đặt giao diện',
    'theme_light': 'Giao diện sáng',
    'theme_dark': 'Giao diện tối',
    'language': 'Ngôn ngữ',
    'english': 'Tiếng Anh',
    'vietnamese': 'Tiếng Việt',
    'account_info': 'Thông tin tài khoản',
    'account_name': 'Quản trị viên',
    'account_role_owner': 'Chủ hộ',
    'edit_profile': 'Chỉnh sửa hồ sơ',
    'preferences': 'Tùy chọn',
    'default_currency': 'Tiền tệ mặc định',
    'data_management': 'Quản lý dữ liệu',
    'clear_cache': 'Xóa bộ nhớ đệm',
    'cache_cleared': 'Đã xóa bộ nhớ đệm thành công',
    'cache_size': 'Dung lượng bộ nhớ đệm: 1.2 MB',
    'reset_demo_data': 'Đặt lại dữ liệu mẫu',
    'reset_demo_data_desc': 'Khôi phục các dự án và chi tiêu mẫu ban đầu',
    'data_reset_success': 'Đã đặt lại dữ liệu mẫu thành công',
    'confirm_delete': 'Xác nhận xóa',
    'cancel': 'Hủy',
    'export_options': 'Tùy chọn xuất dữ liệu',
    'export_options_desc': 'Xuất chi tiêu để sao lưu hoặc chia sẻ',
    'export_csv': 'Xuất file CSV',
    'export_pdf': 'Xuất file PDF',
    'export_csv_desc': 'Bảng tính dữ liệu chi tiêu chi tiết',
    'export_pdf_desc': 'Báo cáo chi tiêu định dạng PDF có thể in',
    'export_coming_soon': 'Tính năng xuất dữ liệu sẽ sớm ra mắt',
    'about_app': 'Thông tin ứng dụng',
    'app_version': 'Phiên bản 1.0.0 (Build 42)',
    'developed_by': 'SimSoft Studio',
    'statistics_charts': 'Thống kê & Biểu đồ',
    'all_projects': 'Tất cả dự án',
    'overview': 'Tổng quan',
    'no_stats_data': 'Không có dữ liệu chi tiêu trong kỳ này',
    'export_data': 'Xuất dữ liệu',
    'export_format': 'Định dạng xuất',
    'scope': 'Phạm vi',
    'select_date_range': 'Chọn khoảng thời gian',
    'all_time': 'Tất cả',
    'this_month': 'Tháng này',
    'last_month': 'Tháng trước',
    'custom_range': 'Tùy chỉnh',
    'start_date': 'Từ ngày',
    'end_date': 'Đến ngày',
    'settlement_summary': 'Tổng kết quyết toán',
    'settlement_formula': 'Công thức: net = đã trả - nợ',
    'bills_count': 'Tổng số hóa đơn',
    'total_amount': 'Tổng số tiền',
    'export_and_share': 'Xuất & Chia sẻ',
    'export_file': 'Xuất file',
  };

  @override
  String translate(String key) {
    if (locale.languageCode == 'vi') return _vi[key] ?? key;
    return _en[key] ?? key;
  }
}

class _SettingsLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  final String lang;
  const _SettingsLocDelegate([this.lang = 'en']);
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => _MockSettingsLoc(Locale(lang));
  @override
  bool shouldReload(_SettingsLocDelegate old) => false;
}

class _FakeProjectRepo extends Fake implements ProjectRepository {
  List<Project> list = [];
  @override
  Future<Either<Failure, List<Project>>> getAllProjects() async => Right(list);
  @override
  Future<Either<Failure, Project>> getProjectById(String id) async => Right(list.firstWhere((p) => p.id == id));
  @override
  Future<Either<Failure, Project>> createProject(Project p) async { list.add(p); return Right(p); }
  @override
  Future<Either<Failure, Project>> updateProject(Project p) async => Right(p);
  @override
  Future<Either<Failure, void>> deleteProject(String id) async { list.removeWhere((p) => p.id == id); return const Right(null); }
}

class _FakeBillRepo extends Fake implements BillRepository {
  List<Bill> list = [];
  @override
  Future<Either<Failure, List<Bill>>> getAll() async => Right(list);
  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async => Right(list.where((b) => b.projectId == projectId).toList());
  @override
  Future<Either<Failure, Bill>> create(Bill b) async { list.add(b); return Right(b); }
  @override
  Future<Either<Failure, Bill>> getById(String billId) async => Right(list.firstWhere((b) => b.id == billId));
  @override
  Future<Either<Failure, Bill>> update(Bill b) async => Right(b);
  @override
  Future<Either<Failure, void>> delete(String billId) async { list.removeWhere((b) => b.id == billId); return const Right(null); }
}

Widget buildSettingsTestApp({
  Widget? child,
  ThemeProvider? themeProvider,
  LanguageProvider? languageProvider,
  String locale = 'en',
}) {
  final tp = themeProvider ?? ThemeProvider();
  final lp = languageProvider ?? LanguageProvider();

  final pRepo = _FakeProjectRepo();
  final bRepo = _FakeBillRepo();

  final pBloc = ProjectBloc(
    createProjectUseCase: CreateProjectUseCase(pRepo),
    getAllProjectsUseCase: GetAllProjectsUseCase(pRepo),
    getProjectByIdUseCase: GetProjectByIdUseCase(pRepo),
    updateProjectUseCase: UpdateProjectUseCase(pRepo),
    deleteProjectUseCase: DeleteProjectUseCase(pRepo),
  )..emit(const ProjectLoaded(projects: []));

  final bBloc = BillsBloc(
    getBillsUseCase: GetBillsUseCase(bRepo),
    addBillUseCase: AddBillUseCase(bRepo),
  )..emit(const BillsLoaded(bills: []));

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>.value(value: tp),
      ChangeNotifierProvider<LanguageProvider>.value(value: lp),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<ProjectBloc>.value(value: pBloc),
        BlocProvider<BillsBloc>.value(value: bBloc),
      ],
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: [
          _SettingsLocDelegate(locale),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('vi'),
        ],
        home: child ?? const SettingsScreen(showAppBar: true),
      ),
    ),
  );
}

Future<void> pumpTestScreen(WidgetTester tester, Widget widget) async {
  tester.view.physicalSize = const Size(1200, 3600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── GROUP 1: Bottom Navigation Bar 4 Tabs (AC 4) ───────────────────────────
  group('1. BottomNavigationBar 4 Tabs Architecture (AC 4)', () {
    testWidgets('1. BottomNavigationBar exists in HomeScreen', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp(child: const HomeScreen()));
      expect(find.byKey(const Key('bottomNavigationBar')), findsOneWidget);
    });

    testWidgets('2. BottomNavigationBar has exactly 4 tabs', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp(child: const HomeScreen()));
      final nav = tester.widget<BottomNavigationBar>(find.byKey(const Key('bottomNavigationBar')));
      expect(nav.items.length, 4);
    });

    testWidgets('3. Tab 0 is Projects (Home dashboard)', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp(child: const HomeScreen()));
      final nav = tester.widget<BottomNavigationBar>(find.byKey(const Key('bottomNavigationBar')));
      expect(nav.items[0].label, 'Projects');
      expect(nav.items[0].icon, isA<Icon>());
    });

    testWidgets('4. Tab 1 is Requests (Bills list)', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp(child: const HomeScreen()));
      final nav = tester.widget<BottomNavigationBar>(find.byKey(const Key('bottomNavigationBar')));
      expect(nav.items[1].label, 'Requests');
    });

    testWidgets('5. Tab 2 is Statistics (Charts hub)', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp(child: const HomeScreen()));
      final nav = tester.widget<BottomNavigationBar>(find.byKey(const Key('bottomNavigationBar')));
      expect(nav.items[2].label, 'Statistics');
    });

    testWidgets('6. Tab 3 is Settings (Consolidated)', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp(child: const HomeScreen()));
      final nav = tester.widget<BottomNavigationBar>(find.byKey(const Key('bottomNavigationBar')));
      expect(nav.items[3].label, 'Settings');
    });

    testWidgets('7. BottomNavigationBar type is fixed', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp(child: const HomeScreen()));
      final nav = tester.widget<BottomNavigationBar>(find.byKey(const Key('bottomNavigationBar')));
      expect(nav.type, BottomNavigationBarType.fixed);
    });

    testWidgets('8. Default selected tab is Tab 0 (Projects)', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp(child: const HomeScreen()));
      final nav = tester.widget<BottomNavigationBar>(find.byKey(const Key('bottomNavigationBar')));
      expect(nav.currentIndex, 0);
    });
  });

  // ── GROUP 2: Navigation & Tab Switching (AC 4, 6) ───────────────────────────
  group('2. Navigation & Tab Switching (AC 4, 6)', () {
    testWidgets('9. Tapping Tab 2 switches view to StatisticsScreen', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp(child: const HomeScreen()));
      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();
      expect(find.byType(StatisticsScreen), findsOneWidget);
    });

    testWidgets('10. Tapping Tab 3 switches view to SettingsScreen', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp(child: const HomeScreen()));
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('11. Switching from Settings back to Projects restores dashboard', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp(child: const HomeScreen()));
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();
      expect(find.text('All Projects'), findsOneWidget);
    });

    testWidgets('12. Full sequential cycle switching 0 -> 1 -> 2 -> 3 -> 0 works', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp(child: const HomeScreen()));
      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('13. FAB is visible on Tab 0 (Projects)', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp(child: const HomeScreen()));
      expect(find.byKey(const Key('addProjectButton')), findsOneWidget);
    });

    testWidgets('14. FAB is hidden when on Tab 2 (Statistics)', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp(child: const HomeScreen()));
      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addProjectButton')), findsNothing);
    });

    testWidgets('15. FAB is hidden when on Tab 3 (Settings)', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp(child: const HomeScreen()));
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addProjectButton')), findsNothing);
    });

    testWidgets('16. BottomNavigationBar remains visible on all tabs', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp(child: const HomeScreen()));
      for (final label in ['Requests', 'Statistics', 'Settings', 'Projects']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('bottomNavigationBar')), findsOneWidget);
      }
    });
  });

  // ── GROUP 3: Account Info Section (AC 1, 3) ─────────────────────────────────
  group('3. Account Info Section (AC 1, 3)', () {
    testWidgets('17. Account card exists with Key accountInfoCard', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('accountInfoCard')), findsOneWidget);
    });

    testWidgets('18. Displays user avatar with initial H', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.text('H'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('19. Displays user display name', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.text('Household Admin'), findsOneWidget);
    });

    testWidgets('20. Displays user email', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.text('household@example.com'), findsOneWidget);
    });

    testWidgets('21. Displays Owner role badge', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('accountRoleBadge')), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);
    });

    testWidgets('22. Edit profile button exists', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('editProfileButton')), findsOneWidget);
    });

    testWidgets('23. Tapping edit profile button shows feedback SnackBar', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      await tester.tap(find.byKey(const Key('editProfileButton')));
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
    });
  });

  // ── GROUP 4: Theme Settings Section (AC 2, 5) ──────────────────────────────
  group('4. Theme Settings Section (AC 2, 5)', () {
    testWidgets('24. Theme card exists with Key themeSettingsCard', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('themeSettingsCard')), findsOneWidget);
    });

    testWidgets('25. Light Mode RadioListTile exists', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('settingsLightModeTile')), findsOneWidget);
    });

    testWidgets('26. Dark Mode RadioListTile exists', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('settingsDarkModeTile')), findsOneWidget);
    });

    testWidgets('27. Default theme mode has Light Mode selected', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      final tile = tester.widget<RadioListTile<bool>>(find.byKey(const Key('settingsLightModeTile')));
      expect(tile.checked, true);
    });

    testWidgets('28. Tapping Dark Mode switches ThemeProvider to dark', (tester) async {
      final tp = ThemeProvider();
      await pumpTestScreen(tester, buildSettingsTestApp(themeProvider: tp));
      await tester.tap(find.byKey(const Key('settingsDarkModeTile')));
      await tester.pumpAndSettle();
      expect(tp.isDarkMode, true);
    });

    testWidgets('29. Tapping Light Mode switches ThemeProvider to light', (tester) async {
      final tp = ThemeProvider();
      await tp.setDarkMode(true);
      await pumpTestScreen(tester, buildSettingsTestApp(themeProvider: tp));
      await tester.tap(find.byKey(const Key('settingsLightModeTile')));
      await tester.pumpAndSettle();
      expect(tp.isDarkMode, false);
    });

    testWidgets('30. Theme section header displays Theme Settings', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.text('Theme Settings'), findsOneWidget);
    });
  });

  // ── GROUP 5: Language Selector (AC 2, 5) ────────────────────────────────────
  group('5. Language Selector (AC 2, 5)', () {
    testWidgets('31. Preferences card exists with Key preferencesCard', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('preferencesCard')), findsOneWidget);
    });

    testWidgets('32. English RadioListTile exists', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('settingsEnglishTile')), findsOneWidget);
    });

    testWidgets('33. Vietnamese RadioListTile exists', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('settingsVietnameseTile')), findsOneWidget);
    });

    testWidgets('34. Default language is English', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      final tile = tester.widget<RadioListTile<String>>(find.byKey(const Key('settingsEnglishTile')));
      expect(tile.checked, true);
    });

    testWidgets('35. Tapping Vietnamese tile changes LanguageProvider to vi', (tester) async {
      final lp = LanguageProvider();
      await pumpTestScreen(tester, buildSettingsTestApp(languageProvider: lp));
      await tester.tap(find.byKey(const Key('settingsVietnameseTile')));
      await tester.pumpAndSettle();
      expect(lp.currentLocale.languageCode, 'vi');
    });

    testWidgets('36. Tapping English tile restores LanguageProvider to en', (tester) async {
      final lp = LanguageProvider();
      await lp.setLanguage('vi');
      await pumpTestScreen(tester, buildSettingsTestApp(languageProvider: lp));
      await tester.tap(find.byKey(const Key('settingsEnglishTile')));
      await tester.pumpAndSettle();
      expect(lp.currentLocale.languageCode, 'en');
    });
  });

  // ── GROUP 6: Currency Selector (AC 2, 5) ────────────────────────────────────
  group('6. Currency Selector (AC 2, 5)', () {
    testWidgets('37. Currency selector row exists in preferences card', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.text('Default Currency'), findsOneWidget);
      expect(find.byKey(const Key('settingsCurrencyDropdown')), findsOneWidget);
    });

    testWidgets('38. Default currency displays EUR (€)', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.text('EUR (€)'), findsOneWidget);
    });

    testWidgets('39. Initial custom currency is respected', (tester) async {
      await pumpTestScreen(
        tester,
        buildSettingsTestApp(child: const SettingsScreen(showAppBar: true, initialCurrency: 'USD')),
      );
      expect(find.text('USD (\$)'), findsOneWidget);
    });

    testWidgets('40. Tapping currency dropdown opens currency options', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      await tester.tap(find.byKey(const Key('settingsCurrencyDropdown')));
      await tester.pumpAndSettle();
      expect(find.text('USD (\$)'), findsWidgets);
      expect(find.text('VND (₫)'), findsWidgets);
      expect(find.text('GBP (£)'), findsWidgets);
      expect(find.text('JPY (¥)'), findsWidgets);
    });

    testWidgets('41. Selecting USD triggers onCurrencyChanged callback', (tester) async {
      String? changed;
      await pumpTestScreen(
        tester,
        buildSettingsTestApp(
          child: SettingsScreen(
            showAppBar: true,
            onCurrencyChanged: (c) => changed = c,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('settingsCurrencyDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('USD (\$)').last);
      await tester.pumpAndSettle();
      expect(changed, 'USD');
      expect(find.text('USD (\$)'), findsOneWidget);
    });

    testWidgets('42. Selecting VND triggers onCurrencyChanged callback', (tester) async {
      String? changed;
      await pumpTestScreen(
        tester,
        buildSettingsTestApp(
          child: SettingsScreen(
            showAppBar: true,
            onCurrencyChanged: (c) => changed = c,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('settingsCurrencyDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('VND (₫)').last);
      await tester.pumpAndSettle();
      expect(changed, 'VND');
    });
  });

  // ── GROUP 7: Export Options UI (AC 3) ──────────────────────────────────────
  group('7. Export Options UI (AC 3)', () {
    testWidgets('43. Export card exists with Key exportOptionsCard', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('exportOptionsCard')), findsOneWidget);
    });

    testWidgets('44. Export to CSV ListTile exists', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('exportCsvTile')), findsOneWidget);
      expect(find.text('Export to CSV'), findsOneWidget);
    });

    testWidgets('45. Export to PDF ListTile exists', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('exportPdfTile')), findsOneWidget);
      expect(find.text('Export to PDF'), findsOneWidget);
    });

    testWidgets('46. Export to CSV has table icon', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byIcon(Icons.table_chart), findsOneWidget);
    });

    testWidgets('47. Export to PDF has PDF icon', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });

    testWidgets('48. Tapping CSV export navigates to ExportDataScreen', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      await tester.tap(find.byKey(const Key('exportCsvTile')));
      await tester.pumpAndSettle();
      expect(find.byType(ExportDataScreen), findsOneWidget);
    });

    testWidgets('49. Tapping PDF export navigates to ExportDataScreen', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      await tester.tap(find.byKey(const Key('exportPdfTile')));
      await tester.pumpAndSettle();
      expect(find.byType(ExportDataScreen), findsOneWidget);
    });
  });

  // ── GROUP 8: Data Management Section (AC 2) ────────────────────────────────
  group('8. Data Management Section (AC 2)', () {
    testWidgets('50. Data management card exists with Key dataManagementCard', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('dataManagementCard')), findsOneWidget);
    });

    testWidgets('51. Displays cache size text', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('cacheSizeText')), findsOneWidget);
      expect(find.text('Cache size: 1.2 MB'), findsOneWidget);
    });

    testWidgets('52. Clear cache button exists', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('clearCacheButton')), findsOneWidget);
    });

    testWidgets('53. Tapping Clear Cache updates subtitle and shows SnackBar', (tester) async {
      bool called = false;
      await pumpTestScreen(
        tester,
        buildSettingsTestApp(
          child: SettingsScreen(
            showAppBar: true,
            onClearCache: () => called = true,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('clearCacheButton')));
      await tester.pump();
      expect(called, true);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Cache cleared successfully'), findsWidgets);
    });

    testWidgets('54. Reset Demo Data button is removed from Data Management', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('resetDataButton')), findsNothing);
      expect(find.text('Reset Demo Data'), findsNothing);
    });

    testWidgets('55. Confirm reset data button key is not found', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('confirmResetDataButton')), findsNothing);
    });

    testWidgets('56. SettingsScreen accepts onResetData callback for backward compatibility', (tester) async {
      await pumpTestScreen(
        tester,
        buildSettingsTestApp(
          child: SettingsScreen(
            showAppBar: true,
            onResetData: () {},
          ),
        ),
      );
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('57. Data Management only contains billTemplatesTile and clearCacheButton', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('billTemplatesTile')), findsOneWidget);
      expect(find.byKey(const Key('clearCacheButton')), findsOneWidget);
      expect(find.byKey(const Key('resetDataButton')), findsNothing);
    });
  });

  // ── GROUP 9: About App Section (AC 2) ──────────────────────────────────────
  group('9. About App Section (AC 2)', () {
    testWidgets('58. About card exists with Key aboutAppCard', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('aboutAppCard')), findsOneWidget);
    });

    testWidgets('59. Displays App Name correctly', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('appNameText')), findsOneWidget);
      expect(find.text('Shared Household Planner'), findsOneWidget);
    });

    testWidgets('60. Displays App Version', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('appVersionText')), findsOneWidget);
      expect(find.text('Version 1.0.0 (Build 42)'), findsOneWidget);
    });

    testWidgets('61. Displays developer SimSoft Studio', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('developedByText')), findsOneWidget);
      expect(find.text('SimSoft Studio'), findsOneWidget);
    });
  });

  // ── GROUP 10: Dark / Light Theme Styling (AC 5) ────────────────────────────
  group('10. Dark / Light Theme Styling (AC 5)', () {
    testWidgets('62. Light theme cards have white background', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      final card = tester.widget<Card>(find.byKey(const Key('accountInfoCard')));
      expect(card.color, Colors.white);
    });

    testWidgets('63. Dark theme cards have dark (#1E1E1E) background', (tester) async {
      final tp = ThemeProvider();
      await tp.setDarkMode(true);
      await pumpTestScreen(tester, buildSettingsTestApp(themeProvider: tp));
      final card = tester.widget<Card>(find.byKey(const Key('accountInfoCard')));
      expect(card.color, const Color(0xFF1E1E1E));
    });

    testWidgets('64. Dark theme themeSettingsCard is dark', (tester) async {
      final tp = ThemeProvider();
      await tp.setDarkMode(true);
      await pumpTestScreen(tester, buildSettingsTestApp(themeProvider: tp));
      final card = tester.widget<Card>(find.byKey(const Key('themeSettingsCard')));
      expect(card.color, const Color(0xFF1E1E1E));
    });

    testWidgets('65. Dark theme preferencesCard is dark', (tester) async {
      final tp = ThemeProvider();
      await tp.setDarkMode(true);
      await pumpTestScreen(tester, buildSettingsTestApp(themeProvider: tp));
      final card = tester.widget<Card>(find.byKey(const Key('preferencesCard')));
      expect(card.color, const Color(0xFF1E1E1E));
    });

    testWidgets('66. Dark theme aboutAppCard is dark', (tester) async {
      final tp = ThemeProvider();
      await tp.setDarkMode(true);
      await pumpTestScreen(tester, buildSettingsTestApp(themeProvider: tp));
      final card = tester.widget<Card>(find.byKey(const Key('aboutAppCard')));
      expect(card.color, const Color(0xFF1E1E1E));
    });
  });

  // ── GROUP 11: Localization / i18n (EN & VI) ─────────────────────────────────
  group('11. Localization / i18n (EN & VI)', () {
    testWidgets('67. English labels render correctly', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp(locale: 'en'));
      expect(find.text('Account Info'), findsOneWidget);
      expect(find.text('Theme Settings'), findsOneWidget);
      expect(find.text('Preferences'), findsOneWidget);
      expect(find.text('Export Options'), findsOneWidget);
      expect(find.text('Data Management'), findsOneWidget);
      expect(find.text('About App'), findsOneWidget);
    });

    testWidgets('68. Vietnamese labels render correctly', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp(locale: 'vi'));
      expect(find.text('Thông tin tài khoản'), findsOneWidget);
      expect(find.text('Cài đặt giao diện'), findsOneWidget);
      expect(find.text('Tùy chọn'), findsOneWidget);
      expect(find.text('Tùy chọn xuất dữ liệu'), findsOneWidget);
      expect(find.text('Quản lý dữ liệu'), findsOneWidget);
      expect(find.text('Thông tin ứng dụng'), findsOneWidget);
    });

    testWidgets('69. Vietnamese currency label renders correctly', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp(locale: 'vi'));
      expect(find.text('Tiền tệ mặc định'), findsOneWidget);
    });

    testWidgets('70. Vietnamese export tiles render correctly', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp(locale: 'vi'));
      expect(find.text('Xuất file CSV'), findsOneWidget);
      expect(find.text('Xuất file PDF'), findsOneWidget);
    });
  });

  // ── GROUP 12: Edge Cases & Robustness ──────────────────────────────────────
  group('12. Edge Cases & Robustness', () {
    testWidgets('71. Standalone mode with showAppBar: false renders without Scaffold AppBar', (tester) async {
      await pumpTestScreen(
        tester,
        buildSettingsTestApp(child: const SettingsScreen(showAppBar: false)),
      );
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('72. Standalone mode with showAppBar: true renders AppBar', (tester) async {
      await pumpTestScreen(
        tester,
        buildSettingsTestApp(child: const SettingsScreen(showAppBar: true)),
      );
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('73. Rapid switching between currencies does not crash', (tester) async {
      final currencies = ['USD', 'VND', 'GBP', 'JPY', 'EUR'];
      await pumpTestScreen(tester, buildSettingsTestApp());
      for (final c in currencies) {
        await tester.tap(find.byKey(const Key('settingsCurrencyDropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining(c).last);
        await tester.pumpAndSettle();
      }
      expect(find.text('EUR (€)'), findsOneWidget);
    });

    testWidgets('74. All cards have 16px circular border radius', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      final cards = tester.widgetList<Card>(find.byType(Card));
      for (final card in cards) {
        expect(card.shape, isA<RoundedRectangleBorder>());
        final shape = card.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(16));
      }
    });

    testWidgets('75. Renders cleanly when providers are not in tree', (tester) async {
      await pumpTestScreen(
        tester,
        const MaterialApp(
          localizationsDelegates: [
            _SettingsLocDelegate(),
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
          home: SettingsScreen(showAppBar: false),
        ),
      );
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Account Info'), findsOneWidget);
    });

    testWidgets('76. About App card displays app_icon image asset', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byKey(const Key('aboutAppCard')), findsOneWidget);
      final imageFinder = find.descendant(
        of: find.byKey(const Key('aboutAppCard')),
        matching: find.byType(Image),
      );
      expect(imageFinder, findsOneWidget);
      final image = tester.widget<Image>(imageFinder);
      expect(image.image, isA<AssetImage>());
      expect((image.image as AssetImage).assetName, 'assets/images/app_icon.png');
    });

    test('77. app_icon and app_avatar image assets exist on disk', () {
      expect(File('assets/images/app_icon.png').existsSync(), isTrue);
      expect(File('assets/images/app_avatar.png').existsSync(), isTrue);
    });

    testWidgets('78. Displays safety note in clear cache tile', (tester) async {
      await pumpTestScreen(tester, buildSettingsTestApp());
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });

    test('79. CacheService formatBytes formats sizes correctly', () {
      expect(CacheService.formatBytes(0), '0 KB');
      expect(CacheService.formatBytes(500), '500 B');
      expect(CacheService.formatBytes(1024 * 150), '150.0 KB');
      expect(CacheService.formatBytes(1024 * 1024 * 2), '2.0 MB');
    });

    test('80. CacheService clears files in directory', () async {
      final tempDir = Directory.systemTemp.createTempSync('cache_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final testFile = File('${tempDir.path}/test_cache.txt');
      await testFile.writeAsString('hello world');
      expect(await testFile.exists(), isTrue);

      final service = CacheService(getTempDir: () async => tempDir);
      final size = await service.getCacheSizeBytes();
      expect(size, greaterThan(0));

      await service.clearCache();
      expect(await testFile.exists(), isFalse);
      expect(await service.getCacheSizeBytes(), equals(0));
    });
  });
}
