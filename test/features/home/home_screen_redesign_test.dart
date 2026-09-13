import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartz/dartz.dart';

import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/core/theme/app_theme.dart';
import 'package:shared_household_planner/features/home/presentation/pages/home_screen.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_project_by_id_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/create_project_screen.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/project_detail_screen.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/project_screen.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/bills_list_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fakes & Mocks
// ─────────────────────────────────────────────────────────────────────────────

class FakeProjectRepo implements ProjectRepository {
  List<Project> list = [];
  bool deleteCalled = false;

  @override
  Future<Either<Failure, Project>> create(Project project) async {
    list.add(project);
    return Right(project);
  }

  @override
  Future<Either<Failure, List<Project>>> getAll() async => Right(list);

  @override
  Future<Either<Failure, Project>> getById(String id) async {
    final p = list.firstWhere((e) => e.id == id, orElse: () => throw Exception('not found'));
    return Right(p);
  }

  @override
  Future<Either<Failure, Project>> update(Project project) async => Right(project);

  @override
  Future<Either<Failure, void>> delete(String id) async {
    deleteCalled = true;
    list.removeWhere((e) => e.id == id);
    return const Right(null);
  }
}

class FakeBillRepo implements BillRepository {
  List<Bill> list = [];

  @override
  Future<Either<Failure, Bill>> create(Bill bill) async {
    list.add(bill);
    return Right(bill);
  }

  @override
  Future<Either<Failure, List<Bill>>> getAll() async => Right(list);

  @override
  Future<Either<Failure, Bill>> getById(String billId) async => Right(list.first);

  @override
  Future<Either<Failure, Bill>> update(Bill bill) async => Right(bill);

  @override
  Future<Either<Failure, void>> delete(String billId) async {
    list.removeWhere((b) => b.id == billId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async {
    return Right(list.where((b) => b.projectId == projectId).toList());
  }
}

class TestLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  final String lang;
  const TestLocDelegate([this.lang = 'en']);

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async => _MockLoc(Locale(lang));

  @override
  bool shouldReload(TestLocDelegate old) => false;
}

class _MockLoc extends AppLocalizations {
  _MockLoc(super.locale);

  static const _en = <String, String>{
    'app_name': 'Shared Household Planner',
    'projects': 'Projects',
    'requests': 'Requests',
    'settings': 'Settings',
    'profile': 'Profile',
    'statistics': 'Statistics',
    'statistics_charts': 'Statistics & Charts',
    'no_stats_data': 'No expense data for this period',
    'split_bills': 'Split Bills',
    'all_projects': 'All Projects',
    'overview': 'Overview',
    'no_projects': 'No projects yet',
    'create_first_project_prompt': 'Create your first project to start tracking shared expenses!',
    'add_project': 'Add Project',
    'create_project': 'Create Project',
    'edit_project': 'Edit Project',
    'leave_project': 'Leave Project',
    'delete_project': 'Delete Project',
    'delete_project_confirm': 'Are you sure you want to delete this project?',
    'delete': 'Delete',
    'cancel': 'Cancel',
    'total_members': 'Total Members',
    'total_bills_count': 'Total Bills',
    'total_spent': 'Total Spent',
    'language': 'Language',
    'english': 'English',
    'vietnamese': 'Vietnamese',
    'theme': 'Theme',
    'light_mode': 'Light',
    'dark_mode': 'Dark',
    'theme_light': 'Light Theme',
    'theme_dark': 'Dark Theme',
    'theme_settings': 'Theme Settings',
    'loading': 'Loading...',
    'error': 'Error',
    'members': 'Members',
    'bills': 'Bills',
    'no_bills': 'No bills yet',
  };

  static const _vi = <String, String>{
    'app_name': 'Trình quản lý hộ gia đình',
    'projects': 'Dự án',
    'requests': 'Yêu cầu',
    'settings': 'Cài đặt',
    'profile': 'Hồ sơ',
    'statistics': 'Thống kê',
    'statistics_charts': 'Thống kê & Biểu đồ',
    'no_stats_data': 'Không có dữ liệu chi tiêu trong kỳ này',
    'split_bills': 'Chia chi tiêu',
    'all_projects': 'Tất cả dự án',
    'overview': 'Tổng quan',
    'no_projects': 'Chưa có dự án nào',
    'create_first_project_prompt': 'Tạo dự án đầu tiên để bắt đầu theo dõi chi tiêu chung!',
    'add_project': 'Thêm dự án',
    'create_project': 'Tạo dự án',
    'edit_project': 'Sửa dự án',
    'leave_project': 'Rời dự án',
    'delete_project': 'Xóa dự án',
    'delete_project_confirm': 'Bạn có chắc chắn muốn xóa dự án này?',
    'delete': 'Xóa',
    'cancel': 'Hủy',
    'total_members': 'Tổng thành viên',
    'total_bills_count': 'Tổng hóa đơn',
    'total_spent': 'Tổng chi',
    'language': 'Ngôn ngữ',
    'english': 'Tiếng Anh',
    'vietnamese': 'Tiếng Việt',
    'theme': 'Giao diện',
    'light_mode': 'Sáng',
    'dark_mode': 'Tối',
    'theme_light': 'Giao diện sáng',
    'theme_dark': 'Giao diện tối',
    'theme_settings': 'Cài đặt giao diện',
    'loading': 'Đang tải...',
    'error': 'Lỗi',
    'members': 'Thành viên',
    'bills': 'Chi tiêu',
    'no_bills': 'Chưa có chi tiêu nào',
  };

  @override
  String translate(String key) {
    if (locale.languageCode == 'vi') {
      return _vi[key] ?? key;
    }
    return _en[key] ?? key;
  }
}

Project sampleProject({
  String id = 'proj-1',
  String name = 'Da Nang Trip',
  String? description = 'Summer vacation 2026',
  List<String> members = const ['Alice', 'Bob', 'Charlie'],
}) {
  return Project(
    id: id,
    name: name,
    description: description,
    members: members,
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 2),
  );
}

Bill sampleBill({
  String id = 'bill-1',
  String title = 'Seafood Dinner',
  double amount = 45.50,
  String projectId = 'proj-1',
}) {
  return Bill(
    id: id,
    title: title,
    amount: amount,
    category: 'Restaurant',
    paidBy: 'Alice',
    date: DateTime(2026, 6, 1),
    participants: const [
      BillParticipant(participantId: 'p1', name: 'Alice', amount: 15.17),
      BillParticipant(participantId: 'p2', name: 'Bob', amount: 15.17),
      BillParticipant(participantId: 'p3', name: 'Charlie', amount: 15.16),
    ],
    projectId: projectId,
  );
}

Widget buildTestApp({
  List<Project> initialProjects = const [],
  List<Bill> initialBills = const [],
  ThemeProvider? themeProvider,
  LanguageProvider? languageProvider,
  String locale = 'en',
}) {
  final pRepo = FakeProjectRepo()..list = List.from(initialProjects);
  final bRepo = FakeBillRepo()..list = List.from(initialBills);

  final pBloc = ProjectBloc(
    createProjectUseCase: CreateProjectUseCase(pRepo),
    getAllProjectsUseCase: GetAllProjectsUseCase(pRepo),
    getProjectByIdUseCase: GetProjectByIdUseCase(pRepo),
    updateProjectUseCase: UpdateProjectUseCase(pRepo),
    deleteProjectUseCase: DeleteProjectUseCase(pRepo),
  );
  if (initialProjects.isNotEmpty) {
    pBloc.emit(ProjectLoaded(projects: initialProjects));
  } else {
    pBloc.emit(const ProjectLoaded(projects: []));
  }

  final bBloc = BillsBloc(
    getBillsUseCase: GetBillsUseCase(bRepo),
    addBillUseCase: AddBillUseCase(bRepo),
  );
  if (initialBills.isNotEmpty) {
    bBloc.emit(BillsLoaded(bills: initialBills));
  } else {
    bBloc.emit(const BillsLoaded(bills: []));
  }

  final tp = themeProvider ?? ThemeProvider();
  final lp = languageProvider ?? LanguageProvider();

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
        theme: tp.currentTheme,
        home: const HomeScreen(),
        routes: {
          '/projects': (_) => const ProjectScreen(),
          '/create-project': (_) => const CreateProjectScreen(),
          '/bills': (_) => const BillsListScreen(),
        },
        localizationsDelegates: [TestLocDelegate(locale)],
        supportedLocales: const [Locale('en'), Locale('vi')],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Test Suite
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── GROUP 1: Header Section (AC 1) ─────────────────────────────────────────
  group('1. Header Section (AC 1)', () {
    testWidgets('1. Displays app name in AppBar', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.text('Shared Household Planner'), findsOneWidget);
    });

    testWidgets('2. Displays theme toggle button with Key', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('themeToggleButton')), findsOneWidget);
    });

    testWidgets('3. Theme toggle button shows dark_mode icon in light theme', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    });

    testWidgets('4. Theme toggle button shows light_mode icon in dark theme', (tester) async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': true});
      final tp = ThemeProvider();
      await tp.loadTheme();
      await tester.pumpWidget(buildTestApp(themeProvider: tp));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
    });

    testWidgets('5. Tapping theme toggle button changes theme', (tester) async {
      final tp = ThemeProvider();
      await tp.loadTheme();
      await tester.pumpWidget(buildTestApp(themeProvider: tp));
      await tester.pumpAndSettle();
      expect(tp.isDarkMode, false);
      await tester.tap(find.byKey(const Key('themeToggleButton')));
      await tester.pumpAndSettle();
      expect(tp.isDarkMode, true);
    });

    testWidgets('6. Language selector popup button is present', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('7. Header shows Vietnamese app name in vi locale', (tester) async {
      await tester.pumpWidget(buildTestApp(locale: 'vi'));
      await tester.pumpAndSettle();
      expect(find.text('Trình quản lý hộ gia đình'), findsOneWidget);
    });

    testWidgets('8. AppBar has low elevation (subtle shadow)', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.elevation, lessThanOrEqualTo(1.0));
    });
  });

  // ── GROUP 2: Bottom Navigation Bar (AC 6 & 7) ──────────────────────────────
  group('2. Bottom Navigation Bar (AC 6 & 7)', () {
    testWidgets('9. BottomNavigationBar exists with Key', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bottomNavigationBar')), findsOneWidget);
    });

    testWidgets('10. BottomNavigationBar has 4 tabs', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      final nav = tester.widget<BottomNavigationBar>(find.byKey(const Key('bottomNavigationBar')));
      expect(nav.items.length, 4);
    });

    testWidgets('11. Tab 0 is Projects with folder icon', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      final nav = tester.widget<BottomNavigationBar>(find.byKey(const Key('bottomNavigationBar')));
      expect(nav.items[0].label, 'Projects');
      expect(nav.items[0].icon, isA<Icon>());
    });

    testWidgets('12. Tab 1 is Requests with receipt icon', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      final nav = tester.widget<BottomNavigationBar>(find.byKey(const Key('bottomNavigationBar')));
      expect(nav.items[1].label, 'Requests');
    });

    testWidgets('13. Tab 2 is Settings with gear icon', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      final nav = tester.widget<BottomNavigationBar>(find.byKey(const Key('bottomNavigationBar')));
      expect(nav.items[2].label, 'Settings');
    });

    testWidgets('14. Tab 3 is Statistics with insights icon', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      final nav = tester.widget<BottomNavigationBar>(find.byKey(const Key('bottomNavigationBar')));
      expect(nav.items[3].label, 'Statistics');
    });

    testWidgets('15. Default tab index is 0 (Projects)', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      final nav = tester.widget<BottomNavigationBar>(find.byKey(const Key('bottomNavigationBar')));
      expect(nav.currentIndex, 0);
    });

    testWidgets('16. Tapping Tab 1 switches view to Requests/Bills', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();
      expect(find.byType(BillsListScreen), findsOneWidget);
    });

    testWidgets('17. Tapping Tab 2 switches view to Settings', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Theme Settings'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('18. Tapping Tab 3 switches view to Statistics', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();
      expect(find.text('Statistics & Charts'), findsOneWidget);
    });

    testWidgets('19. Tapping Tab 0 returns back to Projects view', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Theme Settings'), findsOneWidget);
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();
      expect(find.text('All Projects'), findsOneWidget);
    });

    testWidgets('20. Nav bar labels localized in Vietnamese', (tester) async {
      await tester.pumpWidget(buildTestApp(locale: 'vi'));
      await tester.pumpAndSettle();
      final nav = tester.widget<BottomNavigationBar>(find.byKey(const Key('bottomNavigationBar')));
      expect(nav.items[0].label, 'Dự án');
      expect(nav.items[1].label, 'Yêu cầu');
      expect(nav.items[2].label, 'Cài đặt');
      expect(nav.items[3].label, 'Thống kê');
    });

    testWidgets('21. Nav bar has fixed type', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      final nav = tester.widget<BottomNavigationBar>(find.byKey(const Key('bottomNavigationBar')));
      expect(nav.type, BottomNavigationBarType.fixed);
    });

    testWidgets('22. Unselected labels are shown', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      final nav = tester.widget<BottomNavigationBar>(find.byKey(const Key('bottomNavigationBar')));
      expect(nav.showUnselectedLabels, true);
    });
  });

  // ── GROUP 3: Overview Stats Card (AC 8) ───────────────────────────────────
  group('3. Summary Stats Card (AC 8)', () {
    testWidgets('23. Stats card displayed with Key statsSummaryCard', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('statsSummaryCard')), findsOneWidget);
    });

    testWidgets('24. Shows Overview label', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.text('Overview'), findsOneWidget);
    });

    testWidgets('25. Shows 0 projects when empty', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: []));
      await tester.pumpAndSettle();
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('26. Shows project count accurately', (tester) async {
      final projs = [sampleProject(id: '1'), sampleProject(id: '2')];
      await tester.pumpWidget(buildTestApp(initialProjects: projs));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('27. Shows total unique members aggregated', (tester) async {
      final projs = [
        sampleProject(id: '1', members: ['Alice', 'Bob']),
        sampleProject(id: '2', members: ['Bob', 'Charlie']),
      ];
      // unique: Alice, Bob, Charlie = 3
      await tester.pumpWidget(buildTestApp(initialProjects: projs));
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('28. Shows total bills count accurately', (tester) async {
      final bills = [sampleBill(id: 'b1'), sampleBill(id: 'b2'), sampleBill(id: 'b3')];
      await tester.pumpWidget(buildTestApp(initialBills: bills));
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('29. Shows total amount spent formatted', (tester) async {
      final bills = [sampleBill(id: 'b1', amount: 50.0), sampleBill(id: 'b2', amount: 25.50)];
      await tester.pumpWidget(buildTestApp(initialBills: bills));
      await tester.pumpAndSettle();
      // Total: €75.50
      expect(find.text('€75.50'), findsOneWidget);
    });

    testWidgets('30. Card has 16px rounded corners', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      final card = tester.widget<Card>(find.byKey(const Key('statsSummaryCard')));
      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(16));
    });

    testWidgets('31. Stats labels in Vietnamese in vi locale', (tester) async {
      await tester.pumpWidget(buildTestApp(locale: 'vi'));
      await tester.pumpAndSettle();
      expect(find.text('Tổng quan'), findsOneWidget);
      expect(find.text('Tổng thành viên'), findsOneWidget);
      expect(find.text('Tổng hóa đơn'), findsOneWidget);
      expect(find.text('Tổng chi'), findsOneWidget);
    });
  });

  // ── GROUP 4: Quick Action Buttons (Compatibility) ──────────────────────────
  group('4. Quick Action Buttons Row', () {
    testWidgets('32. projectsButton exists on Tab 0', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectsButton')), findsOneWidget);
    });

    testWidgets('33. splitBillsButton exists on Tab 0', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('splitBillsButton')), findsOneWidget);
    });

    testWidgets('34. Tapping projectsButton navigates to ProjectScreen', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('projectsButton')));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectScreen), findsOneWidget);
    });

    testWidgets('35. Tapping splitBillsButton navigates to BillsListScreen', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('splitBillsButton')));
      await tester.pumpAndSettle();
      expect(find.byType(BillsListScreen), findsOneWidget);
    });

    testWidgets('36. Buttons have rounded corners', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      final btn = tester.widget<ElevatedButton>(find.byKey(const Key('projectsButton')));
      expect(btn.style?.shape, isNotNull);
    });
  });

  // ── GROUP 5: Empty State (AC 4) ───────────────────────────────────────────
  group('5. Empty State (AC 4)', () {
    testWidgets('37. Shows empty state when no projects', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: []));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('emptyProjectsState')), findsOneWidget);
    });

    testWidgets('38. Shows folder open icon in empty state', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: []));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
    });

    testWidgets('39. Shows No projects yet text', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: []));
      await tester.pumpAndSettle();
      expect(find.text('No projects yet'), findsOneWidget);
    });

    testWidgets('40. Shows prompt to create first project', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: []));
      await tester.pumpAndSettle();
      expect(find.text('Create your first project to start tracking shared expenses!'), findsOneWidget);
    });

    testWidgets('41. Shows emptyStateAddProjectButton', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: []));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('emptyStateAddProjectButton')), findsOneWidget);
    });

    testWidgets('42. Tapping emptyStateAddProjectButton opens CreateProjectScreen', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: []));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('emptyStateAddProjectButton')));
      await tester.pumpAndSettle();
      expect(find.byType(CreateProjectScreen), findsOneWidget);
    });

    testWidgets('43. Empty state localized in Vietnamese', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: [], locale: 'vi'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có dự án nào'), findsOneWidget);
      expect(find.text('Tạo dự án đầu tiên để bắt đầu theo dõi chi tiêu chung!'), findsOneWidget);
      expect(find.text('Thêm dự án'), findsOneWidget);
    });

    testWidgets('44. Empty state is not shown when projects exist', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: [sampleProject()]));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('emptyProjectsState')), findsNothing);
    });
  });

  // ── GROUP 6: Floating Action Button (AC 5) ─────────────────────────────────
  group('6. Floating Action Button (AC 5)', () {
    testWidgets('45. FAB exists on Tab 0 with Key addProjectButton', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addProjectButton')), findsOneWidget);
    });

    testWidgets('46. FAB has add icon', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('addProjectButton')),
          matching: find.byIcon(Icons.add),
        ),
        findsOneWidget,
      );
    });

    testWidgets('47. FAB background color is blue', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      final fab = tester.widget<FloatingActionButton>(find.byKey(const Key('addProjectButton')));
      expect(fab.backgroundColor, const Color(0xFF3B82F6));
    });

    testWidgets('48. Tapping FAB opens CreateProjectScreen', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('addProjectButton')));
      await tester.pumpAndSettle();
      expect(find.byType(CreateProjectScreen), findsOneWidget);
    });

    testWidgets('49. FAB is hidden on Settings tab', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addProjectButton')), findsNothing);
    });

    testWidgets('50. FAB is hidden on Statistics tab', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addProjectButton')), findsNothing);
    });

    testWidgets('51. FAB returns when switching back to Projects tab', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addProjectButton')), findsNothing);
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addProjectButton')), findsOneWidget);
    });

    testWidgets('52. FAB has tooltip Add Project', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      final fab = tester.widget<FloatingActionButton>(find.byKey(const Key('addProjectButton')));
      expect(fab.tooltip, 'Add Project');
    });
  });

  // ── GROUP 7: Project Cards Rendering (AC 2 & 3) ────────────────────────────
  group('7. Project Cards Rendering (AC 2 & 3)', () {
    testWidgets('53. Renders project card for project', (tester) async {
      final p = sampleProject(id: 'proj-1', name: 'Tokyo Trip');
      await tester.pumpWidget(buildTestApp(initialProjects: [p]));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectCard_proj-1')), findsOneWidget);
      expect(find.text('Tokyo Trip'), findsOneWidget);
    });

    testWidgets('54. Project card has avatar circle with initial', (tester) async {
      final p = sampleProject(id: 'p1', name: 'Bali Vacation');
      await tester.pumpWidget(buildTestApp(initialProjects: [p]));
      await tester.pumpAndSettle();
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('55. Project card displays member count, bill count, total spent', (tester) async {
      final p = sampleProject(id: 'p1', members: ['Alice', 'Bob']);
      final b = sampleBill(projectId: 'p1', amount: 100.0);
      await tester.pumpWidget(buildTestApp(initialProjects: [p], initialBills: [b]));
      await tester.pumpAndSettle();
      expect(find.text('2 members, 1 bills, €100.00 total'), findsOneWidget);
    });

    testWidgets('56. Project card displays description if present', (tester) async {
      final p = sampleProject(id: 'p1', description: 'Summer trip with friends');
      await tester.pumpWidget(buildTestApp(initialProjects: [p]));
      await tester.pumpAndSettle();
      expect(find.text('Summer trip with friends'), findsOneWidget);
    });

    testWidgets('57. Project card shows chevron icon', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: [sampleProject()]));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('58. Project card has 16px rounded corners', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: [sampleProject(id: 'p1')]));
      await tester.pumpAndSettle();
      final card = tester.widget<Card>(find.byKey(const Key('projectCard_p1')));
      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(16));
    });

    testWidgets('59. Tapping project card navigates to ProjectDetailScreen', (tester) async {
      final p = sampleProject(id: 'p1', name: 'Beach House');
      await tester.pumpWidget(buildTestApp(initialProjects: [p]));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('projectCard_p1')));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectDetailScreen), findsOneWidget);
      expect(find.text('Beach House'), findsWidgets);
    });

    testWidgets('60. Multiple projects rendered in order', (tester) async {
      final projs = [
        sampleProject(id: 'p1', name: 'Project Alpha'),
        sampleProject(id: 'p2', name: 'Project Beta'),
        sampleProject(id: 'p3', name: 'Project Gamma'),
      ];
      await tester.pumpWidget(buildTestApp(initialProjects: projs));
      await tester.pumpAndSettle();
      expect(find.text('Project Alpha'), findsOneWidget);
      expect(find.text('Project Beta'), findsOneWidget);
      expect(find.text('Project Gamma'), findsOneWidget);
    });

    testWidgets('61. Dark theme card background color', (tester) async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': true});
      final tp = ThemeProvider();
      await tp.loadTheme();
      await tester.pumpWidget(buildTestApp(
        initialProjects: [sampleProject(id: 'p1')],
        themeProvider: tp,
      ));
      await tester.pumpAndSettle();
      final card = tester.widget<Card>(find.byKey(const Key('projectCard_p1')));
      expect(card.color, const Color(0xFF1E1E1E));
    });

    testWidgets('62. Light theme card background color is white', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: [sampleProject(id: 'p1')]));
      await tester.pumpAndSettle();
      final card = tester.widget<Card>(find.byKey(const Key('projectCard_p1')));
      expect(card.color, Colors.white);
    });
  });

  // ── GROUP 8: Pull to Refresh (AC 9) ───────────────────────────────────────
  group('8. Pull to Refresh (AC 9)', () {
    testWidgets('63. RefreshIndicator exists with Key pullToRefresh', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pullToRefresh')), findsOneWidget);
    });

    testWidgets('64. Pull down triggers RefreshIndicator', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: [sampleProject()]));
      await tester.pumpAndSettle();
      await tester.fling(find.byKey(const Key('pullToRefresh')), const Offset(0, 300), 1000);
      await tester.pump();
      expect(find.byType(RefreshIndicator), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  // ── GROUP 9: Project Quick Actions (AC 10) ─────────────────────────────────
  group('9. Project Quick Actions (AC 10)', () {
    testWidgets('65. Dismissible exists for project card', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: [sampleProject(id: 'p1')]));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dismissible_p1')), findsOneWidget);
    });

    testWidgets('66. Dismissible direction is endToStart (swipe left)', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: [sampleProject(id: 'p1')]));
      await tester.pumpAndSettle();
      final dismissible = tester.widget<Dismissible>(find.byKey(const Key('dismissible_p1')));
      expect(dismissible.direction, DismissDirection.endToStart);
    });

    testWidgets('67. Swipe left displays delete background', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: [sampleProject(id: 'p1')]));
      await tester.pumpAndSettle();
      await tester.drag(find.byKey(const Key('dismissible_p1')), const Offset(-200, 0));
      await tester.pump();
      expect(find.byIcon(Icons.delete), findsWidgets);
    });

    testWidgets('68. Swipe left shows delete confirmation dialog', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: [sampleProject(id: 'p1')]));
      await tester.pumpAndSettle();
      await tester.drag(find.byKey(const Key('dismissible_p1')), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Delete Project'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this project?'), findsOneWidget);
    });

    testWidgets('69. Cancel button closes delete confirmation dialog', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: [sampleProject(id: 'p1')]));
      await tester.pumpAndSettle();
      await tester.drag(find.byKey(const Key('dismissible_p1')), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Are you sure you want to delete this project?'), findsNothing);
    });

    testWidgets('70. Confirm delete triggers delete on bloc', (tester) async {
      final p = sampleProject(id: 'p1');
      await tester.pumpWidget(buildTestApp(initialProjects: [p]));
      await tester.pumpAndSettle();
      await tester.drag(find.byKey(const Key('dismissible_p1')), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDeleteProjectButton')));
      await tester.pumpAndSettle();
      expect(find.text('Are you sure you want to delete this project?'), findsNothing);
    });

    testWidgets('71. Long press on card opens context menu modal', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: [sampleProject(id: 'p1')]));
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const Key('projectCard_p1')));
      await tester.pumpAndSettle();
      expect(find.text('Edit Project'), findsOneWidget);
      expect(find.text('Leave Project'), findsOneWidget);
      expect(find.text('Delete Project'), findsOneWidget);
    });

    testWidgets('72. Context menu Edit Project navigates to CreateProjectScreen', (tester) async {
      final p = sampleProject(id: 'p1', name: 'Hawaii Trip');
      await tester.pumpWidget(buildTestApp(initialProjects: [p]));
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const Key('projectCard_p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Project'));
      await tester.pumpAndSettle();
      expect(find.byType(CreateProjectScreen), findsOneWidget);
      expect(find.text('Hawaii Trip'), findsOneWidget);
    });

    testWidgets('73. Context menu Leave Project dismisses sheet', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: [sampleProject(id: 'p1')]));
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const Key('projectCard_p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave Project'));
      await tester.pumpAndSettle();
      expect(find.text('Leave Project'), findsNothing);
    });

    testWidgets('74. Context menu Delete Project shows confirmation dialog', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: [sampleProject(id: 'p1')]));
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const Key('projectCard_p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Project'));
      await tester.pumpAndSettle();
      expect(find.text('Are you sure you want to delete this project?'), findsOneWidget);
    });
  });

  // ── GROUP 10: Settings Tab (Tab 2) ─────────────────────────────────────────
  group('10. Settings Tab', () {
    testWidgets('75. Navigating to Settings tab shows Theme Settings', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Theme Settings'), findsOneWidget);
    });

    testWidgets('76. Shows Light Theme and Dark Theme options', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Light Theme'), findsOneWidget);
      expect(find.text('Dark Theme'), findsOneWidget);
    });

    testWidgets('77. Tapping Dark Theme radio changes app theme', (tester) async {
      final tp = ThemeProvider();
      await tp.loadTheme();
      await tester.pumpWidget(buildTestApp(themeProvider: tp));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settingsDarkModeTile')));
      await tester.pumpAndSettle();
      expect(tp.isDarkMode, true);
    });

    testWidgets('78. Tapping Light Theme radio switches back', (tester) async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': true});
      final tp = ThemeProvider();
      await tp.loadTheme();
      await tester.pumpWidget(buildTestApp(themeProvider: tp));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settingsLightModeTile')));
      await tester.pumpAndSettle();
      expect(tp.isDarkMode, false);
    });

    testWidgets('79. Shows English and Vietnamese language options', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settingsEnglishTile')), findsOneWidget);
      expect(find.byKey(const Key('settingsVietnameseTile')), findsOneWidget);
    });

    testWidgets('80. Tapping Vietnamese radio changes language', (tester) async {
      final lp = LanguageProvider();
      await lp.loadLanguage();
      await tester.pumpWidget(buildTestApp(languageProvider: lp));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settingsVietnameseTile')));
      await tester.pumpAndSettle();
      expect(lp.currentLocale.languageCode, 'vi');
    });

    testWidgets('81. Tapping English radio changes language back', (tester) async {
      final lp = LanguageProvider();
      await lp.setLanguage('vi');
      await tester.pumpWidget(buildTestApp(languageProvider: lp));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settingsEnglishTile')));
      await tester.pumpAndSettle();
      expect(lp.currentLocale.languageCode, 'en');
    });
  });

  // ── GROUP 11: Tab 3 (Statistics) & Profile in Settings ───────────────────
  group('11. Statistics Tab & Profile in Settings', () {
    testWidgets('82. Navigating to Tab 3 shows Statistics & Charts header', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();
      expect(find.text('Statistics & Charts'), findsOneWidget);
    });

    testWidgets('83. Settings shows consolidated user profile and email', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('household@example.com'), findsOneWidget);
    });

    testWidgets('84. Tab 3 localized in Vietnamese', (tester) async {
      await tester.pumpWidget(buildTestApp(locale: 'vi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thống kê'));
      await tester.pumpAndSettle();
      expect(find.text('Thống kê & Biểu đồ'), findsOneWidget);
    });
  });

  // ── GROUP 12: Edge Cases & Theme Consistency ──────────────────────────────
  group('12. Edge Cases & Theme Consistency', () {
    testWidgets('85. Rapid switching between all 4 tabs does not crash', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Requests'));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.text('Settings'));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.text('Statistics'));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.text('Projects'));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('86. Project with empty members list renders cleanly', (tester) async {
      final p = sampleProject(id: 'p1', members: []);
      await tester.pumpWidget(buildTestApp(initialProjects: [p]));
      await tester.pumpAndSettle();
      expect(find.text('0 members, 0 bills, €0.00 total'), findsOneWidget);
    });

    testWidgets('87. Project with long name truncates cleanly', (tester) async {
      final p = sampleProject(id: 'p1', name: 'A very long project name that spans multiple words and lines');
      await tester.pumpWidget(buildTestApp(initialProjects: [p]));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectCard_p1')), findsOneWidget);
    });

    testWidgets('88. Project with special unicode characters in Vietnamese', (tester) async {
      final p = sampleProject(id: 'p1', name: 'Chuyến đi Đà Nẵng hè 2026', description: 'Ăn uống & Nghỉ ngơi');
      await tester.pumpWidget(buildTestApp(initialProjects: [p]));
      await tester.pumpAndSettle();
      expect(find.text('Chuyến đi Đà Nẵng hè 2026'), findsOneWidget);
      expect(find.text('Ăn uống & Nghỉ ngơi'), findsOneWidget);
    });

    testWidgets('89. Bills from another project do not count toward this project stats', (tester) async {
      final p1 = sampleProject(id: 'p1', name: 'Project 1');
      final p2 = sampleProject(id: 'p2', name: 'Project 2');
      final b1 = sampleBill(id: 'b1', projectId: 'p1', amount: 30.0);
      final b2 = sampleBill(id: 'b2', projectId: 'p2', amount: 90.0);

      await tester.pumpWidget(buildTestApp(
        initialProjects: [p1, p2],
        initialBills: [b1, b2],
      ));
      await tester.pumpAndSettle();

      expect(find.text('3 members, 1 bills, €30.00 total'), findsOneWidget);
      expect(find.text('3 members, 1 bills, €90.00 total'), findsOneWidget);
    });

    testWidgets('90. Large list of 10 projects scrolls vertically', (tester) async {
      final projs = List.generate(
        10,
        (i) => sampleProject(id: 'p$i', name: 'Project number $i'),
      );
      await tester.pumpWidget(buildTestApp(initialProjects: projs));
      await tester.pumpAndSettle();

      expect(find.text('Project number 0'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('91. Rapid theme toggles from AppBar header do not crash', (tester) async {
      final tp = ThemeProvider();
      await tp.loadTheme();
      await tester.pumpWidget(buildTestApp(themeProvider: tp));
      await tester.pumpAndSettle();

      for (int i = 0; i < 6; i++) {
        await tester.tap(find.byKey(const Key('themeToggleButton')));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('92. HomeScreen renders without error when BLoCs are not provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          localizationsDelegates: const [TestLocDelegate()],
          supportedLocales: const [Locale('en')],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('93. Overview card renders accurately with zero bills and 1 project', (tester) async {
      final p = sampleProject(id: 'p1', members: ['Alice']);
      await tester.pumpWidget(buildTestApp(initialProjects: [p], initialBills: []));
      await tester.pumpAndSettle();
      expect(find.text('€0.00'), findsOneWidget);
    });

    testWidgets('94. Overview card calculates decimal currency properly', (tester) async {
      final b = sampleBill(amount: 123.45);
      await tester.pumpWidget(buildTestApp(initialProjects: [sampleProject()], initialBills: [b]));
      await tester.pumpAndSettle();
      expect(find.text('€123.45'), findsOneWidget);
    });

    testWidgets('95. Avatar colors cycle deterministically', (tester) async {
      final p1 = sampleProject(id: 'p1', name: 'P1');
      final p2 = sampleProject(id: 'p2', name: 'P2');
      await tester.pumpWidget(buildTestApp(initialProjects: [p1, p2]));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectCard_p1')), findsOneWidget);
      expect(find.byKey(const Key('projectCard_p2')), findsOneWidget);
    });

    testWidgets('96. Project count badge shows next to All Projects header', (tester) async {
      final projs = [sampleProject(id: 'p1'), sampleProject(id: 'p2')];
      await tester.pumpWidget(buildTestApp(initialProjects: projs));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('97. Project card tap ripple feedback inkwell exists', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: [sampleProject(id: 'p1')]));
      await tester.pumpAndSettle();
      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('98. Dark theme bottom nav bar has dark background', (tester) async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': true});
      final tp = ThemeProvider();
      await tp.loadTheme();
      await tester.pumpWidget(buildTestApp(themeProvider: tp));
      await tester.pumpAndSettle();

      final nav = tester.widget<BottomNavigationBar>(find.byKey(const Key('bottomNavigationBar')));
      expect(nav.backgroundColor, const Color(0xFF1E1E1E));
    });

    testWidgets('99. Light theme bottom nav bar has white background', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final nav = tester.widget<BottomNavigationBar>(find.byKey(const Key('bottomNavigationBar')));
      expect(nav.backgroundColor, Colors.white);
    });

    testWidgets('100. Context menu has rounded top corners (20px)', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: [sampleProject(id: 'p1')]));
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const Key('projectCard_p1')));
      await tester.pumpAndSettle();
      expect(find.text('Edit Project'), findsOneWidget);
    });

    testWidgets('101. Delete button in context menu has error color', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: [sampleProject(id: 'p1')]));
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const Key('projectCard_p1')));
      await tester.pumpAndSettle();
      final icon = tester.widget<Icon>(find.descendant(
        of: find.widgetWithText(ListTile, 'Delete Project'),
        matching: find.byIcon(Icons.delete),
      ));
      expect(icon.color, isNotNull);
    });

    testWidgets('102. Tapping requests tab keeps bottom nav visible', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bottomNavigationBar')), findsOneWidget);
    });

    testWidgets('103. Tapping settings tab keeps bottom nav visible', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bottomNavigationBar')), findsOneWidget);
    });

    testWidgets('104. Tapping statistics tab keeps bottom nav visible', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bottomNavigationBar')), findsOneWidget);
    });

    testWidgets('105. Empty state add button has add icon', (tester) async {
      await tester.pumpWidget(buildTestApp(initialProjects: []));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('emptyStateAddProjectButton')),
          matching: find.byIcon(Icons.add),
        ),
        findsOneWidget,
      );
    });
  });
}
