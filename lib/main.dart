import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/injection_container.dart';
import 'core/localization/app_localizations.dart';
import 'core/language/language_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/split_bills/domain/repositories/bill_repository.dart';
import 'features/split_bills/presentation/bloc/bills_bloc.dart';
import 'features/split_bills/presentation/pages/bills_list_screen.dart';
import 'features/split_bills/presentation/pages/add_bill_screen.dart';
import 'features/projects/domain/repositories/project_repository.dart';
import 'features/projects/presentation/bloc/project_bloc.dart';
import 'features/projects/presentation/pages/project_screen.dart';
import 'features/projects/presentation/pages/create_project_screen.dart';
import 'features/home/presentation/pages/home_screen.dart';
import 'features/templates/domain/repositories/bill_template_repository.dart';
import 'features/templates/presentation/bloc/bill_templates_bloc.dart';
import 'features/settlement/domain/repositories/settlement_repository.dart';
import 'features/settlement/presentation/bloc/settlement_bloc.dart';
import 'features/settlement/presentation/pages/payment_history_screen.dart';
import 'features/onboarding/domain/services/onboarding_service.dart';
import 'features/onboarding/presentation/pages/onboarding_screen.dart';
import 'core/widgets/global_keyboard_dismiss.dart';

final themeProvider = ThemeProvider();
final languageProvider = LanguageProvider();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check first launch — before loading saved language, so we can default to EN
  final hasSeenOnboarding = await OnboardingService.instance.hasSeenOnboarding();

  await themeProvider.loadTheme();

  // Default to English on very first launch (no saved language)
  if (hasSeenOnboarding) {
    await languageProvider.loadLanguage();
  }
  // On first launch: languageProvider already defaults to 'en' in constructor

  await setupServiceLocator();
  getIt<ProjectBloc>().add(const GetAllProjects());
  getIt<BillsBloc>().add(const GetBillsEvent());
  getIt<BillTemplatesBloc>().add(const LoadTemplatesEvent());
  getIt<SettlementBloc>().add(const LoadSettlementsEvent());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => themeProvider),
        ChangeNotifierProvider<LanguageProvider>(create: (_) => languageProvider),
      ],
      child: MyApp(showOnboarding: !hasSeenOnboarding),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  const MyApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, _) {
        return MultiRepositoryProvider(
          providers: [
            RepositoryProvider<ProjectRepository>.value(
              value: getIt<ProjectRepository>(),
            ),
            RepositoryProvider<BillRepository>.value(
              value: getIt<BillRepository>(),
            ),
            RepositoryProvider<BillTemplateRepository>.value(
              value: getIt<BillTemplateRepository>(),
            ),
            RepositoryProvider<SettlementRepository>.value(
              value: getIt<SettlementRepository>(),
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<BillsBloc>.value(
                value: getIt<BillsBloc>(),
              ),
              BlocProvider<ProjectBloc>.value(
                value: getIt<ProjectBloc>(),
              ),
              BlocProvider<BillTemplatesBloc>.value(
                value: getIt<BillTemplatesBloc>(),
              ),
              BlocProvider<SettlementBloc>.value(
                value: getIt<SettlementBloc>(),
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
              builder: (context, child) => GlobalKeyboardDismiss(child: child),
              home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
              routes: {
                '/bills': (context) => const BillsListScreen(),
                '/add-bill': (context) => const AddBillScreen(),
                '/projects': (context) => const ProjectScreen(),
                '/create-project': (context) => const CreateProjectScreen(),
                '/payment-history': (context) => const PaymentHistoryScreen(),
              },
            ),
          ),
        );
      },
    );
  }
}
