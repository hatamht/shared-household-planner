import 'dart:io';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
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
import 'package:shared_household_planner/features/export/domain/entities/export_options.dart';
import 'package:shared_household_planner/features/export/domain/services/csv_generator.dart';
import 'package:shared_household_planner/features/export/domain/services/export_filename_builder.dart';
import 'package:shared_household_planner/features/export/domain/services/export_service.dart';
import 'package:shared_household_planner/features/export/domain/services/export_settlement_helper.dart';
import 'package:shared_household_planner/features/export/domain/services/pdf_generator.dart';
import 'package:shared_household_planner/features/export/domain/services/share_service.dart';
import 'package:shared_household_planner/features/export/presentation/pages/export_data_screen.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_project_by_id_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/settings/presentation/pages/settings_screen.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test Mocks & Localizations
// ─────────────────────────────────────────────────────────────────────────────
class _MockExportLoc extends AppLocalizations {
  _MockExportLoc(super.locale);

  static const _en = <String, String>{
    'app_name': 'Shared Household Planner',
    'export_data': 'Export Data',
    'export_data_desc': 'Export bills and settlement summary to CSV or PDF',
    'export_format': 'Export Format',
    'scope': 'Scope',
    'all_projects': 'All Projects',
    'select_date_range': 'Select Date Range',
    'all_time': 'All Time',
    'this_month': 'This Month',
    'last_month': 'Last Month',
    'custom_range': 'Custom Range',
    'start_date': 'Start Date',
    'end_date': 'End Date',
    'settlement_summary': 'Settlement Summary',
    'settlement_formula': 'Formula: net = paid - owed',
    'overview': 'Overview',
    'bills_count': 'Total Bills',
    'total_amount': 'Total Amount',
    'export_and_share': 'Export & Share',
    'export_file': 'Export File',
    'share_file': 'Share File',
    'export_success': 'Exported successfully',
    'export_failed': 'Export failed',
    'file_saved_to': 'File saved to',
    'export_options': 'Export Options',
    'export_csv': 'Export to CSV',
    'export_pdf': 'Export to PDF',
    'export_csv_desc': 'Spreadsheet-friendly transaction records',
    'export_pdf_desc': 'Formatted printable expense report',
    'account_info': 'Account Info',
    'theme_settings': 'Theme Settings',
    'preferences': 'Preferences',
    'data_management': 'Data Management',
    'about_app': 'About App',
  };

  static const _vi = <String, String>{
    'app_name': 'Trình quản lý hộ gia đình',
    'export_data': 'Xuất dữ liệu',
    'export_data_desc': 'Xuất chi tiêu và tổng kết quyết toán ra CSV hoặc PDF',
    'export_format': 'Định dạng xuất',
    'scope': 'Phạm vi',
    'all_projects': 'Tất cả dự án',
    'select_date_range': 'Chọn khoảng thời gian',
    'all_time': 'Tất cả',
    'this_month': 'Tháng này',
    'last_month': 'Tháng trước',
    'custom_range': 'Tùy chỉnh',
    'start_date': 'Từ ngày',
    'end_date': 'Đến ngày',
    'settlement_summary': 'Tổng kết quyết toán',
    'settlement_formula': 'Công thức: net = đã trả - nợ',
    'overview': 'Tổng quan',
    'bills_count': 'Tổng số hóa đơn',
    'total_amount': 'Tổng số tiền',
    'export_and_share': 'Xuất & Chia sẻ',
    'export_file': 'Xuất file',
    'share_file': 'Chia sẻ file',
    'export_success': 'Đã xuất file thành công',
    'export_failed': 'Xuất file thất bại',
    'file_saved_to': 'File đã lưu tại',
    'export_options': 'Tùy chọn xuất dữ liệu',
    'export_csv': 'Xuất file CSV',
    'export_pdf': 'Xuất file PDF',
    'export_csv_desc': 'Bảng tính dữ liệu chi tiêu chi tiết',
    'export_pdf_desc': 'Báo cáo chi tiêu định dạng PDF có thể in',
    'account_info': 'Thông tin tài khoản',
    'theme_settings': 'Cài đặt giao diện',
    'preferences': 'Tùy chọn',
    'data_management': 'Quản lý dữ liệu',
    'about_app': 'Thông tin ứng dụng',
  };

  @override
  String translate(String key) {
    if (locale.languageCode == 'vi') return _vi[key] ?? key;
    return _en[key] ?? key;
  }
}

class _ExportLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  final String lang;
  const _ExportLocDelegate([this.lang = 'en']);
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => _MockExportLoc(Locale(lang));
  @override
  bool shouldReload(_ExportLocDelegate old) => false;
}

class _FakeProjectRepo extends Fake implements ProjectRepository {
  List<Project> list = [];
  @override
  Future<Either<Failure, List<Project>>> getAllProjects() async => Right(list);
  @override
  Future<Either<Failure, Project>> getProjectById(String id) async =>
      Right(list.firstWhere((p) => p.id == id));
  @override
  Future<Either<Failure, Project>> createProject(Project p) async {
    list.add(p);
    return Right(p);
  }
  @override
  Future<Either<Failure, Project>> updateProject(Project p) async => Right(p);
  @override
  Future<Either<Failure, void>> deleteProject(String id) async {
    list.removeWhere((p) => p.id == id);
    return const Right(null);
  }
}

class _FakeBillRepo extends Fake implements BillRepository {
  List<Bill> list = [];
  @override
  Future<Either<Failure, List<Bill>>> getAll() async => Right(list);
  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async =>
      Right(list.where((b) => b.projectId == projectId).toList());
  @override
  Future<Either<Failure, Bill>> create(Bill b) async {
    list.add(b);
    return Right(b);
  }
  @override
  Future<Either<Failure, Bill>> getById(String billId) async =>
      Right(list.firstWhere((b) => b.id == billId));
  @override
  Future<Either<Failure, Bill>> update(Bill b) async => Right(b);
  @override
  Future<Either<Failure, void>> delete(String billId) async {
    list.removeWhere((b) => b.id == billId);
    return const Right(null);
  }
}

Widget buildExportTestApp({
  Widget? child,
  List<Bill>? bills,
  List<Project>? projects,
  ThemeProvider? themeProvider,
  LanguageProvider? languageProvider,
  String locale = 'en',
}) {
  final tp = themeProvider ?? ThemeProvider();
  final lp = languageProvider ?? LanguageProvider();

  final pRepo = _FakeProjectRepo();
  if (projects != null) pRepo.list = projects;

  final bRepo = _FakeBillRepo();
  if (bills != null) bRepo.list = bills;

  final pBloc = ProjectBloc(
    createProjectUseCase: CreateProjectUseCase(pRepo),
    getAllProjectsUseCase: GetAllProjectsUseCase(pRepo),
    getProjectByIdUseCase: GetProjectByIdUseCase(pRepo),
    updateProjectUseCase: UpdateProjectUseCase(pRepo),
    deleteProjectUseCase: DeleteProjectUseCase(pRepo),
  )..emit(ProjectLoaded(projects: projects ?? []));

  final bBloc = BillsBloc(
    getBillsUseCase: GetBillsUseCase(bRepo),
    addBillUseCase: AddBillUseCase(bRepo),
  )..emit(BillsLoaded(bills: bills ?? []));

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
          _ExportLocDelegate(locale),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('vi'),
        ],
        home: child ?? const ExportDataScreen(),
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

// ─────────────────────────────────────────────────────────────────────────────
// Sample Data Factories
// ─────────────────────────────────────────────────────────────────────────────
BillParticipant part(String name, double amount, [String? id]) {
  return BillParticipant(
    participantId: id ?? name.toLowerCase(),
    name: name,
    amount: amount,
  );
}

Bill createSampleBill({
  String id = 'b1',
  String title = 'Groceries',
  double amount = 50.0,
  String category = 'Food',
  String paidBy = 'Alice',
  DateTime? date,
  String? projectId,
  List<BillParticipant>? participants,
}) {
  return Bill(
    id: id,
    title: title,
    amount: amount,
    category: category,
    paidBy: paidBy,
    date: date ?? DateTime(2026, 9, 10),
    projectId: projectId,
    participants: participants ??
        [
          part('Alice', 25.0),
          part('Bob', 25.0),
        ],
  );
}

Project createSampleProject({
  String id = 'p1',
  String name = 'Apartment 4B',
  List<String>? members,
}) {
  return Project(
    id: id,
    name: name,
    members: members ?? ['Alice', 'Bob'],
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── GROUP 1: CSV Generator Unit Tests (AC 1, 5) ────────────────────────────
  group('1. CSV Generator Unit Tests (AC 1, 5)', () {
    const csvGen = CsvGenerator();

    test('1. Generates correct header: Date,Person,Amount,Category,Description', () {
      final csv = csvGen.generate(bills: [], includeSettlement: false);
      expect(csv.trim(), 'Date,Person,Amount,Category,Description');
    });

    test('2. Formats single bill correctly', () {
      final bill = createSampleBill(
        date: DateTime(2026, 5, 20),
        paidBy: 'Charlie',
        amount: 45.50,
        category: 'Transport',
        title: 'Train ticket',
      );
      final csv = csvGen.generate(bills: [bill], includeSettlement: false);
      expect(csv, contains('2026-05-20,Charlie,45.50,Transport,Train ticket'));
    });

    test('3. Formats multiple bills in order', () {
      final b1 = createSampleBill(id: '1', title: 'Coffee', amount: 10.0);
      final b2 = createSampleBill(id: '2', title: 'Lunch', amount: 20.0);
      final csv = csvGen.generate(bills: [b1, b2], includeSettlement: false);
      final lines = csv.trim().split('\n');
      expect(lines.length, 3);
      expect(lines[1], contains('Coffee'));
      expect(lines[2], contains('Lunch'));
    });

    test('4. Date format is strictly YYYY-MM-DD', () {
      final bill = createSampleBill(date: DateTime(2026, 1, 5));
      final csv = csvGen.generate(bills: [bill], includeSettlement: false);
      expect(csv, contains('2026-01-05'));
    });

    test('5. Amount is formatted to two decimals (e.g. 10.00)', () {
      final bill = createSampleBill(amount: 10.0);
      final csv = csvGen.generate(bills: [bill], includeSettlement: false);
      expect(csv, contains('10.00'));
    });

    test('6. Escapes fields containing commas with double quotes', () {
      final bill = createSampleBill(title: 'Milk, Bread, Butter');
      final csv = csvGen.generate(bills: [bill], includeSettlement: false);
      expect(csv, contains('"Milk, Bread, Butter"'));
    });

    test('7. Escapes double quotes inside fields by doubling them', () {
      final bill = createSampleBill(title: 'Item "Special" Promo');
      final csv = csvGen.generate(bills: [bill], includeSettlement: false);
      expect(csv, contains('"Item ""Special"" Promo"'));
    });

    test('8. Escapes fields containing newlines', () {
      final bill = createSampleBill(title: 'Line 1\nLine 2');
      final csv = csvGen.generate(bills: [bill], includeSettlement: false);
      expect(csv, contains('"Line 1\nLine 2"'));
    });

    test('9. Escapes person name containing comma', () {
      final bill = createSampleBill(paidBy: 'Doe, John');
      final csv = csvGen.generate(bills: [bill], includeSettlement: false);
      expect(csv, contains('"Doe, John"'));
    });

    test('10. Escapes category name containing commas', () {
      final bill = createSampleBill(category: 'Food, Drinks & Snacks');
      final csv = csvGen.generate(bills: [bill], includeSettlement: false);
      expect(csv, contains('"Food, Drinks & Snacks"'));
    });

    test('11. Empty bills list generates header and settlement status', () {
      final csv = csvGen.generate(bills: [], includeSettlement: true);
      expect(csv, contains('Date,Person,Amount,Category,Description'));
      expect(csv, contains('# Settlement Summary'));
      expect(csv, contains('All balances are settled!'));
    });

    test('12. Includes settlement section header when true', () {
      final bill = createSampleBill();
      final csv = csvGen.generate(bills: [bill], includeSettlement: true);
      expect(csv, contains('# Settlement Summary'));
      expect(csv, contains('From,To,Amount'));
    });

    test('13. Appends debtor to creditor in settlement section', () {
      // Alice paid 50. Alice share 25, Bob share 25 -> Bob owes Alice 25.00
      final bill = createSampleBill(
        paidBy: 'Alice',
        amount: 50.0,
        participants: [
          part('Alice', 25.0),
          part('Bob', 25.0),
        ],
      );
      final csv = csvGen.generate(bills: [bill], includeSettlement: true);
      expect(csv, contains('Bob,Alice,25.00'));
    });

    test('14. Appends all-settled message when everyone has net balance 0', () {
      final bill = createSampleBill(
        paidBy: 'Alice',
        amount: 25.0,
        participants: [
          part('Alice', 25.0),
        ],
      );
      final csv = csvGen.generate(bills: [bill], includeSettlement: true);
      expect(csv, contains('All balances are settled!'));
    });

    test('15. Unicode Vietnamese characters render accurately without corruption', () {
      final bill = createSampleBill(
        title: 'Ăn tối bún chả Hà Nội',
        category: 'Ăn uống & Tiệc tùng',
        paidBy: 'Nguyễn Văn A',
      );
      final csv = csvGen.generate(bills: [bill], includeSettlement: false);
      expect(csv, contains('Ăn tối bún chả Hà Nội'));
      expect(csv, contains('Ăn uống & Tiệc tùng'));
      expect(csv, contains('Nguyễn Văn A'));
    });

    test('16. Setting includeSettlement to false completely omits settlement', () {
      final bill = createSampleBill();
      final csv = csvGen.generate(bills: [bill], includeSettlement: false);
      expect(csv, isNot(contains('# Settlement Summary')));
      expect(csv, isNot(contains('From,To,Amount')));
    });
  });

  // ── GROUP 2: PDF Generator Unit Tests (AC 2, 5) ────────────────────────────
  group('2. PDF Generator Unit Tests (AC 2, 5)', () {
    const pdfGen = PdfGenerator();

    test('17. Generates non-empty Uint8List', () async {
      final bytes = await pdfGen.generate(bills: []);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('18. Generated binary starts with PDF magic header %PDF-', () async {
      final bytes = await pdfGen.generate(bills: []);
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, '%PDF-');
    });

    test('19. Generated binary ends with %%EOF marker', () async {
      final bytes = await pdfGen.generate(bills: []);
      final tail = String.fromCharCodes(bytes.skip(bytes.length - 20));
      expect(tail, contains('%%EOF'));
    });

    test('20. Handles custom project name in PDF', () async {
      final bytes = await pdfGen.generate(
        bills: [],
        projectName: 'Summer Vacation 2026',
      );
      expect(bytes, isNotEmpty);
    });

    test('21. Handles null project name gracefully', () async {
      final bytes = await pdfGen.generate(bills: [], projectName: null);
      expect(bytes, isNotEmpty);
    });

    test('22. Handles empty bills list gracefully', () async {
      final bytes = await pdfGen.generate(bills: []);
      expect(bytes, isNotEmpty);
    });

    test('23. Handles multiple bills in table formatting', () async {
      final b1 = createSampleBill(id: '1', title: 'Taxi', amount: 15.0);
      final b2 = createSampleBill(id: '2', title: 'Museum', amount: 30.0);
      final bytes = await pdfGen.generate(bills: [b1, b2]);
      expect(bytes.length, greaterThan(500));
    });

    test('24. Handles custom currency symbol (£, \$, ₫, €)', () async {
      final bill = createSampleBill(amount: 100.0);
      final bytes = await pdfGen.generate(bills: [bill], currencySymbol: '₫');
      expect(bytes, isNotEmpty);
    });

    test('25. Includes dateRangeLabel in PDF metadata', () async {
      final bytes = await pdfGen.generate(
        bills: [],
        dateRangeLabel: 'May 2026',
      );
      expect(bytes, isNotEmpty);
    });

    test('26. Includes settlement section when debts exist', () async {
      final bill = createSampleBill(
        paidBy: 'Alice',
        amount: 80.0,
        participants: [
          part('Alice', 40.0),
          part('Bob', 40.0),
        ],
      );
      final bytes = await pdfGen.generate(bills: [bill], includeSettlement: true);
      expect(bytes, isNotEmpty);
    });

    test('27. Renders all-settled callout box when debts are empty', () async {
      final bill = createSampleBill(
        paidBy: 'Alice',
        amount: 40.0,
        participants: [
          part('Alice', 40.0),
        ],
      );
      final bytes = await pdfGen.generate(bills: [bill], includeSettlement: true);
      expect(bytes, isNotEmpty);
    });

    test('28. Omits settlement section when includeSettlement is false', () async {
      final bill = createSampleBill();
      final bytes = await pdfGen.generate(bills: [bill], includeSettlement: false);
      expect(bytes, isNotEmpty);
    });
  });

  // ── GROUP 3: Date Range & Project Filtering (AC 3, 4) ──────────────────────
  group('3. Date Range & Project Filtering (AC 3, 4)', () {
    final refDate = DateTime(2026, 9, 15);

    final b1 = createSampleBill(id: '1', date: DateTime(2026, 9, 10), projectId: 'p1'); // This month
    final b2 = createSampleBill(id: '2', date: DateTime(2026, 9, 1), projectId: 'p2');  // This month
    final b3 = createSampleBill(id: '3', date: DateTime(2026, 8, 20), projectId: 'p1'); // Last month
    final b4 = createSampleBill(id: '4', date: DateTime(2026, 7, 10), projectId: 'p2'); // Older
    final allBills = [b1, b2, b3, b4];

    test('29. All Time returns all bills without date filter', () {
      final filter = ExportFilter(
        dateRange: ExportDateRange.allTime,
        referenceDate: refDate,
      );
      final result = filter.filterBills(allBills);
      expect(result.length, 4);
    });

    test('30. This Month returns only bills in September 2026', () {
      final filter = ExportFilter(
        dateRange: ExportDateRange.thisMonth,
        referenceDate: refDate,
      );
      final result = filter.filterBills(allBills);
      expect(result.length, 2);
      expect(result.map((b) => b.id), containsAll(['1', '2']));
    });

    test('31. Last Month returns only bills in August 2026', () {
      final filter = ExportFilter(
        dateRange: ExportDateRange.lastMonth,
        referenceDate: refDate,
      );
      final result = filter.filterBills(allBills);
      expect(result.length, 1);
      expect(result.first.id, '3');
    });

    test('32. Last Month correctly wraps January to December previous year', () {
      final janRef = DateTime(2026, 1, 15);
      final decBill = createSampleBill(id: 'dec', date: DateTime(2025, 12, 25));
      final janBill = createSampleBill(id: 'jan', date: DateTime(2026, 1, 10));

      final filter = ExportFilter(
        dateRange: ExportDateRange.lastMonth,
        referenceDate: janRef,
      );
      final result = filter.filterBills([decBill, janBill]);
      expect(result.length, 1);
      expect(result.first.id, 'dec');
    });

    test('33. Custom Range filters bills inclusively between start and end date', () {
      final filter = ExportFilter(
        dateRange: ExportDateRange.custom,
        customStartDate: DateTime(2026, 8, 1),
        customEndDate: DateTime(2026, 9, 5),
        referenceDate: refDate,
      );
      final result = filter.filterBills(allBills);
      expect(result.length, 2);
      expect(result.map((b) => b.id), containsAll(['2', '3']));
    });

    test('34. Custom Range with only start date filters bills on or after start', () {
      final filter = ExportFilter(
        dateRange: ExportDateRange.custom,
        customStartDate: DateTime(2026, 8, 15),
        referenceDate: refDate,
      );
      final result = filter.filterBills(allBills);
      expect(result.length, 3);
      expect(result.map((b) => b.id), containsAll(['1', '2', '3']));
    });

    test('35. Custom Range with only end date filters bills on or before end', () {
      final filter = ExportFilter(
        dateRange: ExportDateRange.custom,
        customEndDate: DateTime(2026, 8, 1),
        referenceDate: refDate,
      );
      final result = filter.filterBills(allBills);
      expect(result.length, 1);
      expect(result.first.id, '4');
    });

    test('36. Scope All Projects (projectId: null) returns bills from all projects', () {
      const filter = ExportFilter(projectId: null);
      final result = filter.filterBills(allBills);
      expect(result.length, 4);
    });

    test('37. Scope All Projects (projectId: empty string) returns bills from all projects', () {
      const filter = ExportFilter(projectId: '');
      final result = filter.filterBills(allBills);
      expect(result.length, 4);
    });

    test('38. Scope Single Project filters exclusively to matching projectId', () {
      const filter = ExportFilter(projectId: 'p1');
      final result = filter.filterBills(allBills);
      expect(result.length, 2);
      expect(result.every((b) => b.projectId == 'p1'), isTrue);
    });

    test('39. Scope with non-existent projectId returns empty list', () {
      const filter = ExportFilter(projectId: 'non_existent_project');
      final result = filter.filterBills(allBills);
      expect(result, isEmpty);
    });

    test('40. Combined Single Project + This Month filter works together', () {
      final filter = ExportFilter(
        projectId: 'p1',
        dateRange: ExportDateRange.thisMonth,
        referenceDate: refDate,
      );
      final result = filter.filterBills(allBills);
      expect(result.length, 1);
      expect(result.first.id, '1');
    });
  });

  // ── GROUP 4: Settlement Calculation Helper (AC 5) ──────────────────────────
  group('4. Settlement Calculation Helper (AC 5)', () {
    test('41. Empty bills returns empty settlement and empty net balances', () {
      final summary = ExportSettlementHelper.calculate([]);
      expect(summary.settlements, isEmpty);
      expect(summary.isAllSettled, isTrue);
      expect(summary.netBalances, isEmpty);
    });

    test('42. Single participant bill is all settled', () {
      final bill = createSampleBill(
        paidBy: 'Alice',
        amount: 50.0,
        participants: [part('Alice', 50.0)],
      );
      final summary = ExportSettlementHelper.calculate([bill]);
      expect(summary.settlements, isEmpty);
      expect(summary.isAllSettled, isTrue);
      expect(summary.netBalances['Alice'], 0.0);
    });

    test('43. Two participants: Alice paid 100, Bob share 50 -> Bob owes Alice 50', () {
      final bill = createSampleBill(
        paidBy: 'Alice',
        amount: 100.0,
        participants: [
          part('Alice', 50.0),
          part('Bob', 50.0),
        ],
      );
      final summary = ExportSettlementHelper.calculate([bill]);
      expect(summary.settlements.length, 1);
      expect(summary.settlements.first.from, 'Bob');
      expect(summary.settlements.first.to, 'Alice');
      expect(summary.settlements.first.amount, 50.0);
    });

    test('44. Three participants equal split: Alice paid 90, each owes 30', () {
      final bill = createSampleBill(
        paidBy: 'Alice',
        amount: 90.0,
        participants: [
          part('Alice', 30.0),
          part('Bob', 30.0),
          part('Charlie', 30.0),
        ],
      );
      final summary = ExportSettlementHelper.calculate([bill]);
      expect(summary.settlements.length, 2);
      expect(summary.settlements.any((s) => s.from == 'Bob' && s.to == 'Alice' && s.amount == 30.0), isTrue);
      expect(summary.settlements.any((s) => s.from == 'Charlie' && s.to == 'Alice' && s.amount == 30.0), isTrue);
    });

    test('45. Multiple bills cancel out opposite debts', () {
      final b1 = createSampleBill(
        id: '1',
        paidBy: 'Alice',
        amount: 60.0,
        participants: [
          part('Alice', 30.0),
          part('Bob', 30.0),
        ],
      );
      final b2 = createSampleBill(
        id: '2',
        paidBy: 'Bob',
        amount: 60.0,
        participants: [
          part('Alice', 30.0),
          part('Bob', 30.0),
        ],
      );
      final summary = ExportSettlementHelper.calculate([b1, b2]);
      expect(summary.isAllSettled, isTrue);
      expect(summary.settlements, isEmpty);
    });

    test('46. Cyclic debts are minimized to direct transfers', () {
      // Alice pays 30 for Bob (Bob owes Alice 30)
      // Bob pays 30 for Charlie (Charlie owes Bob 30)
      // Net: Alice +30, Charlie -30, Bob 0 -> Charlie pays Alice 30 directly
      final b1 = createSampleBill(
        id: '1',
        paidBy: 'Alice',
        amount: 30.0,
        participants: [part('Bob', 30.0)],
      );
      final b2 = createSampleBill(
        id: '2',
        paidBy: 'Bob',
        amount: 30.0,
        participants: [part('Charlie', 30.0)],
      );
      final summary = ExportSettlementHelper.calculate([b1, b2]);
      expect(summary.settlements.length, 1);
      expect(summary.settlements.first.from, 'Charlie');
      expect(summary.settlements.first.to, 'Alice');
      expect(summary.settlements.first.amount, 30.0);
    });

    test('47. Sum of net balances across members equals 0', () {
      final b = createSampleBill(
        paidBy: 'Alice',
        amount: 100.0,
        participants: [
          part('Alice', 40.0),
          part('Bob', 35.0),
          part('Charlie', 25.0),
        ],
      );
      final summary = ExportSettlementHelper.calculate([b]);
      final sumNet = summary.netBalances.values.fold<double>(0, (s, v) => s + v);
      expect(sumNet.abs(), lessThan(0.001));
    });

    test('48. Ignores sub-cent rounding noise', () {
      final b = createSampleBill(
        paidBy: 'Alice',
        amount: 10.0,
        participants: [
          part('Alice', 9.998),
          part('Bob', 0.002),
        ],
      );
      final summary = ExportSettlementHelper.calculate([b]);
      expect(summary.settlements, isEmpty);
    });

    test('49. Tracks totalPaid per member correctly', () {
      final b1 = createSampleBill(paidBy: 'Alice', amount: 50.0);
      final b2 = createSampleBill(paidBy: 'Alice', amount: 25.0);
      final summary = ExportSettlementHelper.calculate([b1, b2]);
      expect(summary.totalPaid['Alice'], 75.0);
    });

    test('50. Tracks totalShare per member correctly', () {
      final b1 = createSampleBill(participants: [part('Bob', 20.0)]);
      final b2 = createSampleBill(participants: [part('Bob', 15.0)]);
      final summary = ExportSettlementHelper.calculate([b1, b2]);
      expect(summary.totalShare['Bob'], 35.0);
    });
  });

  // ── GROUP 5: Filename Builder & Slugification (AC 7) ────────────────────────
  group('5. Filename Builder & Slugification (AC 7)', () {
    const builder = ExportFilenameBuilder();
    final testDate = DateTime(2026, 9, 13);

    test('51. Generates all-projects-YYYY-MM-DD.csv when project is null', () {
      final filename = builder.build(
        projectName: null,
        date: testDate,
        format: ExportFormat.csv,
      );
      expect(filename, 'all-projects-2026-09-13.csv');
    });

    test('52. Generates all-projects-YYYY-MM-DD.pdf when project is All Projects', () {
      final filename = builder.build(
        projectName: 'All Projects',
        date: testDate,
        format: ExportFormat.pdf,
      );
      expect(filename, 'all-projects-2026-09-13.pdf');
    });

    test('53. Slugifies standard project name to lowercase with hyphens', () {
      final filename = builder.build(
        projectName: 'Apartment 4B Expenses',
        date: testDate,
        format: ExportFormat.csv,
      );
      expect(filename, 'apartment-4b-expenses-2026-09-13.csv');
    });

    test('54. Converts Vietnamese diacritics into ASCII slug', () {
      final filename = builder.build(
        projectName: 'Chuyến đi Đà Lạt',
        date: testDate,
        format: ExportFormat.pdf,
      );
      expect(filename, 'chuyen-di-da-lat-2026-09-13.pdf');
    });

    test('55. Strips special symbols and punctuation', () {
      final filename = builder.build(
        projectName: 'Project #1: Summer & Sun / 2026!',
        date: testDate,
        format: ExportFormat.csv,
      );
      expect(filename, 'project-1-summer-sun-2026-2026-09-13.csv');
    });

    test('56. Strips multiple consecutive hyphens and trims edges', () {
      final filename = builder.build(
        projectName: '---My---Trip---',
        date: testDate,
        format: ExportFormat.csv,
      );
      expect(filename, 'my-trip-2026-09-13.csv');
    });

    test('57. Uses current date when date parameter is omitted', () {
      final filename = builder.build(projectName: 'House');
      final today = DateTime.now();
      expect(filename, contains('${today.year}'));
      expect(filename, endsWith('.csv'));
    });

    test('58. Sets extension .csv for ExportFormat.csv', () {
      final filename = builder.build(format: ExportFormat.csv, date: testDate);
      expect(filename, endsWith('.csv'));
    });

    test('59. Sets extension .pdf for ExportFormat.pdf', () {
      final filename = builder.build(format: ExportFormat.pdf, date: testDate);
      expect(filename, endsWith('.pdf'));
    });

    test('60. Static slugify handles whitespace-only strings', () {
      expect(ExportFilenameBuilder.slugify('   '), 'all-projects');
    });
  });

  // ── GROUP 6: Share Service & Export Service (AC 6) ──────────────────────────
  group('6. Share Service & Export Service (AC 6)', () {
    test('61. FakeShareService records shared file path', () async {
      final fakeShare = FakeShareService();
      final success = await fakeShare.shareFile(filePath: '/tmp/test.csv');
      expect(success, isTrue);
      expect(fakeShare.sharedFiles, contains('/tmp/test.csv'));
    });

    test('62. FakeShareService records shared text', () async {
      final fakeShare = FakeShareService();
      await fakeShare.shareFile(filePath: '/tmp/test.csv', text: 'Summary');
      expect(fakeShare.sharedTexts, contains('Summary'));
    });

    test('63. FakeShareService handles failure when configured', () async {
      final fakeShare = FakeShareService()..shouldSucceed = false;
      final success = await fakeShare.shareFile(filePath: '/tmp/test.csv');
      expect(success, isFalse);
    });

    test('64. FakeShareService reset clears all history', () async {
      final fakeShare = FakeShareService();
      await fakeShare.shareFile(filePath: '/tmp/test.csv');
      fakeShare.reset();
      expect(fakeShare.sharedFiles, isEmpty);
      expect(fakeShare.sharedTexts, isEmpty);
    });

    test('65. ExportService exports CSV to custom directory', () async {
      final tempDir = Directory.systemTemp.createTempSync('export_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final exportService = ExportService(
        getOutputDirectory: () async => tempDir,
      );

      final bill = createSampleBill();
      final res = await exportService.exportToFile(
        bills: [bill],
        filter: const ExportFilter(format: ExportFormat.csv),
      );

      expect(res.success, isTrue);
      expect(res.filePath, isNotNull);
      expect(File(res.filePath!).existsSync(), isTrue);
      final content = File(res.filePath!).readAsStringSync();
      expect(content, contains('Date,Person,Amount,Category,Description'));
    });

    test('66. ExportService exports PDF to custom directory', () async {
      final tempDir = Directory.systemTemp.createTempSync('export_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final exportService = ExportService(
        getOutputDirectory: () async => tempDir,
      );

      final bill = createSampleBill();
      final res = await exportService.exportToFile(
        bills: [bill],
        filter: const ExportFilter(format: ExportFormat.pdf),
      );

      expect(res.success, isTrue);
      expect(res.filePath, isNotNull);
      expect(File(res.filePath!).existsSync(), isTrue);
      final bytes = File(res.filePath!).readAsBytesSync();
      expect(bytes, isNotEmpty);
    });

    test('67. ExportService exportAndShare triggers ShareService', () async {
      final tempDir = Directory.systemTemp.createTempSync('export_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final fakeShare = FakeShareService();
      final exportService = ExportService(
        getOutputDirectory: () async => tempDir,
        shareService: fakeShare,
      );

      final bill = createSampleBill();
      final res = await exportService.exportAndShare(
        bills: [bill],
        filter: const ExportFilter(format: ExportFormat.csv),
      );

      expect(res.success, isTrue);
      expect(fakeShare.sharedFiles, contains(res.filePath));
    });

    test('68. ExportService handles filesystem errors gracefully', () async {
      final exportService = ExportService(
        getOutputDirectory: () async => Directory('/invalid_dir_path_not_permitted'),
      );

      final bill = createSampleBill();
      final res = await exportService.exportToFile(
        bills: [bill],
        filter: const ExportFilter(format: ExportFormat.csv),
      );

      expect(res.success, isFalse);
      expect(res.error, isNotNull);
    });

    test('69. ExportService reports correct billCount matching filter', () async {
      final tempDir = Directory.systemTemp.createTempSync('export_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final exportService = ExportService(getOutputDirectory: () async => tempDir);
      final b1 = createSampleBill(id: '1', projectId: 'p1');
      final b2 = createSampleBill(id: '2', projectId: 'p2');

      final res = await exportService.exportToFile(
        bills: [b1, b2],
        filter: const ExportFilter(projectId: 'p1'),
      );

      expect(res.billCount, 1);
    });

    test('70. ExportResult failure factory sets success to false', () {
      final res = ExportResult.failure(
        format: ExportFormat.csv,
        billCount: 0,
        error: 'Disk full',
      );
      expect(res.success, isFalse);
      expect(res.error, 'Disk full');
    });
  });

  // ── GROUP 7: ExportDataScreen Widget & UI Layout (AC 1-8) ──────────────────
  group('7. ExportDataScreen Widget & UI Layout (AC 1-8)', () {
    testWidgets('71. Screen renders AppBar with title Export Data', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      expect(find.text('Export Data'), findsOneWidget);
    });

    testWidgets('72. Format selection card exists with Key exportFormatCard', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      expect(find.byKey(const Key('exportFormatCard')), findsOneWidget);
    });

    testWidgets('73. CSV choice chip exists with Key formatChip_csv', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      expect(find.byKey(const Key('formatChip_csv')), findsOneWidget);
      expect(find.text('CSV (.csv)'), findsOneWidget);
    });

    testWidgets('74. PDF choice chip exists with Key formatChip_pdf', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      expect(find.byKey(const Key('formatChip_pdf')), findsOneWidget);
      expect(find.text('PDF (.pdf)'), findsOneWidget);
    });

    testWidgets('75. CSV format is selected by default', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      final csvChip = tester.widget<ChoiceChip>(find.byKey(const Key('formatChip_csv')));
      expect(csvChip.selected, isTrue);
    });

    testWidgets('76. Project scope card exists with Key projectScopeCard', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      expect(find.byKey(const Key('projectScopeCard')), findsOneWidget);
    });

    testWidgets('77. Project dropdown selector exists with Key projectSelectorDropdown', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      expect(find.byKey(const Key('projectSelectorDropdown')), findsOneWidget);
    });

    testWidgets('78. Date range card exists with Key dateRangeCard', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      expect(find.byKey(const Key('dateRangeCard')), findsOneWidget);
    });

    testWidgets('79. All Time date range chip exists and is selected by default', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      expect(find.byKey(const Key('dateRange_allTime')), findsOneWidget);
      final chip = tester.widget<ChoiceChip>(find.byKey(const Key('dateRange_allTime')));
      expect(chip.selected, isTrue);
    });

    testWidgets('80. This Month date range chip exists', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      expect(find.byKey(const Key('dateRange_thisMonth')), findsOneWidget);
    });

    testWidgets('81. Last Month date range chip exists', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      expect(find.byKey(const Key('dateRange_lastMonth')), findsOneWidget);
    });

    testWidgets('82. Custom Range date range chip exists', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      expect(find.byKey(const Key('dateRange_custom')), findsOneWidget);
    });

    testWidgets('83. Settlement toggle card exists with Key settlementToggleCard', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      expect(find.byKey(const Key('settlementToggleCard')), findsOneWidget);
    });

    testWidgets('84. Settlement switch exists with Key includeSettlementSwitch', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      expect(find.byKey(const Key('includeSettlementSwitch')), findsOneWidget);
    });

    testWidgets('85. Settlement switch is enabled by default', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      final sw = tester.widget<SwitchListTile>(find.byKey(const Key('includeSettlementSwitch')));
      expect(sw.value, isTrue);
    });

    testWidgets('86. Preview card exists with Key exportPreviewCard', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      expect(find.byKey(const Key('exportPreviewCard')), findsOneWidget);
    });

    testWidgets('87. Displays preview bill count', (tester) async {
      final bills = [createSampleBill(id: '1'), createSampleBill(id: '2')];
      await pumpTestScreen(tester, buildExportTestApp(bills: bills));
      expect(find.byKey(const Key('previewBillCount')), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('88. Displays preview total amount', (tester) async {
      final bills = [createSampleBill(amount: 50.0), createSampleBill(amount: 30.0)];
      await pumpTestScreen(tester, buildExportTestApp(bills: bills));
      expect(find.byKey(const Key('previewTotalAmount')), findsOneWidget);
      expect(find.text('80.00'), findsOneWidget);
    });

    testWidgets('89. Displays preview filename with .csv extension by default', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      expect(find.byKey(const Key('previewFileName')), findsOneWidget);
      final textWidget = tester.widget<Text>(find.byKey(const Key('previewFileName')));
      expect(textWidget.data, endsWith('.csv'));
    });

    testWidgets('90. Primary action button Export & Share exists', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      expect(find.byKey(const Key('exportAndShareButton')), findsOneWidget);
      expect(find.text('Export & Share'), findsOneWidget);
    });

    testWidgets('91. Secondary action button Export File exists', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      expect(find.byKey(const Key('exportFileButton')), findsOneWidget);
      expect(find.text('Export File'), findsOneWidget);
    });
  });

  // ── GROUP 8: Screen Interactions & Format / Date Switching ─────────────────
  group('8. Screen Interactions & Format / Date Switching', () {
    testWidgets('92. Tapping PDF chip switches format to PDF and updates filename', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      await tester.tap(find.byKey(const Key('formatChip_pdf')));
      await tester.pumpAndSettle();

      final pdfChip = tester.widget<ChoiceChip>(find.byKey(const Key('formatChip_pdf')));
      expect(pdfChip.selected, isTrue);

      final textWidget = tester.widget<Text>(find.byKey(const Key('previewFileName')));
      expect(textWidget.data, endsWith('.pdf'));
    });

    testWidgets('93. Tapping CSV chip after PDF switches back to CSV', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      await tester.tap(find.byKey(const Key('formatChip_pdf')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('formatChip_csv')));
      await tester.pumpAndSettle();

      final csvChip = tester.widget<ChoiceChip>(find.byKey(const Key('formatChip_csv')));
      expect(csvChip.selected, isTrue);
      final textWidget = tester.widget<Text>(find.byKey(const Key('previewFileName')));
      expect(textWidget.data, endsWith('.csv'));
    });

    testWidgets('94. Initial format set to PDF starts with PDF selected', (tester) async {
      await pumpTestScreen(
        tester,
        buildExportTestApp(child: const ExportDataScreen(initialFormat: ExportFormat.pdf)),
      );
      final pdfChip = tester.widget<ChoiceChip>(find.byKey(const Key('formatChip_pdf')));
      expect(pdfChip.selected, isTrue);
    });

    testWidgets('95. Tapping Custom Range reveals start and end date picker buttons', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      expect(find.byKey(const Key('startDatePickerButton')), findsNothing);

      await tester.tap(find.byKey(const Key('dateRange_custom')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('startDatePickerButton')), findsOneWidget);
      expect(find.byKey(const Key('endDatePickerButton')), findsOneWidget);
    });

    testWidgets('96. Toggling Settlement switch updates switch value', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());
      final sw = find.byKey(const Key('includeSettlementSwitch'));
      await tester.tap(sw);
      await tester.pumpAndSettle();

      final updated = tester.widget<SwitchListTile>(sw);
      expect(updated.value, isFalse);
    });

    testWidgets('97. Tapping Export File invokes ExportService and shows SnackBar', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('export_ui_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final exportService = ExportService(getOutputDirectory: () async => tempDir);
      await pumpTestScreen(
        tester,
        buildExportTestApp(child: ExportDataScreen(exportService: exportService)),
      );

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('exportFileButton')));
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('File saved to:'), findsOneWidget);
    });

    testWidgets('98. Tapping Export & Share invokes ExportService share and shows SnackBar', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('export_ui_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final fakeShare = FakeShareService();
      final exportService = ExportService(
        getOutputDirectory: () async => tempDir,
        shareService: fakeShare,
      );

      await pumpTestScreen(
        tester,
        buildExportTestApp(child: ExportDataScreen(exportService: exportService)),
      );

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('exportAndShareButton')));
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeShare.sharedFiles, isNotEmpty);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Exported successfully:'), findsOneWidget);
    });
  });

  // ── GROUP 9: SettingsScreen Integration (AC 1, 2) ──────────────────────────
  group('9. SettingsScreen Integration (AC 1, 2)', () {
    testWidgets('99. SettingsScreen exportCsvTile triggers onExportCsv callback if provided', (tester) async {
      bool called = false;
      await pumpTestScreen(
        tester,
        buildExportTestApp(
          child: SettingsScreen(
            showAppBar: true,
            onExportCsv: () => called = true,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('exportCsvTile')));
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });

    testWidgets('100. SettingsScreen exportPdfTile triggers onExportPdf callback if provided', (tester) async {
      bool called = false;
      await pumpTestScreen(
        tester,
        buildExportTestApp(
          child: SettingsScreen(
            showAppBar: true,
            onExportPdf: () => called = true,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('exportPdfTile')));
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });

    testWidgets('101. SettingsScreen exportCsvTile navigates to ExportDataScreen', (tester) async {
      await pumpTestScreen(
        tester,
        buildExportTestApp(child: const SettingsScreen(showAppBar: true)),
      );

      await tester.tap(find.byKey(const Key('exportCsvTile')));
      await tester.pumpAndSettle();

      expect(find.byType(ExportDataScreen), findsOneWidget);
      final csvChip = tester.widget<ChoiceChip>(find.byKey(const Key('formatChip_csv')));
      expect(csvChip.selected, isTrue);
    });

    testWidgets('102. SettingsScreen exportPdfTile navigates to ExportDataScreen with PDF pre-selected', (tester) async {
      await pumpTestScreen(
        tester,
        buildExportTestApp(child: const SettingsScreen(showAppBar: true)),
      );

      await tester.tap(find.byKey(const Key('exportPdfTile')));
      await tester.pumpAndSettle();

      expect(find.byType(ExportDataScreen), findsOneWidget);
      final pdfChip = tester.widget<ChoiceChip>(find.byKey(const Key('formatChip_pdf')));
      expect(pdfChip.selected, isTrue);
    });
  });

  // ── GROUP 10: Theme & Localization (AC 5, 8) ───────────────────────────────
  group('10. Theme & Localization (AC 5, 8)', () {
    testWidgets('103. Light theme renders cards with white background', (tester) async {
      final tp = ThemeProvider();
      await tp.setDarkMode(false);
      await pumpTestScreen(tester, buildExportTestApp(themeProvider: tp));

      final card = tester.widget<Card>(find.byKey(const Key('exportFormatCard')));
      expect(card.color, Colors.white);
    });

    testWidgets('104. Dark theme renders cards with dark (#1E1E1E) background', (tester) async {
      final tp = ThemeProvider();
      await tp.setDarkMode(true);
      await pumpTestScreen(tester, buildExportTestApp(themeProvider: tp));

      final card = tester.widget<Card>(find.byKey(const Key('exportFormatCard')));
      expect(card.color, const Color(0xFF1E1E1E));
    });

    testWidgets('105. All cards have 16px circular border radius', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp());

      final cardKeys = [
        'exportFormatCard',
        'projectScopeCard',
        'dateRangeCard',
        'settlementToggleCard',
        'exportPreviewCard',
      ];

      for (final k in cardKeys) {
        final card = tester.widget<Card>(find.byKey(Key(k)));
        final shape = card.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(16));
      }
    });

    testWidgets('106. Vietnamese locale renders translated export labels', (tester) async {
      await pumpTestScreen(tester, buildExportTestApp(locale: 'vi'));

      expect(find.text('Xuất dữ liệu'), findsOneWidget);
      expect(find.text('Định dạng xuất'), findsOneWidget);
      expect(find.text('Phạm vi'), findsOneWidget);
      expect(find.text('Chọn khoảng thời gian'), findsOneWidget);
      expect(find.text('Tổng quan'), findsOneWidget);
      expect(find.text('Xuất & Chia sẻ'), findsOneWidget);
      expect(find.text('Xuất file'), findsOneWidget);
    });
  });

  // ── GROUP 11: PDF Currency Symbol & Font Glyph Safety (Shared-60) ──────────
  group('11. PDF Currency Symbol, Font Glyph Safety & Project Currency Binding (Shared-60)', () {
    test('107. formatCurrencyAmount formats VND without decimals and with VND suffix', () {
      expect(PdfGenerator.formatCurrencyAmount(150000, 'VND'), '150,000 VND');
      expect(PdfGenerator.formatCurrencyAmount(0, 'VND'), '0 VND');
    });

    test('108. formatCurrencyAmount maps ₫ and đ to VND to avoid broken glyphs', () {
      expect(PdfGenerator.formatCurrencyAmount(250000, '₫'), '250,000 VND');
      expect(PdfGenerator.formatCurrencyAmount(50000, 'đ'), '50,000 VND');
    });

    test('109. formatCurrencyAmount formats USD with \$ prefix and 2 decimals', () {
      expect(PdfGenerator.formatCurrencyAmount(123.45, 'USD'), '\$123.45');
      expect(PdfGenerator.formatCurrencyAmount(100, '\$'), '\$100.00');
    });

    test('110. formatCurrencyAmount formats EUR with 2 decimals', () {
      expect(PdfGenerator.formatCurrencyAmount(45.5, 'EUR'), '45.50 EUR');
      expect(PdfGenerator.formatCurrencyAmount(99, '€'), '€99.00');
    });

    test('111. formatCurrencyAmount formats JPY with ¥ prefix and 0 decimals', () {
      expect(PdfGenerator.formatCurrencyAmount(1200, 'JPY'), '¥1,200');
      expect(PdfGenerator.formatCurrencyAmount(500, '¥'), '¥500');
    });

    test('112. formatCurrencyAmount formats GBP with £ prefix and 2 decimals', () {
      expect(PdfGenerator.formatCurrencyAmount(75.2, 'GBP'), '£75.20');
      expect(PdfGenerator.formatCurrencyAmount(10, '£'), '£10.00');
    });

    test('113. PdfGenerator generates valid PDF bytes with VND currency', () async {
      final generator = const PdfGenerator();
      final bill = createSampleBill(
        id: 'b1',
        title: 'Dinner',
        amount: 250000,
        paidBy: 'u1',
        projectId: 'p1',
      );

      final pdfBytes = await generator.generate(
        bills: [bill],
        projectName: 'Household VND',
        currencySymbol: 'VND',
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46])); // %PDF
    });

    test('114. PdfGenerator generates valid PDF bytes with ₫ currency safely mapped', () async {
      final generator = const PdfGenerator();
      final bill = createSampleBill(
        id: 'b2',
        title: 'Coffee',
        amount: 50000,
        paidBy: 'u1',
        projectId: 'p1',
      );

      final pdfBytes = await generator.generate(
        bills: [bill],
        projectName: 'Household Dong',
        currencySymbol: '₫',
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46])); // %PDF
    });

    test('115. ExportService defaults currencySymbol to VND when exporting PDF', () async {
      final tempDir = Directory.systemTemp.createTempSync('export_vnd_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final exportService = ExportService(
        getOutputDirectory: () async => tempDir,
      );

      final bill = createSampleBill(
        id: 'b3',
        title: 'Groceries',
        amount: 300000,
        paidBy: 'u1',
      );

      final filter = const ExportFilter(
        format: ExportFormat.pdf,
        dateRange: ExportDateRange.allTime,
      );

      final result = await exportService.exportToFile(
        bills: [bill],
        filter: filter,
      );

      expect(result.success, isTrue);
      final file = File(result.filePath!);
      expect(await file.exists(), isTrue);
    });

    testWidgets('116. ExportDataScreen resolves currency from selected project and exports', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('export_screen_curr_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      String? capturedCurrency;
      final mockPdf = _CapturePdfGenerator(onGenerate: (curr) => capturedCurrency = curr);

      final exportService = ExportService(
        pdfGenerator: mockPdf,
        getOutputDirectory: () async => tempDir,
      );

      final p = Project(
        id: 'proj_usd',
        name: 'US Trip',
        members: const ['Alice'],
        currency: 'USD',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final bill = createSampleBill(
        id: 'b_usd',
        title: 'Taxi',
        amount: 45.0,
        paidBy: 'Alice',
        projectId: 'proj_usd',
      );

      await pumpTestScreen(
        tester,
        buildExportTestApp(
          projects: [p],
          bills: [bill],
          child: ExportDataScreen(
            exportService: exportService,
            initialProjectId: 'proj_usd',
            initialFormat: ExportFormat.pdf,
          ),
        ),
      );

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('exportFileButton')));
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(capturedCurrency, equals('USD'));
    });
  });
}

class _CapturePdfGenerator extends PdfGenerator {
  final void Function(String currency) onGenerate;
  const _CapturePdfGenerator({required this.onGenerate});

  @override
  Future<Uint8List> generate({
    required List<Bill> bills,
    String? projectName,
    String? dateRangeLabel,
    String currencySymbol = 'VND',
    bool includeSettlement = true,
    dynamic settlementLogs,
  }) async {
    onGenerate(currencySymbol);
    return Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
  }
}

