import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dartz/dartz.dart';

import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/add_bill_screen.dart';
import 'package:shared_household_planner/features/split_bills/presentation/widgets/bill_card.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/settings/presentation/pages/settings_screen.dart';

import 'package:shared_household_planner/features/templates/domain/entities/bill_template.dart';
import 'package:shared_household_planner/features/templates/data/models/bill_template_model.dart';
import 'package:shared_household_planner/features/templates/data/datasources/bill_template_local_datasource.dart';
import 'package:shared_household_planner/features/templates/data/repositories/bill_template_repository_impl.dart';
import 'package:shared_household_planner/features/templates/domain/repositories/bill_template_repository.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/get_templates_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/create_template_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/update_template_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/delete_template_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/toggle_favorite_template_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/record_template_usage_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/get_suggested_templates_usecase.dart';
import 'package:shared_household_planner/features/templates/presentation/bloc/bill_templates_bloc.dart';
import 'package:shared_household_planner/features/templates/presentation/pages/bill_templates_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test Fakes & Mocks
// ─────────────────────────────────────────────────────────────────────────────

class FakeBillTemplateLocalDataSource implements BillTemplateLocalDataSource {
  final Map<String, BillTemplateModel> storage = {};
  bool shouldThrow = false;

  @override
  Future<BillTemplateModel> insertTemplate(BillTemplateModel template) async {
    if (shouldThrow) throw Exception('DB error');
    storage[template.id] = template;
    return template;
  }

  @override
  Future<BillTemplateModel> getTemplateById(String id) async {
    if (shouldThrow) throw Exception('DB error');
    final item = storage[id];
    if (item == null) throw Exception('Not found');
    return item;
  }

  @override
  Future<List<BillTemplateModel>> getTemplates({String? projectId}) async {
    if (shouldThrow) throw Exception('DB error');
    if (projectId != null && projectId.isNotEmpty) {
      return storage.values.where((t) => t.projectId == projectId).toList();
    }
    return storage.values.toList();
  }

  @override
  Future<BillTemplateModel> updateTemplate(BillTemplateModel template) async {
    if (shouldThrow) throw Exception('DB error');
    storage[template.id] = template;
    return template;
  }

  @override
  Future<void> deleteTemplate(String id) async {
    if (shouldThrow) throw Exception('DB error');
    storage.remove(id);
  }

  @override
  Future<List<BillTemplateModel>> getFavoriteTemplates({String? projectId}) async {
    if (shouldThrow) throw Exception('DB error');
    return storage.values.where((t) => t.isFavorite).toList();
  }

  @override
  Future<List<BillTemplateModel>> getSuggestedTemplates({String? projectId, int limit = 3}) async {
    if (shouldThrow) throw Exception('DB error');
    final list = storage.values.toList()
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return list.take(limit).toList();
  }

  @override
  Future<void> recordTemplateUsage(String id) async {
    if (shouldThrow) throw Exception('DB error');
    final item = storage[id];
    if (item != null) {
      storage[id] = item.copyWith(
        usageCount: item.usageCount + 1,
        lastUsedAt: DateTime.now(),
      ) as BillTemplateModel;
    }
  }

  @override
  Future<BillTemplateModel> toggleFavorite(String id) async {
    if (shouldThrow) throw Exception('DB error');
    final item = storage[id];
    if (item == null) throw Exception('Not found');
    final updated = item.copyWith(isFavorite: !item.isFavorite) as BillTemplateModel;
    storage[id] = updated;
    return updated;
  }
}

class FakeBillTemplateRepository implements BillTemplateRepository {
  final List<BillTemplate> templates = [];
  bool shouldFail = false;

  @override
  Future<Either<Failure, List<BillTemplate>>> getTemplates({String? projectId}) async {
    if (shouldFail) return const Left(LocalFailure('Repo error'));
    if (projectId != null) {
      return Right(templates.where((t) => t.projectId == projectId).toList());
    }
    return Right(List.from(templates));
  }

  @override
  Future<Either<Failure, BillTemplate>> getTemplateById(String id) async {
    if (shouldFail) return const Left(LocalFailure('Repo error'));
    final match = templates.where((t) => t.id == id);
    if (match.isEmpty) return const Left(LocalFailure('Not found'));
    return Right(match.first);
  }

  @override
  Future<Either<Failure, BillTemplate>> createTemplate(BillTemplate template) async {
    if (shouldFail) return const Left(LocalFailure('Repo error'));
    templates.add(template);
    return Right(template);
  }

  @override
  Future<Either<Failure, BillTemplate>> updateTemplate(BillTemplate template) async {
    if (shouldFail) return const Left(LocalFailure('Repo error'));
    final index = templates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      templates[index] = template;
    } else {
      templates.add(template);
    }
    return Right(template);
  }

  @override
  Future<Either<Failure, void>> deleteTemplate(String id) async {
    if (shouldFail) return const Left(LocalFailure('Repo error'));
    templates.removeWhere((t) => t.id == id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, BillTemplate>> toggleFavorite(String id) async {
    if (shouldFail) return const Left(LocalFailure('Repo error'));
    final index = templates.indexWhere((t) => t.id == id);
    if (index != -1) {
      final updated = templates[index].copyWith(isFavorite: !templates[index].isFavorite);
      templates[index] = updated;
      return Right(updated);
    }
    return const Left(LocalFailure('Not found'));
  }

  @override
  Future<Either<Failure, BillTemplate>> toggleFavoriteTemplate(String id) => toggleFavorite(id);

  @override
  Future<Either<Failure, void>> recordTemplateUsage(String id) async {
    if (shouldFail) return const Left(LocalFailure('Repo error'));
    final index = templates.indexWhere((t) => t.id == id);
    if (index != -1) {
      final t = templates[index];
      templates[index] = t.copyWith(
        usageCount: t.usageCount + 1,
        lastUsedAt: DateTime.now(),
      );
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<BillTemplate>>> getSuggestedTemplates({String? projectId, int limit = 3}) async {
    if (shouldFail) return const Left(LocalFailure('Repo error'));
    final list = List<BillTemplate>.from(templates)
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return Right(list.take(limit).toList());
  }

  @override
  Future<Either<Failure, List<BillTemplate>>> getFavoriteTemplates({String? projectId}) async {
    if (shouldFail) return const Left(LocalFailure('Repo error'));
    return Right(templates.where((t) => t.isFavorite).toList());
  }
}

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
    if (idx != -1) bills[idx] = bill;
    return Right(bill);
  }

  @override
  Future<Either<Failure, void>> delete(String billId) async {
    bills.removeWhere((b) => b.id == billId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Bill>>> getByProjectId(String projectId) async =>
      Right(bills.where((b) => b.projectId == projectId).toList());

  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async =>
      getByProjectId(projectId);

  @override
  Future<Either<Failure, List<Bill>>> getByDateRange(DateTime start, DateTime end) async =>
      Right(List.from(bills));

  @override
  Future<Either<Failure, List<Bill>>> getByPayer(String payerName) async =>
      Right(bills.where((b) => b.paidBy == payerName).toList());

  @override
  Future<Either<Failure, List<Bill>>> getByCategory(String category) async =>
      Right(bills.where((b) => b.category == category).toList());
}

class FakeProjectRepo implements ProjectRepository {
  final List<Project> projects = [];

  @override
  Future<Either<Failure, Project>> create(Project project) async {
    projects.add(project);
    return Right(project);
  }

  @override
  Future<Either<Failure, List<Project>>> getAll() async => Right(List.from(projects));

  @override
  Future<Either<Failure, Project>> getById(String id) async =>
      Right(projects.firstWhere((p) => p.id == id));

  @override
  Future<Either<Failure, Project>> update(Project project) async {
    final idx = projects.indexWhere((p) => p.id == project.id);
    if (idx != -1) projects[idx] = project;
    return Right(project);
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    projects.removeWhere((p) => p.id == id);
    return const Right(null);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Test Helpers
// ─────────────────────────────────────────────────────────────────────────────

BillTemplate createSampleTemplate({
  String id = 'tpl-1',
  String title = 'Weekly Groceries',
  double amount = 150000.0,
  String category = 'food',
  String categoryIcon = '🍕',
  String categoryColor = '#4CAF50',
  String currency = 'VND',
  String paidBy = 'Alice',
  List<String> participants = const ['Alice', 'Bob'],
  String splitMode = 'equal',
  String? projectId,
  bool isFavorite = false,
  int usageCount = 0,
  DateTime? lastUsedAt,
  DateTime? createdAt,
}) {
  return BillTemplate(
    id: id,
    title: title,
    amount: amount,
    category: category,
    categoryIcon: categoryIcon,
    categoryColor: categoryColor,
    currency: currency,
    paidBy: paidBy,
    participants: participants,
    splitMode: splitMode,
    projectId: projectId,
    isFavorite: isFavorite,
    usageCount: usageCount,
    lastUsedAt: lastUsedAt,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}

class TestTemplatesLocalizations extends AppLocalizations {
  TestTemplatesLocalizations(Locale locale) : super(locale);

  static Map<String, String> _loadJson(String code) {
    try {
      final file = File('lib/core/localization/translations/$code.json');
      if (file.existsSync()) {
        final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, v.toString()));
      }
    } catch (_) {}
    return {};
  }

  static final Map<String, String> _en = _loadJson('en');
  static final Map<String, String> _vi = _loadJson('vi');

  @override
  String translate(String key) {
    if (locale.languageCode == 'vi') {
      return _vi[key] ?? _en[key] ?? key;
    }
    return _en[key] ?? key;
  }
}

class TestTemplatesLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const TestTemplatesLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(TestTemplatesLocalizations(locale));
  }

  @override
  bool shouldReload(TestTemplatesLocalizationsDelegate old) => false;
}

Widget buildTestWidget({
  required Widget child,
  BillTemplateRepository? templateRepo,
  BillTemplatesBloc? templatesBloc,
  BillRepository? billRepo,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
}) {
  final fakeTemplateRepo = templateRepo ?? FakeBillTemplateRepository();
  final fakeBillRepo = billRepo ?? FakeBillRepo();
  final fakeProjectRepo = FakeProjectRepo();

  final bTemplatesBloc = templatesBloc ??
      BillTemplatesBloc(
        getTemplatesUseCase: GetTemplatesUseCase(fakeTemplateRepo),
        createTemplateUseCase: CreateTemplateUseCase(fakeTemplateRepo),
        updateTemplateUseCase: UpdateTemplateUseCase(fakeTemplateRepo),
        deleteTemplateUseCase: DeleteTemplateUseCase(fakeTemplateRepo),
        toggleFavoriteTemplateUseCase: ToggleFavoriteTemplateUseCase(fakeTemplateRepo),
        recordTemplateUsageUseCase: RecordTemplateUsageUseCase(fakeTemplateRepo),
        getSuggestedTemplatesUseCase: GetSuggestedTemplatesUseCase(fakeTemplateRepo),
      )..add(const LoadTemplatesEvent());

  final billsBloc = BillsBloc(
    getBillsUseCase: GetBillsUseCase(fakeBillRepo),
    addBillUseCase: AddBillUseCase(fakeBillRepo),
  );

  final projectBloc = ProjectBloc(
    createProjectUseCase: CreateProjectUseCase(fakeProjectRepo),
    getAllProjectsUseCase: GetAllProjectsUseCase(fakeProjectRepo),
    updateProjectUseCase: UpdateProjectUseCase(fakeProjectRepo),
    deleteProjectUseCase: DeleteProjectUseCase(fakeProjectRepo),
  );

  Widget effectiveChild = child;
  if (child is AddBillScreen && child.initialCompactMode == null) {
    effectiveChild = AddBillScreen(
      key: child.key,
      billToEdit: child.billToEdit,
      projectId: child.projectId,
      requireProject: child.requireProject,
      projectSettings: child.projectSettings,
      template: child.template,
      initialImagePath: child.initialImagePath,
      initialImagePaths: child.initialImagePaths,
      onPickImage: child.onPickImage,
      onPickMultipleImages: child.onPickMultipleImages,
      projectName: child.projectName,
      initialCompactMode: false,
    );
  }

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<BillTemplateRepository>.value(value: fakeTemplateRepo),
      RepositoryProvider<BillRepository>.value(value: fakeBillRepo),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<BillTemplatesBloc>.value(value: bTemplatesBloc),
        BlocProvider<BillsBloc>.value(value: billsBloc),
        BlocProvider<ProjectBloc>.value(value: projectBloc),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('vi')],
        localizationsDelegates: const [
          TestTemplatesLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: effectiveChild,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN TEST SUITE (Shared-36)
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. BillTemplate Entity Tests', () {
    test('Equality holds for identical attributes', () {
      final t1 = createSampleTemplate(id: '1', title: 'Rent');
      final t2 = createSampleTemplate(id: '1', title: 'Rent');
      expect(t1, equals(t2));
      expect(t1.hashCode, equals(t2.hashCode));
    });

    test('Inequality when id differs', () {
      final t1 = createSampleTemplate(id: '1');
      final t2 = createSampleTemplate(id: '2');
      expect(t1, isNot(equals(t2)));
    });

    test('Inequality when title differs', () {
      final t1 = createSampleTemplate(title: 'Groceries');
      final t2 = createSampleTemplate(title: 'Utilities');
      expect(t1, isNot(equals(t2)));
    });

    test('Inequality when amount differs', () {
      final t1 = createSampleTemplate(amount: 100);
      final t2 = createSampleTemplate(amount: 200);
      expect(t1, isNot(equals(t2)));
    });

    test('Inequality when category differs', () {
      final t1 = createSampleTemplate(category: 'food');
      final t2 = createSampleTemplate(category: 'transport');
      expect(t1, isNot(equals(t2)));
    });

    test('Inequality when isFavorite differs', () {
      final t1 = createSampleTemplate(isFavorite: false);
      final t2 = createSampleTemplate(isFavorite: true);
      expect(t1, isNot(equals(t2)));
    });

    test('Inequality when usageCount differs', () {
      final t1 = createSampleTemplate(usageCount: 1);
      final t2 = createSampleTemplate(usageCount: 2);
      expect(t1, isNot(equals(t2)));
    });

    test('Props contains all key fields', () {
      final t = createSampleTemplate();
      expect(t.props, contains(t.id));
      expect(t.props, contains(t.title));
      expect(t.props, contains(t.amount));
      expect(t.props, contains(t.category));
      expect(t.props, contains(t.isFavorite));
      expect(t.props, contains(t.usageCount));
    });

    test('copyWith with no arguments returns equal object', () {
      final t = createSampleTemplate();
      final copy = t.copyWith();
      expect(copy, equals(t));
    });

    test('copyWith updates title', () {
      final t = createSampleTemplate();
      final copy = t.copyWith(title: 'Electricity Bill');
      expect(copy.title, 'Electricity Bill');
      expect(copy.id, t.id);
    });

    test('copyWith updates amount', () {
      final t = createSampleTemplate();
      final copy = t.copyWith(amount: 500000);
      expect(copy.amount, 500000);
    });

    test('copyWith updates category, icon, and color', () {
      final t = createSampleTemplate();
      final copy = t.copyWith(
        category: 'utilities',
        categoryIcon: '⚡',
        categoryColor: '#FF9800',
      );
      expect(copy.category, 'utilities');
      expect(copy.categoryIcon, '⚡');
      expect(copy.categoryColor, '#FF9800');
    });

    test('copyWith updates currency, paidBy, splitMode', () {
      final t = createSampleTemplate();
      final copy = t.copyWith(currency: 'USD', paidBy: 'Charlie', splitMode: 'custom');
      expect(copy.currency, 'USD');
      expect(copy.paidBy, 'Charlie');
      expect(copy.splitMode, 'custom');
    });

    test('copyWith updates participants', () {
      final t = createSampleTemplate();
      final copy = t.copyWith(participants: ['X', 'Y', 'Z']);
      expect(copy.participants, equals(['X', 'Y', 'Z']));
    });

    test('copyWith updates isFavorite, usageCount, lastUsedAt, projectId', () {
      final now = DateTime.now();
      final t = createSampleTemplate();
      final copy = t.copyWith(
        isFavorite: true,
        usageCount: 10,
        lastUsedAt: now,
        projectId: 'proj-123',
      );
      expect(copy.isFavorite, isTrue);
      expect(copy.usageCount, 10);
      expect(copy.lastUsedAt, equals(now));
      expect(copy.projectId, 'proj-123');
    });
  });

  group('2. BillTemplateModel Serialization Tests', () {
    test('toJson and fromJson preserves all fields', () {
      final now = DateTime(2026, 2, 15, 10, 30);
      final model = BillTemplateModel(
        id: 't-1',
        title: 'Dinner',
        amount: 250000,
        category: 'restaurant',
        categoryIcon: '🍽️',
        categoryColor: '#E91E63',
        currency: 'VND',
        paidBy: 'Bob',
        participants: const ['Bob', 'Alice'],
        splitMode: 'equal',
        projectId: 'p-1',
        isFavorite: true,
        usageCount: 3,
        lastUsedAt: now,
        createdAt: now,
      );

      final json = model.toJson();
      final restored = BillTemplateModel.fromJson(json);

      expect(restored.id, model.id);
      expect(restored.title, model.title);
      expect(restored.amount, model.amount);
      expect(restored.category, model.category);
      expect(restored.categoryIcon, model.categoryIcon);
      expect(restored.categoryColor, model.categoryColor);
      expect(restored.currency, model.currency);
      expect(restored.paidBy, model.paidBy);
      expect(restored.participants, model.participants);
      expect(restored.splitMode, model.splitMode);
      expect(restored.projectId, model.projectId);
      expect(restored.isFavorite, isTrue);
      expect(restored.usageCount, 3);
      expect(restored.lastUsedAt, equals(now));
      expect(restored.createdAt, equals(now));
    });

    test('toJson and fromJson with minimal/null optional fields', () {
      final now = DateTime(2026, 1, 1);
      final model = BillTemplateModel(
        id: 't-min',
        title: 'Simple',
        amount: 0,
        category: 'other',
        createdAt: now,
      );

      final json = model.toJson();
      final restored = BillTemplateModel.fromJson(json);

      expect(restored.id, 't-min');
      expect(restored.title, 'Simple');
      expect(restored.amount, 0.0);
      expect(restored.category, 'other');
      expect(restored.currency, 'VND');
      expect(restored.participants, isEmpty);
      expect(restored.isFavorite, isFalse);
      expect(restored.usageCount, 0);
      expect(restored.lastUsedAt, isNull);
    });

    test('toMap and fromMap for SQLite persistence', () {
      final now = DateTime(2026, 3, 1, 14, 0);
      final model = BillTemplateModel(
        id: 'db-1',
        title: 'Electricity',
        amount: 320000,
        category: 'utilities',
        categoryIcon: '⚡',
        categoryColor: '#FFB300',
        currency: 'VND',
        paidBy: 'John',
        participants: const ['John', 'Jane'],
        splitMode: 'equal',
        projectId: 'p-house',
        isFavorite: true,
        usageCount: 5,
        lastUsedAt: now,
        createdAt: now,
      );

      final map = model.toMap();
      expect(map['id'], 'db-1');
      expect(map['is_favorite'], 1);
      expect(map['participants'], jsonEncode(['John', 'Jane']));

      final restored = BillTemplateModel.fromMap(map);
      expect(restored.id, 'db-1');
      expect(restored.isFavorite, isTrue);
      expect(restored.participants, equals(['John', 'Jane']));
      expect(restored.usageCount, 5);
      expect(restored.lastUsedAt, equals(now));
    });

    test('fromMap parses is_favorite 0 as false', () {
      final map = {
        'id': 'db-2',
        'title': 'Test',
        'amount': 100.0,
        'category': 'other',
        'is_favorite': 0,
        'created_at': DateTime.now().toIso8601String(),
      };
      final model = BillTemplateModel.fromMap(map);
      expect(model.isFavorite, isFalse);
    });

    test('fromMap handles null/empty participants string gracefully', () {
      final map = {
        'id': 'db-3',
        'title': 'Test',
        'amount': 100.0,
        'category': 'other',
        'participants': '',
        'created_at': DateTime.now().toIso8601String(),
      };
      final model = BillTemplateModel.fromMap(map);
      expect(model.participants, isEmpty);
    });

    test('fromMap handles invalid json participants gracefully', () {
      final map = {
        'id': 'db-4',
        'title': 'Test',
        'amount': 100.0,
        'category': 'other',
        'participants': 'not-a-valid-json',
        'created_at': DateTime.now().toIso8601String(),
      };
      final model = BillTemplateModel.fromMap(map);
      expect(model.participants, isEmpty);
    });

    test('fromMap converts integer amount to double', () {
      final map = {
        'id': 'db-5',
        'title': 'Test',
        'amount': 250,
        'category': 'other',
        'created_at': DateTime.now().toIso8601String(),
      };
      final model = BillTemplateModel.fromMap(map);
      expect(model.amount, 250.0);
    });

    test('fromEntity and toEntity conversion cycle', () {
      final entity = createSampleTemplate(id: 'entity-1', title: 'Coffee');
      final model = BillTemplateModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.title, entity.title);

      final backToEntity = model.toEntity();
      expect(backToEntity, equals(entity));
    });

    test('fromJson handles int amount conversion', () {
      final json = {
        'id': 'json-1',
        'title': 'Test',
        'amount': 99,
        'category': 'other',
        'createdAt': DateTime.now().toIso8601String(),
      };
      final model = BillTemplateModel.fromJson(json);
      expect(model.amount, 99.0);
    });

    test('fromJson handles empty or null participants', () {
      final json = {
        'id': 'json-2',
        'title': 'Test',
        'amount': 10.0,
        'category': 'other',
        'participants': null,
        'createdAt': DateTime.now().toIso8601String(),
      };
      final model = BillTemplateModel.fromJson(json);
      expect(model.participants, isEmpty);
    });

    test('toMap serializes null last_used_at as null', () {
      final model = BillTemplateModel(
        id: 'null-used',
        title: 'Never used',
        amount: 50,
        category: 'other',
        lastUsedAt: null,
        createdAt: DateTime.now(),
      );
      final map = model.toMap();
      expect(map['last_used_at'], isNull);
    });

    test('fromMap handles null last_used_at without errors', () {
      final map = {
        'id': 'db-6',
        'title': 'Test',
        'amount': 100.0,
        'category': 'other',
        'last_used_at': null,
        'created_at': DateTime.now().toIso8601String(),
      };
      final model = BillTemplateModel.fromMap(map);
      expect(model.lastUsedAt, isNull);
    });
  });

  group('3. BillTemplateLocalDataSource Tests', () {
    late FakeBillTemplateLocalDataSource dataSource;

    setUp(() {
      dataSource = FakeBillTemplateLocalDataSource();
    });

    test('insertTemplate persists item in storage', () async {
      final model = BillTemplateModel.fromEntity(createSampleTemplate(id: 'ds-1'));
      await dataSource.insertTemplate(model);

      final fetched = await dataSource.getTemplateById('ds-1');
      expect(fetched.id, 'ds-1');
    });

    test('getTemplateById throws when not found', () async {
      expect(() => dataSource.getTemplateById('non-existent'), throwsException);
    });

    test('getTemplates returns all stored items', () async {
      await dataSource.insertTemplate(BillTemplateModel.fromEntity(createSampleTemplate(id: '1')));
      await dataSource.insertTemplate(BillTemplateModel.fromEntity(createSampleTemplate(id: '2')));

      final all = await dataSource.getTemplates();
      expect(all.length, 2);
    });

    test('getTemplates filters by projectId', () async {
      await dataSource.insertTemplate(BillTemplateModel.fromEntity(
          createSampleTemplate(id: 'p1', projectId: 'project-A')));
      await dataSource.insertTemplate(BillTemplateModel.fromEntity(
          createSampleTemplate(id: 'p2', projectId: 'project-B')));

      final projA = await dataSource.getTemplates(projectId: 'project-A');
      expect(projA.length, 1);
      expect(projA.first.id, 'p1');
    });

    test('updateTemplate updates existing record', () async {
      final original = BillTemplateModel.fromEntity(createSampleTemplate(id: 'up-1', title: 'Old'));
      await dataSource.insertTemplate(original);

      final updated = original.copyWith(title: 'New') as BillTemplateModel;
      await dataSource.updateTemplate(updated);

      final fetched = await dataSource.getTemplateById('up-1');
      expect(fetched.title, 'New');
    });

    test('deleteTemplate removes record', () async {
      final model = BillTemplateModel.fromEntity(createSampleTemplate(id: 'del-1'));
      await dataSource.insertTemplate(model);
      await dataSource.deleteTemplate('del-1');

      expect(() => dataSource.getTemplateById('del-1'), throwsException);
    });

    test('getFavoriteTemplates returns only favorites', () async {
      await dataSource.insertTemplate(BillTemplateModel.fromEntity(
          createSampleTemplate(id: 'fav-1', isFavorite: true)));
      await dataSource.insertTemplate(BillTemplateModel.fromEntity(
          createSampleTemplate(id: 'not-fav', isFavorite: false)));

      final favs = await dataSource.getFavoriteTemplates();
      expect(favs.length, 1);
      expect(favs.first.id, 'fav-1');
    });

    test('getSuggestedTemplates sorts by usage count descending', () async {
      await dataSource.insertTemplate(BillTemplateModel.fromEntity(
          createSampleTemplate(id: 'low', usageCount: 2)));
      await dataSource.insertTemplate(BillTemplateModel.fromEntity(
          createSampleTemplate(id: 'high', usageCount: 20)));
      await dataSource.insertTemplate(BillTemplateModel.fromEntity(
          createSampleTemplate(id: 'mid', usageCount: 10)));

      final suggested = await dataSource.getSuggestedTemplates(limit: 3);
      expect(suggested.map((s) => s.id).toList(), equals(['high', 'mid', 'low']));
    });

    test('recordTemplateUsage increments count and sets lastUsedAt', () async {
      final model = BillTemplateModel.fromEntity(
          createSampleTemplate(id: 'use-1', usageCount: 0, lastUsedAt: null));
      await dataSource.insertTemplate(model);

      await dataSource.recordTemplateUsage('use-1');
      final fetched = await dataSource.getTemplateById('use-1');
      expect(fetched.usageCount, 1);
      expect(fetched.lastUsedAt, isNotNull);
    });

    test('handles exceptions when storage throws', () async {
      dataSource.shouldThrow = true;
      expect(() => dataSource.getTemplates(), throwsException);
    });
  });

  group('4. BillTemplateRepositoryImpl Tests', () {
    late FakeBillTemplateLocalDataSource fakeDataSource;
    late BillTemplateRepositoryImpl repository;

    setUp(() {
      fakeDataSource = FakeBillTemplateLocalDataSource();
      repository = BillTemplateRepositoryImpl(fakeDataSource);
    });

    test('getTemplates returns Right(List<BillTemplate>)', () async {
      await fakeDataSource.insertTemplate(BillTemplateModel.fromEntity(createSampleTemplate(id: 'r1')));
      final result = await repository.getTemplates();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('should succeed'), (list) => expect(list.length, 1));
    });

    test('getTemplates returns Left(LocalFailure) on datasource error', () async {
      fakeDataSource.shouldThrow = true;
      final result = await repository.getTemplates();

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<LocalFailure>()), (_) => fail('should fail'));
    });

    test('getTemplates with projectId filters correctly', () async {
      await fakeDataSource.insertTemplate(
          BillTemplateModel.fromEntity(createSampleTemplate(id: 'p1', projectId: 'house')));
      final result = await repository.getTemplates(projectId: 'house');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('should succeed'), (list) => expect(list.first.projectId, 'house'));
    });

    test('createTemplate saves and returns Right(BillTemplate)', () async {
      final tpl = createSampleTemplate(id: 'create-1');
      final result = await repository.createTemplate(tpl);

      expect(result.isRight(), isTrue);
      final stored = await fakeDataSource.getTemplateById('create-1');
      expect(stored, isNotNull);
    });

    test('updateTemplate updates and returns Right(BillTemplate)', () async {
      final tpl = createSampleTemplate(id: 'up-1', title: 'Old');
      await fakeDataSource.insertTemplate(BillTemplateModel.fromEntity(tpl));

      final updated = tpl.copyWith(title: 'Updated');
      final result = await repository.updateTemplate(updated);

      expect(result.isRight(), isTrue);
      final stored = await fakeDataSource.getTemplateById('up-1');
      expect(stored.title, 'Updated');
    });

    test('deleteTemplate removes item and returns Right(null)', () async {
      await fakeDataSource.insertTemplate(BillTemplateModel.fromEntity(createSampleTemplate(id: 'del-1')));
      final result = await repository.deleteTemplate('del-1');

      expect(result.isRight(), isTrue);
      expect(() => fakeDataSource.getTemplateById('del-1'), throwsException);
    });

    test('toggleFavorite toggles favorite state', () async {
      final tpl = createSampleTemplate(id: 'fav-toggle', isFavorite: false);
      await fakeDataSource.insertTemplate(BillTemplateModel.fromEntity(tpl));

      final result = await repository.toggleFavorite('fav-toggle');
      expect(result.isRight(), isTrue);
      result.fold((_) => fail('failed'), (item) => expect(item.isFavorite, isTrue));
    });

    test('toggleFavorite returns Left if item not found', () async {
      final result = await repository.toggleFavorite('not-found');
      expect(result.isLeft(), isTrue);
    });

    test('recordTemplateUsage calls increment on datasource', () async {
      final tpl = createSampleTemplate(id: 'rec-1', usageCount: 0);
      await fakeDataSource.insertTemplate(BillTemplateModel.fromEntity(tpl));

      final result = await repository.recordTemplateUsage('rec-1');
      expect(result.isRight(), isTrue);
      final stored = await fakeDataSource.getTemplateById('rec-1');
      expect(stored.usageCount, 1);
    });

    test('getSuggestedTemplates returns suggested list', () async {
      await fakeDataSource.insertTemplate(BillTemplateModel.fromEntity(
          createSampleTemplate(id: 'sug-1', usageCount: 15)));
      final result = await repository.getSuggestedTemplates();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('failed'), (list) => expect(list.first.id, 'sug-1'));
    });
  });

  group('5. Domain Use Cases Tests', () {
    late FakeBillTemplateRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeBillTemplateRepository();
    });

    test('GetTemplatesUseCase calls repository.getTemplates()', () async {
      fakeRepo.templates.add(createSampleTemplate(id: 'uc-1'));
      final useCase = GetTemplatesUseCase(fakeRepo);
      final result = await useCase();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('failed'), (l) => expect(l.length, 1));
    });

    test('CreateTemplateUseCase calls repository.createTemplate()', () async {
      final useCase = CreateTemplateUseCase(fakeRepo);
      final tpl = createSampleTemplate(id: 'uc-create');
      final result = await useCase(tpl);

      expect(result.isRight(), isTrue);
      expect(fakeRepo.templates.any((t) => t.id == 'uc-create'), isTrue);
    });

    test('UpdateTemplateUseCase calls repository.updateTemplate()', () async {
      fakeRepo.templates.add(createSampleTemplate(id: 'uc-up', title: 'Initial'));
      final useCase = UpdateTemplateUseCase(fakeRepo);
      final result = await useCase(createSampleTemplate(id: 'uc-up', title: 'Modified'));

      expect(result.isRight(), isTrue);
      expect(fakeRepo.templates.first.title, 'Modified');
    });

    test('DeleteTemplateUseCase calls repository.deleteTemplate()', () async {
      fakeRepo.templates.add(createSampleTemplate(id: 'uc-del'));
      final useCase = DeleteTemplateUseCase(fakeRepo);
      final result = await useCase('uc-del');

      expect(result.isRight(), isTrue);
      expect(fakeRepo.templates, isEmpty);
    });

    test('ToggleFavoriteTemplateUseCase calls repository.toggleFavoriteTemplate()', () async {
      fakeRepo.templates.add(createSampleTemplate(id: 'uc-fav', isFavorite: false));
      final useCase = ToggleFavoriteTemplateUseCase(fakeRepo);
      final result = await useCase('uc-fav');

      expect(result.isRight(), isTrue);
      expect(fakeRepo.templates.first.isFavorite, isTrue);
    });

    test('RecordTemplateUsageUseCase calls repository.recordTemplateUsage()', () async {
      fakeRepo.templates.add(createSampleTemplate(id: 'uc-use', usageCount: 0));
      final useCase = RecordTemplateUsageUseCase(fakeRepo);
      final result = await useCase('uc-use');

      expect(result.isRight(), isTrue);
      expect(fakeRepo.templates.first.usageCount, 1);
    });

    test('GetSuggestedTemplatesUseCase calls repository.getSuggestedTemplates()', () async {
      fakeRepo.templates.add(createSampleTemplate(id: 'uc-sug', usageCount: 10));
      final useCase = GetSuggestedTemplatesUseCase(fakeRepo);
      final result = await useCase();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('failed'), (l) => expect(l.first.id, 'uc-sug'));
    });
  });

  group('6. BillTemplatesBloc Unit Tests', () {
    late FakeBillTemplateRepository fakeRepo;
    late BillTemplatesBloc bloc;

    setUp(() {
      fakeRepo = FakeBillTemplateRepository();
      bloc = BillTemplatesBloc(
        getTemplatesUseCase: GetTemplatesUseCase(fakeRepo),
        createTemplateUseCase: CreateTemplateUseCase(fakeRepo),
        updateTemplateUseCase: UpdateTemplateUseCase(fakeRepo),
        deleteTemplateUseCase: DeleteTemplateUseCase(fakeRepo),
        toggleFavoriteTemplateUseCase: ToggleFavoriteTemplateUseCase(fakeRepo),
        recordTemplateUsageUseCase: RecordTemplateUsageUseCase(fakeRepo),
        getSuggestedTemplatesUseCase: GetSuggestedTemplatesUseCase(fakeRepo),
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is BillTemplatesInitial', () {
      expect(bloc.state, isA<BillTemplatesInitial>());
    });

    test('LoadTemplatesEvent emits Loading then Loaded', () async {
      fakeRepo.templates.add(createSampleTemplate(id: 'b1', isFavorite: true));
      fakeRepo.templates.add(createSampleTemplate(id: 'b2', isFavorite: false, usageCount: 5));

      final expectedStates = [
        isA<BillTemplatesLoading>(),
        isA<BillTemplatesLoaded>()
            .having((s) => s.templates.length, 'templates.length', 2)
            .having((s) => s.favorites.length, 'favorites.length', 1)
            .having((s) => s.suggested.length, 'suggested.length', 2),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const LoadTemplatesEvent());
    });

    test('LoadTemplatesEvent emits BillTemplatesError on failure', () async {
      fakeRepo.shouldFail = true;

      final expectedStates = [
        isA<BillTemplatesLoading>(),
        isA<BillTemplatesError>().having((s) => s.message, 'message', 'Repo error'),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));
      bloc.add(const LoadTemplatesEvent());
    });

    test('CreateTemplateEvent creates template and reloads', () async {
      final tpl = createSampleTemplate(id: 'create-b');

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<BillTemplatesLoading>(),
          isA<BillTemplatesLoaded>().having((s) => s.templates.length, 'templates.length', 1),
        ]),
      );

      bloc.add(CreateTemplateEvent(tpl));
    });

    test('UpdateTemplateEvent updates template and reloads', () async {
      fakeRepo.templates.add(createSampleTemplate(id: 'up-b', title: 'Old'));

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<BillTemplatesLoading>(),
          isA<BillTemplatesLoaded>().having((s) => s.templates.first.title, 'title', 'New Title'),
        ]),
      );

      bloc.add(UpdateTemplateEvent(createSampleTemplate(id: 'up-b', title: 'New Title')));
    });

    test('DeleteTemplateEvent deletes template and reloads', () async {
      fakeRepo.templates.add(createSampleTemplate(id: 'del-b'));

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<BillTemplatesLoading>(),
          isA<BillTemplatesLoaded>().having((s) => s.templates, 'templates', isEmpty),
        ]),
      );

      bloc.add(const DeleteTemplateEvent('del-b'));
    });

    test('ToggleFavoriteTemplateEvent toggles favorite and reloads', () async {
      fakeRepo.templates.add(createSampleTemplate(id: 'fav-b', isFavorite: false));

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<BillTemplatesLoading>(),
          isA<BillTemplatesLoaded>().having((s) => s.favorites.length, 'favorites.length', 1),
        ]),
      );

      bloc.add(const ToggleFavoriteTemplateEvent('fav-b'));
    });

    test('RecordTemplateUsageEvent records usage and reloads', () async {
      fakeRepo.templates.add(createSampleTemplate(id: 'use-b', usageCount: 1));

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<BillTemplatesLoading>(),
          isA<BillTemplatesLoaded>().having((s) => s.templates.first.usageCount, 'usageCount', 2),
        ]),
      );

      bloc.add(const RecordTemplateUsageEvent('use-b'));
    });

    test('BillTemplatesLoaded props contains templates, suggested', () {
      final tpl = createSampleTemplate();
      final state = BillTemplatesLoaded(
        templates: [tpl],
        suggested: [tpl],
      );
      expect(state.props, equals([[tpl], [tpl]]));
    });

    test('BillTemplatesError props contains message', () {
      const state = BillTemplatesError('Something failed');
      expect(state.props, equals(['Something failed']));
    });

    test('CreateTemplateEvent props contains template', () {
      final tpl = createSampleTemplate();
      final event = CreateTemplateEvent(tpl);
      expect(event.props, equals([tpl]));
    });

    test('DeleteTemplateEvent props contains id', () {
      const event = DeleteTemplateEvent('id-123');
      expect(event.props, equals(['id-123']));
    });
  });

  group('7. BillTemplatesScreen Widget Tests', () {
    late FakeBillTemplateRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeBillTemplateRepository();
    });

    testWidgets('renders screen with title and search bar', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const BillTemplatesScreen(),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Bill Templates'), findsOneWidget);
      expect(find.byKey(const Key('searchTemplatesField')), findsOneWidget);
    });

    testWidgets('renders 3 tabs: All, Favorites, Suggested', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const BillTemplatesScreen(),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('allTemplatesTab')), findsOneWidget);
      expect(find.byKey(const Key('favoriteTemplatesTab')), findsOneWidget);
      expect(find.byKey(const Key('suggestedTemplatesTab')), findsOneWidget);
    });

    testWidgets('renders empty state when no templates exist', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const BillTemplatesScreen(),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('emptyTemplates_no_templates_yet')), findsOneWidget);
      expect(find.text('No templates created yet'), findsOneWidget);
    });

    testWidgets('renders template card when templates are available', (tester) async {
      fakeRepo.templates.add(createSampleTemplate(id: 't-card', title: 'Internet Bill'));

      await tester.pumpWidget(buildTestWidget(
        child: const BillTemplatesScreen(),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('templateCard_t-card')), findsOneWidget);
      expect(find.text('Internet Bill'), findsOneWidget);
    });

    testWidgets('search filters template list by title', (tester) async {
      fakeRepo.templates.add(createSampleTemplate(id: 't1', title: 'Coffee'));
      fakeRepo.templates.add(createSampleTemplate(id: 't2', title: 'Groceries'));

      await tester.pumpWidget(buildTestWidget(
        child: const BillTemplatesScreen(),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('searchTemplatesField')), 'Cof');
      await tester.pumpAndSettle();

      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Groceries'), findsNothing);
    });

    testWidgets('switching to Favorites tab displays favorites', (tester) async {
      fakeRepo.templates.add(createSampleTemplate(id: 'fav-1', title: 'My Fav', isFavorite: true));
      fakeRepo.templates.add(createSampleTemplate(id: 'not-fav', title: 'Regular', isFavorite: false));

      await tester.pumpWidget(buildTestWidget(
        child: const BillTemplatesScreen(),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('favoriteTemplatesTab')));
      await tester.pumpAndSettle();

      expect(find.text('My Fav'), findsOneWidget);
      expect(find.text('Regular'), findsNothing);
    });

    testWidgets('switching to Suggested tab displays suggested templates', (tester) async {
      fakeRepo.templates.add(createSampleTemplate(id: 'sug-1', title: 'Top Used', usageCount: 10));

      await tester.pumpWidget(buildTestWidget(
        child: const BillTemplatesScreen(),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('suggestedTemplatesTab')));
      await tester.pumpAndSettle();

      expect(find.text('Top Used'), findsOneWidget);
    });

    testWidgets('tapping favorite button toggles favorite state', (tester) async {
      fakeRepo.templates.add(createSampleTemplate(id: 'toggle-t', title: 'Fav Test', isFavorite: false));

      await tester.pumpWidget(buildTestWidget(
        child: const BillTemplatesScreen(),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('toggleFavorite_toggle-t')));
      await tester.pumpAndSettle();

      expect(fakeRepo.templates.first.isFavorite, isTrue);
    });

    testWidgets('tapping delete button shows confirmation dialog', (tester) async {
      fakeRepo.templates.add(createSampleTemplate(id: 'del-t', title: 'To Delete'));

      await tester.pumpWidget(buildTestWidget(
        child: const BillTemplatesScreen(),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deleteTemplate_del-t')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('confirmDeleteTemplateDialog')), findsOneWidget);
      expect(find.text('Delete Template'), findsOneWidget);
    });

    testWidgets('canceling delete dialog does not delete template', (tester) async {
      fakeRepo.templates.add(createSampleTemplate(id: 'del-cancel', title: 'Keep Me'));

      await tester.pumpWidget(buildTestWidget(
        child: const BillTemplatesScreen(),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deleteTemplate_del-cancel')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancelDeleteButton')));
      await tester.pumpAndSettle();

      expect(fakeRepo.templates.any((t) => t.id == 'del-cancel'), isTrue);
      expect(find.text('Keep Me'), findsOneWidget);
    });

    testWidgets('confirming delete dialog deletes template', (tester) async {
      fakeRepo.templates.add(createSampleTemplate(id: 'del-confirm', title: 'Remove Me'));

      await tester.pumpWidget(buildTestWidget(
        child: const BillTemplatesScreen(),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deleteTemplate_del-confirm')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirmDeleteButton')));
      await tester.pumpAndSettle();

      expect(fakeRepo.templates.any((t) => t.id == 'del-confirm'), isFalse);
    });

    testWidgets('FAB opens Create Template dialog and submits', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const BillTemplatesScreen(),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('createTemplateFAB')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('templateDialogTitle')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('templateTitleInput')), 'Weekly Dinner');
      await tester.enterText(find.byKey(const Key('templateAmountInput')), '200000');
      await tester.enterText(find.byKey(const Key('templatePaidByInput')), 'Alice');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveTemplateDialogButton')));
      await tester.pumpAndSettle();

      expect(fakeRepo.templates.any((t) => t.title == 'Weekly Dinner'), isTrue);
    });

    testWidgets('Edit button opens dialog with pre-filled fields and saves updates', (tester) async {
      fakeRepo.templates.add(createSampleTemplate(id: 'edit-me', title: 'Before Edit', amount: 100000));

      await tester.pumpWidget(buildTestWidget(
        child: const BillTemplatesScreen(),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('editTemplate_edit-me')));
      await tester.pumpAndSettle();

      expect(find.text('Before Edit'), findsWidgets);

      await tester.enterText(find.byKey(const Key('templateTitleInput')), 'After Edit');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveTemplateDialogButton')));
      await tester.pumpAndSettle();

      expect(fakeRepo.templates.first.title, 'After Edit');
    });

    testWidgets('Tapping Use button triggers onSelectTemplate callback', (tester) async {
      final tpl = createSampleTemplate(id: 'use-test', title: 'Apply This');
      fakeRepo.templates.add(tpl);

      BillTemplate? selected;
      await tester.pumpWidget(buildTestWidget(
        child: BillTemplatesScreen(
          onSelectTemplate: (t) => selected = t,
        ),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('useTemplate_use-test')));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.id, 'use-test');
    });
  });

  group('8. AddBillScreen & BillTemplate Integration Tests', () {
    late FakeBillTemplateRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeBillTemplateRepository();
    });

    testWidgets('Pre-fills form fields when template is passed in constructor', (tester) async {
      final tpl = createSampleTemplate(
        id: 'init-tpl',
        title: 'Weekly Groceries',
        amount: 350000,
        paidBy: 'David',
        currency: 'VND',
        participants: ['David', 'Emma'],
      );

      await tester.pumpWidget(buildTestWidget(
        child: AddBillScreen(template: tpl),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Weekly Groceries'), findsOneWidget);
      expect(find.text('350,000'), findsOneWidget);
      expect(find.text('David'), findsAtLeastNWidgets(1));
    });

    testWidgets('Bill editing does not mutate original BillTemplate object', (tester) async {
      final tpl = createSampleTemplate(
        id: 'immut-tpl',
        title: 'Original Title',
        amount: 100000,
      );

      await tester.pumpWidget(buildTestWidget(
        child: AddBillScreen(template: tpl),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      // Enter new title in AddBillScreen
      await tester.enterText(find.byKey(const Key('titleField')), 'Modified Title in Form');
      await tester.pumpAndSettle();

      // Original template remains unchanged
      expect(tpl.title, 'Original Title');
      expect(tpl.amount, 100000);
    });

    testWidgets('Shows quick templates horizontal row when templates exist', (tester) async {
      fakeRepo.templates.add(createSampleTemplate(id: 'q1', title: 'Quick Coffee'));

      await tester.pumpWidget(buildTestWidget(
        child: const AddBillScreen(),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('quickTemplatesRow')), findsOneWidget);
      expect(find.byKey(const Key('quickTemplateChip_q1')), findsOneWidget);
      expect(find.text('Quick Coffee'), findsOneWidget);
    });

    testWidgets('Tapping quick template chip applies template to form', (tester) async {
      fakeRepo.templates.add(createSampleTemplate(
        id: 'chip-1',
        title: 'Applied from Chip',
        amount: 80000,
        paidBy: 'Sam',
      ));

      await tester.pumpWidget(buildTestWidget(
        child: const AddBillScreen(),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('quickTemplateChip_chip-1')));
      await tester.pumpAndSettle();

      expect(find.text('Applied from Chip'), findsWidgets);
      expect(find.text('80,000'), findsOneWidget);
    });

    testWidgets('Save as template button creates template from current form', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(
        child: const AddBillScreen(),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'New Custom Template');
      tester.widget<TextField>(find.byKey(const Key('amountField'))).controller!.text = '120000';
      await tester.enterText(find.byKey(const Key('payerField')), 'Alex');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveAsTemplateButton')));
      await tester.pumpAndSettle();

      expect(fakeRepo.templates.any((t) => t.title == 'New Custom Template'), isTrue);
    });

    testWidgets('Save as template button validates empty title', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(
        child: const AddBillScreen(),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveAsTemplateButton')));
      await tester.pumpAndSettle();

      expect(find.text('Bill name is required'), findsOneWidget);
      expect(fakeRepo.templates, isEmpty);
    });

    testWidgets('AppBar save as template action button creates template', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const AddBillScreen(),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'AppBar Template');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveAsTemplateAppBarButton')));
      await tester.pumpAndSettle();

      expect(fakeRepo.templates.any((t) => t.title == 'AppBar Template'), isTrue);
    });

    testWidgets('Manage templates button in quick templates opens BillTemplatesScreen', (tester) async {
      fakeRepo.templates.add(createSampleTemplate(id: 'q-nav', title: 'Nav Test'));

      await tester.pumpWidget(buildTestWidget(
        child: const AddBillScreen(),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('openTemplatesScreenButton')));
      await tester.pumpAndSettle();

      expect(find.byType(BillTemplatesScreen), findsOneWidget);
    });

    testWidgets('Submitting bill created from template records template usage', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final tpl = createSampleTemplate(
        id: 'use-rec',
        title: 'Lunch',
        amount: 100000,
        paidBy: 'Alice',
        participants: ['Alice', 'Bob'],
        usageCount: 0,
      );
      fakeRepo.templates.add(tpl);

      await tester.pumpWidget(buildTestWidget(
        child: AddBillScreen(template: tpl),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(fakeRepo.templates.first.usageCount, 1);
    });

    testWidgets('AddBillScreen without template initializes with empty fields', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const AddBillScreen(),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('titleField')), findsOneWidget);
    });
  });

  group('9. BillCard Integration Tests', () {
    late FakeBillTemplateRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeBillTemplateRepository();
    });

    testWidgets('Renders Save as template button on BillCard', (tester) async {
      final bill = Bill(
        id: 'b-card-1',
        title: 'Team Lunch',
        amount: 400000,
        category: 'restaurant',
        date: DateTime(2026, 3, 1),
        paidBy: 'Alice',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 200000),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 200000),
        ],
      );

      await tester.pumpWidget(buildTestWidget(
        child: Scaffold(body: BillCard(bill: bill)),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('saveAsTemplate_b-card-1')), findsOneWidget);
    });

    testWidgets('Tapping Save as template button invokes onSaveAsTemplate callback', (tester) async {
      bool callbackInvoked = false;
      final bill = Bill(
        id: 'b-cb-1',
        title: 'Team Lunch',
        amount: 400000,
        category: 'restaurant',
        date: DateTime(2026, 3, 1),
        paidBy: 'Alice',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 200000),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 200000),
        ],
      );

      await tester.pumpWidget(buildTestWidget(
        child: Scaffold(
          body: BillCard(
            bill: bill,
            onSaveAsTemplate: () => callbackInvoked = true,
          ),
        ),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveAsTemplate_b-cb-1')));
      await tester.pumpAndSettle();

      expect(callbackInvoked, isTrue);
    });

    testWidgets('Tapping Save as template button dispatches CreateTemplateEvent when no callback', (tester) async {
      final bill = Bill(
        id: 'b-direct-1',
        title: 'Utility Bill',
        amount: 150000,
        category: 'utilities',
        date: DateTime(2026, 3, 1),
        paidBy: 'Carol',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Carol', amount: 150000),
        ],
      );

      await tester.pumpWidget(buildTestWidget(
        child: Scaffold(body: BillCard(bill: bill)),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveAsTemplate_b-direct-1')));
      await tester.pumpAndSettle();

      expect(fakeRepo.templates.any((t) => t.title == 'Utility Bill'), isTrue);
    });

    testWidgets('Shows SnackBar after saving template from BillCard', (tester) async {
      final bill = Bill(
        id: 'b-snack-1',
        title: 'Snack Bill',
        amount: 50000,
        category: 'food',
        date: DateTime(2026, 3, 1),
        paidBy: 'Dan',
        participants: [
          BillParticipant(participantId: 'p1', name: 'Dan', amount: 50000),
        ],
      );

      await tester.pumpWidget(buildTestWidget(
        child: Scaffold(body: BillCard(bill: bill)),
        templateRepo: fakeRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveAsTemplate_b-snack-1')));
      await tester.pumpAndSettle();

      expect(find.text('Template saved successfully'), findsOneWidget);
    });
  });

  group('10. SettingsScreen Integration Tests', () {
    testWidgets('Renders billTemplatesTile in data management section', (tester) async {
      tester.view.physicalSize = const Size(1200, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(
        child: const SettingsScreen(showAppBar: true),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('billTemplatesTile')), findsOneWidget);
      expect(find.text('Bill Templates'), findsOneWidget);
      expect(find.text('Create and use recurring bill templates'), findsOneWidget);
    });

    testWidgets('Tapping billTemplatesTile navigates to BillTemplatesScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(
        child: const SettingsScreen(showAppBar: true),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('billTemplatesTile')));
      await tester.pumpAndSettle();

      expect(find.byType(BillTemplatesScreen), findsOneWidget);
    });
  });

  group('11. Bilingual & Dark/Light Theme Tests', () {
    late FakeBillTemplateRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeBillTemplateRepository();
    });

    testWidgets('Displays localized strings in English', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const BillTemplatesScreen(),
        templateRepo: fakeRepo,
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Bill Templates'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Suggested'), findsOneWidget);
    });

    testWidgets('Displays localized strings in Vietnamese', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        child: const BillTemplatesScreen(),
        templateRepo: fakeRepo,
        locale: const Locale('vi'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Mẫu hóa đơn'), findsWidgets);
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Yêu thích'), findsOneWidget);
      expect(find.text('Gợi ý'), findsOneWidget);
    });

    testWidgets('Renders BillTemplatesScreen in Dark Theme without errors', (tester) async {
      fakeRepo.templates.add(createSampleTemplate(id: 'dark-t', title: 'Night Template'));

      await tester.pumpWidget(buildTestWidget(
        child: const BillTemplatesScreen(),
        templateRepo: fakeRepo,
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Night Template'), findsOneWidget);
    });

    testWidgets('Renders BillTemplatesScreen in Light Theme without errors', (tester) async {
      fakeRepo.templates.add(createSampleTemplate(id: 'light-t', title: 'Day Template'));

      await tester.pumpWidget(buildTestWidget(
        child: const BillTemplatesScreen(),
        templateRepo: fakeRepo,
        themeMode: ThemeMode.light,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Day Template'), findsOneWidget);
    });

    testWidgets('Renders quick templates row in Dark Theme on AddBillScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      fakeRepo.templates.add(createSampleTemplate(id: 'dark-chip', title: 'Dark Chip'));

      await tester.pumpWidget(buildTestWidget(
        child: const AddBillScreen(),
        templateRepo: fakeRepo,
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('quickTemplateChip_dark-chip')), findsOneWidget);
      expect(find.text('Dark Chip'), findsOneWidget);
    });
  });
}
