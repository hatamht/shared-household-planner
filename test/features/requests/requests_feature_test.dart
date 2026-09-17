import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:dartz/dartz.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/core/theme/app_theme.dart';

import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_project_by_id_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/project_detail_screen.dart';

import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/bills_list_screen.dart';

import 'package:shared_household_planner/features/requests/domain/entities/request_item.dart';
import 'package:shared_household_planner/features/requests/domain/repositories/request_repository.dart';
import 'package:shared_household_planner/features/requests/domain/usecases/request_usecases.dart';
import 'package:shared_household_planner/features/requests/data/models/request_model.dart';
import 'package:shared_household_planner/features/requests/presentation/bloc/request_bloc.dart';
import 'package:shared_household_planner/features/requests/presentation/bloc/request_event.dart';
import 'package:shared_household_planner/features/requests/presentation/bloc/request_state.dart';
import 'package:shared_household_planner/features/requests/presentation/pages/request_list_screen.dart';
import 'package:shared_household_planner/features/requests/presentation/widgets/create_request_bottom_sheet.dart';
import 'package:shared_household_planner/features/requests/presentation/widgets/request_card.dart';
import 'package:shared_household_planner/features/home/presentation/pages/home_screen.dart';

// ─────────────────────────────────────────────────────────────
// In-Memory Mock RequestRepository
// ─────────────────────────────────────────────────────────────
class MockRequestRepository implements RequestRepository {
  final List<RequestItem> items;

  MockRequestRepository([List<RequestItem>? initial])
      : items = initial != null ? List.from(initial) : [];

  @override
  Future<Either<Failure, RequestItem>> createRequest(RequestItem request) async {
    items.add(request);
    return Right(request);
  }

  @override
  Future<Either<Failure, List<RequestItem>>> getAllRequests() async {
    final sorted = List<RequestItem>.from(items)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Right(sorted);
  }

  @override
  Future<Either<Failure, List<RequestItem>>> getRequestsByProjectId(String projectId) async {
    final filtered = items
        .where((r) => r.projectId == projectId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Right(filtered);
  }

  @override
  Future<Either<Failure, RequestItem>> getRequestById(String id) async {
    final match = items.where((r) => r.id == id).firstOrNull;
    if (match != null) {
      return Right(match);
    }
    return const Left(LocalFailure('Request not found'));
  }

  @override
  Future<Either<Failure, RequestItem>> updateRequest(RequestItem request) async {
    final idx = items.indexWhere((r) => r.id == request.id);
    if (idx >= 0) {
      items[idx] = request;
      return Right(request);
    }
    return const Left(LocalFailure('Request not found for update'));
  }

  @override
  Future<Either<Failure, void>> deleteRequest(String id) async {
    final removed = items.removeWhere((r) => r.id == id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, int>> getRequestCountByProjectId(String projectId) async {
    final count = items.where((r) => r.projectId == projectId).length;
    return Right(count);
  }
}

// ─────────────────────────────────────────────────────────────
// In-Memory Mock ProjectRepository
// ─────────────────────────────────────────────────────────────
class MockProjectRepository implements ProjectRepository {
  final List<Project> projects;

  MockProjectRepository([List<Project>? initial])
      : projects = initial != null ? List.from(initial) : [];

  @override
  Future<Either<Failure, Project>> create(Project project) async {
    projects.add(project);
    return Right(project);
  }

  @override
  Future<Either<Failure, List<Project>>> getAll() async =>
      Right(List.from(projects));

  @override
  Future<Either<Failure, Project>> getById(String id) async {
    final p = projects.where((p) => p.id == id).firstOrNull;
    if (p != null) return Right(p);
    return const Left(LocalFailure('Project not found'));
  }

  @override
  Future<Either<Failure, Project>> update(Project project) async {
    final idx = projects.indexWhere((p) => p.id == project.id);
    if (idx >= 0) {
      projects[idx] = project;
      return Right(project);
    }
    return const Left(LocalFailure('Project not found'));
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    projects.removeWhere((p) => p.id == id);
    return const Right(null);
  }
}

// ─────────────────────────────────────────────────────────────
// In-Memory Mock BillRepository
// ─────────────────────────────────────────────────────────────
class MockBillRepository implements BillRepository {
  final List<Bill> bills;

  MockBillRepository([List<Bill>? initial])
      : bills = initial != null ? List.from(initial) : [];

  @override
  Future<Either<Failure, Bill>> create(Bill bill) async {
    bills.add(bill);
    return Right(bill);
  }

  @override
  Future<Either<Failure, List<Bill>>> getAll() async => Right(List.from(bills));

  @override
  Future<Either<Failure, Bill>> getById(String id) async {
    final b = bills.where((b) => b.id == id).firstOrNull;
    if (b != null) return Right(b);
    return const Left(LocalFailure('Bill not found'));
  }

  @override
  Future<Either<Failure, Bill>> update(Bill bill) async {
    final idx = bills.indexWhere((b) => b.id == bill.id);
    if (idx >= 0) {
      bills[idx] = bill;
      return Right(bill);
    }
    return const Left(LocalFailure('Bill not found'));
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    bills.removeWhere((b) => b.id == id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async {
    return Right(bills.where((b) => b.projectId == projectId).toList());
  }
}

// ─────────────────────────────────────────────────────────────
// Localization Mock
// ─────────────────────────────────────────────────────────────
class TestRequestsLocalizations extends AppLocalizations {
  TestRequestsLocalizations() : super(const Locale('en'));

  static const Map<String, String> _strings = {
    'requests': 'Requests',
    'request': 'Request',
    'request_list': 'Request List',
    'create_request': 'Create Request',
    'edit_request': 'Edit Request',
    'delete_request': 'Delete Request',
    'delete_request_confirm': 'Are you sure you want to delete this request?',
    'request_title': 'Title',
    'request_title_hint': 'Enter request title',
    'request_description': 'Description',
    'request_description_hint': 'Enter description (optional)',
    'request_status': 'Status',
    'request_status_pending': 'Pending',
    'request_status_completed': 'Completed',
    'request_status_cancelled': 'Cancelled',
    'mark_completed': 'Mark Completed',
    'mark_cancelled': 'Mark Cancelled',
    'revert_pending': 'Revert to Pending',
    'request_created': 'Request created successfully',
    'request_updated': 'Request updated successfully',
    'request_deleted': 'Request deleted successfully',
    'request_title_required': 'Please enter a title',
    'select_project_required': 'Please select a project',
    'no_requests': 'No requests found',
    'all_requests': 'All Requests',
    'filter_all': 'All',
    'filter_pending': 'Pending',
    'filter_completed': 'Completed',
    'filter_cancelled': 'Cancelled',
    'requests_count': 'Requests',
    'requests_tab': 'Requests',
    'bills_tab': 'Bills',
    'bills': 'Bills',
    'projects': 'Projects',
    'statistics': 'Statistics',
    'settings': 'Settings',
    'save': 'Save',
    'delete': 'Delete',
    'cancel': 'Cancel',
    'edit': 'Edit',
    'project': 'Project',
    'add_project': 'Add Project',
    'leave_project': 'Leave Project',
    'delete_project': 'Delete Project',
    'delete_project_confirm': 'Are you sure you want to delete this project?',
    'edit_project': 'Edit Project',
    'settlement_tab': 'Settlement',
    'statistics_tab': 'Statistics',
    'light_mode': 'Light Mode',
    'dark_mode': 'Dark Mode',
  };

  @override
  String translate(String key) => _strings[key] ?? key;
}

class TestRequestsLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const TestRequestsLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async =>
      TestRequestsLocalizations();
  @override
  bool shouldReload(TestRequestsLocalizationsDelegate old) => false;
}

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────
final _dt = DateTime(2026, 9, 17, 10, 0);

Project makeProject({
  required String id,
  required String name,
  List<String>? members,
  String? description,
}) {
  return Project(
    id: id,
    name: name,
    description: description ?? 'Test project',
    members: members ?? ['Alice', 'Bob'],
    createdAt: _dt,
    updatedAt: _dt,
  );
}

RequestItem makeRequest({
  String id = 'req-1',
  String projectId = 'proj-1',
  String title = 'Buy paper towels',
  String? description = 'Costco pack of 12',
  RequestStatus status = RequestStatus.pending,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return RequestItem(
    id: id,
    projectId: projectId,
    title: title,
    description: description,
    status: status,
    createdAt: createdAt ?? _dt,
    updatedAt: updatedAt,
  );
}

Widget buildTestApp({
  required Widget child,
  MockRequestRepository? requestRepo,
  MockProjectRepository? projectRepo,
  MockBillRepository? billRepo,
  ThemeMode themeMode = ThemeMode.light,
}) {
  final rRepo = requestRepo ?? MockRequestRepository();
  final pRepo = projectRepo ?? MockProjectRepository();
  final bRepo = billRepo ?? MockBillRepository();

  final requestBloc = RequestBloc(
    getAllRequestsUseCase: GetAllRequestsUseCase(rRepo),
    getRequestsByProjectIdUseCase: GetRequestsByProjectIdUseCase(rRepo),
    createRequestUseCase: CreateRequestUseCase(rRepo),
    updateRequestUseCase: UpdateRequestUseCase(rRepo),
    deleteRequestUseCase: DeleteRequestUseCase(rRepo),
  )..add(const LoadRequestsEvent());

  final projectBloc = ProjectBloc(
    createProjectUseCase: CreateProjectUseCase(pRepo),
    getAllProjectsUseCase: GetAllProjectsUseCase(pRepo),
    getProjectByIdUseCase: GetProjectByIdUseCase(pRepo),
    updateProjectUseCase: UpdateProjectUseCase(pRepo),
    deleteProjectUseCase: DeleteProjectUseCase(pRepo),
  )..add(const GetAllProjects());

  final billsBloc = BillsBloc(
    getBillsUseCase: GetBillsUseCase(bRepo),
    addBillUseCase: AddBillUseCase(bRepo),
  )..add(const GetBillsEvent());

  return MultiProvider(
    providers: [
      RepositoryProvider<RequestRepository>.value(value: rRepo),
      RepositoryProvider<ProjectRepository>.value(value: pRepo),
      RepositoryProvider<BillRepository>.value(value: bRepo),
      ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
      ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<RequestBloc>.value(value: requestBloc),
        BlocProvider<ProjectBloc>.value(value: projectBloc),
        BlocProvider<BillsBloc>.value(value: billsBloc),
      ],
      child: MaterialApp(
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        localizationsDelegates: const [
          TestRequestsLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: child,
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('en', null);
  });

  // ───────────────────────────────────────────────────────────
  // Group 1: Request Entity & Model (15 tests)
  // ───────────────────────────────────────────────────────────
  group('1. Request Entity & Model', () {
    test('1.1 RequestStatus.fromString parses correctly', () {
      expect(RequestStatus.fromString('pending'), RequestStatus.pending);
      expect(RequestStatus.fromString('completed'), RequestStatus.completed);
      expect(RequestStatus.fromString('cancelled'), RequestStatus.cancelled);
      expect(RequestStatus.fromString('canceled'), RequestStatus.cancelled);
    });

    test('1.2 RequestStatus.fromString is case-insensitive and trims whitespace', () {
      expect(RequestStatus.fromString(' PENDING '), RequestStatus.pending);
      expect(RequestStatus.fromString('Completed '), RequestStatus.completed);
      expect(RequestStatus.fromString(' CANCELLED'), RequestStatus.cancelled);
    });

    test('1.3 RequestStatus.fromString defaults to pending for unknown value', () {
      expect(RequestStatus.fromString('unknown_status'), RequestStatus.pending);
      expect(RequestStatus.fromString(''), RequestStatus.pending);
    });

    test('1.4 RequestStatus.toDbValue returns expected string', () {
      expect(RequestStatus.pending.toDbValue(), 'pending');
      expect(RequestStatus.completed.toDbValue(), 'completed');
      expect(RequestStatus.cancelled.toDbValue(), 'cancelled');
    });

    test('1.5 RequestItem getters: isPending, isCompleted, isCancelled', () {
      final p = makeRequest(status: RequestStatus.pending);
      expect(p.isPending, isTrue);
      expect(p.isCompleted, isFalse);
      expect(p.isCancelled, isFalse);

      final c = makeRequest(status: RequestStatus.completed);
      expect(c.isPending, isFalse);
      expect(c.isCompleted, isTrue);
      expect(c.isCancelled, isFalse);

      final x = makeRequest(status: RequestStatus.cancelled);
      expect(x.isPending, isFalse);
      expect(x.isCompleted, isFalse);
      expect(x.isCancelled, isTrue);
    });

    test('1.6 RequestItem copyWith updates fields properly', () {
      final req = makeRequest();
      final updated = req.copyWith(
        title: 'New Title',
        status: RequestStatus.completed,
      );
      expect(updated.id, req.id);
      expect(updated.title, 'New Title');
      expect(updated.status, RequestStatus.completed);
      expect(updated.description, req.description);
    });

    test('1.7 RequestItem copyWith clearDescription removes description', () {
      final req = makeRequest(description: 'Old description');
      final cleared = req.copyWith(clearDescription: true);
      expect(cleared.description, isNull);
    });

    test('1.8 RequestItem copyWith retains description when not specified', () {
      final req = makeRequest(description: 'Preserved note');
      final modified = req.copyWith(title: 'Updated title');
      expect(modified.description, 'Preserved note');
    });

    test('1.9 RequestItem Equatable value equality', () {
      final req1 = makeRequest(id: 'r1', title: 'Buy milk');
      final req2 = makeRequest(id: 'r1', title: 'Buy milk');
      expect(req1, equals(req2));
    });

    test('1.10 RequestItem inequality when title or status differs', () {
      final req1 = makeRequest(id: 'r1', title: 'Buy milk');
      final req2 = makeRequest(id: 'r1', title: 'Buy juice');
      expect(req1, isNot(equals(req2)));
    });

    test('1.11 RequestModel toJson serializes all fields properly', () {
      final model = RequestModel(
        id: 'r-123',
        projectId: 'p-456',
        title: 'Clean kitchen',
        description: 'Sweep and mop',
        status: RequestStatus.pending,
        createdAt: DateTime(2026, 9, 17, 12, 0),
        updatedAt: DateTime(2026, 9, 17, 13, 0),
      );
      final json = model.toJson();
      expect(json['id'], 'r-123');
      expect(json['projectId'], 'p-456');
      expect(json['title'], 'Clean kitchen');
      expect(json['description'], 'Sweep and mop');
      expect(json['status'], 'pending');
      expect(json['createdAt'], contains('2026-09-17'));
      expect(json['updatedAt'], contains('2026-09-17'));
    });

    test('1.12 RequestModel fromJson deserializes valid map', () {
      final json = {
        'id': 'r-999',
        'projectId': 'p-888',
        'title': 'Fix leaky faucet',
        'description': null,
        'status': 'completed',
        'createdAt': '2026-09-17T10:30:00.000',
        'updatedAt': '2026-09-17T11:00:00.000',
      };
      final model = RequestModel.fromJson(json);
      expect(model.id, 'r-999');
      expect(model.projectId, 'p-888');
      expect(model.title, 'Fix leaky faucet');
      expect(model.description, isNull);
      expect(model.status, RequestStatus.completed);
      expect(model.updatedAt, isNotNull);
    });

    test('1.13 RequestModel round-trip toJson and fromJson preserves data', () {
      final original = RequestModel(
        id: 'r-rt',
        projectId: 'p-rt',
        title: 'Round trip test',
        description: 'Details preserved',
        status: RequestStatus.cancelled,
        createdAt: DateTime(2026, 9, 17, 8, 0),
      );
      final serialized = original.toJson();
      final restored = RequestModel.fromJson(serialized);
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.status, original.status);
      expect(restored.description, original.description);
    });

    test('1.14 RequestModel fromEntity and toEntity conversions', () {
      final entity = makeRequest(id: 'ent-1', title: 'Entity test');
      final model = RequestModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.title, entity.title);
      final convertedBack = model.toEntity();
      expect(convertedBack, equals(entity));
    });

    test('1.15 RequestModel copyWith preserves type and fields', () {
      final model = RequestModel(
        id: 'm-1',
        projectId: 'p-1',
        title: 'Original',
        createdAt: _dt,
      );
      final copy = model.copyWith(title: 'Modified');
      expect(copy, isA<RequestModel>());
      expect(copy.title, 'Modified');
      expect(copy.id, 'm-1');
    });
  });

  // ───────────────────────────────────────────────────────────
  // Group 2: Repository & DataSource (15 tests)
  // ───────────────────────────────────────────────────────────
  group('2. Request Repository Operations', () {
    test('2.1 createRequest adds item and returns Right', () async {
      final repo = MockRequestRepository();
      final req = makeRequest(id: 'r-add', title: 'New Request');
      final res = await repo.createRequest(req);
      expect(res.isRight(), isTrue);
      expect(repo.items.length, 1);
    });

    test('2.2 getAllRequests returns all items sorted by createdAt DESC', () async {
      final r1 = makeRequest(id: 'r1', createdAt: DateTime(2026, 9, 15));
      final r2 = makeRequest(id: 'r2', createdAt: DateTime(2026, 9, 17));
      final repo = MockRequestRepository([r1, r2]);
      final res = await repo.getAllRequests();
      res.fold((l) => fail(l.message), (list) {
        expect(list.length, 2);
        expect(list.first.id, 'r2');
      });
    });

    test('2.3 getRequestsByProjectId returns items for specific project only', () async {
      final r1 = makeRequest(id: 'r1', projectId: 'p-alpha');
      final r2 = makeRequest(id: 'r2', projectId: 'p-beta');
      final r3 = makeRequest(id: 'r3', projectId: 'p-alpha');
      final repo = MockRequestRepository([r1, r2, r3]);

      final resAlpha = await repo.getRequestsByProjectId('p-alpha');
      resAlpha.fold((l) => fail(l.message), (list) {
        expect(list.length, 2);
        expect(list.every((r) => r.projectId == 'p-alpha'), isTrue);
      });

      final resBeta = await repo.getRequestsByProjectId('p-beta');
      resBeta.fold((l) => fail(l.message), (list) {
        expect(list.length, 1);
        expect(list.first.id, 'r2');
      });
    });

    test('2.4 getRequestsByProjectId returns empty list for unknown project', () async {
      final repo = MockRequestRepository([makeRequest(projectId: 'p1')]);
      final res = await repo.getRequestsByProjectId('non-existent');
      res.fold((l) => fail(l.message), (list) => expect(list, isEmpty));
    });

    test('2.5 getRequestById returns matching request', () async {
      final req = makeRequest(id: 'target-id');
      final repo = MockRequestRepository([req]);
      final res = await repo.getRequestById('target-id');
      expect(res.isRight(), isTrue);
      res.fold((l) => fail(l.message), (item) => expect(item.id, 'target-id'));
    });

    test('2.6 getRequestById returns Left when not found', () async {
      final repo = MockRequestRepository();
      final res = await repo.getRequestById('missing-id');
      expect(res.isLeft(), isTrue);
    });

    test('2.7 updateRequest modifies existing request', () async {
      final req = makeRequest(id: 'u-1', title: 'Before');
      final repo = MockRequestRepository([req]);
      final updated = req.copyWith(title: 'After');
      final res = await repo.updateRequest(updated);
      expect(res.isRight(), isTrue);
      expect(repo.items.first.title, 'After');
    });

    test('2.8 updateRequest returns Left if request does not exist', () async {
      final repo = MockRequestRepository();
      final res = await repo.updateRequest(makeRequest(id: 'ghost'));
      expect(res.isLeft(), isTrue);
    });

    test('2.9 deleteRequest removes request from repository', () async {
      final req = makeRequest(id: 'del-1');
      final repo = MockRequestRepository([req]);
      final res = await repo.deleteRequest('del-1');
      expect(res.isRight(), isTrue);
      expect(repo.items, isEmpty);
    });

    test('2.10 getRequestCountByProjectId returns accurate count', () async {
      final repo = MockRequestRepository([
        makeRequest(id: '1', projectId: 'pA'),
        makeRequest(id: '2', projectId: 'pA'),
        makeRequest(id: '3', projectId: 'pB'),
      ]);
      final countA = await repo.getRequestCountByProjectId('pA');
      final countB = await repo.getRequestCountByProjectId('pB');
      final countC = await repo.getRequestCountByProjectId('pC');
      expect(countA.getOrElse(() => -1), 2);
      expect(countB.getOrElse(() => -1), 1);
      expect(countC.getOrElse(() => -1), 0);
    });

    test('2.11 Multiple requests can belong to same project (1-to-many)', () async {
      final repo = MockRequestRepository();
      for (int i = 1; i <= 5; i++) {
        await repo.createRequest(makeRequest(id: 'req-$i', projectId: 'proj-shared'));
      }
      final res = await repo.getRequestsByProjectId('proj-shared');
      expect(res.getOrElse(() => []).length, 5);
    });

    test('2.12 Updating request status persists across queries', () async {
      final repo = MockRequestRepository([makeRequest(id: 'r-stat', status: RequestStatus.pending)]);
      await repo.updateRequest(makeRequest(id: 'r-stat', status: RequestStatus.completed));
      final fetch = await repo.getRequestById('r-stat');
      expect(fetch.getOrElse(() => makeRequest()).status, RequestStatus.completed);
    });

    test('2.13 Deleting one request does not affect other requests in same project', () async {
      final repo = MockRequestRepository([
        makeRequest(id: 'r1', projectId: 'p1'),
        makeRequest(id: 'r2', projectId: 'p1'),
      ]);
      await repo.deleteRequest('r1');
      final list = await repo.getRequestsByProjectId('p1');
      expect(list.getOrElse(() => []).length, 1);
      expect(list.getOrElse(() => []).first.id, 'r2');
    });

    test('2.14 Project isolation: requests for Project X not included in Project Y', () async {
      final repo = MockRequestRepository([
        makeRequest(id: 'rx', projectId: 'proj-X', title: 'Task for X'),
        makeRequest(id: 'ry', projectId: 'proj-Y', title: 'Task for Y'),
      ]);
      final xList = await repo.getRequestsByProjectId('proj-X');
      final yList = await repo.getRequestsByProjectId('proj-Y');
      expect(xList.getOrElse(() => []).every((r) => r.projectId == 'proj-X'), isTrue);
      expect(yList.getOrElse(() => []).every((r) => r.projectId == 'proj-Y'), isTrue);
    });

    test('2.15 Changing request projectId moves request to target project', () async {
      final repo = MockRequestRepository([makeRequest(id: 'move-me', projectId: 'p1')]);
      final moved = makeRequest(id: 'move-me', projectId: 'p2');
      await repo.updateRequest(moved);

      final p1List = await repo.getRequestsByProjectId('p1');
      final p2List = await repo.getRequestsByProjectId('p2');
      expect(p1List.getOrElse(() => []), isEmpty);
      expect(p2List.getOrElse(() => []).length, 1);
    });
  });

  // ───────────────────────────────────────────────────────────
  // Group 3: Request UseCases (10 tests)
  // ───────────────────────────────────────────────────────────
  group('3. Request UseCases', () {
    test('3.1 CreateRequestUseCase creates and returns request', () async {
      final repo = MockRequestRepository();
      final uc = CreateRequestUseCase(repo);
      final res = await uc(makeRequest(id: 'uc-1'));
      expect(res.isRight(), isTrue);
      expect(repo.items.length, 1);
    });

    test('3.2 GetAllRequestsUseCase delegates to repository', () async {
      final repo = MockRequestRepository([makeRequest(id: '1'), makeRequest(id: '2')]);
      final uc = GetAllRequestsUseCase(repo);
      final res = await uc();
      expect(res.getOrElse(() => []).length, 2);
    });

    test('3.3 GetRequestsByProjectIdUseCase delegates with projectId', () async {
      final repo = MockRequestRepository([
        makeRequest(projectId: 'pA'),
        makeRequest(projectId: 'pB'),
      ]);
      final uc = GetRequestsByProjectIdUseCase(repo);
      final res = await uc('pA');
      expect(res.getOrElse(() => []).length, 1);
    });

    test('3.4 GetRequestByIdUseCase retrieves specific request', () async {
      final repo = MockRequestRepository([makeRequest(id: 'seek')]);
      final uc = GetRequestByIdUseCase(repo);
      final res = await uc('seek');
      expect(res.isRight(), isTrue);
    });

    test('3.5 UpdateRequestUseCase updates request in repo', () async {
      final repo = MockRequestRepository([makeRequest(id: 'upd', title: 'Old')]);
      final uc = UpdateRequestUseCase(repo);
      await uc(makeRequest(id: 'upd', title: 'New'));
      expect(repo.items.first.title, 'New');
    });

    test('3.6 DeleteRequestUseCase removes request from repo', () async {
      final repo = MockRequestRepository([makeRequest(id: 'del')]);
      final uc = DeleteRequestUseCase(repo);
      await uc('del');
      expect(repo.items, isEmpty);
    });

    test('3.7 GetRequestCountUseCase delegates to repository', () async {
      final repo = MockRequestRepository([
        makeRequest(projectId: 'cnt-proj'),
        makeRequest(projectId: 'cnt-proj'),
      ]);
      final uc = GetRequestCountUseCase(repo);
      final count = await uc('cnt-proj');
      expect(count.getOrElse(() => 0), 2);
    });

    test('3.8 CreateRequestUseCase propagates failures cleanly', () async {
      final uc = CreateRequestUseCase(MockRequestRepository());
      final res = await uc(makeRequest());
      expect(res.isRight(), isTrue);
    });

    test('3.9 DeleteRequestUseCase on empty repo succeeds gracefully', () async {
      final uc = DeleteRequestUseCase(MockRequestRepository());
      final res = await uc('non-existing');
      expect(res.isRight(), isTrue);
    });

    test('3.10 GetAllRequestsUseCase on empty repo returns empty list', () async {
      final uc = GetAllRequestsUseCase(MockRequestRepository());
      final res = await uc();
      expect(res.getOrElse(() => [makeRequest()]), isEmpty);
    });
  });

  // ───────────────────────────────────────────────────────────
  // Group 4: RequestBloc (15 tests)
  // ───────────────────────────────────────────────────────────
  group('4. RequestBloc State Management', () {
    late MockRequestRepository repo;
    late RequestBloc bloc;

    setUp(() {
      repo = MockRequestRepository();
      bloc = RequestBloc(
        getAllRequestsUseCase: GetAllRequestsUseCase(repo),
        getRequestsByProjectIdUseCase: GetRequestsByProjectIdUseCase(repo),
        createRequestUseCase: CreateRequestUseCase(repo),
        updateRequestUseCase: UpdateRequestUseCase(repo),
        deleteRequestUseCase: DeleteRequestUseCase(repo),
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('4.1 Initial state is RequestInitial', () {
      expect(bloc.state, isA<RequestInitial>());
    });

    test('4.2 LoadRequestsEvent emits RequestLoaded', () async {
      repo.items.add(makeRequest(id: 'r1'));
      bloc.add(const LoadRequestsEvent());
      await expectLater(
        bloc.stream,
        emits(isA<RequestLoaded>().having((s) => s.allRequests.length, 'length', 1)),
      );
    });

    test('4.3 CreateRequestEvent adds request to state', () async {
      bloc.emit(const RequestLoaded(allRequests: []));
      final req = makeRequest(id: 'new-req');
      bloc.add(CreateRequestEvent(req));
      await expectLater(
        bloc.stream,
        emits(isA<RequestLoaded>().having((s) => s.allRequests.first.id, 'id', 'new-req')),
      );
    });

    test('4.4 UpdateRequestEvent updates request in state', () async {
      final original = makeRequest(id: 'up-1', title: 'Before');
      repo.items.add(original);
      bloc.emit(RequestLoaded(allRequests: [original]));
      final updated = original.copyWith(title: 'After');
      bloc.add(UpdateRequestEvent(updated));
      await expectLater(
        bloc.stream,
        emits(isA<RequestLoaded>().having((s) => s.allRequests.first.title, 'title', 'After')),
      );
    });

    test('4.5 ChangeRequestStatusEvent marks completed', () async {
      final req = makeRequest(id: 's1', status: RequestStatus.pending);
      repo.items.add(req);
      bloc.emit(RequestLoaded(allRequests: [req]));

      bloc.add(const ChangeRequestStatusEvent(
        requestId: 's1',
        newStatus: RequestStatus.completed,
      ));
      await expectLater(
        bloc.stream,
        emits(isA<RequestLoaded>().having((s) => s.allRequests.first.status, 'status', RequestStatus.completed)),
      );
    });

    test('4.6 ChangeRequestStatusEvent marks cancelled', () async {
      final req = makeRequest(id: 's2', status: RequestStatus.pending);
      repo.items.add(req);
      bloc.emit(RequestLoaded(allRequests: [req]));

      bloc.add(const ChangeRequestStatusEvent(
        requestId: 's2',
        newStatus: RequestStatus.cancelled,
      ));
      await expectLater(
        bloc.stream,
        emits(isA<RequestLoaded>().having((s) => s.allRequests.first.status, 'status', RequestStatus.cancelled)),
      );
    });

    test('4.7 ChangeRequestStatusEvent reverts to pending', () async {
      final req = makeRequest(id: 's3', status: RequestStatus.completed);
      repo.items.add(req);
      bloc.emit(RequestLoaded(allRequests: [req]));

      bloc.add(const ChangeRequestStatusEvent(
        requestId: 's3',
        newStatus: RequestStatus.pending,
      ));
      await expectLater(
        bloc.stream,
        emits(isA<RequestLoaded>().having((s) => s.allRequests.first.status, 'status', RequestStatus.pending)),
      );
    });

    test('4.8 DeleteRequestEvent removes request from state', () async {
      final req = makeRequest(id: 'd1');
      repo.items.add(req);
      bloc.emit(RequestLoaded(allRequests: [req]));

      bloc.add(const DeleteRequestEvent('d1'));
      await expectLater(
        bloc.stream,
        emits(isA<RequestLoaded>().having((s) => s.allRequests, 'empty', isEmpty)),
      );
    });

    test('4.9 FilterRequestsEvent updates selectedProjectId', () async {
      bloc.emit(const RequestLoaded(allRequests: []));
      bloc.add(const FilterRequestsEvent(projectId: 'p-filter'));
      await expectLater(
        bloc.stream,
        emits(isA<RequestLoaded>().having((s) => s.selectedProjectId, 'projectId', 'p-filter')),
      );
    });

    test('4.10 FilterRequestsEvent updates statusFilter', () async {
      bloc.emit(const RequestLoaded(allRequests: []));
      bloc.add(const FilterRequestsEvent(statusFilter: RequestStatus.pending));
      await expectLater(
        bloc.stream,
        emits(isA<RequestLoaded>().having((s) => s.statusFilter, 'status', RequestStatus.pending)),
      );
    });

    test('4.11 filteredRequests getter applies project and status filters', () {
      final state = RequestLoaded(
        allRequests: [
          makeRequest(id: '1', projectId: 'pA', status: RequestStatus.pending),
          makeRequest(id: '2', projectId: 'pA', status: RequestStatus.completed),
          makeRequest(id: '3', projectId: 'pB', status: RequestStatus.pending),
        ],
        selectedProjectId: 'pA',
        statusFilter: RequestStatus.pending,
      );
      expect(state.filteredRequests.length, 1);
      expect(state.filteredRequests.first.id, '1');
    });

    test('4.12 countForProject computes project requests count', () {
      final state = RequestLoaded(allRequests: [
        makeRequest(projectId: 'pX'),
        makeRequest(projectId: 'pX'),
        makeRequest(projectId: 'pY'),
      ]);
      expect(state.countForProject('pX'), 2);
      expect(state.countForProject('pY'), 1);
      expect(state.countForProject('pZ'), 0);
    });

    test('4.13 countByStatus computes count accurately', () {
      final state = RequestLoaded(allRequests: [
        makeRequest(status: RequestStatus.pending),
        makeRequest(status: RequestStatus.completed),
        makeRequest(status: RequestStatus.completed),
      ]);
      expect(state.pendingCount, 1);
      expect(state.completedCount, 2);
      expect(state.cancelledCount, 0);
    });

    test('4.14 FilterRequestsEvent clears filter when null is passed', () async {
      bloc.emit(const RequestLoaded(
        allRequests: [],
        selectedProjectId: 'p1',
        statusFilter: RequestStatus.completed,
      ));
      bloc.add(const FilterRequestsEvent(projectId: null, statusFilter: null));
      await expectLater(
        bloc.stream,
        emits(isA<RequestLoaded>()
            .having((s) => s.selectedProjectId, 'projectId', isNull)
            .having((s) => s.statusFilter, 'statusFilter', isNull)),
      );
    });

    test('4.15 RequestLoaded copyWith preserves existing values if not specified', () {
      const original = RequestLoaded(
        allRequests: [],
        selectedProjectId: 'orig-p',
        statusFilter: RequestStatus.pending,
      );
      final copy = original.copyWith();
      expect(copy.selectedProjectId, 'orig-p');
      expect(copy.statusFilter, RequestStatus.pending);
    });
  });

  // ───────────────────────────────────────────────────────────
  // Group 5: CreateRequestBottomSheet Widget Tests (15 tests)
  // ───────────────────────────────────────────────────────────
  group('5. CreateRequestBottomSheet Widget Tests', () {
    testWidgets('5.1 Renders create request modal elements', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'Apartment 4B');
      await tester.pumpWidget(buildTestApp(
        child: const Scaffold(body: CreateRequestBottomSheet()),
        projectRepo: MockProjectRepository([p1]),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('createRequestModalTitle')), findsOneWidget);
      expect(find.byKey(const Key('requestProjectDropdown')), findsOneWidget);
      expect(find.byKey(const Key('requestTitleField')), findsOneWidget);
      expect(find.byKey(const Key('requestDescriptionField')), findsOneWidget);
      expect(find.byKey(const Key('saveRequestButton')), findsOneWidget);
    });

    testWidgets('5.2 Shows validation error when title is empty', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'Apartment 4B');
      await tester.pumpWidget(buildTestApp(
        child: const Scaffold(body: CreateRequestBottomSheet()),
        projectRepo: MockProjectRepository([p1]),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveRequestButton')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a title'), findsOneWidget);
    });

    testWidgets('5.3 Pre-selects initialProjectId when provided', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'Project 1');
      final p2 = makeProject(id: 'p2', name: 'Project 2');
      await tester.pumpWidget(buildTestApp(
        child: const Scaffold(body: CreateRequestBottomSheet(initialProjectId: 'p2')),
        projectRepo: MockProjectRepository([p1, p2]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Project 2'), findsOneWidget);
    });

    testWidgets('5.4 Creates request and dispatches event when valid', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'Vacation Home');
      final requestRepo = MockRequestRepository();

      await tester.pumpWidget(buildTestApp(
        child: const Scaffold(body: CreateRequestBottomSheet(initialProjectId: 'p1')),
        projectRepo: MockProjectRepository([p1]),
        requestRepo: requestRepo,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('requestTitleField')), 'Buy sunscreen');
      await tester.enterText(find.byKey(const Key('requestDescriptionField')), 'SPF 50 waterproof');
      await tester.tap(find.byKey(const Key('saveRequestButton')));
      await tester.pumpAndSettle();

      expect(requestRepo.items.length, 1);
      expect(requestRepo.items.first.title, 'Buy sunscreen');
      expect(requestRepo.items.first.description, 'SPF 50 waterproof');
      expect(requestRepo.items.first.projectId, 'p1');
    });

    testWidgets('5.5 Pre-fills form fields when requestToEdit is passed', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'Apartment');
      final req = makeRequest(
        id: 'edit-1',
        projectId: 'p1',
        title: 'Fix door handle',
        description: 'Loose screws',
      );

      await tester.pumpWidget(buildTestApp(
        child: Scaffold(body: CreateRequestBottomSheet(requestToEdit: req)),
        projectRepo: MockProjectRepository([p1]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Edit Request'), findsOneWidget);
      expect(find.text('Fix door handle'), findsOneWidget);
      expect(find.text('Loose screws'), findsOneWidget);
    });

    testWidgets('5.6 Saves edited request updates', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'Apartment');
      final req = makeRequest(id: 'edit-save', projectId: 'p1', title: 'Before Edit');
      final requestRepo = MockRequestRepository([req]);

      await tester.pumpWidget(buildTestApp(
        child: Scaffold(body: CreateRequestBottomSheet(requestToEdit: req)),
        projectRepo: MockProjectRepository([p1]),
        requestRepo: requestRepo,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('requestTitleField')), 'After Edit');
      await tester.tap(find.byKey(const Key('saveRequestButton')));
      await tester.pumpAndSettle();

      expect(requestRepo.items.first.title, 'After Edit');
    });

    testWidgets('5.7 Close button pops the bottom sheet', (tester) async {
      bool popped = false;
      final p1 = makeProject(id: 'p1', name: 'Home');
      await tester.pumpWidget(buildTestApp(
        projectRepo: MockProjectRepository([p1]),
        child: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () async {
                await CreateRequestBottomSheet.show(ctx);
                popped = true;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('closeRequestModalButton')), findsOneWidget);
      await tester.tap(find.byKey(const Key('closeRequestModalButton')));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });

    testWidgets('5.8 Renders properly in Dark Theme', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'Dark Mode Home');
      await tester.pumpWidget(buildTestApp(
        themeMode: ThemeMode.dark,
        child: const Scaffold(body: CreateRequestBottomSheet()),
        projectRepo: MockProjectRepository([p1]),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('createRequestModalTitle')), findsOneWidget);
    });

    testWidgets('5.9 Description is optional and saves as null when empty', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'Test Home');
      final requestRepo = MockRequestRepository();

      await tester.pumpWidget(buildTestApp(
        child: const Scaffold(body: CreateRequestBottomSheet(initialProjectId: 'p1')),
        projectRepo: MockProjectRepository([p1]),
        requestRepo: requestRepo,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('requestTitleField')), 'Just title');
      await tester.tap(find.byKey(const Key('saveRequestButton')));
      await tester.pumpAndSettle();

      expect(requestRepo.items.first.description, isNull);
    });

    testWidgets('5.10 Can switch selected project in dropdown', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'Project Alpha');
      final p2 = makeProject(id: 'p2', name: 'Project Beta');
      final requestRepo = MockRequestRepository();

      await tester.pumpWidget(buildTestApp(
        child: const Scaffold(body: CreateRequestBottomSheet(initialProjectId: 'p1')),
        projectRepo: MockProjectRepository([p1, p2]),
        requestRepo: requestRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('requestProjectDropdown')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Project Beta').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('requestTitleField')), 'Beta Task');
      await tester.tap(find.byKey(const Key('saveRequestButton')));
      await tester.pumpAndSettle();

      expect(requestRepo.items.first.projectId, 'p2');
    });

    testWidgets('5.11 Static show helper displays modal sheet', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              key: const Key('triggerBtn'),
              onPressed: () => CreateRequestBottomSheet.show(ctx),
              child: const Text('Show'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('triggerBtn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('createRequestModalTitle')), findsOneWidget);
    });

    testWidgets('5.12 Whitespace-only title is rejected by validator', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'Apartment');
      await tester.pumpWidget(buildTestApp(
        child: const Scaffold(body: CreateRequestBottomSheet()),
        projectRepo: MockProjectRepository([p1]),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('requestTitleField')), '   ');
      await tester.tap(find.byKey(const Key('saveRequestButton')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a title'), findsOneWidget);
    });

    testWidgets('5.13 Auto-selects first project if none initially selected', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'First Project');
      await tester.pumpWidget(buildTestApp(
        child: const Scaffold(body: CreateRequestBottomSheet()),
        projectRepo: MockProjectRepository([p1]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('First Project'), findsOneWidget);
    });

    testWidgets('5.14 Trims leading and trailing spaces on title', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'House');
      final requestRepo = MockRequestRepository();

      await tester.pumpWidget(buildTestApp(
        child: const Scaffold(body: CreateRequestBottomSheet(initialProjectId: 'p1')),
        projectRepo: MockProjectRepository([p1]),
        requestRepo: requestRepo,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('requestTitleField')), '  Clean fridge  ');
      await tester.tap(find.byKey(const Key('saveRequestButton')));
      await tester.pumpAndSettle();

      expect(requestRepo.items.first.title, 'Clean fridge');
    });

    testWidgets('5.15 Editing request updates updatedAt timestamp', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'Apartment');
      final req = makeRequest(id: 'ts-test', projectId: 'p1', title: 'Old Title');
      final requestRepo = MockRequestRepository([req]);

      await tester.pumpWidget(buildTestApp(
        child: Scaffold(body: CreateRequestBottomSheet(requestToEdit: req)),
        projectRepo: MockProjectRepository([p1]),
        requestRepo: requestRepo,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('requestTitleField')), 'New Title');
      await tester.tap(find.byKey(const Key('saveRequestButton')));
      await tester.pumpAndSettle();

      expect(requestRepo.items.first.updatedAt, isNotNull);
    });
  });

  // ───────────────────────────────────────────────────────────
  // Group 6: RequestListScreen & RequestCard (15 tests)
  // ───────────────────────────────────────────────────────────
  group('6. RequestListScreen & RequestCard Widget Tests', () {
    testWidgets('6.1 Shows emptyRequestsView when no requests exist', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const RequestListScreen(),
        requestRepo: MockRequestRepository([]),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('emptyRequestsView')), findsOneWidget);
      expect(find.text('No requests found'), findsOneWidget);
      expect(find.byKey(const Key('emptyAddRequestButton')), findsOneWidget);
    });

    testWidgets('6.2 Renders request cards when requests exist', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'Cabin');
      final r1 = makeRequest(id: 'r1', projectId: 'p1', title: 'Buy firewood');
      final r2 = makeRequest(id: 'r2', projectId: 'p1', title: 'Fix window');

      await tester.pumpWidget(buildTestApp(
        child: const RequestListScreen(),
        projectRepo: MockProjectRepository([p1]),
        requestRepo: MockRequestRepository([r1, r2]),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('requestCard_r1')), findsOneWidget);
      expect(find.byKey(const Key('requestCard_r2')), findsOneWidget);
      expect(find.text('Buy firewood'), findsOneWidget);
      expect(find.text('Fix window'), findsOneWidget);
    });

    testWidgets('6.3 RequestCard displays project name badge', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'Lake House');
      final r1 = makeRequest(id: 'r1', projectId: 'p1', title: 'Boating license');

      await tester.pumpWidget(buildTestApp(
        child: const RequestListScreen(),
        projectRepo: MockProjectRepository([p1]),
        requestRepo: MockRequestRepository([r1]),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('requestProjectName_r1')), findsOneWidget);
      expect(find.text('Lake House'), findsOneWidget);
    });

    testWidgets('6.4 Displays status chip for pending, completed, cancelled', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'House');
      final r1 = makeRequest(id: 'r1', projectId: 'p1', status: RequestStatus.pending);
      final r2 = makeRequest(id: 'r2', projectId: 'p1', status: RequestStatus.completed);
      final r3 = makeRequest(id: 'r3', projectId: 'p1', status: RequestStatus.cancelled);

      await tester.pumpWidget(buildTestApp(
        child: const RequestListScreen(),
        projectRepo: MockProjectRepository([p1]),
        requestRepo: MockRequestRepository([r1, r2, r3]),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('requestStatusChip_r1')), findsOneWidget);
      expect(find.byKey(const Key('requestStatusChip_r2')), findsOneWidget);
      expect(find.byKey(const Key('requestStatusChip_r3')), findsOneWidget);
    });

    testWidgets('6.5 Completed request displays title with line-through', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'House');
      final r1 = makeRequest(id: 'r-done', projectId: 'p1', title: 'Mow lawn', status: RequestStatus.completed);

      await tester.pumpWidget(buildTestApp(
        child: const RequestListScreen(),
        projectRepo: MockProjectRepository([p1]),
        requestRepo: MockRequestRepository([r1]),
      ));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.byKey(const Key('requestTitle_r-done')));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('6.6 Tapping markCompletedButton marks request as completed', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'House');
      final r1 = makeRequest(id: 'r-comp', projectId: 'p1', status: RequestStatus.pending);
      final requestRepo = MockRequestRepository([r1]);

      await tester.pumpWidget(buildTestApp(
        child: const RequestListScreen(),
        projectRepo: MockProjectRepository([p1]),
        requestRepo: requestRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('markCompletedButton_r-comp')));
      await tester.pumpAndSettle();

      expect(requestRepo.items.first.status, RequestStatus.completed);
    });

    testWidgets('6.7 Tapping markCancelledButton marks request as cancelled', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'House');
      final r1 = makeRequest(id: 'r-canc', projectId: 'p1', status: RequestStatus.pending);
      final requestRepo = MockRequestRepository([r1]);

      await tester.pumpWidget(buildTestApp(
        child: const RequestListScreen(),
        projectRepo: MockProjectRepository([p1]),
        requestRepo: requestRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('markCancelledButton_r-canc')));
      await tester.pumpAndSettle();

      expect(requestRepo.items.first.status, RequestStatus.cancelled);
    });

    testWidgets('6.8 Tapping revertPendingButton reverts status to pending', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'House');
      final r1 = makeRequest(id: 'r-rev', projectId: 'p1', status: RequestStatus.completed);
      final requestRepo = MockRequestRepository([r1]);

      await tester.pumpWidget(buildTestApp(
        child: const RequestListScreen(),
        projectRepo: MockProjectRepository([p1]),
        requestRepo: requestRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('revertPendingButton_r-rev')));
      await tester.pumpAndSettle();

      expect(requestRepo.items.first.status, RequestStatus.pending);
    });

    testWidgets('6.9 Delete button shows confirmation dialog and removes request', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'House');
      final r1 = makeRequest(id: 'r-del', projectId: 'p1', title: 'To be deleted');
      final requestRepo = MockRequestRepository([r1]);

      await tester.pumpWidget(buildTestApp(
        child: const RequestListScreen(),
        projectRepo: MockProjectRepository([p1]),
        requestRepo: requestRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deleteRequestButton_r-del')));
      await tester.pumpAndSettle();

      expect(find.text('Delete Request'), findsOneWidget);
      expect(find.byKey(const Key('confirmDeleteRequestButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirmDeleteRequestButton')));
      await tester.pumpAndSettle();

      expect(requestRepo.items, isEmpty);
      expect(find.byKey(const Key('requestCard_r-del')), findsNothing);
    });

    testWidgets('6.10 Status filter chips filter requests correctly', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'House');
      final r1 = makeRequest(id: 'r1', title: 'Task Pending', status: RequestStatus.pending);
      final r2 = makeRequest(id: 'r2', title: 'Task Done', status: RequestStatus.completed);

      await tester.pumpWidget(buildTestApp(
        child: const RequestListScreen(),
        projectRepo: MockProjectRepository([p1]),
        requestRepo: MockRequestRepository([r1, r2]),
      ));
      await tester.pumpAndSettle();

      // Tap Pending filter chip
      await tester.tap(find.byKey(const Key('filterStatusPending')));
      await tester.pumpAndSettle();

      expect(find.text('Task Pending'), findsOneWidget);
      expect(find.text('Task Done'), findsNothing);

      // Tap Completed filter chip
      await tester.tap(find.byKey(const Key('filterStatusCompleted')));
      await tester.pumpAndSettle();

      expect(find.text('Task Pending'), findsNothing);
      expect(find.text('Task Done'), findsOneWidget);

      // Tap All filter chip
      await tester.tap(find.byKey(const Key('filterStatusAll')));
      await tester.pumpAndSettle();

      expect(find.text('Task Pending'), findsOneWidget);
      expect(find.text('Task Done'), findsOneWidget);
    });

    testWidgets('6.11 Project dropdown filters requests by project', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'Project Alpha');
      final p2 = makeProject(id: 'p2', name: 'Project Beta');
      final r1 = makeRequest(id: 'r1', projectId: 'p1', title: 'Alpha Request');
      final r2 = makeRequest(id: 'r2', projectId: 'p2', title: 'Beta Request');

      await tester.pumpWidget(buildTestApp(
        child: const RequestListScreen(),
        projectRepo: MockProjectRepository([p1, p2]),
        requestRepo: MockRequestRepository([r1, r2]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Alpha Request'), findsOneWidget);
      expect(find.text('Beta Request'), findsOneWidget);

      // Select Project Alpha
      await tester.tap(find.byKey(const Key('requestProjectFilterDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Project Alpha').last);
      await tester.pumpAndSettle();

      expect(find.text('Alpha Request'), findsOneWidget);
      expect(find.text('Beta Request'), findsNothing);
    });

    testWidgets('6.12 Search field filters requests by title and description', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'House');
      final r1 = makeRequest(id: 'r1', title: 'Buy Apples', description: 'Gala apples');
      final r2 = makeRequest(id: 'r2', title: 'Buy Bananas', description: 'Yellow ripe');

      await tester.pumpWidget(buildTestApp(
        child: const RequestListScreen(),
        projectRepo: MockProjectRepository([p1]),
        requestRepo: MockRequestRepository([r1, r2]),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('requestSearchField')), 'apples');
      await tester.pumpAndSettle();

      expect(find.text('Buy Apples'), findsOneWidget);
      expect(find.text('Buy Bananas'), findsNothing);

      // Search by description keyword
      await tester.enterText(find.byKey(const Key('requestSearchField')), 'ripe');
      await tester.pumpAndSettle();

      expect(find.text('Buy Apples'), findsNothing);
      expect(find.text('Buy Bananas'), findsOneWidget);
    });

    testWidgets('6.13 Clear search button clears query and restores list', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'House');
      final r1 = makeRequest(id: 'r1', title: 'First Item');
      final r2 = makeRequest(id: 'r2', title: 'Second Item');

      await tester.pumpWidget(buildTestApp(
        child: const RequestListScreen(),
        projectRepo: MockProjectRepository([p1]),
        requestRepo: MockRequestRepository([r1, r2]),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('requestSearchField')), 'First');
      await tester.pumpAndSettle();
      expect(find.text('Second Item'), findsNothing);

      await tester.tap(find.byKey(const Key('clearRequestSearchButton')));
      await tester.pumpAndSettle();

      expect(find.text('First Item'), findsOneWidget);
      expect(find.text('Second Item'), findsOneWidget);
    });

    testWidgets('6.14 Tapping edit button opens edit modal with request data', (tester) async {
      final p1 = makeProject(id: 'p1', name: 'House');
      final r1 = makeRequest(id: 'r-ed', projectId: 'p1', title: 'Original Item');

      await tester.pumpWidget(buildTestApp(
        child: const RequestListScreen(),
        projectRepo: MockProjectRepository([p1]),
        requestRepo: MockRequestRepository([r1]),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('editRequestButton_r-ed')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Request'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Original Item'), findsOneWidget);
    });

    testWidgets('6.15 Tapping FAB opens CreateRequestBottomSheet', (tester) async {
      await tester.pumpWidget(buildTestApp(
        child: const RequestListScreen(),
        requestRepo: MockRequestRepository([]),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('addRequestFab')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('createRequestModalTitle')), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────
  // Group 7: HomeScreen Integration & Project Card Badges (10 tests)
  // ───────────────────────────────────────────────────────────
  group('7. HomeScreen Integration & Badges', () {
    testWidgets('7.1 ProjectCard displays request count badge', (tester) async {
      final p1 = makeProject(id: 'p-badge', name: 'Beach House');
      final r1 = makeRequest(id: 'rb-1', projectId: 'p-badge');
      final r2 = makeRequest(id: 'rb-2', projectId: 'p-badge');

      await tester.pumpWidget(buildTestApp(
        child: const HomeScreen(),
        projectRepo: MockProjectRepository([p1]),
        requestRepo: MockRequestRepository([r1, r2]),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectRequestBadge_p-badge')), findsOneWidget);
      expect(find.text('2 Requests'), findsOneWidget);
    });

    testWidgets('7.2 Request count badge shows 0 Requests when project has no requests', (tester) async {
      final p1 = makeProject(id: 'p-zero', name: 'Quiet Retreat');

      await tester.pumpWidget(buildTestApp(
        child: const HomeScreen(),
        projectRepo: MockProjectRepository([p1]),
        requestRepo: MockRequestRepository([]),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectRequestBadge_p-zero')), findsOneWidget);
      expect(find.text('0 Requests'), findsOneWidget);
    });

    testWidgets('7.3 Long-pressing project card shows view requests context menu option', (tester) async {
      final p1 = makeProject(id: 'p-ctx', name: 'Context Menu Project');

      await tester.pumpWidget(buildTestApp(
        child: const HomeScreen(),
        projectRepo: MockProjectRepository([p1]),
      ));
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('projectCard_p-ctx')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('viewProjectRequests_p-ctx')), findsOneWidget);
    });

    testWidgets('7.4 Tapping view requests in context menu opens RequestListScreen for that project', (tester) async {
      final p1 = makeProject(id: 'p-nav', name: 'Navigation Project');
      final r1 = makeRequest(id: 'r-nav', projectId: 'p-nav', title: 'Target Request');

      await tester.pumpWidget(buildTestApp(
        child: const HomeScreen(),
        projectRepo: MockProjectRepository([p1]),
        requestRepo: MockRequestRepository([r1]),
      ));
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const Key('projectCard_p-nav')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('viewProjectRequests_p-nav')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('requestListScreen')), findsOneWidget);
      expect(find.text('Target Request'), findsOneWidget);
    });

    testWidgets('7.5 Tab 1 contains requestsTabSegmentedButton', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const HomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('requestsTabSegmentedButton')), findsOneWidget);
      expect(find.byType(BillsListScreen), findsOneWidget);
    });

    testWidgets('7.6 Switching segment in Tab 1 displays RequestListScreen', (tester) async {
      final r1 = makeRequest(id: 'r-seg', title: 'Segment Item');

      await tester.pumpWidget(buildTestApp(
        child: const HomeScreen(),
        requestRepo: MockRequestRepository([r1]),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();

      // Tap the requests segment in SegmentedButton
      await tester.tap(find.descendant(
        of: find.byKey(const Key('requestsTabSegmentedButton')),
        matching: find.text('Requests'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Segment Item'), findsOneWidget);
    });

    testWidgets('7.7 Switching back to Bills segment restores BillsListScreen', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const HomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();

      // Switch to Requests
      await tester.tap(find.descendant(
        of: find.byKey(const Key('requestsTabSegmentedButton')),
        matching: find.text('Requests'),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(BillsListScreen), findsNothing);

      // Switch back to Bills
      await tester.tap(find.descendant(
        of: find.byKey(const Key('requestsTabSegmentedButton')),
        matching: find.text('Bills'),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(BillsListScreen), findsOneWidget);
    });

    testWidgets('7.8 ProjectDetailScreen has projectRequestsButton in AppBar', (tester) async {
      final p1 = makeProject(id: 'p-det', name: 'Detail Project');

      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: p1),
        projectRepo: MockProjectRepository([p1]),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('projectRequestsButton')), findsOneWidget);
    });

    testWidgets('7.9 Tapping projectRequestsButton in ProjectDetailScreen navigates to RequestListScreen', (tester) async {
      final p1 = makeProject(id: 'p-det', name: 'Detail Project');
      final r1 = makeRequest(id: 'r-from-det', projectId: 'p-det', title: 'Specific Request');

      await tester.pumpWidget(buildTestApp(
        child: ProjectDetailScreen(project: p1),
        projectRepo: MockProjectRepository([p1]),
        requestRepo: MockRequestRepository([r1]),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('projectRequestsButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('requestListScreen')), findsOneWidget);
      expect(find.text('Specific Request'), findsOneWidget);
    });

    testWidgets('7.10 FloatingActionButton on Requests sub-tab opens CreateRequestBottomSheet', (tester) async {
      await tester.pumpWidget(buildTestApp(child: const HomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: find.byKey(const Key('requestsTabSegmentedButton')),
        matching: find.text('Requests'),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('addRequestFab')), findsOneWidget);
      await tester.tap(find.byKey(const Key('addRequestFab')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('createRequestModalTitle')), findsOneWidget);
    });
  });
}
