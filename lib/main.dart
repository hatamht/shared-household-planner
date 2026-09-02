import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/injection_container.dart';
import 'core/localization/app_localizations.dart';
import 'core/language/language_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/split_bills/presentation/bloc/bills_bloc.dart';
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
        return BlocProvider<BillsBloc>.value(
          value: getIt<BillsBloc>(),
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
          ),
        );
      },
    );
  }
}
