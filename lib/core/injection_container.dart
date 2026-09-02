import 'package:get_it/get_it.dart';
import 'package:shared_household_planner/features/split_bills/data/datasources/database_helper.dart';
import 'package:shared_household_planner/features/split_bills/data/datasources/local_bill_datasource.dart';
import 'package:shared_household_planner/features/split_bills/data/repositories/bill_repository_impl.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';

final getIt = GetIt.instance;

/// Dependency Injection Setup using GetIt
/// 
/// Registers all application dependencies as singletons:
/// - DatabaseHelper: Database access layer
/// - LocalBillDataSource: Data source for bills
/// - BillRepository: Repository interface implementation
/// - UseCases: Business logic (GetBills, AddBill)
/// - BillsBloc: State management for bills feature
/// 
/// Call [setupServiceLocator] in main() before runApp() to initialize all services.
Future<void> setupServiceLocator() async {
  // Register DatabaseHelper singleton
  getIt.registerSingleton<DatabaseHelper>(
    DatabaseHelper(),
  );

  // Initialize database and create tables
  final database = await getIt<DatabaseHelper>().database;

  // Register LocalBillDataSource with DatabaseHelper
  getIt.registerSingleton<LocalBillDataSource>(
    LocalBillDataSourceImpl(database),
  );

  // Register BillRepository with LocalBillDataSource
  getIt.registerSingleton<BillRepository>(
    BillRepositoryImpl(getIt<LocalBillDataSource>()),
  );

  // Register UseCases with BillRepository
  getIt.registerSingleton<GetBillsUseCase>(
    GetBillsUseCase(getIt<BillRepository>()),
  );

  getIt.registerSingleton<AddBillUseCase>(
    AddBillUseCase(getIt<BillRepository>()),
  );

  // Register BillsBloc with UseCase instances
  getIt.registerSingleton<BillsBloc>(
    BillsBloc(
      getBillsUseCase: getIt<GetBillsUseCase>(),
      addBillUseCase: getIt<AddBillUseCase>(),
    ),
  );
}
