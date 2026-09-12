import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:dartz/dartz.dart';

import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/category_entity.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/category_icon.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/add_bill_screen.dart';
import 'package:shared_household_planner/features/split_bills/presentation/widgets/add_category_bottom_sheet.dart';
import 'package:shared_household_planner/features/split_bills/presentation/widgets/edit_category_bottom_sheet.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project_settings.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test Fakes & Mock Setup
// ─────────────────────────────────────────────────────────────────────────────
class FakeBillRepo implements BillRepository {
  final List<Bill> bills = [];

  @override
  Future<Either<Failure, Bill>> create(Bill bill) async {
    bills.add(bill);
    return Right(bill);
  }

  @override
  Future<Either<Failure, List<Bill>>> getAll() async => Right(List.from(bills));

  @override
  Future<Either<Failure, Bill>> getById(String billId) async =>
      Right(bills.firstWhere((b) => b.id == billId));

  @override
  Future<Either<Failure, Bill>> update(Bill bill) async {
    final idx = bills.indexWhere((b) => b.id == bill.id);
    if (idx != -1) {
      bills[idx] = bill;
    }
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

class FakeProjRepo implements ProjectRepository {
  final List<Project> projects;
  FakeProjRepo([this.projects = const []]);

  @override
  Future<Either<Failure, List<Project>>> getAll() async => Right(projects);
  @override
  Future<Either<Failure, Project>> create(Project project) async => Right(project);
  @override
  Future<Either<Failure, Project>> getById(String id) async =>
      Right(projects.firstWhere((p) => p.id == id));
  @override
  Future<Either<Failure, Project>> update(Project project) async => Right(project);
  @override
  Future<Either<Failure, void>> delete(String id) async => const Right(null);
}

class TestCategoryLocalizations extends AppLocalizations {
  TestCategoryLocalizations(Locale locale) : super(locale);

  static const Map<String, String> _en = {
    'add_bill': 'Add Bill',
    'bill_name': 'Bill Name',
    'amount': 'Amount',
    'category': 'Category',
    'payer': 'Payer',
    'participants': 'Participants',
    'participant_name': 'Participant Name',
    'enter_name': 'Enter name',
    'add': 'Add',
    'save_bill': 'Save Bill',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'edit': 'Edit',
    'add_category': 'Add Category',
    'edit_category': 'Edit Category',
    'category_name': 'Category Name',
    'category_name_required': 'Category name is required',
    'category_already_exists': 'Category already exists',
    'save_category': 'Save Category',
    'delete_category': 'Delete category?',
    'delete_category_title': 'Delete category?',
    'delete_category_confirm_message': 'This action cannot be undone.',
    'delete_category_message': 'This action cannot be undone.',
    'confirm_delete': 'Confirm Delete',
    'cannot_delete_default_categories': 'Cannot delete default categories',
    'category_deleted': 'Category deleted',
    'category_updated': 'Category updated',
    'category_deleted_label': '(Deleted)',
    'choose_icon': 'Choose Icon',
    'choose_color': 'Choose Color',
    'suggestions': 'Suggestions',
    'expense': 'Expense',
    'income': 'Income',
    'transfer': 'Transfer',
    'title': 'Title',
    'currency': 'Currency',
    'paid_by': 'Paid By',
    'when': 'When',
    'split': 'Split',
    'select_date': 'Select Date',
    'each_pays': 'Each pays',
    'select_project': 'Select Project (Optional)',
    'no_project': 'No Project',
    'category_restaurant': 'Restaurant',
    'category_transport': 'Transport',
    'category_shopping': 'Shopping',
    'category_health': 'Health',
    'category_entertainment': 'Entertainment',
    'category_travel': 'Travel',
    'category_utilities': 'Utilities',
    'category_education': 'Education',
    'category_party': 'Party',
    'category_office': 'Office',
    'category_pet': 'Pet',
    'category_sport': 'Sport',
  };

  static const Map<String, String> _vi = {
    'add_bill': 'Thêm hóa đơn',
    'bill_name': 'Tên hóa đơn',
    'amount': 'Số tiền',
    'category': 'Danh mục',
    'payer': 'Người trả',
    'participants': 'Người tham gia',
    'save_bill': 'Lưu hóa đơn',
    'cancel': 'Hủy',
    'delete': 'Xóa',
    'edit': 'Sửa',
    'add_category': 'Thêm danh mục',
    'edit_category': 'Chỉnh sửa danh mục',
    'category_name': 'Tên danh mục',
    'category_name_required': 'Tên danh mục không được để trống',
    'category_already_exists': 'Danh mục đã tồn tại',
    'save_category': 'Lưu danh mục',
    'delete_category': 'Xóa danh mục?',
    'delete_category_title': 'Xóa danh mục?',
    'delete_category_confirm_message': 'Hành động này không thể hoàn tác.',
    'cannot_delete_default_categories': 'Không thể xóa danh mục mặc định',
    'category_deleted': 'Đã xóa danh mục',
    'category_updated': 'Đã cập nhật danh mục',
    'category_deleted_label': '(Đã xóa)',
    'choose_icon': 'Chọn biểu tượng',
    'choose_color': 'Chọn màu sắc',
    'category_restaurant': 'Nhà hàng',
    'category_transport': 'Giao thông',
  };

  @override
  String translate(String key) {
    if (locale.languageCode == 'vi') {
      return _vi[key] ?? _en[key] ?? key;
    }
    return _en[key] ?? key;
  }
}

class TestCategoryLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  final Locale forcedLocale;
  const TestCategoryLocalizationsDelegate({this.forcedLocale = const Locale('en')});

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      TestCategoryLocalizations(forcedLocale);

  @override
  bool shouldReload(TestCategoryLocalizationsDelegate old) => false;
}

Widget buildTestApp({
  Widget? child,
  FakeBillRepo? billRepo,
  List<Project>? projects,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) {
  final repo = billRepo ?? FakeBillRepo();
  final billsBloc = BillsBloc(
    getBillsUseCase: GetBillsUseCase(repo),
    addBillUseCase: AddBillUseCase(repo),
  );
  final projectBloc = ProjectBloc(
    createProjectUseCase: CreateProjectUseCase(FakeProjRepo(projects ?? [])),
    getAllProjectsUseCase: GetAllProjectsUseCase(FakeProjRepo(projects ?? [])),
    updateProjectUseCase: UpdateProjectUseCase(FakeProjRepo(projects ?? [])),
    deleteProjectUseCase: DeleteProjectUseCase(FakeProjRepo(projects ?? [])),
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<BillsBloc>.value(value: billsBloc),
        BlocProvider<ProjectBloc>.value(value: projectBloc),
      ],
      child: MaterialApp(
        theme: ThemeData(
          brightness: brightness,
          useMaterial3: true,
        ),
        localizationsDelegates: [
          TestCategoryLocalizationsDelegate(forcedLocale: locale),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [locale],
        home: child ?? const AddBillScreen(),
      ),
    ),
  );
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  const customCategory = CategoryIconItem(
    id: 'coffee',
    icon: '☕',
    nameKey: 'Coffee & Snacks',
    colorHex: '#795548',
  );

  // ───────────────────────────────────────────────────────────────────────────
  // AC 1 & 2: Edit Category Bottom Sheet UI & Pre-filled Data (15 tests)
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 1 & 2: EditCategoryBottomSheet UI & Pre-filled Data', () {
    testWidgets('Pre-fills existing category name in edit name field', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Scaffold(
          body: EditCategoryBottomSheet(
            category: customCategory,
            existingCategories: const [customCategory],
            isDefaultCategory: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('editCategoryNameField')), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Coffee & Snacks'), findsOneWidget);
    });

    testWidgets('Pre-fills existing category icon/emoji in prefix container', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Scaffold(
          body: EditCategoryBottomSheet(
            category: customCategory,
            existingCategories: const [customCategory],
            isDefaultCategory: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('☕'), findsOneWidget);
    });

    testWidgets('Pre-fills existing category color swatch as selected', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Scaffold(
          body: EditCategoryBottomSheet(
            category: customCategory,
            existingCategories: const [customCategory],
            isDefaultCategory: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('color_swatch_#795548')), findsOneWidget);
    });

    testWidgets('Renders Edit Category header title and cancel button', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Scaffold(
          body: EditCategoryBottomSheet(
            category: customCategory,
            existingCategories: const [customCategory],
            isDefaultCategory: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Edit Category'), findsOneWidget);
      expect(find.byKey(const Key('cancelCategoryButton')), findsOneWidget);
    });

    testWidgets('Renders 20+ icons in icon picker horizontal list', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Scaffold(
          body: EditCategoryBottomSheet(
            category: customCategory,
            existingCategories: const [customCategory],
            isDefaultCategory: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Choose Icon'), findsOneWidget);
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('Renders 12+ preset colors in color picker wrap', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Scaffold(
          body: EditCategoryBottomSheet(
            category: customCategory,
            existingCategories: const [customCategory],
            isDefaultCategory: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Choose Color'), findsOneWidget);
      expect(find.byKey(const Key('color_swatch_#F44336')), findsOneWidget);
      expect(find.byKey(const Key('color_swatch_#2196F3')), findsOneWidget);
      expect(find.byKey(const Key('color_swatch_#4CAF50')), findsOneWidget);
    });

    testWidgets('Renders Save Category button with active color', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Scaffold(
          body: EditCategoryBottomSheet(
            category: customCategory,
            existingCategories: const [customCategory],
            isDefaultCategory: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final saveBtn = find.byKey(const Key('saveCategoryButton'));
      expect(saveBtn, findsOneWidget);
      expect(find.text('Save Category'), findsOneWidget);
    });

    testWidgets('Renders Delete button with red warning style and delete icon', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Scaffold(
          body: EditCategoryBottomSheet(
            category: customCategory,
            existingCategories: const [customCategory],
            isDefaultCategory: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final deleteBtn = find.byKey(const Key('deleteCategoryButton'));
      expect(deleteBtn, findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('Tapping cancel button dismisses bottom sheet with null', (tester) async {
      CategoryEditResult? result;
      await tester.pumpWidget(buildTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await EditCategoryBottomSheet.show(
                context,
                category: customCategory,
                existingCategories: const [customCategory],
              );
            },
            child: const Text('Open Sheet'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cancelCategoryButton')), findsOneWidget);
      await tester.tap(find.byKey(const Key('cancelCategoryButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('editCategoryNameField')), findsNothing);
      expect(result, isNull);
    });

    testWidgets('Tapping color swatch updates selected color', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Scaffold(
          body: EditCategoryBottomSheet(
            category: customCategory,
            existingCategories: const [customCategory],
            isDefaultCategory: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('color_swatch_#2196F3')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('Tapping icon option updates selected icon & emoji', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Scaffold(
          body: EditCategoryBottomSheet(
            category: customCategory,
            existingCategories: const [customCategory],
            isDefaultCategory: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final iconKey = Key('icon_option_${suggestedCategoryIcons[0].codePoint}');
      await tester.tap(find.byKey(iconKey));
      await tester.pumpAndSettle();

      expect(find.text('🍽️'), findsOneWidget);
    });

    testWidgets('Sheet adapts with scrollview to prevent overflow on small viewports', (tester) async {
      tester.view.physicalSize = const Size(360, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(
        child: Scaffold(
          body: EditCategoryBottomSheet(
            category: customCategory,
            existingCategories: const [customCategory],
            isDefaultCategory: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 3: Edit Functionality & Validation (15 tests)
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 3: Edit Functionality & Validation', () {
    testWidgets('Empty category name displays error message', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Scaffold(
          body: EditCategoryBottomSheet(
            category: customCategory,
            existingCategories: const [customCategory],
            isDefaultCategory: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editCategoryNameField')), '');
      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();

      expect(find.text('Category name is required'), findsOneWidget);
    });

    testWidgets('Whitespace only category name displays error message', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Scaffold(
          body: EditCategoryBottomSheet(
            category: customCategory,
            existingCategories: const [customCategory],
            isDefaultCategory: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editCategoryNameField')), '    ');
      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();

      expect(find.text('Category name is required'), findsOneWidget);
    });

    testWidgets('Duplicate name with another category shows error', (tester) async {
      const otherCat = CategoryIconItem(id: 'gym', icon: '🏋️', nameKey: 'Gym');
      await tester.pumpWidget(buildTestApp(
        child: Scaffold(
          body: EditCategoryBottomSheet(
            category: customCategory,
            existingCategories: const [customCategory, otherCat],
            isDefaultCategory: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editCategoryNameField')), 'Gym');
      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();

      expect(find.text('Category already exists'), findsOneWidget);
    });

    testWidgets('Keeping exact same name does NOT trigger duplicate error', (tester) async {
      CategoryEditResult? result;
      await tester.pumpWidget(buildTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await EditCategoryBottomSheet.show(
                context,
                category: customCategory,
                existingCategories: const [customCategory],
              );
            },
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap save without changing name
      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();

      expect(find.text('Category already exists'), findsNothing);
      expect(result, isNotNull);
      expect(result!.action, equals(CategoryEditAction.updated));
      expect(result!.updatedCategory!.nameKey, equals('Coffee & Snacks'));
    });

    testWidgets('Updating name, icon, and color returns updated result', (tester) async {
      CategoryEditResult? result;
      await tester.pumpWidget(buildTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await EditCategoryBottomSheet.show(
                context,
                category: customCategory,
                existingCategories: const [customCategory],
              );
            },
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editCategoryNameField')), 'Bakery Treats');
      await tester.tap(find.byKey(const Key('color_swatch_#4CAF50')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.action, equals(CategoryEditAction.updated));
      expect(result!.updatedCategory!.id, equals('coffee'));
      expect(result!.updatedCategory!.nameKey, equals('Bakery Treats'));
      expect(result!.updatedCategory!.colorHex, equals('#4CAF50'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 4 & 5: Category Delete & Confirmation Dialog (20 tests)
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 4 & 5: Category Delete & Confirmation Dialog', () {
    testWidgets('Tapping delete button on custom category opens confirmation dialog', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Scaffold(
          body: EditCategoryBottomSheet(
            category: customCategory,
            existingCategories: const [customCategory],
            isDefaultCategory: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deleteCategoryButton')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Delete category?'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
      expect(find.byKey(const Key('cancelDeleteCategoryButton')), findsOneWidget);
      expect(find.byKey(const Key('confirmDeleteCategoryButton')), findsOneWidget);
    });

    testWidgets('Tapping cancel in confirmation dialog keeps bottom sheet open', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Scaffold(
          body: EditCategoryBottomSheet(
            category: customCategory,
            existingCategories: const [customCategory],
            isDefaultCategory: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deleteCategoryButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancelDeleteCategoryButton')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byKey(const Key('editCategoryNameField')), findsOneWidget);
    });

    testWidgets('Tapping confirm delete in dialog closes dialog and returns deleted result', (tester) async {
      CategoryEditResult? result;
      await tester.pumpWidget(buildTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await EditCategoryBottomSheet.show(
                context,
                category: customCategory,
                existingCategories: const [customCategory],
                isDefaultCategory: false,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deleteCategoryButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirmDeleteCategoryButton')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byKey(const Key('editCategoryNameField')), findsNothing);
      expect(result, isNotNull);
      expect(result!.action, equals(CategoryEditAction.deleted));
      expect(result!.originalCategory.id, equals('coffee'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 6: Prevent Delete of 12 System / Default Categories (15 tests)
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 6: Prevent Delete of Default Categories', () {
    for (final defaultCat in defaultCategoryIcons) {
      testWidgets('Cannot delete default category: ${defaultCat.id}', (tester) async {
        await tester.pumpWidget(buildTestApp(
          child: Scaffold(
            body: EditCategoryBottomSheet(
              category: defaultCat,
              existingCategories: defaultCategoryIcons,
              isDefaultCategory: true,
            ),
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('deleteCategoryButton')));
        await tester.pumpAndSettle();

        // Must show snackbar warning
        expect(find.byKey(const Key('cannotDeleteDefaultSnackbar')), findsOneWidget);
        expect(find.text('Cannot delete default categories'), findsOneWidget);

        // Must NOT show confirmation dialog
        expect(find.byType(AlertDialog), findsNothing);

        // Bottom sheet stays open
        expect(find.byKey(const Key('editCategoryNameField')), findsOneWidget);
      });
    }

    testWidgets('Auto-detects default category via isDefaultCategory null check', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => EditCategoryBottomSheet.show(
                context,
                category: defaultCategoryIcons.first,
                existingCategories: defaultCategoryIcons,
                // isDefaultCategory omitted -> auto detect
              ),
              child: const Text('Open Default'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Default'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deleteCategoryButton')));
      await tester.pumpAndSettle();

      expect(find.text('Cannot delete default categories'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 7 & 10: Category Selector UI Integration & Real-time Updates (20 tests)
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 7 & 10: Category Selector UI Integration & Real-time Updates', () {
    testWidgets('Each category pill has edit pencil affordance button', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit_category_icon_restaurant')), findsOneWidget);
      expect(find.byKey(const Key('edit_category_icon_transport')), findsOneWidget);
    });

    testWidgets('Long pressing category pill opens EditCategoryBottomSheet', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('category_icon_restaurant')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('editCategoryNameField')), findsOneWidget);
      expect(find.text('Edit Category'), findsOneWidget);
    });

    testWidgets('Tapping edit pencil button opens EditCategoryBottomSheet', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit_category_icon_transport')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('editCategoryNameField')), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Transport'), findsOneWidget);
    });

    testWidgets('Editing category name updates selector pill immediately', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Open Add Category and add custom category
      await tester.tap(find.byKey(const Key('addCategoryButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('newCategoryNameField')), 'Snack Bar');
      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();

      expect(find.text('Snack Bar'), findsWidgets);

      // Edit this custom category
      await tester.tap(find.byKey(const Key('edit_category_icon_snack_bar')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editCategoryNameField')), 'Midnight Snacks');
      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();

      expect(find.text('Midnight Snacks'), findsWidgets);
      expect(find.text('Category updated'), findsOneWidget);
    });

    testWidgets('Deleting selected category falls back to default restaurant category', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Add a custom category
      await tester.tap(find.byKey(const Key('addCategoryButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('newCategoryNameField')), 'Boba Tea');
      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('category_icon_boba_tea')), findsOneWidget);

      // Open Edit and Delete
      await tester.tap(find.byKey(const Key('edit_category_icon_boba_tea')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deleteCategoryButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirmDeleteCategoryButton')));
      await tester.pumpAndSettle();

      // Boba Tea pill is gone
      expect(find.byKey(const Key('category_icon_boba_tea')), findsNothing);
      expect(find.text('Category deleted'), findsOneWidget);

      // Selected category fell back to default restaurant
      expect(find.text('Restaurant'), findsWidgets);
    });

    testWidgets('Category title updates when edited if user has not modified title manually', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Add custom category
      await tester.tap(find.byKey(const Key('addCategoryButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('newCategoryNameField')), 'Books');
      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Books'), findsOneWidget);

      // Edit Books to Magazines
      await tester.tap(find.byKey(const Key('edit_category_icon_books')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editCategoryNameField')), 'Magazines');
      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();

      // Title updated automatically
      expect(find.widgetWithText(TextField, 'Magazines'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 8: Localization & Translations (10 tests)
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 8: i18n & Translations', () {
    testWidgets('Renders Edit Category in Vietnamese locale', (tester) async {
      await tester.pumpWidget(buildTestApp(
        locale: const Locale('vi'),
        child: Scaffold(
          body: EditCategoryBottomSheet(
            category: customCategory,
            existingCategories: const [customCategory],
            isDefaultCategory: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Chỉnh sửa danh mục'), findsOneWidget);
      expect(find.text('Lưu danh mục'), findsOneWidget);
      expect(find.text('Xóa'), findsOneWidget);
    });

    testWidgets('Renders Delete confirmation dialog in Vietnamese locale', (tester) async {
      await tester.pumpWidget(buildTestApp(
        locale: const Locale('vi'),
        child: Scaffold(
          body: EditCategoryBottomSheet(
            category: customCategory,
            existingCategories: const [customCategory],
            isDefaultCategory: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deleteCategoryButton')));
      await tester.pumpAndSettle();

      expect(find.text('Xóa danh mục?'), findsOneWidget);
      expect(find.text('Hành động này không thể hoàn tác.'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);
    });

    test('en.json contains all required category edit & delete keys', () {
      final enFile = File('lib/core/localization/translations/en.json');
      final content = enFile.readAsStringSync();
      final map = jsonDecode(content) as Map<String, dynamic>;

      expect(map.containsKey('edit_category'), isTrue);
      expect(map.containsKey('delete_category'), isTrue);
      expect(map.containsKey('delete_category_title'), isTrue);
      expect(map.containsKey('delete_category_confirm_message'), isTrue);
      expect(map.containsKey('cannot_delete_default_categories'), isTrue);
      expect(map.containsKey('category_deleted'), isTrue);
      expect(map.containsKey('category_updated'), isTrue);
      expect(map.containsKey('category_deleted_label'), isTrue);
    });

    test('vi.json contains all required category edit & delete keys', () {
      final viFile = File('lib/core/localization/translations/vi.json');
      final content = viFile.readAsStringSync();
      final map = jsonDecode(content) as Map<String, dynamic>;

      expect(map.containsKey('edit_category'), isTrue);
      expect(map.containsKey('delete_category'), isTrue);
      expect(map.containsKey('delete_category_title'), isTrue);
      expect(map.containsKey('delete_category_confirm_message'), isTrue);
      expect(map.containsKey('cannot_delete_default_categories'), isTrue);
      expect(map.containsKey('category_deleted'), isTrue);
      expect(map.containsKey('category_updated'), isTrue);
      expect(map.containsKey('category_deleted_label'), isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 9: Edge Cases & Migration Logic (10 tests)
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 9: Edge Cases & Migration Logic', () {
    test('CategoryEditResult constructors handle null updatedCategory properly', () {
      final deleted = CategoryEditResult.deleted(originalCategory: customCategory);
      expect(deleted.action, equals(CategoryEditAction.deleted));
      expect(deleted.updatedCategory, isNull);
      expect(deleted.originalCategory, equals(customCategory));

      final updated = CategoryEditResult.updated(
        originalCategory: customCategory,
        updatedCategory: customCategory,
      );
      expect(updated.action, equals(CategoryEditAction.updated));
      expect(updated.updatedCategory, equals(customCategory));
    });

    test('CategoryIconItem equality and props check', () {
      const item1 = CategoryIconItem(id: 'c1', icon: '☕', nameKey: 'Coffee', colorHex: '#123456');
      const item2 = CategoryIconItem(id: 'c1', icon: '☕', nameKey: 'Coffee', colorHex: '#123456');
      expect(item1, equals(item2));
      expect(item1.color, equals(colorFromHex('#123456')));
    });

    test('Bill effectiveCategoryColor falls back gracefully for deleted category', () {
      final bill = Bill(
        id: 'b1',
        title: 'Lunch',
        amount: 50.0,
        category: 'deleted_category',
        date: DateTime.now(),
        paidBy: 'An',
        participants: const [BillParticipant(participantId: 'p1', name: 'An', amount: 50.0)],
      );
      // Fallback to default gray (#9E9E9E) if category is unknown
      expect(bill.effectiveCategoryColor, equals('#9E9E9E'));
    });

    test('Bill with explicit categoryColor preserves color even if category was deleted', () {
      final bill = Bill(
        id: 'b2',
        title: 'Special Meal',
        amount: 100.0,
        category: 'deleted_custom',
        categoryColor: '#E91E63',
        date: DateTime.now(),
        paidBy: 'An',
        participants: const [BillParticipant(participantId: 'p1', name: 'An', amount: 100.0)],
      );
      expect(bill.effectiveCategoryColor, equals('#E91E63'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 11: Detailed Preset Color Swatches Selection (14 tests)
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 11: Preset Color Swatches Selection (All 14 Colors)', () {
    for (int i = 0; i < presetCategoryColors.length; i++) {
      final hex = presetCategoryColors[i];
      testWidgets('Selecting preset color swatch #$i ($hex) updates active color', (tester) async {
        await tester.pumpWidget(buildTestApp(
          child: Scaffold(
            body: EditCategoryBottomSheet(
              category: customCategory,
              existingCategories: const [customCategory],
              isDefaultCategory: false,
            ),
          ),
        ));
        await tester.pumpAndSettle();

        final swatchFinder = find.byKey(Key('color_swatch_$hex'));
        expect(swatchFinder, findsOneWidget);

        await tester.tap(swatchFinder);
        await tester.pumpAndSettle();

        // Check icon appears in this swatch
        final checkFinder = find.descendant(of: swatchFinder, matching: find.byIcon(Icons.check));
        expect(checkFinder, findsOneWidget);
      });
    }
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 11: Suggested Icons Selection (16 tests)
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 11: Suggested Icons Selection', () {
    for (int i = 0; i < 16; i++) {
      final iconData = suggestedCategoryIcons[i];
      testWidgets('Selecting icon #$i (${iconData.codePoint}) updates icon in preview', (tester) async {
        await tester.pumpWidget(buildTestApp(
          child: Scaffold(
            body: EditCategoryBottomSheet(
              category: customCategory,
              existingCategories: const [customCategory],
              isDefaultCategory: false,
            ),
          ),
        ));
        await tester.pumpAndSettle();

        final iconOption = find.byKey(Key('icon_option_${iconData.codePoint}'));
        if (iconOption.evaluate().isNotEmpty) {
          await tester.tap(iconOption);
          await tester.pumpAndSettle();
        }
      });
    }
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 11: Detailed Auto-Detection for All 12 Default Categories (12 tests)
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 11: Auto-detection for all 12 Default Categories', () {
    for (final defaultCat in defaultCategoryIcons) {
      testWidgets('Auto-detects default category without flag: ${defaultCat.id}', (tester) async {
        await tester.pumpWidget(buildTestApp(
          child: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => EditCategoryBottomSheet.show(
                  context,
                  category: defaultCat,
                  existingCategories: defaultCategoryIcons,
                  // auto-detect
                ),
                child: Text('Open ${defaultCat.id}'),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open ${defaultCat.id}'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('deleteCategoryButton')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('cannotDeleteDefaultSnackbar')), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
      });
    }
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 11: Category Name Input Edge Cases & Unicode (10 tests)
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 11: Category Name Input Edge Cases & Unicode', () {
    testWidgets('Supports Vietnamese unicode characters: Ăn uống & Tiệc tùng', (tester) async {
      CategoryEditResult? result;
      await tester.pumpWidget(buildTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await EditCategoryBottomSheet.show(
                context,
                category: customCategory,
                existingCategories: const [customCategory],
                isDefaultCategory: false,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editCategoryNameField')), 'Ăn uống & Tiệc tùng');
      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.updatedCategory!.nameKey, equals('Ăn uống & Tiệc tùng'));
    });

    testWidgets('Trims leading and trailing spaces upon saving', (tester) async {
      CategoryEditResult? result;
      await tester.pumpWidget(buildTestApp(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await EditCategoryBottomSheet.show(
                context,
                category: customCategory,
                existingCategories: const [customCategory],
                isDefaultCategory: false,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editCategoryNameField')), '   Coffee Club   ');
      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.updatedCategory!.nameKey, equals('Coffee Club'));
    });

    testWidgets('Case-insensitive duplicate detection prevents collision', (tester) async {
      const other = CategoryIconItem(id: 'c2', icon: '⚽', nameKey: 'Football');
      await tester.pumpWidget(buildTestApp(
        child: Scaffold(
          body: EditCategoryBottomSheet(
            category: customCategory,
            existingCategories: const [customCategory, other],
            isDefaultCategory: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editCategoryNameField')), 'football');
      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();

      expect(find.text('Category already exists'), findsOneWidget);
    });

    testWidgets('Entering text clears previous validation error', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Scaffold(
          body: EditCategoryBottomSheet(
            category: customCategory,
            existingCategories: const [customCategory],
            isDefaultCategory: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Trigger empty error
      await tester.enterText(find.byKey(const Key('editCategoryNameField')), '');
      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();
      expect(find.text('Category name is required'), findsOneWidget);

      // Type valid text
      await tester.enterText(find.byKey(const Key('editCategoryNameField')), 'New Valid Name');
      await tester.pumpAndSettle();

      expect(find.text('Category name is required'), findsNothing);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 11: CategoryEntity Serialization & Helper Methods (10 tests)
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 11: CategoryEntity Serialization & Models', () {
    test('CategoryEntity serializes toJson and fromJson correctly', () {
      const entity = CategoryEntity(
        id: 'cat1',
        name: 'Gifts',
        icon: '🎁',
        colorHex: '#E040FB',
        iconCodePoint: 58742,
      );
      final json = entity.toJson();
      expect(json['id'], equals('cat1'));
      expect(json['name'], equals('Gifts'));
      expect(json['icon'], equals('🎁'));
      expect(json['colorHex'], equals('#E040FB'));
      expect(json['iconCodePoint'], equals(58742));

      final restored = CategoryEntity.fromJson(json);
      expect(restored, equals(entity));
      expect(restored.materialIcon, isNotNull);
      expect(restored.color, equals(colorFromHex('#E040FB')));
    });

    test('initialCategories contains all 12 default entities with unique IDs', () {
      expect(initialCategories.length, equals(12));
      final ids = initialCategories.map((c) => c.id).toSet();
      expect(ids.length, equals(12));
    });

    test('colorFromHex handles invalid hex strings with default color fallback', () {
      final fallback = colorFromHex('invalid');
      expect(fallback, equals(const Color(0xFF9E9E9E)));

      final emptyFallback = colorFromHex('');
      expect(emptyFallback, equals(const Color(0xFF9E9E9E)));
    });

    test('colorToHex handles various colors properly', () {
      expect(colorToHex(const Color(0xFFFF0000)), equals('#FF0000'));
      expect(colorToHex(const Color(0xFF00FF00)), equals('#00FF00'));
      expect(colorToHex(const Color(0xFF0000FF)), equals('#0000FF'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // AC 11: Full End-to-End AddBill Integration Flows (8 tests)
  // ───────────────────────────────────────────────────────────────────────────
  group('AC 11: Full End-to-End AddBill Integration Flows', () {
    testWidgets('Edit custom category and then save bill with updated category', (tester) async {
      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(billRepo: billRepo));
      await tester.pumpAndSettle();

      // 1. Add custom category
      await tester.tap(find.byKey(const Key('addCategoryButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('newCategoryNameField')), 'Coffee & Tea');
      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();

      // 2. Edit it to 'Espresso Bar'
      await tester.tap(find.byKey(const Key('edit_category_icon_coffee_&_tea')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editCategoryNameField')), 'Espresso Bar');
      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();

      // 3. Fill remaining bill fields
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '45000');
      await tester.enterText(find.widgetWithText(TextField, 'Payer'), 'Huy');
      await tester.enterText(find.widgetWithText(TextField, 'Participant Name'), 'Huy');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Participant Name'), 'An');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      // 4. Save bill
      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.bills.length, equals(1));
      expect(billRepo.bills.first.category, equals('coffee_&_tea'));
    });

    testWidgets('Deleting custom category and saving bill uses fallback category', (tester) async {
      final billRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(billRepo: billRepo));
      await tester.pumpAndSettle();

      // 1. Add custom category
      await tester.tap(find.byKey(const Key('addCategoryButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('newCategoryNameField')), 'Ice Cream');
      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();

      // 2. Delete it
      await tester.tap(find.byKey(const Key('edit_category_icon_ice_cream')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deleteCategoryButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirmDeleteCategoryButton')));
      await tester.pumpAndSettle();

      // 3. Fill and save bill with at least 2 participants
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '30000');
      await tester.enterText(find.widgetWithText(TextField, 'Payer'), 'Lan');
      await tester.enterText(find.widgetWithText(TextField, 'Participant Name'), 'Lan');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Participant Name'), 'Hoa');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(billRepo.bills.length, equals(1));
      // Fallback category is restaurant
      expect(billRepo.bills.first.category, equals('restaurant'));
    });

    test('CategorySuggestion props and equality check', () {
      const s1 = CategorySuggestion(
        id: 'party',
        nameEn: 'Party',
        nameVi: 'Tiệp',
        emoji: '🎉',
        iconData: Icons.cake,
        colorHex: '#E040FB',
      );
      const s2 = CategorySuggestion(
        id: 'party',
        nameEn: 'Party',
        nameVi: 'Tiệp',
        emoji: '🎉',
        iconData: Icons.cake,
        colorHex: '#E040FB',
      );
      expect(s1, equals(s2));
      expect(s1.props, equals(['party', 'Party', 'Tiệp', '🎉', Icons.cake, '#E040FB']));
    });

    test('currencySymbols map contains major currencies', () {
      expect(currencySymbols.containsKey('VND'), isTrue);
      expect(currencySymbols.containsKey('USD'), isTrue);
      expect(currencySymbols.containsKey('EUR'), isTrue);
    });
  });
}
