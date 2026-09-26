import 'package:get_it/get_it.dart';
import 'package:shared_household_planner/features/split_bills/data/datasources/database_helper.dart';
import 'package:shared_household_planner/features/split_bills/data/datasources/local_bill_datasource.dart';
import 'package:shared_household_planner/features/split_bills/data/repositories/bill_repository_impl.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/projects/data/datasources/project_local_datasource.dart';
import 'package:shared_household_planner/features/projects/data/repositories/project_repository_impl.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_project_by_id_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/services/last_active_project_service.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/templates/data/datasources/bill_template_local_datasource.dart';
import 'package:shared_household_planner/features/templates/data/repositories/bill_template_repository_impl.dart';
import 'package:shared_household_planner/features/templates/domain/repositories/bill_template_repository.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/create_template_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/delete_template_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/get_suggested_templates_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/get_templates_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/record_template_usage_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/toggle_favorite_template_usecase.dart';
import 'package:shared_household_planner/features/templates/domain/usecases/update_template_usecase.dart';
import 'package:shared_household_planner/features/templates/presentation/bloc/bill_templates_bloc.dart';
import 'package:shared_household_planner/features/settlement/data/datasources/settlement_local_datasource.dart';
import 'package:shared_household_planner/features/settlement/data/repositories/settlement_repository_impl.dart';
import 'package:shared_household_planner/features/settlement/domain/repositories/settlement_repository.dart';
import 'package:shared_household_planner/features/settlement/domain/usecases/settlement_usecases.dart';
import 'package:shared_household_planner/features/settlement/presentation/bloc/settlement_bloc.dart';
import 'package:shared_household_planner/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_household_planner/features/auth/domain/repositories/cloud_sync_repository.dart';
import 'package:shared_household_planner/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:shared_household_planner/features/auth/data/repositories/firestore_cloud_sync_repository.dart';
import 'package:shared_household_planner/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_household_planner/features/sync/domain/services/network_connectivity_service.dart';
import 'package:shared_household_planner/features/sync/domain/services/sync_service.dart';
import 'package:shared_household_planner/features/sync/presentation/bloc/sync_bloc.dart';


final getIt = GetIt.instance;

/// Dependency Injection Setup using GetIt
/// 
/// Registers all application dependencies as singletons:
/// - DatabaseHelper: Database access layer
/// - LocalBillDataSource: Data source for bills
/// - BillRepository: Repository interface implementation
/// - UseCases: Business logic (GetBills, AddBill)
/// - BillsBloc: State management for bills feature
/// - ProjectLocalDataSource: Data source for projects
/// - ProjectRepository: Repository interface implementation
/// - UseCases: Business logic for projects
/// - ProjectBloc: State management for projects feature
/// 
/// Call [setupServiceLocator] in main() before runApp() to initialize all services.
Future<void> setupServiceLocator() async {
  // Register DatabaseHelper singleton if not registered
  if (!getIt.isRegistered<DatabaseHelper>()) {
    getIt.registerSingleton<DatabaseHelper>(
      DatabaseHelper(),
    );
  }

  // Initialize database and create tables
  final database = await getIt<DatabaseHelper>().database;

  // Register LocalBillDataSource with DatabaseHelper
  if (!getIt.isRegistered<LocalBillDataSource>()) {
    getIt.registerSingleton<LocalBillDataSource>(
      LocalBillDataSourceImpl(database),
    );
  }

  // Register BillRepository with LocalBillDataSource
  if (!getIt.isRegistered<BillRepository>()) {
    getIt.registerSingleton<BillRepository>(
      BillRepositoryImpl(getIt<LocalBillDataSource>()),
    );
  }

  // Register UseCases with BillRepository
  if (!getIt.isRegistered<GetBillsUseCase>()) {
    getIt.registerSingleton<GetBillsUseCase>(
      GetBillsUseCase(getIt<BillRepository>()),
    );
  }

  if (!getIt.isRegistered<AddBillUseCase>()) {
    getIt.registerSingleton<AddBillUseCase>(
      AddBillUseCase(getIt<BillRepository>()),
    );
  }

  // Register BillsBloc with UseCase instances
  if (!getIt.isRegistered<BillsBloc>()) {
    getIt.registerSingleton<BillsBloc>(
      BillsBloc(
        getBillsUseCase: getIt<GetBillsUseCase>(),
        addBillUseCase: getIt<AddBillUseCase>(),
      ),
    );
  }

  // Register ProjectLocalDataSource
  if (!getIt.isRegistered<ProjectLocalDataSource>()) {
    getIt.registerSingleton<ProjectLocalDataSource>(
      ProjectLocalDataSourceImpl(database),
    );
  }

  // Register ProjectRepository
  if (!getIt.isRegistered<ProjectRepository>()) {
    getIt.registerSingleton<ProjectRepository>(
      ProjectRepositoryImpl(getIt<ProjectLocalDataSource>()),
    );
  }

  // Register Project UseCases
  if (!getIt.isRegistered<CreateProjectUseCase>()) {
    getIt.registerSingleton<CreateProjectUseCase>(
      CreateProjectUseCase(getIt<ProjectRepository>()),
    );
  }

  if (!getIt.isRegistered<GetAllProjectsUseCase>()) {
    getIt.registerSingleton<GetAllProjectsUseCase>(
      GetAllProjectsUseCase(getIt<ProjectRepository>()),
    );
  }

  if (!getIt.isRegistered<GetProjectByIdUseCase>()) {
    getIt.registerSingleton<GetProjectByIdUseCase>(
      GetProjectByIdUseCase(getIt<ProjectRepository>()),
    );
  }

  if (!getIt.isRegistered<UpdateProjectUseCase>()) {
    getIt.registerSingleton<UpdateProjectUseCase>(
      UpdateProjectUseCase(getIt<ProjectRepository>()),
    );
  }

  if (!getIt.isRegistered<DeleteProjectUseCase>()) {
    getIt.registerSingleton<DeleteProjectUseCase>(
      DeleteProjectUseCase(getIt<ProjectRepository>()),
    );
  }

  // Register ProjectBloc
  if (!getIt.isRegistered<ProjectBloc>()) {
    getIt.registerSingleton<ProjectBloc>(
      ProjectBloc(
        createProjectUseCase: getIt<CreateProjectUseCase>(),
        getAllProjectsUseCase: getIt<GetAllProjectsUseCase>(),
        getProjectByIdUseCase: getIt<GetProjectByIdUseCase>(),
        updateProjectUseCase: getIt<UpdateProjectUseCase>(),
        deleteProjectUseCase: getIt<DeleteProjectUseCase>(),
      ),
    );
  }

  // ────────────────────────────────────────
  // Bill Templates Feature Registration
  // ────────────────────────────────────────
  if (!getIt.isRegistered<BillTemplateLocalDataSource>()) {
    getIt.registerSingleton<BillTemplateLocalDataSource>(
      BillTemplateLocalDataSourceImpl(database),
    );
  }

  if (!getIt.isRegistered<BillTemplateRepository>()) {
    getIt.registerSingleton<BillTemplateRepository>(
      BillTemplateRepositoryImpl(getIt<BillTemplateLocalDataSource>()),
    );
  }

  if (!getIt.isRegistered<GetTemplatesUseCase>()) {
    getIt.registerSingleton<GetTemplatesUseCase>(
      GetTemplatesUseCase(getIt<BillTemplateRepository>()),
    );
  }

  if (!getIt.isRegistered<CreateTemplateUseCase>()) {
    getIt.registerSingleton<CreateTemplateUseCase>(
      CreateTemplateUseCase(getIt<BillTemplateRepository>()),
    );
  }

  if (!getIt.isRegistered<UpdateTemplateUseCase>()) {
    getIt.registerSingleton<UpdateTemplateUseCase>(
      UpdateTemplateUseCase(getIt<BillTemplateRepository>()),
    );
  }

  if (!getIt.isRegistered<DeleteTemplateUseCase>()) {
    getIt.registerSingleton<DeleteTemplateUseCase>(
      DeleteTemplateUseCase(getIt<BillTemplateRepository>()),
    );
  }

  if (!getIt.isRegistered<ToggleFavoriteTemplateUseCase>()) {
    getIt.registerSingleton<ToggleFavoriteTemplateUseCase>(
      ToggleFavoriteTemplateUseCase(getIt<BillTemplateRepository>()),
    );
  }

  if (!getIt.isRegistered<RecordTemplateUsageUseCase>()) {
    getIt.registerSingleton<RecordTemplateUsageUseCase>(
      RecordTemplateUsageUseCase(getIt<BillTemplateRepository>()),
    );
  }

  if (!getIt.isRegistered<GetSuggestedTemplatesUseCase>()) {
    getIt.registerSingleton<GetSuggestedTemplatesUseCase>(
      GetSuggestedTemplatesUseCase(getIt<BillTemplateRepository>()),
    );
  }

  if (!getIt.isRegistered<BillTemplatesBloc>()) {
    getIt.registerSingleton<BillTemplatesBloc>(
      BillTemplatesBloc(
        getTemplatesUseCase: getIt<GetTemplatesUseCase>(),
        createTemplateUseCase: getIt<CreateTemplateUseCase>(),
        updateTemplateUseCase: getIt<UpdateTemplateUseCase>(),
        deleteTemplateUseCase: getIt<DeleteTemplateUseCase>(),
        toggleFavoriteTemplateUseCase: getIt<ToggleFavoriteTemplateUseCase>(),
        recordTemplateUsageUseCase: getIt<RecordTemplateUsageUseCase>(),
        getSuggestedTemplatesUseCase: getIt<GetSuggestedTemplatesUseCase>(),
      ),
    );
  }

  // ────────────────────────────────────────
  // Settlement Logs Feature Registration
  // ────────────────────────────────────────
  if (!getIt.isRegistered<SettlementLocalDataSource>()) {
    getIt.registerSingleton<SettlementLocalDataSource>(
      SettlementLocalDataSourceImpl(database),
    );
  }

  if (!getIt.isRegistered<SettlementRepository>()) {
    getIt.registerSingleton<SettlementRepository>(
      SettlementRepositoryImpl(getIt<SettlementLocalDataSource>()),
    );
  }

  if (!getIt.isRegistered<GetSettlementLogsUseCase>()) {
    getIt.registerSingleton<GetSettlementLogsUseCase>(
      GetSettlementLogsUseCase(getIt<SettlementRepository>()),
    );
  }

  if (!getIt.isRegistered<CreateSettlementLogUseCase>()) {
    getIt.registerSingleton<CreateSettlementLogUseCase>(
      CreateSettlementLogUseCase(getIt<SettlementRepository>()),
    );
  }

  if (!getIt.isRegistered<UpdateSettlementLogUseCase>()) {
    getIt.registerSingleton<UpdateSettlementLogUseCase>(
      UpdateSettlementLogUseCase(getIt<SettlementRepository>()),
    );
  }

  if (!getIt.isRegistered<DeleteSettlementLogUseCase>()) {
    getIt.registerSingleton<DeleteSettlementLogUseCase>(
      DeleteSettlementLogUseCase(getIt<SettlementRepository>()),
    );
  }

  if (!getIt.isRegistered<MarkAsPaidUseCase>()) {
    getIt.registerSingleton<MarkAsPaidUseCase>(
      MarkAsPaidUseCase(getIt<SettlementRepository>()),
    );
  }

  if (!getIt.isRegistered<UndoMarkAsPaidUseCase>()) {
    getIt.registerSingleton<UndoMarkAsPaidUseCase>(
      UndoMarkAsPaidUseCase(getIt<SettlementRepository>()),
    );
  }

  if (!getIt.isRegistered<SettlementBloc>()) {
    getIt.registerSingleton<SettlementBloc>(
      SettlementBloc(
        getSettlementLogsUseCase: getIt<GetSettlementLogsUseCase>(),
        createSettlementLogUseCase: getIt<CreateSettlementLogUseCase>(),
        updateSettlementLogUseCase: getIt<UpdateSettlementLogUseCase>(),
        deleteSettlementLogUseCase: getIt<DeleteSettlementLogUseCase>(),
        markAsPaidUseCase: getIt<MarkAsPaidUseCase>(),
        undoMarkAsPaidUseCase: getIt<UndoMarkAsPaidUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<LastActiveProjectService>()) {
    getIt.registerSingleton<LastActiveProjectService>(
      LastActiveProjectService.instance,
    );
  }

  // ── Auth & Cloud Sync ──────────────────────────────────────────────────
  if (!getIt.isRegistered<AuthRepository>()) {
    getIt.registerSingleton<AuthRepository>(
      FirebaseAuthRepository(),
    );
  }

  if (!getIt.isRegistered<CloudSyncRepository>()) {
    getIt.registerSingleton<CloudSyncRepository>(
      FirestoreCloudSyncRepository(),
    );
  }

  if (!getIt.isRegistered<AuthBloc>()) {
    getIt.registerSingleton<AuthBloc>(
      AuthBloc(authRepository: getIt<AuthRepository>()),
    );
  }

  // ── Sync Engine ─────────────────────────────────────────────────────────
  if (!getIt.isRegistered<NetworkConnectivityService>()) {
    getIt.registerSingleton<NetworkConnectivityService>(
      DefaultNetworkConnectivityService(),
    );
  }

  SharedPreferences? sharedPreferences;
  try {
    sharedPreferences = await SharedPreferences.getInstance();
  } catch (_) {}

  if (!getIt.isRegistered<SyncService>()) {
    getIt.registerSingleton<SyncService>(
      SyncService(
        cloudSyncRepository: getIt<CloudSyncRepository>(),
        connectivityService: getIt<NetworkConnectivityService>(),
        sharedPreferences: sharedPreferences,
      ),
    );
  }

  if (!getIt.isRegistered<SyncBloc>()) {
    getIt.registerSingleton<SyncBloc>(
      SyncBloc(syncService: getIt<SyncService>()),
    );
  }
}
