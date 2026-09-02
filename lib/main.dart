import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/split_bills/data/datasources/database_helper.dart';
import 'features/split_bills/data/datasources/local_bill_datasource.dart';
import 'features/split_bills/data/repositories/bill_repository_impl.dart';
import 'features/split_bills/domain/repositories/bill_repository.dart';
import 'features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'features/split_bills/presentation/bloc/bills_bloc.dart';

final getIt = GetIt.instance;

void setupServiceLocator() async {
  // Database
  final database = await DatabaseHelper().database;
  
  // Data Sources
  getIt.registerSingleton<LocalBillDataSource>(
    LocalBillDataSourceImpl(database),
  );

  // Repositories
  getIt.registerSingleton<BillRepository>(
    BillRepositoryImpl(getIt<LocalBillDataSource>()),
  );

  // Use Cases
  getIt.registerSingleton<GetBillsUseCase>(
    GetBillsUseCase(getIt<BillRepository>()),
  );
  getIt.registerSingleton<AddBillUseCase>(
    AddBillUseCase(getIt<BillRepository>()),
  );

  // BLoCs
  getIt.registerSingleton<BillsBloc>(
    BillsBloc(
      getBillsUseCase: getIt<GetBillsUseCase>(),
      addBillUseCase: getIt<AddBillUseCase>(),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ThemeProvider();
  await themeProvider.loadTheme();
  await setupServiceLocator();
  
  runApp(
    ChangeNotifierProvider<ThemeProvider>(
      create: (_) => themeProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Shared Household Planner',
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('vi'),
          ],
          theme: themeProvider.currentTheme,
          home: BlocProvider<BillsBloc>(
            create: (_) => getIt<BillsBloc>(),
            child: const MyHomePage(title: 'Shared Household Planner'),
          ),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.translate('app_name')),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return IconButton(
                    icon: Icon(
                      themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: Colors.white,
                    ),
                    onPressed: () => themeProvider.toggleTheme(),
                    tooltip: themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              appLocalizations.translate('app_name'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Text(
              'Shared Household Planner',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BlocProvider<BillsBloc>.value(
                      value: getIt<BillsBloc>(),
                      child: const BillsListScreen(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.receipt),
              label: Text(appLocalizations.translate('split_bills')),
            ),
          ],
        ),
      ),
    );
  }
}

// Import BillsListScreen at the end
import 'features/split_bills/presentation/pages/bills_list_screen.dart';
