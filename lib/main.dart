import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/injection_container.dart';
import 'core/localization/app_localizations.dart';
import 'core/language/language_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/split_bills/presentation/bloc/bills_bloc.dart';
import 'features/split_bills/presentation/pages/bills_list_screen.dart';
import 'features/split_bills/presentation/pages/add_bill_screen.dart';
import 'features/projects/presentation/bloc/project_bloc.dart';
import 'features/projects/presentation/pages/project_screen.dart';
import 'features/projects/presentation/pages/create_project_screen.dart';
import 'features/home/presentation/pages/home_screen.dart';

final themeProvider = ThemeProvider();
final languageProvider = LanguageProvider();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeProvider.loadTheme();
  await languageProvider.loadLanguage();
  await setupServiceLocator();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => themeProvider),
        ChangeNotifierProvider<LanguageProvider>(create: (_) => languageProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, _) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<BillsBloc>.value(
              value: getIt<BillsBloc>(),
            ),
            BlocProvider<ProjectBloc>.value(
              value: getIt<ProjectBloc>(),
            ),
          ],
          child: MaterialApp(
            title: 'Shared Household Planner',
            locale: languageProvider.currentLocale,
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
            home: const HomeScreen(),
            routes: {
              '/bills': (context) => const BillsListScreen(),
              '/add-bill': (context) => const AddBillScreen(),
              '/projects': (context) => const ProjectScreen(),
              '/create-project': (context) => const CreateProjectScreen(),
            },
          ),
        );
      },
    );
  }
}
