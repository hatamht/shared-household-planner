import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/split_mode.dart';
import 'package:shared_household_planner/features/split_bills/domain/services/smart_split_calculator.dart';
import 'package:shared_household_planner/features/split_bills/domain/services/default_split_mode_service.dart';
import 'package:shared_household_planner/features/split_bills/data/models/bill_model.dart';
import 'package:shared_household_planner/features/split_bills/data/models/bill_participant_model.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/add_bill_screen.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/bill_detail_screen.dart';
import 'package:shared_household_planner/features/split_bills/presentation/widgets/bill_card.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/templates/domain/repositories/bill_template_repository.dart';
import 'package:shared_household_planner/features/templates/domain/entities/bill_template.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/get_templates_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/create_template_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/update_template_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/delete_template_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/toggle_favorite_template_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/record_template_usage_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/get_suggested_templates_usecase.dart';
import 'package:shared_household_planner/features/templates/presentation/bloc/bill_templates_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test Fakes & Setup
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
  Future<Either<Failure, Bill>> getById(String id) async =>
      Right(bills.firstWhere((b) => b.id == id));

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

class FakeBillTemplateRepository implements BillTemplateRepository {
  final List<BillTemplate> templates = [];

  @override
  Future<Either<Failure, List<BillTemplate>>> getTemplates({String? projectId}) async =>
      Right(List.from(templates));

  @override
  Future<Either<Failure, BillTemplate>> getTemplateById(String id) async =>
      Right(templates.firstWhere((t) => t.id == id));

  @override
  Future<Either<Failure, BillTemplate>> createTemplate(BillTemplate template) async {
    templates.add(template);
    return Right(template);
  }

  @override
  Future<Either<Failure, BillTemplate>> updateTemplate(BillTemplate template) async {
    final idx = templates.indexWhere((t) => t.id == template.id);
    if (idx != -1) templates[idx] = template;
    return Right(template);
  }

  @override
  Future<Either<Failure, void>> deleteTemplate(String id) async {
    templates.removeWhere((t) => t.id == id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, BillTemplate>> toggleFavorite(String id) async {
    final idx = templates.indexWhere((t) => t.id == id);
    final t = templates[idx];
    final updated = t.copyWith(isFavorite: !t.isFavorite);
    templates[idx] = updated;
    return Right(updated);
  }

  @override
  Future<Either<Failure, BillTemplate>> toggleFavoriteTemplate(String id) => toggleFavorite(id);

  @override
  Future<Either<Failure, List<BillTemplate>>> getFavoriteTemplates({String? projectId}) async =>
      Right(templates.where((t) => t.isFavorite).toList());

  @override
  Future<Either<Failure, void>> recordTemplateUsage(String id) async {
    final idx = templates.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final t = templates[idx];
      templates[idx] = t.copyWith(usageCount: t.usageCount + 1, lastUsedAt: DateTime.now());
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<BillTemplate>>> getSuggestedTemplates({String? projectId, int limit = 3}) async =>
      Right(templates.take(limit).toList());
}

class TestLocalizations extends AppLocalizations {
  TestLocalizations(Locale locale) : super(locale);

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

class TestLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const TestLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(TestLocalizations(locale));
  }

  @override
  bool shouldReload(TestLocalizationsDelegate old) => false;
}

Widget buildTestApp({
  required Widget child,
  BillRepository? billRepo,
  ProjectRepository? projectRepo,
  BillTemplateRepository? templateRepo,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
}) {
  final fakeBillRepo = billRepo ?? FakeBillRepo();
  final fakeProjectRepo = projectRepo ?? FakeProjectRepo();
  final fakeTemplateRepo = templateRepo ?? FakeBillTemplateRepository();

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

  final billTemplatesBloc = BillTemplatesBloc(
    getTemplatesUseCase: GetTemplatesUseCase(fakeTemplateRepo),
    createTemplateUseCase: CreateTemplateUseCase(fakeTemplateRepo),
    updateTemplateUseCase: UpdateTemplateUseCase(fakeTemplateRepo),
    deleteTemplateUseCase: DeleteTemplateUseCase(fakeTemplateRepo),
    toggleFavoriteTemplateUseCase: ToggleFavoriteTemplateUseCase(fakeTemplateRepo),
    recordTemplateUsageUseCase: RecordTemplateUsageUseCase(fakeTemplateRepo),
    getSuggestedTemplatesUseCase: GetSuggestedTemplatesUseCase(fakeTemplateRepo),
  );

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<BillRepository>.value(value: fakeBillRepo),
      RepositoryProvider<ProjectRepository>.value(value: fakeProjectRepo),
      RepositoryProvider<BillTemplateRepository>.value(value: fakeTemplateRepo),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<BillsBloc>.value(value: billsBloc),
        BlocProvider<ProjectBloc>.value(value: projectBloc),
        BlocProvider<BillTemplatesBloc>.value(value: billTemplatesBloc),
      ],
      child: MaterialApp(
        locale: locale,
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        localizationsDelegates: const [
          TestLocalizationsDelegate(),
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
    DefaultSplitModeService.setMockInstance(DefaultSplitModeService(null, true));
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. SplitMode Enum & Localization Tests (10 tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('1. SplitMode Enum & Localization Tests', () {
    test('1.1 Enum contains exactly 4 modes', () {
      expect(SplitMode.values.length, 4);
      expect(SplitMode.values, contains(SplitMode.equal));
      expect(SplitMode.values, contains(SplitMode.percentage));
      expect(SplitMode.values, contains(SplitMode.shares));
      expect(SplitMode.values, contains(SplitMode.custom));
    });

    test('1.2 String values match expected identifiers', () {
      expect(SplitMode.equal.value, 'equal');
      expect(SplitMode.percentage.value, 'percentage');
      expect(SplitMode.shares.value, 'shares');
      expect(SplitMode.custom.value, 'custom');
    });

    test('1.3 Localization keys are correctly defined', () {
      expect(SplitMode.equal.localizationKey, 'split_mode_equal');
      expect(SplitMode.percentage.localizationKey, 'split_mode_percentage');
      expect(SplitMode.shares.localizationKey, 'split_mode_shares');
      expect(SplitMode.custom.localizationKey, 'split_mode_custom');
    });

    test('1.4 Icons are distinct for each mode', () {
      final icons = SplitMode.values.map((m) => m.icon).toSet();
      expect(icons.length, 4);
    });

    test('1.5 fromString handles standard string keys', () {
      expect(SplitMode.fromString('equal'), SplitMode.equal);
      expect(SplitMode.fromString('percentage'), SplitMode.percentage);
      expect(SplitMode.fromString('shares'), SplitMode.shares);
      expect(SplitMode.fromString('custom'), SplitMode.custom);
    });

    test('1.6 fromString handles alias names', () {
      expect(SplitMode.fromString('percent'), SplitMode.percentage);
      expect(SplitMode.fromString('share'), SplitMode.shares);
      expect(SplitMode.fromString('custom_amount'), SplitMode.custom);
    });

    test('1.7 fromString handles case-insensitivity and whitespace', () {
      expect(SplitMode.fromString('  PERCENTAGE  '), SplitMode.percentage);
      expect(SplitMode.fromString('Shares'), SplitMode.shares);
      expect(SplitMode.fromString('EQUAL'), SplitMode.equal);
    });

    test('1.8 fromString defaults to equal on unknown or null strings', () {
      expect(SplitMode.fromString(null), SplitMode.equal);
      expect(SplitMode.fromString(''), SplitMode.equal);
      expect(SplitMode.fromString('invalid_mode'), SplitMode.equal);
    });

    test('1.9 getLocalizedName returns English translation', () {
      final loc = TestLocalizations(const Locale('en'));
      expect(SplitMode.equal.getLocalizedName(loc), 'Equal');
      expect(SplitMode.percentage.getLocalizedName(loc), 'By Percentage');
      expect(SplitMode.shares.getLocalizedName(loc), 'By Shares');
      expect(SplitMode.custom.getLocalizedName(loc), 'Custom Amount');
    });

    test('1.10 getLocalizedName returns Vietnamese translation', () {
      final loc = TestLocalizations(const Locale('vi'));
      expect(SplitMode.equal.getLocalizedName(loc), 'Chia đều');
      expect(SplitMode.percentage.getLocalizedName(loc), 'Theo phần trăm');
      expect(SplitMode.shares.getLocalizedName(loc), 'Theo phần chia');
      expect(SplitMode.custom.getLocalizedName(loc), 'Số tiền tùy chỉnh');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. BillParticipant Entity & Model Tests (10 tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('2. BillParticipant Entity & Model Tests', () {
    test('2.1 Creates participant with required fields and optional nulls', () {
      const p = BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000);
      expect(p.participantId, 'p1');
      expect(p.name, 'Alice');
      expect(p.amount, 50000);
      expect(p.percentage, isNull);
      expect(p.shares, isNull);
    });

    test('2.2 Creates participant with percentage and shares', () {
      const p = BillParticipant(
        participantId: 'p2',
        name: 'Bob',
        amount: 30000,
        percentage: 30.0,
        shares: 2.0,
      );
      expect(p.percentage, 30.0);
      expect(p.shares, 2.0);
    });

    test('2.3 copyWith updates specific fields correctly', () {
      const p = BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000);
      final updated = p.copyWith(amount: 60000, percentage: 60.0, shares: 3.0);
      expect(updated.participantId, 'p1');
      expect(updated.name, 'Alice');
      expect(updated.amount, 60000);
      expect(updated.percentage, 60.0);
      expect(updated.shares, 3.0);
    });

    test('2.4 copyWith without arguments returns identical values', () {
      const p = BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000, percentage: 50.0);
      final copy = p.copyWith();
      expect(copy, equals(p));
    });

    test('2.5 Equatable equality checks all properties', () {
      const p1 = BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000, percentage: 50.0);
      const p2 = BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000, percentage: 50.0);
      const p3 = BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000, percentage: 40.0);
      expect(p1, equals(p2));
      expect(p1, isNot(equals(p3)));
    });

    test('2.6 BillParticipantModel.toJson includes percentage and shares when present', () {
      const model = BillParticipantModel(
        participantId: 'p1',
        name: 'Alice',
        amount: 50000,
        percentage: 50.0,
        shares: 2.0,
      );
      final json = model.toJson();
      expect(json['participantId'], 'p1');
      expect(json['name'], 'Alice');
      expect(json['amount'], 50000.0);
      expect(json['percentage'], 50.0);
      expect(json['shares'], 2.0);
    });

    test('2.7 BillParticipantModel.toJson omits null percentage and shares', () {
      const model = BillParticipantModel(participantId: 'p1', name: 'Alice', amount: 50000);
      final json = model.toJson();
      expect(json.containsKey('percentage'), isFalse);
      expect(json.containsKey('shares'), isFalse);
    });

    test('2.8 BillParticipantModel.fromJson deserializes optional fields', () {
      final json = {'participantId': 'p1', 'name': 'Alice', 'amount': 50000, 'percentage': 40, 'shares': 2};
      final model = BillParticipantModel.fromJson(json);
      expect(model.participantId, 'p1');
      expect(model.name, 'Alice');
      expect(model.amount, 50000.0);
      expect(model.percentage, 40.0);
      expect(model.shares, 2.0);
    });

    test('2.9 BillParticipantModel.fromEntity maps correctly', () {
      const entity = BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000, percentage: 50.0);
      final model = BillParticipantModel.fromEntity(entity);
      expect(model.participantId, entity.participantId);
      expect(model.percentage, entity.percentage);
    });

    test('2.10 BillParticipantModel copyWith returns BillParticipantModel instance', () {
      const model = BillParticipantModel(participantId: 'p1', name: 'Alice', amount: 50000);
      final copy = model.copyWith(amount: 70000);
      expect(copy, isA<BillParticipantModel>());
      expect(copy.amount, 70000);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. Bill Entity & Model with SplitMode Tests (10 tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('3. Bill Entity & Model with SplitMode Tests', () {
    test('3.1 Bill defaults splitMode to equal', () {
      final bill = Bill(
        id: 'b1',
        title: 'Lunch',
        amount: 100000,
        category: 'food',
        date: DateTime(2026, 9, 1),
        paidBy: 'Alice',
        participants: const [],
      );
      expect(bill.splitMode, 'equal');
      expect(bill.splitModeEnum, SplitMode.equal);
    });

    test('3.2 Bill accepts custom splitMode', () {
      final bill = Bill(
        id: 'b2',
        title: 'Taxi',
        amount: 150000,
        category: 'transport',
        date: DateTime(2026, 9, 1),
        paidBy: 'Bob',
        participants: const [],
        splitMode: 'percentage',
      );
      expect(bill.splitMode, 'percentage');
      expect(bill.splitModeEnum, SplitMode.percentage);
    });

    test('3.3 Bill copyWith preserves and updates splitMode', () {
      final bill = Bill(
        id: 'b1',
        title: 'Lunch',
        amount: 100000,
        category: 'food',
        date: DateTime(2026, 9, 1),
        paidBy: 'Alice',
        participants: const [],
        splitMode: 'shares',
      );
      final updated = bill.copyWith(splitMode: 'custom');
      expect(updated.splitMode, 'custom');
      expect(updated.splitModeEnum, SplitMode.custom);
      expect(updated.title, 'Lunch');
    });

    test('3.4 Bill equality considers splitMode', () {
      final b1 = Bill(
        id: 'b1',
        title: 'Lunch',
        amount: 100000,
        category: 'food',
        date: DateTime(2026, 9, 1),
        paidBy: 'Alice',
        participants: const [],
        splitMode: 'equal',
      );
      final b2 = Bill(
        id: 'b1',
        title: 'Lunch',
        amount: 100000,
        category: 'food',
        date: DateTime(2026, 9, 1),
        paidBy: 'Alice',
        participants: const [],
        splitMode: 'percentage',
      );
      expect(b1, isNot(equals(b2)));
    });

    test('3.5 BillModel.toJson includes splitMode', () {
      final model = BillModel(
        id: 'b1',
        title: 'Dinner',
        amount: 200000,
        category: 'food',
        date: DateTime(2026, 9, 1),
        paidBy: 'Alice',
        participants: const [],
        splitMode: 'shares',
      );
      final json = model.toJson();
      expect(json['splitMode'], 'shares');
    });

    test('3.6 BillModel.fromJson reads splitMode correctly', () {
      final json = {
        'id': 'b1',
        'title': 'Dinner',
        'amount': 200000,
        'category': 'food',
        'date': '2026-09-01T00:00:00.000',
        'paidBy': 'Alice',
        'participants': '[]',
        'splitMode': 'percentage',
      };
      final model = BillModel.fromJson(json);
      expect(model.splitMode, 'percentage');
      expect(model.splitModeEnum, SplitMode.percentage);
    });

    test('3.7 BillModel.fromJson defaults missing splitMode to equal', () {
      final json = {
        'id': 'b1',
        'title': 'Dinner',
        'amount': 200000,
        'category': 'food',
        'date': '2026-09-01T00:00:00.000',
        'paidBy': 'Alice',
        'participants': '[]',
      };
      final model = BillModel.fromJson(json);
      expect(model.splitMode, 'equal');
    });

    test('3.8 BillModel.fromEntity preserves splitMode', () {
      final entity = Bill(
        id: 'b1',
        title: 'Lunch',
        amount: 100000,
        category: 'food',
        date: DateTime(2026, 9, 1),
        paidBy: 'Alice',
        participants: const [],
        splitMode: 'custom',
      );
      final model = BillModel.fromEntity(entity);
      expect(model.splitMode, 'custom');
    });

    test('3.9 BillModel copyWith returns BillModel instance with new splitMode', () {
      final model = BillModel(
        id: 'b1',
        title: 'Dinner',
        amount: 200000,
        category: 'food',
        date: DateTime(2026, 9, 1),
        paidBy: 'Alice',
        participants: const [],
      );
      final copy = model.copyWith(splitMode: 'shares');
      expect(copy, isA<BillModel>());
      expect(copy.splitMode, 'shares');
    });

    test('3.10 BillModel participants serialization preserves breakdown', () {
      const p = BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000, percentage: 50.0, shares: 1.0);
      final model = BillModel(
        id: 'b1',
        title: 'Dinner',
        amount: 100000,
        category: 'food',
        date: DateTime(2026, 9, 1),
        paidBy: 'Alice',
        participants: const [p],
        splitMode: 'shares',
      );
      final json = model.toJson();
      final revived = BillModel.fromJson(json);
      expect(revived.participants.first.percentage, 50.0);
      expect(revived.participants.first.shares, 1.0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. SmartSplitCalculator - Equal Mode Tests (10 tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('4. SmartSplitCalculator - Equal Mode Tests', () {
    test('4.1 Divides total amount equally between 2 participants', () {
      final result = SmartSplitCalculator.calculateEqual(
        totalAmount: 100000,
        participantNames: ['Alice', 'Bob'],
      );
      expect(result.length, 2);
      expect(result[0].amount, 50000);
      expect(result[1].amount, 50000);
      expect(result[0].percentage, 50.0);
      expect(result[0].shares, 1.0);
    });

    test('4.2 Divides total amount equally among 3 participants', () {
      final result = SmartSplitCalculator.calculateEqual(
        totalAmount: 90000,
        participantNames: ['Alice', 'Bob', 'Charlie'],
      );
      expect(result.length, 3);
      for (final p in result) {
        expect(p.amount, 30000);
        expect(p.percentage, closeTo(33.33, 0.01));
      }
    });

    test('4.3 Handles odd total amount with fractional result', () {
      final result = SmartSplitCalculator.calculateEqual(
        totalAmount: 100,
        participantNames: ['Alice', 'Bob', 'Charlie'],
      );
      expect(result[0].amount, closeTo(33.333, 0.001));
    });

    test('4.4 Handles 5 participants evenly', () {
      final result = SmartSplitCalculator.calculateEqual(
        totalAmount: 100000,
        participantNames: ['A', 'B', 'C', 'D', 'E'],
      );
      expect(result.length, 5);
      for (final p in result) {
        expect(p.amount, 20000);
        expect(p.percentage, 20.0);
      }
    });

    test('4.5 Handles 10 participants evenly', () {
      final names = List.generate(10, (i) => 'User$i');
      final result = SmartSplitCalculator.calculateEqual(
        totalAmount: 1000000,
        participantNames: names,
      );
      expect(result.length, 10);
      for (final p in result) {
        expect(p.amount, 100000);
        expect(p.percentage, 10.0);
      }
    });

    test('4.6 Handles totalAmount = 0', () {
      final result = SmartSplitCalculator.calculateEqual(
        totalAmount: 0,
        participantNames: ['Alice', 'Bob'],
      );
      expect(result[0].amount, 0.0);
      expect(result[1].amount, 0.0);
    });

    test('4.7 Handles empty participant list', () {
      final result = SmartSplitCalculator.calculateEqual(
        totalAmount: 100000,
        participantNames: [],
      );
      expect(result, isEmpty);
    });

    test('4.8 Preserves custom participantIds mapping', () {
      final result = SmartSplitCalculator.calculateEqual(
        totalAmount: 100000,
        participantNames: ['Alice', 'Bob'],
        participantIds: {'Alice': 'custom_id_1', 'Bob': 'custom_id_2'},
      );
      expect(result[0].participantId, 'custom_id_1');
      expect(result[1].participantId, 'custom_id_2');
    });

    test('4.9 Generates unique UUIDs when no custom IDs provided', () {
      final result = SmartSplitCalculator.calculateEqual(
        totalAmount: 100000,
        participantNames: ['Alice', 'Bob'],
      );
      expect(result[0].participantId, isNotEmpty);
      expect(result[1].participantId, isNotEmpty);
      expect(result[0].participantId, isNot(equals(result[1].participantId)));
    });

    test('4.10 Handles single participant edge case', () {
      final result = SmartSplitCalculator.calculateEqual(
        totalAmount: 50000,
        participantNames: ['Solo'],
      );
      expect(result.length, 1);
      expect(result[0].amount, 50000);
      expect(result[0].percentage, 100.0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. SmartSplitCalculator - By Percentage Mode Tests (12 tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('5. SmartSplitCalculator - By Percentage Mode Tests', () {
    test('5.1 Calculates 30% / 40% / 30% split on 1,000,000', () {
      final result = SmartSplitCalculator.calculatePercentage(
        totalAmount: 1000000,
        percentages: {'Alice': 30.0, 'Bob': 40.0, 'Charlie': 30.0},
      );
      expect(result.length, 3);
      expect(result.firstWhere((p) => p.name == 'Alice').amount, 300000);
      expect(result.firstWhere((p) => p.name == 'Bob').amount, 400000);
      expect(result.firstWhere((p) => p.name == 'Charlie').amount, 300000);
    });

    test('5.2 Calculates 50% / 50% split on 500,000', () {
      final result = SmartSplitCalculator.calculatePercentage(
        totalAmount: 500000,
        percentages: {'Alice': 50.0, 'Bob': 50.0},
      );
      expect(result[0].amount, 250000);
      expect(result[1].amount, 250000);
    });

    test('5.3 Calculates 100% / 0% split', () {
      final result = SmartSplitCalculator.calculatePercentage(
        totalAmount: 100000,
        percentages: {'Alice': 100.0, 'Bob': 0.0},
      );
      expect(result.firstWhere((p) => p.name == 'Alice').amount, 100000);
      expect(result.firstWhere((p) => p.name == 'Bob').amount, 0);
    });

    test('5.4 Calculates decimal percentages (12.5% vs 87.5%)', () {
      final result = SmartSplitCalculator.calculatePercentage(
        totalAmount: 80000,
        percentages: {'Alice': 12.5, 'Bob': 87.5},
      );
      expect(result.firstWhere((p) => p.name == 'Alice').amount, 10000);
      expect(result.firstWhere((p) => p.name == 'Bob').amount, 70000);
    });

    test('5.5 Calculates 3-way split (33.33 / 33.33 / 33.34)', () {
      final result = SmartSplitCalculator.calculatePercentage(
        totalAmount: 300000,
        percentages: {'Alice': 33.33, 'Bob': 33.33, 'Charlie': 33.34},
      );
      expect(result.firstWhere((p) => p.name == 'Alice').amount, closeTo(99990, 1));
      expect(result.firstWhere((p) => p.name == 'Charlie').amount, closeTo(100020, 1));
    });

    test('5.6 Handles totalAmount = 0 in percentage mode', () {
      final result = SmartSplitCalculator.calculatePercentage(
        totalAmount: 0,
        percentages: {'Alice': 50.0, 'Bob': 50.0},
      );
      expect(result[0].amount, 0);
      expect(result[1].amount, 0);
    });

    test('5.7 Preserves percentage property on BillParticipant', () {
      final result = SmartSplitCalculator.calculatePercentage(
        totalAmount: 100000,
        percentages: {'Alice': 75.0, 'Bob': 25.0},
      );
      expect(result.firstWhere((p) => p.name == 'Alice').percentage, 75.0);
      expect(result.firstWhere((p) => p.name == 'Bob').percentage, 25.0);
    });

    test('5.8 Preserves participantIds mapping in percentage calculation', () {
      final result = SmartSplitCalculator.calculatePercentage(
        totalAmount: 100000,
        percentages: {'Alice': 50.0, 'Bob': 50.0},
        participantIds: {'Alice': 'id-1', 'Bob': 'id-2'},
      );
      expect(result.firstWhere((p) => p.name == 'Alice').participantId, 'id-1');
    });

    test('5.9 distributePercentagesEvenly for 2 participants returns [50.0, 50.0]', () {
      final list = SmartSplitCalculator.distributePercentagesEvenly(2);
      expect(list, [50.0, 50.0]);
      expect(list.reduce((a, b) => a + b), 100.0);
    });

    test('5.10 distributePercentagesEvenly for 3 participants sums to exactly 100.0', () {
      final list = SmartSplitCalculator.distributePercentagesEvenly(3);
      expect(list.length, 3);
      final sum = list.reduce((a, b) => a + b);
      expect(sum, 100.0);
    });

    test('5.11 distributePercentagesEvenly for 4 and 5 participants sums to 100.0', () {
      expect(SmartSplitCalculator.distributePercentagesEvenly(4).reduce((a, b) => a + b), 100.0);
      expect(SmartSplitCalculator.distributePercentagesEvenly(5).reduce((a, b) => a + b), 100.0);
    });

    test('5.12 distributePercentagesEvenly returns empty list for 0 or negative count', () {
      expect(SmartSplitCalculator.distributePercentagesEvenly(0), isEmpty);
      expect(SmartSplitCalculator.distributePercentagesEvenly(-1), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. SmartSplitCalculator - By Shares Mode Tests (12 tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('6. SmartSplitCalculator - By Shares Mode Tests', () {
    test('6.1 Calculates 2 shares vs 1 share vs 1 share (2:1:1 ratio)', () {
      final result = SmartSplitCalculator.calculateShares(
        totalAmount: 100000,
        shares: {'Alice': 2.0, 'Bob': 1.0, 'Charlie': 1.0},
      );
      expect(result.firstWhere((p) => p.name == 'Alice').amount, 50000);
      expect(result.firstWhere((p) => p.name == 'Bob').amount, 25000);
      expect(result.firstWhere((p) => p.name == 'Charlie').amount, 25000);
      expect(result.firstWhere((p) => p.name == 'Alice').percentage, 50.0);
      expect(result.firstWhere((p) => p.name == 'Alice').shares, 2.0);
    });

    test('6.2 Calculates 1 share vs 1 share (1:1 ratio)', () {
      final result = SmartSplitCalculator.calculateShares(
        totalAmount: 60000,
        shares: {'Alice': 1.0, 'Bob': 1.0},
      );
      expect(result[0].amount, 30000);
      expect(result[1].amount, 30000);
    });

    test('6.3 Calculates 3:2:1 ratio on 600,000', () {
      final result = SmartSplitCalculator.calculateShares(
        totalAmount: 600000,
        shares: {'Alice': 3.0, 'Bob': 2.0, 'Charlie': 1.0},
      );
      expect(result.firstWhere((p) => p.name == 'Alice').amount, 300000);
      expect(result.firstWhere((p) => p.name == 'Bob').amount, 200000);
      expect(result.firstWhere((p) => p.name == 'Charlie').amount, 100000);
    });

    test('6.4 Calculates fractional shares (1.5 vs 2.5 shares)', () {
      final result = SmartSplitCalculator.calculateShares(
        totalAmount: 40000,
        shares: {'Alice': 1.5, 'Bob': 2.5},
      );
      expect(result.firstWhere((p) => p.name == 'Alice').amount, 15000);
      expect(result.firstWhere((p) => p.name == 'Bob').amount, 25000);
    });

    test('6.5 Calculates large share counts proportionally', () {
      final result = SmartSplitCalculator.calculateShares(
        totalAmount: 300000,
        shares: {'Alice': 100.0, 'Bob': 200.0},
      );
      expect(result.firstWhere((p) => p.name == 'Alice').amount, 100000);
      expect(result.firstWhere((p) => p.name == 'Bob').amount, 200000);
    });

    test('6.6 Participant with 0 shares pays 0 amount', () {
      final result = SmartSplitCalculator.calculateShares(
        totalAmount: 100000,
        shares: {'Alice': 2.0, 'Bob': 0.0},
      );
      expect(result.firstWhere((p) => p.name == 'Alice').amount, 100000);
      expect(result.firstWhere((p) => p.name == 'Bob').amount, 0);
    });

    test('6.7 Total shares = 0 returns zero amounts without throwing', () {
      final result = SmartSplitCalculator.calculateShares(
        totalAmount: 100000,
        shares: {'Alice': 0.0, 'Bob': 0.0},
      );
      expect(result[0].amount, 0);
      expect(result[1].amount, 0);
    });

    test('6.8 Total amount = 0 returns 0 for all participants', () {
      final result = SmartSplitCalculator.calculateShares(
        totalAmount: 0,
        shares: {'Alice': 2.0, 'Bob': 3.0},
      );
      expect(result[0].amount, 0);
      expect(result[1].amount, 0);
    });

    test('6.9 Calculates participant percentage from shares correctly', () {
      final result = SmartSplitCalculator.calculateShares(
        totalAmount: 100000,
        shares: {'Alice': 1.0, 'Bob': 3.0},
      );
      expect(result.firstWhere((p) => p.name == 'Alice').percentage, 25.0);
      expect(result.firstWhere((p) => p.name == 'Bob').percentage, 75.0);
    });

    test('6.10 Preserves participantIds mapping in shares calculation', () {
      final result = SmartSplitCalculator.calculateShares(
        totalAmount: 100000,
        shares: {'Alice': 1.0, 'Bob': 1.0},
        participantIds: {'Alice': 'uid-1', 'Bob': 'uid-2'},
      );
      expect(result.firstWhere((p) => p.name == 'Alice').participantId, 'uid-1');
    });

    test('6.11 Handles single participant with shares', () {
      final result = SmartSplitCalculator.calculateShares(
        totalAmount: 50000,
        shares: {'Alice': 5.0},
      );
      expect(result.firstWhere((p) => p.name == 'Alice').amount, 50000);
      expect(result.firstWhere((p) => p.name == 'Alice').percentage, 100.0);
    });

    test('6.12 Handles empty shares map', () {
      final result = SmartSplitCalculator.calculateShares(
        totalAmount: 50000,
        shares: {},
      );
      expect(result, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. SmartSplitCalculator - Custom Amount Mode Tests (10 tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('7. SmartSplitCalculator - Custom Amount Mode Tests', () {
    test('7.1 Preserves exact custom amounts', () {
      final result = SmartSplitCalculator.calculateCustom(
        totalAmount: 150000,
        customAmounts: {'Alice': 70000, 'Bob': 50000, 'Charlie': 30000},
      );
      expect(result.firstWhere((p) => p.name == 'Alice').amount, 70000);
      expect(result.firstWhere((p) => p.name == 'Bob').amount, 50000);
      expect(result.firstWhere((p) => p.name == 'Charlie').amount, 30000);
    });

    test('7.2 Automatically computes percentage field for each participant', () {
      final result = SmartSplitCalculator.calculateCustom(
        totalAmount: 100000,
        customAmounts: {'Alice': 40000, 'Bob': 60000},
      );
      expect(result.firstWhere((p) => p.name == 'Alice').percentage, 40.0);
      expect(result.firstWhere((p) => p.name == 'Bob').percentage, 60.0);
    });

    test('7.3 Handles one participant paying zero', () {
      final result = SmartSplitCalculator.calculateCustom(
        totalAmount: 50000,
        customAmounts: {'Alice': 50000, 'Bob': 0},
      );
      expect(result.firstWhere((p) => p.name == 'Alice').amount, 50000);
      expect(result.firstWhere((p) => p.name == 'Bob').amount, 0);
      expect(result.firstWhere((p) => p.name == 'Bob').percentage, 0.0);
    });

    test('7.4 Handles totalAmount = 0', () {
      final result = SmartSplitCalculator.calculateCustom(
        totalAmount: 0,
        customAmounts: {'Alice': 0, 'Bob': 0},
      );
      expect(result[0].amount, 0);
      expect(result[0].percentage, 0.0);
    });

    test('7.5 Handles large amounts without overflow', () {
      final result = SmartSplitCalculator.calculateCustom(
        totalAmount: 100000000,
        customAmounts: {'Alice': 60000000, 'Bob': 40000000},
      );
      expect(result.firstWhere((p) => p.name == 'Alice').amount, 60000000);
    });

    test('7.6 Preserves participantIds mapping in custom amounts', () {
      final result = SmartSplitCalculator.calculateCustom(
        totalAmount: 100000,
        customAmounts: {'Alice': 100000},
        participantIds: {'Alice': 'custom_uid'},
      );
      expect(result[0].participantId, 'custom_uid');
    });

    test('7.7 Handles decimal amounts', () {
      final result = SmartSplitCalculator.calculateCustom(
        totalAmount: 10.5,
        customAmounts: {'Alice': 5.25, 'Bob': 5.25},
      );
      expect(result[0].amount, 5.25);
      expect(result[1].amount, 5.25);
    });

    test('7.8 Generates unique participant IDs when not provided', () {
      final result = SmartSplitCalculator.calculateCustom(
        totalAmount: 100,
        customAmounts: {'Alice': 50, 'Bob': 50},
      );
      expect(result[0].participantId, isNot(equals(result[1].participantId)));
    });

    test('7.9 Handles empty customAmounts map', () {
      final result = SmartSplitCalculator.calculateCustom(
        totalAmount: 100,
        customAmounts: {},
      );
      expect(result, isEmpty);
    });

    test('7.10 Handles 4 participants custom allocation', () {
      final result = SmartSplitCalculator.calculateCustom(
        totalAmount: 100,
        customAmounts: {'A': 10, 'B': 20, 'C': 30, 'D': 40},
      );
      expect(result.length, 4);
      expect(result.map((p) => p.amount).reduce((a, b) => a + b), 100);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 8. SmartSplitCalculator - Validation Logic Tests (15 tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('8. SmartSplitCalculator - Validation Logic Tests', () {
    test('8.1 validatePercentage returns valid when sum is exactly 100%', () {
      final res = SmartSplitCalculator.validatePercentage({'Alice': 40.0, 'Bob': 60.0});
      expect(res.isValid, isTrue);
      expect(res.errorMessageKey, isNull);
    });

    test('8.2 validatePercentage returns invalid when sum is less than 100%', () {
      final res = SmartSplitCalculator.validatePercentage({'Alice': 30.0, 'Bob': 40.0});
      expect(res.isValid, isFalse);
      expect(res.errorMessageKey, 'percentage_must_equal_100');
    });

    test('8.3 validatePercentage returns invalid when sum exceeds 100%', () {
      final res = SmartSplitCalculator.validatePercentage({'Alice': 60.0, 'Bob': 50.0});
      expect(res.isValid, isFalse);
      expect(res.errorMessageKey, 'percentage_must_equal_100');
    });

    test('8.4 validatePercentage returns invalid when percentage is negative', () {
      final res = SmartSplitCalculator.validatePercentage({'Alice': 110.0, 'Bob': -10.0});
      expect(res.isValid, isFalse);
      expect(res.errorMessageKey, 'percentage_cannot_be_negative');
    });

    test('8.5 validatePercentage handles floating point tolerance within 0.01', () {
      final res = SmartSplitCalculator.validatePercentage({'Alice': 33.33, 'Bob': 33.33, 'Charlie': 33.34});
      expect(res.isValid, isTrue);
    });

    test('8.6 validatePercentage returns invalid for empty map', () {
      final res = SmartSplitCalculator.validatePercentage({});
      expect(res.isValid, isFalse);
      expect(res.errorMessageKey, 'min_2_participants');
    });

    test('8.7 validateShares returns valid when total shares > 0', () {
      final res = SmartSplitCalculator.validateShares({'Alice': 2.0, 'Bob': 1.0});
      expect(res.isValid, isTrue);
    });

    test('8.8 validateShares returns invalid when total shares == 0', () {
      final res = SmartSplitCalculator.validateShares({'Alice': 0.0, 'Bob': 0.0});
      expect(res.isValid, isFalse);
      expect(res.errorMessageKey, 'total_shares_must_be_positive');
    });

    test('8.9 validateShares returns invalid when any share is negative', () {
      final res = SmartSplitCalculator.validateShares({'Alice': 3.0, 'Bob': -1.0});
      expect(res.isValid, isFalse);
      expect(res.errorMessageKey, 'shares_cannot_be_negative');
    });

    test('8.10 validateShares returns invalid for empty map', () {
      final res = SmartSplitCalculator.validateShares({});
      expect(res.isValid, isFalse);
      expect(res.errorMessageKey, 'min_2_participants');
    });

    test('8.11 validateCustom returns valid when sum equals totalAmount', () {
      final res = SmartSplitCalculator.validateCustom(100000, {'Alice': 60000, 'Bob': 40000});
      expect(res.isValid, isTrue);
    });

    test('8.12 validateCustom returns invalid when sum != totalAmount', () {
      final res = SmartSplitCalculator.validateCustom(100000, {'Alice': 50000, 'Bob': 40000});
      expect(res.isValid, isFalse);
      expect(res.errorMessageKey, 'custom_amounts_must_equal_total');
    });

    test('8.13 validateCustom returns invalid when any amount is negative', () {
      final res = SmartSplitCalculator.validateCustom(100000, {'Alice': 120000, 'Bob': -20000});
      expect(res.isValid, isFalse);
      expect(res.errorMessageKey, 'amount_cannot_be_negative');
    });

    test('8.14 General validate enforces min 2 participants and amount > 0', () {
      final res1 = SmartSplitCalculator.validate(
        mode: SplitMode.equal,
        totalAmount: 100000,
        participants: ['Alice'],
      );
      expect(res1.isValid, isFalse);
      expect(res1.errorMessageKey, 'min_2_participants');

      final res2 = SmartSplitCalculator.validate(
        mode: SplitMode.equal,
        totalAmount: 0,
        participants: ['Alice', 'Bob'],
      );
      expect(res2.isValid, isFalse);
      expect(res2.errorMessageKey, 'amount_must_be_positive');
    });

    test('8.15 General validate dispatches to mode-specific validations', () {
      final valid = SmartSplitCalculator.validate(
        mode: SplitMode.percentage,
        totalAmount: 100,
        participants: ['Alice', 'Bob'],
        percentages: {'Alice': 50, 'Bob': 50},
      );
      expect(valid.isValid, isTrue);

      final invalid = SmartSplitCalculator.validate(
        mode: SplitMode.percentage,
        totalAmount: 100,
        participants: ['Alice', 'Bob'],
        percentages: {'Alice': 50, 'Bob': 40},
      );
      expect(invalid.isValid, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 9. DefaultSplitModeService Tests (10 tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('9. DefaultSplitModeService Tests', () {
    test('9.1 Sets and gets default split mode for category', () async {
      final service = DefaultSplitModeService();
      await service.setDefaultSplitModeForCategory('food', 'percentage');
      final result = await service.getDefaultSplitModeForCategory('food');
      expect(result, 'percentage');
    });

    test('9.2 Returns null when category default has not been set', () async {
      final service = DefaultSplitModeService();
      final result = await service.getDefaultSplitModeForCategory('non_existent');
      expect(result, isNull);
    });

    test('9.3 Overwrites category default split mode', () async {
      final service = DefaultSplitModeService();
      await service.setDefaultSplitModeForCategory('utilities', 'shares');
      await service.setDefaultSplitModeForCategory('utilities', 'custom');
      final result = await service.getDefaultSplitModeForCategory('utilities');
      expect(result, 'custom');
    });

    test('9.4 Sets and gets default split mode for person', () async {
      final service = DefaultSplitModeService();
      await service.setDefaultSplitModeForPerson('Alice', 'shares');
      final result = await service.getDefaultSplitModeForPerson('Alice');
      expect(result, 'shares');
    });

    test('9.5 Returns null when person default has not been set', () async {
      final service = DefaultSplitModeService();
      final result = await service.getDefaultSplitModeForPerson('Unknown');
      expect(result, isNull);
    });

    test('9.6 Overwrites person default split mode', () async {
      final service = DefaultSplitModeService();
      await service.setDefaultSplitModeForPerson('Bob', 'equal');
      await service.setDefaultSplitModeForPerson('Bob', 'percentage');
      final result = await service.getDefaultSplitModeForPerson('Bob');
      expect(result, 'percentage');
    });

    test('9.7 clearDefaults removes all category and person defaults', () async {
      final service = DefaultSplitModeService();
      await service.setDefaultSplitModeForCategory('shopping', 'custom');
      await service.setDefaultSplitModeForPerson('Charlie', 'shares');
      await service.clearDefaults();

      expect(await service.getDefaultSplitModeForCategory('shopping'), isNull);
      expect(await service.getDefaultSplitModeForPerson('Charlie'), isNull);
    });

    test('9.8 Supports multiple distinct category defaults simultaneously', () async {
      final service = DefaultSplitModeService();
      await service.setDefaultSplitModeForCategory('food', 'equal');
      await service.setDefaultSplitModeForCategory('travel', 'shares');
      await service.setDefaultSplitModeForCategory('entertainment', 'custom');

      expect(await service.getDefaultSplitModeForCategory('food'), 'equal');
      expect(await service.getDefaultSplitModeForCategory('travel'), 'shares');
      expect(await service.getDefaultSplitModeForCategory('entertainment'), 'custom');
    });

    test('9.9 Singleton instance is accessible and retains defaults', () async {
      final instance = DefaultSplitModeService.instance;
      await instance.setDefaultSplitModeForCategory('health', 'percentage');
      expect(await instance.getDefaultSplitModeForCategory('health'), 'percentage');
    });

    test('9.10 setMockInstance replaces global singleton instance', () async {
      final mock = DefaultSplitModeService();
      await mock.setDefaultSplitModeForCategory('mock_cat', 'custom');
      DefaultSplitModeService.setMockInstance(mock);
      expect(await DefaultSplitModeService.instance.getDefaultSplitModeForCategory('mock_cat'), 'custom');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 10. AddBillScreen Widget Tests: Split Modes UI & Interactions (15 tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('10. AddBillScreen Widget Tests: Split Modes UI & Interactions', () {
    testWidgets('10.1 Renders Split Mode radio group with all 4 modes', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('splitModeRadioGroup')), findsOneWidget);
      expect(find.byKey(const Key('splitModeRadio_equal')), findsOneWidget);
      expect(find.byKey(const Key('splitModeRadio_percentage')), findsOneWidget);
      expect(find.byKey(const Key('splitModeRadio_shares')), findsOneWidget);
      expect(find.byKey(const Key('splitModeRadio_custom')), findsOneWidget);
    });

    testWidgets('10.2 Default split mode is equal and displays realtimeSplitText when amount present', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('amountField')), '100000');
      await tester.enterText(find.byKey(const Key('participantNameField')), 'Alice');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Bob');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('realtimeSplitText')), findsOneWidget);
    });

    testWidgets('10.3 Switching to Percentage mode renders percentage inputs', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Alice');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Bob');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('splitModeRadio_percentage')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('percentageInputsSection')), findsOneWidget);
      expect(find.byKey(const Key('totalPercentageText')), findsOneWidget);
      expect(find.byKey(const Key('percentageInput_Alice')), findsOneWidget);
      expect(find.byKey(const Key('percentageInput_Bob')), findsOneWidget);
    });

    testWidgets('10.4 Changing percentage input updates calculated participant amounts', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('amountField')), '100000');
      await tester.enterText(find.byKey(const Key('participantNameField')), 'Alice');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Bob');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('splitModeRadio_percentage')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('percentageInput_Alice')), '70');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calculatedAmount_Alice')), findsOneWidget);
      expect(find.textContaining('70000'), findsOneWidget);
    });

    testWidgets('10.5 Distribute evenly button sets percentages to 50/50 for 2 participants', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Alice');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Bob');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('splitModeRadio_percentage')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('distributePercentagesEvenlyButton')));
      await tester.pumpAndSettle();

      expect(find.textContaining('100.0% / 100%'), findsOneWidget);
    });

    testWidgets('10.6 Switching to Shares mode renders shares controls', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Alice');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Bob');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('splitModeRadio_shares')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sharesInputsSection')), findsOneWidget);
      expect(find.byKey(const Key('totalSharesText')), findsOneWidget);
      expect(find.byKey(const Key('sharesInput_Alice')), findsOneWidget);
      expect(find.byKey(const Key('sharesPlus_Alice')), findsOneWidget);
      expect(find.byKey(const Key('sharesMinus_Alice')), findsOneWidget);
    });

    testWidgets('10.7 Tapping sharesPlus increments shares', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('amountField')), '120000');
      await tester.enterText(find.byKey(const Key('participantNameField')), 'Alice');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Bob');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('splitModeRadio_shares')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sharesPlus_Alice')));
      await tester.pumpAndSettle();

      // Alice now has 2 shares, Bob has 1 share -> total 3 shares -> Alice pays 80000
      expect(find.textContaining('80000'), findsOneWidget);
    });

    testWidgets('10.8 Switching to Custom mode renders custom amount inputs', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Alice');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Bob');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('splitModeRadio_custom')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('customInputsSection')), findsOneWidget);
      expect(find.byKey(const Key('remainingAmountText')), findsOneWidget);
      expect(find.byKey(const Key('customAmountInput_Alice')), findsOneWidget);
      expect(find.byKey(const Key('fillRemainingButton_Alice')), findsOneWidget);
    });

    testWidgets('10.9 Fill remaining button fills difference into participant amount', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('amountField')), '100000');
      await tester.enterText(find.byKey(const Key('participantNameField')), 'Alice');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Bob');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('splitModeRadio_custom')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('customAmountInput_Alice')), '40000');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('fillRemainingButton_Bob')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Remaining: 0'), findsOneWidget);
    });

    testWidgets('10.10 Validation error snackbar shown if percentages sum != 100 on submit', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'Dinner');
      await tester.enterText(find.byKey(const Key('amountField')), '100000');
      await tester.enterText(find.byKey(const Key('payerField')), 'Alice');

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Alice');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Bob');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('splitModeRadio_percentage')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('percentageInput_Alice')), '30');
      await tester.enterText(find.byKey(const Key('percentageInput_Bob')), '40');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Total percentage must equal 100%'), findsOneWidget);
    });

    testWidgets('10.11 Validation error snackbar shown if custom amounts sum != total on submit', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'Dinner');
      await tester.enterText(find.byKey(const Key('amountField')), '100000');
      await tester.enterText(find.byKey(const Key('payerField')), 'Alice');

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Alice');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Bob');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('splitModeRadio_custom')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('customAmountInput_Alice')), '30000');
      await tester.enterText(find.byKey(const Key('customAmountInput_Bob')), '40000');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Custom amounts must equal total bill amount'), findsOneWidget);
    });

    testWidgets('10.12 Submitting valid Percentage split bill persists splitMode and breakdown', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(billRepo: fakeRepo, child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'Group Dinner');
      await tester.enterText(find.byKey(const Key('amountField')), '200000');
      await tester.enterText(find.byKey(const Key('payerField')), 'Alice');

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Alice');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Bob');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('splitModeRadio_percentage')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('percentageInput_Alice')), '60');
      await tester.enterText(find.byKey(const Key('percentageInput_Bob')), '40');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(fakeRepo.bills.length, 1);
      final saved = fakeRepo.bills.first;
      expect(saved.splitMode, 'percentage');
      expect(saved.participants.firstWhere((p) => p.name == 'Alice').amount, 120000);
      expect(saved.participants.firstWhere((p) => p.name == 'Bob').amount, 80000);
    });

    testWidgets('10.13 Submitting valid Shares split bill persists splitMode and breakdown', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeBillRepo();
      await tester.pumpWidget(buildTestApp(billRepo: fakeRepo, child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'Family Meal');
      await tester.enterText(find.byKey(const Key('amountField')), '150000');
      await tester.enterText(find.byKey(const Key('payerField')), 'Alice');

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Alice');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Bob');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('splitModeRadio_shares')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sharesPlus_Alice'))); // Alice has 2 shares
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      expect(fakeRepo.bills.length, 1);
      final saved = fakeRepo.bills.first;
      expect(saved.splitMode, 'shares');
      expect(saved.participants.firstWhere((p) => p.name == 'Alice').amount, 100000);
      expect(saved.participants.firstWhere((p) => p.name == 'Bob').amount, 50000);
    });

    testWidgets('10.14 Pre-populates splitMode and participants from billToEdit', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final existingBill = Bill(
        id: 'edit_b1',
        title: 'Old Dinner',
        amount: 300000,
        category: 'food',
        date: DateTime(2026, 9, 1),
        paidBy: 'Charlie',
        splitMode: 'shares',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 200000, shares: 2.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 100000, shares: 1.0),
        ],
      );

      await tester.pumpWidget(buildTestApp(child: AddBillScreen(billToEdit: existingBill)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sharesInputsSection')), findsOneWidget);
    });

    testWidgets('10.15 Save default split mode checkbox saves default for category', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(child: const AddBillScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('titleField')), 'Groceries');
      await tester.enterText(find.byKey(const Key('amountField')), '100000');
      await tester.enterText(find.byKey(const Key('payerField')), 'Alice');

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Alice');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('participantNameField')), 'Bob');
      await tester.tap(find.byKey(const Key('addParticipantButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('splitModeRadio_shares')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveDefaultSplitModeCheckbox')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProjectButton')));
      await tester.pumpAndSettle();

      final savedDefault = await DefaultSplitModeService.instance.getDefaultSplitModeForCategory('restaurant');
      expect(savedDefault, 'shares');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 11. BillDetailScreen & BillCard Breakdown Widget Tests (12 tests)
  // ═══════════════════════════════════════════════════════════════════════════
  group('11. BillDetailScreen & BillCard Breakdown Widget Tests', () {
    testWidgets('11.1 BillDetailScreen renders title, amount, category, payer, and date', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final bill = Bill(
        id: 'detail_b1',
        title: 'Team Hotpot',
        amount: 450000,
        category: 'food',
        date: DateTime(2026, 9, 10),
        paidBy: 'David',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 150000),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 150000),
          BillParticipant(participantId: 'p3', name: 'David', amount: 150000),
        ],
      );

      await tester.pumpWidget(buildTestApp(child: BillDetailScreen(bill: bill)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('billDetailTitle')), findsOneWidget);
      expect(find.text('Team Hotpot'), findsOneWidget);
      expect(find.byKey(const Key('billDetailAmount')), findsOneWidget);
      expect(find.byKey(const Key('billDetailCategory')), findsOneWidget);
      expect(find.byKey(const Key('billDetailPayer')), findsOneWidget);
      expect(find.textContaining('David'), findsWidgets);
    });

    testWidgets('11.2 BillDetailScreen renders Split Mode badge', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final bill = Bill(
        id: 'detail_b2',
        title: 'Taxi Ride',
        amount: 120000,
        category: 'transport',
        date: DateTime(2026, 9, 10),
        paidBy: 'Alice',
        splitMode: 'percentage',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 60000, percentage: 50.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 60000, percentage: 50.0),
        ],
      );

      await tester.pumpWidget(buildTestApp(child: BillDetailScreen(bill: bill)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('billDetailSplitMode')), findsOneWidget);
      expect(find.textContaining('By Percentage'), findsOneWidget);
    });

    testWidgets('11.3 BillDetailScreen renders Split Breakdown section with all participants', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final bill = Bill(
        id: 'detail_b3',
        title: 'Groceries',
        amount: 300000,
        category: 'food',
        date: DateTime(2026, 9, 10),
        paidBy: 'Alice',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 150000),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 150000),
        ],
      );

      await tester.pumpWidget(buildTestApp(child: BillDetailScreen(bill: bill)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('billDetailBreakdown')), findsOneWidget);
      expect(find.byKey(const Key('splitBreakdownTitle')), findsOneWidget);
      expect(find.byKey(const Key('breakdownParticipantName_Alice')), findsOneWidget);
      expect(find.byKey(const Key('breakdownParticipantName_Bob')), findsOneWidget);
      expect(find.byKey(const Key('breakdownParticipantAmount_Alice')), findsOneWidget);
      expect(find.byKey(const Key('breakdownParticipantAmount_Bob')), findsOneWidget);
    });

    testWidgets('11.4 BillDetailScreen shows percentage details in breakdown', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final bill = Bill(
        id: 'detail_b4',
        title: 'Electricity',
        amount: 200000,
        category: 'utilities',
        date: DateTime(2026, 9, 10),
        paidBy: 'Bob',
        splitMode: 'percentage',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 80000, percentage: 40.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 120000, percentage: 60.0),
        ],
      );

      await tester.pumpWidget(buildTestApp(child: BillDetailScreen(bill: bill)));
      await tester.pumpAndSettle();

      expect(find.text('40.0%'), findsOneWidget);
      expect(find.text('60.0%'), findsOneWidget);
    });

    testWidgets('11.5 BillDetailScreen shows shares details in breakdown', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final bill = Bill(
        id: 'detail_b5',
        title: 'Party Snacks',
        amount: 300000,
        category: 'food',
        date: DateTime(2026, 9, 10),
        paidBy: 'Alice',
        splitMode: 'shares',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Adult1', amount: 200000, shares: 2.0, percentage: 66.7),
          BillParticipant(participantId: 'p2', name: 'Child1', amount: 100000, shares: 1.0, percentage: 33.3),
        ],
      );

      await tester.pumpWidget(buildTestApp(child: BillDetailScreen(bill: bill)));
      await tester.pumpAndSettle();

      expect(find.textContaining('2 shares'), findsOneWidget);
      expect(find.textContaining('1 share'), findsOneWidget);
    });

    testWidgets('11.6 BillDetailScreen renders receipts section when bill has receipts', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final bill = Bill(
        id: 'detail_b6',
        title: 'Fuel',
        amount: 50000,
        category: 'transport',
        date: DateTime(2026, 9, 10),
        paidBy: 'Alice',
        participants: const [],
        imagePaths: const ['/mock/receipt1.jpg'],
      );

      await tester.pumpWidget(buildTestApp(child: BillDetailScreen(bill: bill)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('billDetailReceipts')), findsOneWidget);
    });

    testWidgets('11.7 BillDetailScreen edit button navigates to AddBillScreen with billToEdit', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final bill = Bill(
        id: 'detail_b7',
        title: 'Dinner Edit',
        amount: 150000,
        category: 'food',
        date: DateTime(2026, 9, 10),
        paidBy: 'Alice',
        participants: const [],
      );

      await tester.pumpWidget(buildTestApp(child: BillDetailScreen(bill: bill)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('billDetailEditButton')));
      await tester.pumpAndSettle();

      expect(find.byType(AddBillScreen), findsOneWidget);
    });

    testWidgets('11.8 BillDetailScreen save template button creates template', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeTemplateRepo = FakeBillTemplateRepository();
      final bill = Bill(
        id: 'detail_b8',
        title: 'Template Test Bill',
        amount: 150000,
        category: 'food',
        date: DateTime(2026, 9, 10),
        paidBy: 'Alice',
        splitMode: 'shares',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 150000),
        ],
      );

      await tester.pumpWidget(buildTestApp(
        templateRepo: fakeTemplateRepo,
        child: BillDetailScreen(bill: bill),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('billDetailSaveTemplateButton')));
      await tester.pumpAndSettle();

      expect(fakeTemplateRepo.templates.length, 1);
      expect(fakeTemplateRepo.templates.first.splitMode, 'shares');
    });

    testWidgets('11.9 BillCard displays splitModeChip when splitMode is not equal', (tester) async {
      final bill = Bill(
        id: 'card_b1',
        title: 'Shared Taxi',
        amount: 80000,
        category: 'transport',
        date: DateTime(2026, 9, 10),
        paidBy: 'Bob',
        splitMode: 'shares',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 40000),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 40000),
        ],
      );

      await tester.pumpWidget(buildTestApp(child: BillCard(bill: bill)));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('splitModeChip_${bill.id}')), findsOneWidget);
    });

    testWidgets('11.10 BillCard omits splitModeChip when splitMode is equal', (tester) async {
      final bill = Bill(
        id: 'card_b2',
        title: 'Equal Meal',
        amount: 100000,
        category: 'food',
        date: DateTime(2026, 9, 10),
        paidBy: 'Alice',
        splitMode: 'equal',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 50000),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 50000),
        ],
      );

      await tester.pumpWidget(buildTestApp(child: BillCard(bill: bill)));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('splitModeChip_${bill.id}')), findsNothing);
    });

    testWidgets('11.11 BillCard viewBillDetail button opens BillDetailScreen', (tester) async {
      final bill = Bill(
        id: 'card_b3',
        title: 'Open Detail Test',
        amount: 50000,
        category: 'food',
        date: DateTime(2026, 9, 10),
        paidBy: 'Alice',
        participants: const [],
      );

      await tester.pumpWidget(buildTestApp(child: BillCard(bill: bill)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('viewBillDetail_${bill.id}')));
      await tester.pumpAndSettle();

      expect(find.byType(BillDetailScreen), findsOneWidget);
    });

    testWidgets('11.12 BillCard tap on card without receipt opens BillDetailScreen', (tester) async {
      final bill = Bill(
        id: 'card_b4',
        title: 'No Receipt Bill',
        amount: 60000,
        category: 'food',
        date: DateTime(2026, 9, 10),
        paidBy: 'Bob',
        participants: const [],
      );

      await tester.pumpWidget(buildTestApp(child: BillCard(bill: bill)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('billCard_${bill.id}')));
      await tester.pumpAndSettle();

      expect(find.byType(BillDetailScreen), findsOneWidget);
    });
  });
}
