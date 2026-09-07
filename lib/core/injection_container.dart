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
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';

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
}
