import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/usecases/usecase.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_project_by_id_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/data/models/project_model.dart';
import 'package:shared_household_planner/features/projects/data/datasources/project_local_datasource.dart';
import 'package:shared_household_planner/features/projects/data/repositories/project_repository_impl.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/project_screen.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/create_project_screen.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';

// Fake datasource for repository testing
class FakeProjectLocalDataSource implements ProjectLocalDataSource {
  final Map<String, ProjectModel> _storage = {};
  bool shouldThrow = false;

  @override
  Future<ProjectModel> addProject(ProjectModel project) async {
    if (shouldThrow) throw Exception('DataSource error');
    _storage[project.id] = project;
    return project;
  }

  @override
  Future<List<ProjectModel>> getAllProjects() async {
    if (shouldThrow) throw Exception('DataSource error');
    return _storage.values.toList();
  }

  @override
  Future<ProjectModel> getProjectById(String id) async {
    if (shouldThrow) throw Exception('DataSource error');
    if (_storage.containsKey(id)) return _storage[id]!;
    throw Exception('Project not found');
  }

  @override
  Future<ProjectModel> updateProject(ProjectModel project) async {
    if (shouldThrow) throw Exception('DataSource error');
    if (_storage.containsKey(project.id)) {
      _storage[project.id] = project;
      return project;
    }
    throw Exception('Project not found');
  }

  @override
  Future<void> deleteProject(String id) async {
    if (shouldThrow) throw Exception('DataSource error');
    if (_storage.containsKey(id)) {
      _storage.remove(id);
      return;
    }
    throw Exception('Project not found');
  }
}

// Fake repository for usecase and bloc testing
class FakeProjectRepository implements ProjectRepository {
  final List<Project> _projects = [];
  bool shouldFail = false;

  @override
  Future<Either<Failure, Project>> create(Project project) async {
    if (shouldFail) return const Left(LocalFailure('Failed to create'));
    _projects.add(project);
    return Right(project);
  }

  @override
  Future<Either<Failure, List<Project>>> getAll() async {
    if (shouldFail) return const Left(LocalFailure('Failed to fetch'));
    return Right(List.from(_projects));
  }

  @override
  Future<Either<Failure, Project>> getById(String id) async {
    if (shouldFail) return const Left(LocalFailure('Failed to get'));
    final found = _projects.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Not found'),
    );
    return Right(found);
  }

  @override
  Future<Either<Failure, Project>> update(Project project) async {
    if (shouldFail) return const Left(LocalFailure('Failed to update'));
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      _projects[index] = project;
      return Right(project);
    }
    return const Left(LocalFailure('Project not found'));
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    if (shouldFail) return const Left(LocalFailure('Failed to delete'));
    _projects.removeWhere((p) => p.id == id);
    return const Right(null);
  }
}

class TestAppLocalizations extends AppLocalizations {
  TestAppLocalizations() : super(const Locale('en'));

  static const Map<String, String> _testStrings = {
    'projects': 'Projects',
    'no_projects': 'No projects yet',
    'create_project': 'Create Project',
    'edit_project': 'Edit Project',
    'delete_project': 'Delete Project',
    'project_name': 'Project Name',
    'project_name_example': 'e.g., Trip to Da Nang, Home Renovation',
    'description': 'Description',
    'description_example': 'e.g., Summer vacation 2026',
    'members': 'Members',
    'add_member': 'Add Member',
    'member_name': 'Member Name',
    'enter_name': 'Enter name',
    'save': 'Save',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'project_name_required': 'Project name is required',
    'min_1_member': 'At least 1 member is required',
    'delete_project_confirm': 'Are you sure you want to delete this project?',
  };

  @override
  String translate(String key) => _testStrings[key] ?? key;
}

class TestAppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const TestAppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async => TestAppLocalizations();

  @override
  bool shouldReload(TestAppLocalizationsDelegate old) => false;
}

void main() {
  final testDate = DateTime(2026, 9, 7, 10, 0);
  final testProject = Project(
    id: 'proj-1',
    name: 'Da Nang Trip',
    description: 'Vacation with friends',
    members: const ['An', 'Binh', 'Chi'],
    createdAt: testDate,
    updatedAt: testDate,
  );

  group('Project Entity & Model Tests', () {
    test('Project entity supports value equality', () {
      final p1 = Project(
        id: '1',
        name: 'Trip',
        description: 'Desc',
        members: const ['An'],
        createdAt: testDate,
        updatedAt: testDate,
      );
      final p2 = Project(
        id: '1',
        name: 'Trip',
        description: 'Desc',
        members: const ['An'],
        createdAt: testDate,
        updatedAt: testDate,
      );
      expect(p1, equals(p2));
    });

    test('Project copyWith updates fields correctly', () {
      final updated = testProject.copyWith(name: 'Hue Trip');
      expect(updated.name, 'Hue Trip');
      expect(updated.id, testProject.id);
      expect(updated.members, testProject.members);
    });

    test('ProjectModel serialization with List members', () {
      final model = ProjectModel.fromEntity(testProject);
      final json = model.toJson();
      expect(json['id'], 'proj-1');
      expect(json['name'], 'Da Nang Trip');
      expect(json['members'], ['An', 'Binh', 'Chi']);

      final fromJson = ProjectModel.fromJson(json);
      expect(fromJson.id, model.id);
      expect(fromJson.name, model.name);
      expect(fromJson.members, model.members);
    });

    test('ProjectModel handles SQLite JSON string members', () {
      final sqliteRow = {
        'id': 'proj-2',
        'name': 'Home Repair',
        'description': null,
        'members': jsonEncode(['Dung', 'Em']),
        'createdAt': testDate.toIso8601String(),
        'updatedAt': testDate.toIso8601String(),
      };

      final model = ProjectModel.fromJson(sqliteRow);
      expect(model.id, 'proj-2');
      expect(model.name, 'Home Repair');
      expect(model.members, ['Dung', 'Em']);
      expect(model.description, isNull);

      final sqliteMap = model.toSqliteMap();
      expect(sqliteMap['members'], isA<String>());
      expect(jsonDecode(sqliteMap['members'] as String), ['Dung', 'Em']);
    });
  });

  group('ProjectRepositoryImpl Tests', () {
    late FakeProjectLocalDataSource fakeDataSource;
    late ProjectRepositoryImpl repository;

    setUp(() {
      fakeDataSource = FakeProjectLocalDataSource();
      repository = ProjectRepositoryImpl(fakeDataSource);
    });

    test('create returns Right(Project) on success', () async {
      final result = await repository.create(testProject);
      expect(result.isRight(), true);
      result.fold((l) => fail('should be right'), (p) => expect(p.name, testProject.name));
    });

    test('create returns Left(Failure) on error', () async {
      fakeDataSource.shouldThrow = true;
      final result = await repository.create(testProject);
      expect(result.isLeft(), true);
    });

    test('getAll returns Right(List<Project>)', () async {
      await repository.create(testProject);
      final result = await repository.getAll();
      expect(result.isRight(), true);
      result.fold((l) => fail('should be right'), (list) => expect(list.length, 1));
    });

    test('update and delete work correctly', () async {
      await repository.create(testProject);
      final updated = testProject.copyWith(name: 'Updated Name');
      final updateResult = await repository.update(updated);
      expect(updateResult.isRight(), true);

      final deleteResult = await repository.delete(testProject.id);
      expect(deleteResult.isRight(), true);

      final allAfterDelete = await repository.getAll();
      allAfterDelete.fold((l) => fail('should be right'), (list) => expect(list.isEmpty, true));
    });
  });

  group('Project UseCases Tests', () {
    late FakeProjectRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeProjectRepository();
    });

    test('CreateProjectUseCase creates project', () async {
      final useCase = CreateProjectUseCase(fakeRepo);
      final result = await useCase(CreateProjectParams(project: testProject));
      expect(result.isRight(), true);
    });

    test('GetAllProjectsUseCase returns projects', () async {
      final createUseCase = CreateProjectUseCase(fakeRepo);
      final getAllUseCase = GetAllProjectsUseCase(fakeRepo);
      await createUseCase(CreateProjectParams(project: testProject));

      final result = await getAllUseCase(const NoParams());
      expect(result.isRight(), true);
      result.fold((l) => fail('should be right'), (list) => expect(list.length, 1));
    });

    test('GetProjectByIdUseCase, UpdateProjectUseCase, DeleteProjectUseCase', () async {
      await CreateProjectUseCase(fakeRepo)(CreateProjectParams(project: testProject));
      final getById = GetProjectByIdUseCase(fakeRepo);
      final update = UpdateProjectUseCase(fakeRepo);
      final delete = DeleteProjectUseCase(fakeRepo);

      final getRes = await getById(GetProjectByIdParams(id: testProject.id));
      expect(getRes.isRight(), true);

      final updateRes = await update(UpdateProjectParams(project: testProject.copyWith(name: 'New')));
      expect(updateRes.isRight(), true);

      final delRes = await delete(DeleteProjectParams(id: testProject.id));
      expect(delRes.isRight(), true);
    });
  });

  group('ProjectBloc Tests', () {
    late FakeProjectRepository fakeRepo;
    late ProjectBloc bloc;

    setUp(() {
      fakeRepo = FakeProjectRepository();
      bloc = ProjectBloc(
        createProjectUseCase: CreateProjectUseCase(fakeRepo),
        getAllProjectsUseCase: GetAllProjectsUseCase(fakeRepo),
        getProjectByIdUseCase: GetProjectByIdUseCase(fakeRepo),
        updateProjectUseCase: UpdateProjectUseCase(fakeRepo),
        deleteProjectUseCase: DeleteProjectUseCase(fakeRepo),
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is ProjectInitial', () {
      expect(bloc.state, isA<ProjectInitial>());
    });

    test('GetAllProjects emits Loading then Loaded', () async {
      bloc.add(const GetAllProjects());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ProjectLoading>(),
          isA<ProjectLoaded>(),
        ]),
      );
    });

    test('CreateProject adds project and reloads list', () async {
      bloc.add(CreateProject(testProject));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ProjectLoading>(),
          isA<ProjectLoaded>().having((s) => s.projects.length, 'projects count', 1),
        ]),
      );
    });

    test('DeleteProject removes project and reloads list', () async {
      await fakeRepo.create(testProject);
      bloc.add(DeleteProject(testProject.id));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ProjectLoading>(),
          isA<ProjectLoaded>().having((s) => s.projects.length, 'projects count', 0),
        ]),
      );
    });
  });

  group('Project UI Widget Tests', () {
    late FakeProjectRepository fakeRepo;
    late ProjectBloc bloc;

    setUp(() {
      fakeRepo = FakeProjectRepository();
      bloc = ProjectBloc(
        createProjectUseCase: CreateProjectUseCase(fakeRepo),
        getAllProjectsUseCase: GetAllProjectsUseCase(fakeRepo),
        getProjectByIdUseCase: GetProjectByIdUseCase(fakeRepo),
        updateProjectUseCase: UpdateProjectUseCase(fakeRepo),
        deleteProjectUseCase: DeleteProjectUseCase(fakeRepo),
      );
    });

    tearDown(() {
      bloc.close();
    });

    Widget createTestWidget(Widget child) {
      return BlocProvider<ProjectBloc>.value(
        value: bloc,
        child: MaterialApp(
          home: child,
          localizationsDelegates: const [
            TestAppLocalizationsDelegate(),
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('vi'),
          ],
        ),
      );
    }

    testWidgets('ProjectScreen displays empty message when no projects', (tester) async {
      await tester.pumpWidget(createTestWidget(const ProjectScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('No projects yet'), findsOneWidget);
    });

    testWidgets('CreateProjectScreen form validation and adding member', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(const CreateProjectScreen()));
      await tester.pumpAndSettle();

      final saveButton = find.byKey(const Key('saveProjectButton'));

      // Tap save without filling form -> validation error
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Project name is required'), findsOneWidget);

      // Enter project name
      await tester.enterText(find.byKey(const Key('projectNameField')), 'Da Nang Trip');
      await tester.pumpAndSettle();

      // Tap save without members -> requires member
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      expect(find.text('At least 1 member is required'), findsOneWidget);

      // Add members
      await tester.enterText(find.byKey(const Key('memberNameField')), 'Alice');
      await tester.tap(find.byKey(const Key('addMemberButton')));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.byKey(const Key('memberChip_0')), findsOneWidget);

      // Save project
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
    });
  });
}
