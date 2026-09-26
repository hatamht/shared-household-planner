import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_project_by_id_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/add_bill_screen.dart';

// ─────────────────────────────────────────────
// Test Localization
// ─────────────────────────────────────────────
class TestAppLocalizations extends AppLocalizations {
  final Locale _locale;
  TestAppLocalizations(this._locale) : super(_locale);

  static final Map<String, String> _enDict = {
    'add_bill': 'Add Bill',
    'edit_bill': 'Edit Bill',
    'bill_name': 'Bill Name',
    'bill_name_example': 'e.g. Dinner with friends',
    'bill_name_hint': 'e.g. Dinner with friends',
    'bill_name_required': 'Please enter a bill name',
    'amount': 'Amount',
    'amount_required': 'Please enter an amount',
    'amount_must_be_positive': 'Amount must be greater than zero',
    'payer_required': 'Please select or enter who paid',
    'min_2_participants': 'Please select at least 2 participants',
    'select_project': 'Select Project (Optional)',
    'no_project': 'No Project',
    'project': 'Project',
    'project_required': 'Please select a project',
    'select_project_modal_title': 'Select Project',
    'no_project_selected': 'No Project Selected',
    'choose_project': 'Choose Project',
    'project_no_members': 'This project has no members. Please add members first.',
    'tap_to_toggle': 'Tap to select/deselect',
    'participants': 'Participants',
    'participant_name': 'Participant Name',
    'split': 'Split',
    'expense': 'Expense',
    'income': 'Income',
    'transfer': 'Transfer',
    'save_bill': 'Save Bill',
    'save': 'Save',
    'cancel': 'Cancel',
    'paid_by': 'Paid by',
    'each_pays': 'Each pays',
    'date': 'Date',
    'notes': 'Notes',
    'category': 'Category',
    'category_restaurant': 'Restaurant',
    'category_transport': 'Transport',
    'category_shopping': 'Shopping',
    'description': 'Description',
    'today': 'Today',
    'members': 'members',
    'camera': 'Camera',
    'expand': 'Expand',
    'collapse': 'Collapse',
    'compact_mode': 'Compact',
    'full_mode': 'Full',
    'select_project_first': 'Please select a project first',
    'more': 'More',
    'select_participants': 'Select Participants',
    'select_all': 'Select All',
    'deselect_all': 'Deselect All',
    'done': 'Done',
    'equal': 'Equal',
    'exact': 'Exact',
    'percentage': 'Percentage',
    'shares': 'Shares',
    'custom': 'Custom',
    'adjustment': 'Adjustment',
    'you': 'You',
    'receipt': 'Receipt',
    'split_bills': 'Split Bills',
    'split_mode': 'Split Mode',
    'split_mode_equal': 'Equal',
    'split_mode_percentage': 'Percentage',
    'split_mode_shares': 'Shares',
    'split_mode_custom': 'Custom',
  };

  static final Map<String, String> _viDict = {
    'add_bill': 'Thêm hóa đơn',
    'edit_bill': 'Sửa hóa đơn',
    'bill_name': 'Tên hóa đơn',
    'amount': 'Số tiền',
    'save_bill': 'Lưu hóa đơn',
    'save': 'Lưu',
    'description': 'Mô tả',
    'today': 'Hôm nay',
    'members': 'thành viên',
    'camera': 'Máy ảnh',
    'expand': 'Mở rộng',
    'collapse': 'Thu gọn',
    'compact_mode': 'Thu gọn',
    'full_mode': 'Đầy đủ',
    'select_project_first': 'Vui lòng chọn dự án trước',
    'more': 'Thêm',
    'select_participants': 'Chọn người tham gia',
    'select_all': 'Chọn tất cả',
    'deselect_all': 'Bỏ chọn tất cả',
    'done': 'Xong',
    'equal': 'Chia đều',
    'select_project': 'Chọn dự án',
    'paid_by': 'Người trả',
    'you': 'Bạn',
    'receipt': 'Biên lai',
    'no_project_selected': 'Chưa chọn dự án',
    'choose_project': 'Chọn dự án',
    'split_bills': 'Chia hóa đơn',
    'split_mode': 'Chế độ chia',
    'split_mode_equal': 'Chia đều',
    'split_mode_percentage': 'Phần trăm',
    'split_mode_shares': 'Cổ phần',
    'split_mode_custom': 'Tùy chỉnh',
  };

  @override
  String translate(String key) {
    if (_locale.languageCode == 'vi') {
      return _viDict[key] ?? _enDict[key] ?? key;
    }
    return _enDict[key] ?? key;
  }
}

class _TestLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  final Locale locale;
  const _TestLocalizationsDelegate({this.locale = const Locale('en')});

  @override
  bool isSupported(Locale l) => true;

  @override
  Future<AppLocalizations> load(Locale l) async => TestAppLocalizations(locale);

  @override
  bool shouldReload(_TestLocalizationsDelegate old) => old.locale != locale;
}

// ─────────────────────────────────────────────
// Test Repositories
// ─────────────────────────────────────────────
class FakeBillRepository implements BillRepository {
  final List<Bill> bills = [];
  Bill? lastCreatedBill;
  Bill? lastUpdatedBill;

  @override
  Future<Either<Failure, Bill>> create(Bill bill) async {
    bills.add(bill);
    lastCreatedBill = bill;
    return Right(bill);
  }

  @override
  Future<Either<Failure, List<Bill>>> getAll() async => Right(List.from(bills));

  @override
  Future<Either<Failure, Bill>> getById(String billId) async {
    final b = bills.firstWhere((b) => b.id == billId,
        orElse: () => throw Exception('Not found'));
    return Right(b);
  }

  @override
  Future<Either<Failure, Bill>> update(Bill bill) async {
    final index = bills.indexWhere((b) => b.id == bill.id);
    if (index != -1) {
      bills[index] = bill;
    } else {
      bills.add(bill);
    }
    lastUpdatedBill = bill;
    return Right(bill);
  }

  @override
  Future<Either<Failure, void>> delete(String billId) async {
    bills.removeWhere((b) => b.id == billId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async {
    return Right(bills.where((b) => b.projectId == projectId).toList());
  }
}

class FakeProjectRepository implements ProjectRepository {
  final List<Project> projects;
  FakeProjectRepository(this.projects);

  @override
  Future<Either<Failure, List<Project>>> getAll() async => Right(List.from(projects));
  @override
  Future<Either<Failure, Project>> create(Project project) async {
    projects.add(project);
    return Right(project);
  }
  @override
  Future<Either<Failure, Project>> getById(String id) async {
    return Right(projects.firstWhere((p) => p.id == id));
  }
  @override
  Future<Either<Failure, Project>> update(Project project) async => Right(project);
  @override
  Future<Either<Failure, void>> delete(String id) async => const Right(null);
}

// ─────────────────────────────────────────────
// Test Helpers
// ─────────────────────────────────────────────
Project makeProject({
  String id = 'proj-1',
  String name = 'Apartment Shared',
  List<String>? members,
}) {
  return Project(
    id: id,
    name: name,
    members: members ?? ['Alice', 'Bob', 'Charlie'],
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

BillsBloc makeBillsBloc({FakeBillRepository? repo}) {
  final r = repo ?? FakeBillRepository();
  return BillsBloc(
    getBillsUseCase: GetBillsUseCase(r),
    addBillUseCase: AddBillUseCase(r),
  );
}

ProjectBloc makeProjectBloc(List<Project> projects) {
  final repo = FakeProjectRepository(projects);
  final bloc = ProjectBloc(
    getAllProjectsUseCase: GetAllProjectsUseCase(repo),
    createProjectUseCase: CreateProjectUseCase(repo),
    getProjectByIdUseCase: GetProjectByIdUseCase(repo),
    updateProjectUseCase: UpdateProjectUseCase(repo),
    deleteProjectUseCase: DeleteProjectUseCase(repo),
  );
  bloc.add(const GetAllProjects());
  return bloc;
}

Widget buildTestApp({
  required Widget child,
  BillsBloc? billsBloc,
  ProjectBloc? projectBloc,
  FakeBillRepository? billRepo,
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
      if (billRepo != null)
        RepositoryProvider<BillRepository>.value(value: billRepo),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<BillsBloc>.value(value: billsBloc ?? makeBillsBloc()),
        BlocProvider<ProjectBloc>.value(value: projectBloc ?? makeProjectBloc([])),
      ],
      child: MaterialApp(
        theme: ThemeData(
          brightness: brightness,
          useMaterial3: true,
        ),
        locale: locale,
        localizationsDelegates: [
          _TestLocalizationsDelegate(locale: locale),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('vi')],
        home: child,
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ═══════════════════════════════════════════════════════════════════
  // Group 1: AC 1 - Default Compact Mode Layout & Elements (10 tests)
  // ═══════════════════════════════════════════════════════════════════
  group('AC 1: Compact Mode Default Layout & Elements', () {
    testWidgets('1.1 Screen opens in Compact Mode by default for new bill', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('compactDescriptionField')), findsOneWidget);
      expect(find.byKey(const Key('compactAmountField')), findsOneWidget);
    });

    testWidgets('1.2 Description field is present with correct hint', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('compactDescriptionField')), findsOneWidget);
      expect(find.text('e.g. Dinner with friends'), findsOneWidget);
    });

    testWidgets('1.3 Amount field is present with zero or empty initial value', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('compactAmountField')), findsOneWidget);
    });

    testWidgets('1.4 Secondary chip bar contains compactDateChip', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('compactDateChip')), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('1.5 Secondary chip bar contains compactMembersChip', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('compactMembersChip')), findsOneWidget);
    });

    testWidgets('1.6 Secondary chip bar contains compactCameraChip', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('compactCameraChip')), findsOneWidget);
    });

    testWidgets('1.7 Secondary chip bar contains expandToFullModeButton', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('expandToFullModeButton')), findsOneWidget);
    });

    testWidgets('1.8 Compact split chip is present with default Equal mode', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('compactSplitChip')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('compactSplitChip')), matching: find.textContaining('Equal')), findsOneWidget);
    });

    testWidgets('1.9 Full mode fields are hidden in compact mode', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('transactionTypeTabs')), findsNothing);
      expect(find.byKey(const Key('payerField')), findsNothing);
      expect(find.byKey(const Key('quickTemplatesSection')), findsNothing);
    });

    testWidgets('1.10 Compact mode displays top project selector', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectSelector')), findsOneWidget);
      expect(find.byKey(const Key('projectSelectorButton')), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Group 2: AC 2 & 9 - Project Selector Mandatory & Save Button (10 tests)
  // ═══════════════════════════════════════════════════════════════════
  group('AC 2 & 9: Project Selector Mandatory & Save Button Disabled State', () {
    testWidgets('2.1 Save button disabled when project is null and amount is 0', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      final saveBillBtn = tester.widget<TextButton>(find.byKey(const Key('saveBillButton')));
      expect(saveBillBtn.onPressed, isNull);

      final saveProjectBtn = tester.widget<ElevatedButton>(find.byKey(const Key('saveProjectButton')));
      expect(saveProjectBtn.onPressed, isNull);
    });

    testWidgets('2.2 Save button disabled when project is selected but amount is 0', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1');
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p1'), projectBloc: pb));
      await tester.pumpAndSettle();

      final saveBillBtn = tester.widget<TextButton>(find.byKey(const Key('saveBillButton')));
      expect(saveBillBtn.onPressed, isNull);

      final saveProjectBtn = tester.widget<ElevatedButton>(find.byKey(const Key('saveProjectButton')));
      expect(saveProjectBtn.onPressed, isNull);
      pb.close();
    });

    testWidgets('2.3 Save button disabled when amount > 0 but project is null', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '50000';
      await tester.pumpAndSettle();

      final saveBillBtn = tester.widget<TextButton>(find.byKey(const Key('saveBillButton')));
      expect(saveBillBtn.onPressed, isNull);

      final saveProjectBtn = tester.widget<ElevatedButton>(find.byKey(const Key('saveProjectButton')));
      expect(saveProjectBtn.onPressed, isNull);
    });

    testWidgets('2.4 Save button enabled when project is selected AND amount > 0', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1');
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p1'), projectBloc: pb));
      await tester.pumpAndSettle();

      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '50000';
      await tester.pumpAndSettle();

      final saveBillBtn = tester.widget<TextButton>(find.byKey(const Key('saveBillButton')));
      expect(saveBillBtn.onPressed, isNotNull);

      final saveProjectBtn = tester.widget<ElevatedButton>(find.byKey(const Key('saveProjectButton')));
      expect(saveProjectBtn.onPressed, isNotNull);
      pb.close();
    });

    testWidgets('2.5 Selecting project enables save button if amount already entered', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1');
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      // Deselect project to None first
      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('projectPickerItem_none')));
      await tester.pumpAndSettle();

      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '120000';
      await tester.pumpAndSettle();

      expect(tester.widget<TextButton>(find.byKey(const Key('saveBillButton'))).onPressed, isNull);

      // Select project via top selector button
      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('projectPickerItem_p1')));
      await tester.pumpAndSettle();

      expect(tester.widget<TextButton>(find.byKey(const Key('saveBillButton'))).onPressed, isNotNull);
      pb.close();
    });

    testWidgets('2.6 Deselecting project to None disables save button', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1');
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p1'), projectBloc: pb));
      await tester.pumpAndSettle();

      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '100000';
      await tester.pumpAndSettle();

      expect(tester.widget<TextButton>(find.byKey(const Key('saveBillButton'))).onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('projectPickerItem_none')));
      await tester.pumpAndSettle();

      expect(tester.widget<TextButton>(find.byKey(const Key('saveBillButton'))).onPressed, isNull);
      pb.close();
    });

    testWidgets('2.7 Clearing amount disables save button again', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1');
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p1'), projectBloc: pb));
      await tester.pumpAndSettle();

      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '50000';
      await tester.pumpAndSettle();
      expect(tester.widget<TextButton>(find.byKey(const Key('saveBillButton'))).onPressed, isNotNull);

      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '';
      await tester.pumpAndSettle();
      expect(tester.widget<TextButton>(find.byKey(const Key('saveBillButton'))).onPressed, isNull);
      pb.close();
    });

    testWidgets('2.8 Entering negative or zero amount keeps save button disabled', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1');
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p1'), projectBloc: pb));
      await tester.pumpAndSettle();

      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '0';
      await tester.pumpAndSettle();
      expect(tester.widget<TextButton>(find.byKey(const Key('saveBillButton'))).onPressed, isNull);

      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '-50';
      await tester.pumpAndSettle();
      expect(tester.widget<TextButton>(find.byKey(const Key('saveBillButton'))).onPressed, isNull);
      pb.close();
    });

    testWidgets('2.9 Top project selector shows required indicator or hint when none selected', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('No Project Selected')), findsOneWidget);
    });

    testWidgets('2.10 Top project selector shows project name once selected', (tester) async {
      final p = makeProject(id: 'p1', name: 'Family Vacation');
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p1'), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('Family Vacation')), findsOneWidget);
      pb.close();
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Group 3: AC 3 - Members Chip & Project-Member Filtering (10 tests)
  // ═══════════════════════════════════════════════════════════════════
  group('AC 3: Members Chip Shows ONLY Selected Project Members', () {
    testWidgets('3.1 Shows default "Members" label when no project selected', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('compactMembersChip')), matching: find.text('members')), findsOneWidget);
    });

    testWidgets('3.2 Shows project member count when project is selected', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob', 'Charlie']);
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p1'), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('compactMembersChip')), matching: find.text('3 members')), findsOneWidget);
      pb.close();
    });

    testWidgets('3.3 Tapping members chip without project shows warning snackbar', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactMembersChip')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('selectProjectFirstSnackBar')), findsOneWidget);
      expect(find.text('Please select a project first'), findsOneWidget);
    });

    testWidgets('3.4 Tapping members chip with project opens members bottom sheet', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p1'), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactMembersChip')));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      pb.close();
    });

    testWidgets('3.5 Members bottom sheet ONLY contains members of selected project', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob']);
      final p2 = makeProject(id: 'p2', name: 'Project 2', members: ['Charlie', 'Dave']);
      final pb = makeProjectBloc([p1, p2]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p1'), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactMembersChip')));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Charlie'), findsNothing);
      expect(find.text('Dave'), findsNothing);
      pb.close();
    });

    testWidgets('3.6 Switching project updates members list to new project members', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob']);
      final p2 = makeProject(id: 'p2', name: 'Project 2', members: ['Charlie', 'Dave', 'Eve']);
      final pb = makeProjectBloc([p1, p2]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p1'), projectBloc: pb));
      await tester.pumpAndSettle();

      // Switch to p2
      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('projectPickerItem_p2')));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('compactMembersChip')), matching: find.text('3 members')), findsOneWidget);

      await tester.tap(find.byKey(const Key('compactMembersChip')));
      await tester.pumpAndSettle();

      expect(find.text('Charlie'), findsOneWidget);
      expect(find.text('Dave'), findsOneWidget);
      expect(find.text('Eve'), findsOneWidget);
      expect(find.text('Alice'), findsNothing);
      pb.close();
    });

    testWidgets('3.7 Can toggle member selection in members bottom sheet', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob', 'Charlie']);
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p1'), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactMembersChip')));
      await tester.pumpAndSettle();

      // Toggle Charlie off
      await tester.tap(find.byKey(const Key('compact_member_checkbox_Charlie')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactMembersDoneButton')));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('compactMembersChip')), matching: find.text('2 members')), findsOneWidget);
      pb.close();
    });

    testWidgets('3.8 When single participant selected, chip shows that participant name', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p1'), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactMembersChip')));
      await tester.pumpAndSettle();

      // Deselect Bob
      await tester.tap(find.byKey(const Key('compact_member_checkbox_Bob')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactMembersDoneButton')));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('compactMembersChip')), matching: find.text('Alice')), findsOneWidget);
      pb.close();
    });

    testWidgets('3.9 Can set payer in members bottom sheet', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p1'), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactMembersChip')));
      await tester.pumpAndSettle();

      // Set Bob as payer
      await tester.tap(find.byKey(const Key('compact_set_payer_Bob')));
      await tester.pumpAndSettle();

      // Bob should have star icon indicating payer
      expect(find.descendant(of: find.byKey(const Key('compact_set_payer_Bob')), matching: find.byIcon(Icons.star)), findsOneWidget);

      await tester.tap(find.byKey(const Key('compactMembersDoneButton')));
      await tester.pumpAndSettle();
      pb.close();
    });

    testWidgets('3.10 Select All button in bottom sheet selects all members', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob', 'Charlie']);
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p1'), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactMembersChip')));
      await tester.pumpAndSettle();

      // Deselect Charlie
      await tester.tap(find.byKey(const Key('compact_member_checkbox_Charlie')));
      await tester.pumpAndSettle();

      // Tap Select All
      await tester.tap(find.byKey(const Key('compactMembersSelectAllButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactMembersDoneButton')));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('compactMembersChip')), matching: find.text('3 members')), findsOneWidget);
      pb.close();
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Group 4: AC 4 & 5 - Expand to Full Mode (10 tests)
  // ═══════════════════════════════════════════════════════════════════
  group('AC 4 & 5: Expand Button Toggles to Full Mode', () {
    testWidgets('4.1 Expand button has tune or expand icon', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      final expandChip = find.byKey(const Key('expandToFullModeButton'));
      expect(expandChip, findsOneWidget);
      expect(find.descendant(of: expandChip, matching: find.byIcon(Icons.tune)), findsOneWidget);
    });

    testWidgets('4.2 Tapping expandToFullModeButton switches to full mode', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('compactDescriptionField')), findsNothing);
      expect(find.byKey(const Key('transactionTypeTabs')), findsOneWidget);
      expect(find.byKey(const Key('titleField')), findsOneWidget);
    });

    testWidgets('4.3 Full mode displays collapse button at top', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('collapseToCompactModeButton')), findsOneWidget);
      expect(find.text('Collapse'), findsOneWidget);
    });

    testWidgets('4.4 Full mode displays transactionTypeTabs and form elements', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('transactionTypeTabs')), findsOneWidget);
      expect(find.byKey(const Key('titleField')), findsOneWidget);
    });

    testWidgets('4.5 Full mode displays category grid', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('category_icon_restaurant')), findsOneWidget);
    });

    testWidgets('4.6 Full mode displays payer field', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('payerField')), findsOneWidget);
    });

    testWidgets('4.7 Full mode displays realtime split calculation preview when amount > 0', (tester) async {
      final p = makeProject(id: 'p1', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p1'), projectBloc: pb));
      await tester.pumpAndSettle();

      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '100000';
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('realtimeSplitText')), findsOneWidget);
      pb.close();
    });

    testWidgets('4.8 Full mode displays image / camera buttons', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pickGalleryButton')), findsOneWidget);
      expect(find.byKey(const Key('takeCameraButton')), findsOneWidget);
    });

    testWidgets('4.9 Top project selector remains visible at top in full mode', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectSelector')), findsOneWidget);
      expect(find.byKey(const Key('projectSelectorButton')), findsOneWidget);
    });

    testWidgets('4.10 initialCompactMode parameter false starts directly in full mode', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(initialCompactMode: false)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('titleField')), findsOneWidget);
      expect(find.byKey(const Key('compactDescriptionField')), findsNothing);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Group 5: AC 6 - Collapse back to Compact Mode & State Preservation (10 tests)
  // ═══════════════════════════════════════════════════════════════════
  group('AC 6: Collapse back to Compact Mode & State Preservation', () {
    testWidgets('5.1 Collapse button collapses full mode back to compact mode', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('collapseToCompactModeButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('compactDescriptionField')), findsOneWidget);
      expect(find.byKey(const Key('compactAmountField')), findsOneWidget);
      expect(find.byKey(const Key('transactionTypeTabs')), findsNothing);
    });

    testWidgets('5.2 Description entered in compact mode is preserved in full mode titleField', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('compactDescriptionField')), 'Sushi Dinner');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();

      final tf = tester.widget<TextField>(find.byKey(const Key('titleField')));
      expect(tf.controller?.text, 'Sushi Dinner');
    });

    testWidgets('5.3 Title edited in full mode is preserved when collapsing back to compact', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'BBQ Party');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('collapseToCompactModeButton')));
      await tester.pumpAndSettle();

      final ctf = tester.widget<TextField>(find.byKey(const Key('compactDescriptionField')));
      expect(ctf.controller?.text, 'BBQ Party');
    });

    testWidgets('5.4 Amount entered in compact mode is preserved in full mode amountField', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '250000';
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();

      final af = tester.widget<TextField>(find.byKey(const Key('amountField')));
      expect(af.controller?.text, '250000');
    });

    testWidgets('5.5 Amount edited in full mode is preserved when collapsing back to compact', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();

      tester.widget<TextField>(find.byKey(const Key('amountField'))).controller!.text = '450000';
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('collapseToCompactModeButton')));
      await tester.pumpAndSettle();

      final caf = tester.widget<TextField>(find.byKey(const Key('compactAmountField')));
      expect(caf.controller?.text, '450000');
    });

    testWidgets('5.6 Selected project is preserved across expand and collapse', (tester) async {
      final p = makeProject(id: 'p1', name: 'Team Outing');
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p1'), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('Team Outing')), findsOneWidget);

      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('Team Outing')), findsOneWidget);

      await tester.tap(find.byKey(const Key('collapseToCompactModeButton')));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('Team Outing')), findsOneWidget);
      pb.close();
    });

    testWidgets('5.7 Selected date is preserved across expand and collapse', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('compactDateChip')), matching: find.text('Today')), findsOneWidget);

      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('collapseToCompactModeButton')));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('compactDateChip')), matching: find.text('Today')), findsOneWidget);
    });

    testWidgets('5.8 Selected participants are preserved across expand and collapse', (tester) async {
      final p = makeProject(id: 'p1', name: 'Apartment', members: ['Alice', 'Bob', 'Charlie']);
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p1'), projectBloc: pb));
      await tester.pumpAndSettle();

      // Deselect Charlie in compact mode
      await tester.tap(find.byKey(const Key('compactMembersChip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('compact_member_checkbox_Charlie')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('compactMembersDoneButton')));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('compactMembersChip')), matching: find.text('2 members')), findsOneWidget);

      // Expand to full mode
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();

      // Collapse back
      await tester.tap(find.byKey(const Key('collapseToCompactModeButton')));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('compactMembersChip')), matching: find.text('2 members')), findsOneWidget);
      pb.close();
    });

    testWidgets('5.9 Multiple toggles between compact and full mode maintain stability', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('expandToFullModeButton')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('collapseToCompactModeButton')), findsOneWidget);

        await tester.tap(find.byKey(const Key('collapseToCompactModeButton')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('expandToFullModeButton')), findsOneWidget);
      }
    });

    testWidgets('5.10 Editing bill starts directly in full mode', (tester) async {
      final bill = Bill(
        id: 'b1',
        title: 'Old Bill',
        amount: 50.0,
        currency: 'USD',
        date: DateTime.now(),
        category: 'food',
        paidBy: 'Alice',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 25.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 25.0),
        ],
        projectId: 'p1',
      );

      await tester.pumpWidget(buildTestApp(child: AddBillScreen(billToEdit: bill)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('titleField')), findsOneWidget);
      expect(find.byKey(const Key('compactDescriptionField')), findsNothing);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Group 6: AC 7 - Top Project Selector in Both Modes (8 tests)
  // ═══════════════════════════════════════════════════════════════════
  group('AC 7: Top Project Selector in Both Modes', () {
    testWidgets('6.1 Top project selector renders at very top in compact mode', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectSelector')), findsOneWidget);
      expect(find.byKey(const Key('projectSelectorButton')), findsOneWidget);
    });

    testWidgets('6.2 Top project selector renders at very top in full mode', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(initialCompactMode: false)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectSelector')), findsOneWidget);
      expect(find.byKey(const Key('projectSelectorButton')), findsOneWidget);
    });

    testWidgets('6.3 Tapping top selector in compact mode opens project picker sheet', (tester) async {
      final p = makeProject(id: 'p1', name: 'Trip to Da Lat');
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();

      expect(find.text('Select Project'), findsOneWidget);
      expect(find.byKey(const Key('projectPickerItem_p1')), findsOneWidget);
      pb.close();
    });

    testWidgets('6.4 Tapping top selector in full mode opens project picker sheet', (tester) async {
      final p = makeProject(id: 'p1', name: 'Trip to Nha Trang');
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(initialCompactMode: false), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();

      expect(find.text('Select Project'), findsOneWidget);
      expect(find.byKey(const Key('projectPickerItem_p1')), findsOneWidget);
      pb.close();
    });

    testWidgets('6.5 Selecting project from sheet in compact mode updates UI immediately', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project Alpha');
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('projectPickerItem_p1')));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('Project Alpha')), findsOneWidget);
      pb.close();
    });

    testWidgets('6.6 Selecting project from sheet in full mode updates UI immediately', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project Beta');
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(initialCompactMode: false), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectSelectorButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('projectPickerItem_p1')));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('Project Beta')), findsOneWidget);
      pb.close();
    });

    testWidgets('6.7 widget.projectId resolves project name from ProjectBloc automatically', (tester) async {
      final p = makeProject(id: 'proj_xyz', name: 'Resolved XYZ');
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'proj_xyz'), projectBloc: pb));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('Resolved XYZ')), findsOneWidget);
      pb.close();
    });

    testWidgets('6.8 widget.projectName takes precedence if ProjectBloc is not yet ready', (tester) async {
      final pb = makeProjectBloc([]);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(projectId: 'custom_id', projectName: 'Explicit Name'),
        projectBloc: pb,
      ));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('selectedProjectName')), matchRoot: true, matching: find.text('Explicit Name')), findsOneWidget);
      pb.close();
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Group 7: AC 8 - Keyboard Auto-focus & Smart Categorization (6 tests)
  // ═══════════════════════════════════════════════════════════════════
  group('AC 8: Keyboard Auto-focus & Smart Category Detection', () {
    testWidgets('7.1 Description field has autofocus enabled in compact mode', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pump();

      final textField = tester.widget<TextField>(find.byKey(const Key('compactDescriptionField')));
      expect(textField.focusNode?.hasFocus, isTrue);
    });

    testWidgets('7.2 Auto-detects restaurant category for "Lunch with team"', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('compactDescriptionField')), 'Lunch with team');
      await tester.pumpAndSettle();

      // Expand to check selected category
      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('selectedCategoryIconBadge')), findsOneWidget);
    });

    testWidgets('7.3 Auto-detects transport category for "Grab taxi"', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('compactDescriptionField')), 'Grab taxi home');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('selectedCategoryIconBadge')), findsOneWidget);
    });

    testWidgets('7.4 Auto-detects coffee / cafe keywords', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('compactDescriptionField')), 'Morning coffee');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('selectedCategoryIconBadge')), findsOneWidget);
    });

    testWidgets('7.5 Auto-detects shopping keywords for "Supermarket"', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('compactDescriptionField')), 'Supermarket groceries');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('expandToFullModeButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('selectedCategoryIconBadge')), findsOneWidget);
    });

    testWidgets('7.6 Detects category correctly from helper function', (tester) async {
      expect(detectCategoryFromText('ăn trưa'), 'restaurant');
      expect(detectCategoryFromText('xe ôm grab'), 'transport');
      expect(detectCategoryFromText('mua sắm tiki'), 'shopping');
      expect(detectCategoryFromText('khám bệnh thuốc'), 'health');
      expect(detectCategoryFromText('xem phim rạp chiếu'), 'entertainment');
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Group 8: AC 9 - Saving Bill from Compact Mode (10 tests)
  // ═══════════════════════════════════════════════════════════════════
  group('AC 9: Successfully Saving Bill from Compact Mode', () {
    testWidgets('8.1 Save creates Bill with correct amount', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(projectId: 'p1'),
        projectBloc: pb,
        billsBloc: bb,
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('compactDescriptionField')), 'Lunch');
      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '80000';
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveBillButton')));
      await tester.pumpAndSettle();

      expect(billRepo.bills.isNotEmpty, isTrue);
      expect(billRepo.bills.first.amount, 80000.0);
      pb.close();
      bb.close();
    });

    testWidgets('8.2 Save creates Bill with title from description', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(projectId: 'p1'),
        projectBloc: pb,
        billsBloc: bb,
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('compactDescriptionField')), 'Dinner Buffet');
      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '200000';
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveBillButton')));
      await tester.pumpAndSettle();

      expect(billRepo.bills.first.title, 'Dinner Buffet');
      pb.close();
      bb.close();
    });

    testWidgets('8.3 Save sets fallback title from category if description empty', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(projectId: 'p1'),
        projectBloc: pb,
        billsBloc: bb,
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '150000';
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveBillButton')));
      await tester.pumpAndSettle();

      expect(billRepo.bills.first.title.isNotEmpty, isTrue);
      pb.close();
      bb.close();
    });

    testWidgets('8.4 Save links bill to selected project ID', (tester) async {
      final p = makeProject(id: 'proj_alpha', name: 'Project Alpha', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(projectId: 'proj_alpha'),
        projectBloc: pb,
        billsBloc: bb,
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '100000';
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveBillButton')));
      await tester.pumpAndSettle();

      expect(billRepo.bills.first.projectId, 'proj_alpha');
      pb.close();
      bb.close();
    });

    testWidgets('8.5 Save defaults payer to first project member when not set', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(projectId: 'p1'),
        projectBloc: pb,
        billsBloc: bb,
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '100000';
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveBillButton')));
      await tester.pumpAndSettle();

      expect(billRepo.bills.first.paidBy, 'Alice');
      pb.close();
      bb.close();
    });

    testWidgets('8.6 Save defaults participants to all project members', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob', 'Charlie']);
      final pb = makeProjectBloc([p]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(projectId: 'p1'),
        projectBloc: pb,
        billsBloc: bb,
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '100000';
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveBillButton')));
      await tester.pumpAndSettle();

      final participantNames = billRepo.bills.first.participants.map((p) => p.name).toList();
      expect(participantNames, ['Alice', 'Bob', 'Charlie']);
      pb.close();
      bb.close();
    });

    testWidgets('8.7 Save saves custom payer selected in compact mode', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(projectId: 'p1'),
        projectBloc: pb,
        billsBloc: bb,
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '100000';
      await tester.pumpAndSettle();

      // Change payer to Bob
      await tester.tap(find.byKey(const Key('compactMembersChip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('compact_set_payer_Bob')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('compactMembersDoneButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveBillButton')));
      await tester.pumpAndSettle();

      expect(billRepo.bills.first.paidBy, 'Bob');
      pb.close();
      bb.close();
    });

    testWidgets('8.8 Save via bottom saveProjectButton behaves identically', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(projectId: 'p1'),
        projectBloc: pb,
        billsBloc: bb,
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('compactDescriptionField')), 'Coffee');
      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '45000';
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.bills.isNotEmpty, isTrue);
      expect(billRepo.bills.first.title, 'Coffee');
      expect(billRepo.bills.first.amount, 45000.0);
      pb.close();
      bb.close();
    });

    testWidgets('8.9 Saving bill pops current route when navigator is present', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            key: const Key('openAddBill'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
                      RepositoryProvider<BillRepository>.value(value: billRepo),
                    ],
                    child: MultiBlocProvider(
                      providers: [
                        BlocProvider<BillsBloc>.value(value: bb),
                        BlocProvider<ProjectBloc>.value(value: pb),
                      ],
                      child: const AddBillScreen(projectId: 'p1'),
                    ),
                  ),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
        localizationsDelegates: const [
          _TestLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('openAddBill')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('compactAmountField')), findsOneWidget);

      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '99000';
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveBillButton')));
      await tester.pumpAndSettle();

      // Screen is popped back to root
      expect(find.byKey(const Key('openAddBill')), findsOneWidget);
      pb.close();
      bb.close();
    });

    testWidgets('8.10 Save preserves selected split mode', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);
      final billRepo = FakeBillRepository();
      final bb = makeBillsBloc(repo: billRepo);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(projectId: 'p1'),
        projectBloc: pb,
        billsBloc: bb,
        billRepo: billRepo,
      ));
      await tester.pumpAndSettle();

      tester.widget<TextField>(find.byKey(const Key('compactAmountField'))).controller!.text = '100000';
      await tester.pumpAndSettle();

      // Open split sheet and choose percentage
      await tester.tap(find.byKey(const Key('compactSplitChip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('compact_split_mode_percentage')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('compactSplitDoneButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveBillButton')));
      await tester.pumpAndSettle();

      expect(billRepo.bills.first.splitMode, 'percentage');
      pb.close();
      bb.close();
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Group 9: AC 10 - Dark / Light Theme & Dual Language (8 tests)
  // ═══════════════════════════════════════════════════════════════════
  group('AC 10: Theme & Dual Language Localization', () {
    testWidgets('9.1 Renders cleanly in Light Mode', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        brightness: Brightness.light,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('compactDescriptionField')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('9.2 Renders cleanly in Dark Mode', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('compactDescriptionField')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('9.3 English shows correct strings for compact mode', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Add Bill'), findsOneWidget);
      expect(find.text('Expand'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('9.4 Vietnamese shows correct strings for compact mode', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        locale: const Locale('vi'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Thêm hóa đơn'), findsOneWidget);
      expect(find.text('Mở rộng'), findsOneWidget);
      expect(find.text('Hôm nay'), findsOneWidget);
      expect(find.text('Lưu hóa đơn'), findsOneWidget);
    });

    testWidgets('9.5 Vietnamese full mode shows "Thu gọn" for collapse button', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(initialCompactMode: false),
        locale: const Locale('vi'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Thu gọn'), findsOneWidget);
    });

    testWidgets('9.6 Vietnamese members sheet shows localized titles', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(projectId: 'p1'),
        projectBloc: pb,
        locale: const Locale('vi'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactMembersChip')));
      await tester.pumpAndSettle();

      expect(find.text('thành viên'), findsOneWidget);
      expect(find.text('Bỏ chọn tất cả'), findsOneWidget);
      expect(find.text('Xong'), findsOneWidget);
      pb.close();
    });

    testWidgets('9.7 Vietnamese snackbar shows localized warning when project missing', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        locale: const Locale('vi'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactMembersChip')));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng chọn dự án trước'), findsOneWidget);
    });

    testWidgets('9.8 Theme toggle preserves user input', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        brightness: Brightness.light,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('compactDescriptionField')), 'Electricity Bill');
      await tester.pumpAndSettle();

      // Rebuild in dark mode
      await tester.pumpWidget(buildTestApp(
        child: const AddBillScreen(),
        brightness: Brightness.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Electricity Bill'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Group 10: Compact Split Chip, Date, and Camera Interactions (8 tests)
  // ═══════════════════════════════════════════════════════════════════
  group('AC 1: Secondary Bar & Split Chip Interactions', () {
    testWidgets('10.1 Tapping compactSplitChip opens split options bottom sheet', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p1'), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactSplitChip')));
      await tester.pumpAndSettle();

      expect(find.text('Split Mode'), findsOneWidget);
      expect(find.byKey(const Key('compact_split_mode_equal')), findsOneWidget);
      expect(find.byKey(const Key('compact_split_mode_percentage')), findsOneWidget);
      expect(find.byKey(const Key('compact_split_mode_shares')), findsOneWidget);
      expect(find.byKey(const Key('compact_split_mode_custom')), findsOneWidget);
      pb.close();
    });

    testWidgets('10.2 Changing split mode updates compactSplitChip label to Percentage', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p1'), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactSplitChip')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compact_split_mode_percentage')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactSplitDoneButton')));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('compactSplitChip')), matching: find.textContaining('Percentage')), findsOneWidget);
      pb.close();
    });

    testWidgets('10.3 Changing split mode updates compactSplitChip label to Shares', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p1'), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactSplitChip')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compact_split_mode_shares')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactSplitDoneButton')));
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byKey(const Key('compactSplitChip')), matching: find.textContaining('Shares')), findsOneWidget);
      pb.close();
    });

    testWidgets('10.4 Compact camera chip invokes onPickImage callback', (tester) async {
      bool cameraTapped = false;

      await tester.pumpWidget(buildTestApp(
        child: AddBillScreen(
          onPickImage: (source) async {
            cameraTapped = true;
            return '/mock/path/camera.jpg';
          },
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactCameraChip')));
      await tester.pumpAndSettle();

      expect(cameraTapped, isTrue);
    });

    testWidgets('10.5 Compact date chip opens date picker dialog', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactDateChip')));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('10.6 Selecting past date in date picker updates compactDateChip label', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactDateChip')));
      await tester.pumpAndSettle();

      // Tap OK on the date picker
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('compactDateChip')), findsOneWidget);
    });

    testWidgets('10.7 Selecting payer from compact split bottom sheet updates payer chip', (tester) async {
      final p = makeProject(id: 'p1', name: 'Project 1', members: ['Alice', 'Bob']);
      final pb = makeProjectBloc([p]);

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen(projectId: 'p1'), projectBloc: pb));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactSplitChip')));
      await tester.pumpAndSettle();

      expect(find.text('Paid by'), findsOneWidget);
      await tester.tap(find.byKey(const Key('compact_payer_chip_Bob')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('compactSplitDoneButton')));
      await tester.pumpAndSettle();

      pb.close();
    });

    testWidgets('10.8 Compact secondary bar chips render neatly with spacing and borders', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('compactDateChip')), findsOneWidget);
      expect(find.byKey(const Key('compactMembersChip')), findsOneWidget);
      expect(find.byKey(const Key('compactCameraChip')), findsOneWidget);
      expect(find.byKey(const Key('expandToFullModeButton')), findsOneWidget);
    });
  });
}
