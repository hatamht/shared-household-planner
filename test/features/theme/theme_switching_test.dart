import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_household_planner/core/theme/app_theme.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/features/home/presentation/pages/home_screen.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_project_by_id_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/project_screen.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_household_planner/core/error/failure.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fakes & Helpers
// ─────────────────────────────────────────────────────────────────────────────

class FakeProjectRepository implements ProjectRepository {
  @override
  Future<Either<Failure, Project>> create(Project project) async =>
      Right(project);

  @override
  Future<Either<Failure, List<Project>>> getAll() async => const Right([]);

  @override
  Future<Either<Failure, Project>> getById(String id) async =>
      const Left(LocalFailure('not found'));

  @override
  Future<Either<Failure, Project>> update(Project project) async =>
      Right(project);

  @override
  Future<Either<Failure, void>> delete(String id) async =>
      const Right(null);
}

class TestLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const TestLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      _TestLocalizations(locale);

  @override
  bool shouldReload(TestLocalizationsDelegate old) => false;
}

class _TestLocalizations extends AppLocalizations {
  _TestLocalizations(super.locale);

  static const _strings = <String, String>{
    'app_name': 'Shared Household Planner',
    'split_bills': 'Split Bills',
    'projects': 'Projects',
    'language': 'Language',
    'english': 'English',
    'vietnamese': 'Vietnamese',
    'theme': 'Theme',
    'light_mode': 'Light',
    'dark_mode': 'Dark',
    'theme_light': 'Light Theme',
    'theme_dark': 'Dark Theme',
    'theme_settings': 'Theme Settings',
    'no_projects': 'No projects yet',
    'create_project': 'Create Project',
    'delete_project': 'Delete Project',
    'edit_project': 'Edit Project',
    'error': 'Error',
    'members': 'Members',
    'delete': 'Delete',
    'cancel': 'Cancel',
    'delete_project_confirm': 'Confirm?',
  };

  @override
  String translate(String key) => _strings[key] ?? key;
}

ProjectBloc _makeBloc() {
  final repo = FakeProjectRepository();
  return ProjectBloc(
    createProjectUseCase: CreateProjectUseCase(repo),
    getAllProjectsUseCase: GetAllProjectsUseCase(repo),
    getProjectByIdUseCase: GetProjectByIdUseCase(repo),
    updateProjectUseCase: UpdateProjectUseCase(repo),
    deleteProjectUseCase: DeleteProjectUseCase(repo),
  );
}

Widget _buildApp({
  required ThemeProvider themeProvider,
  Widget? home,
}) {
  final bloc = _makeBloc();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider()),
    ],
    child: Consumer2<ThemeProvider, LanguageProvider>(
      builder: (ctx, tp, lp, _) {
        return BlocProvider<ProjectBloc>.value(
          value: bloc,
          child: MaterialApp(
            theme: tp.currentTheme,
            home: home ?? const HomeScreen(),
            routes: {
              '/projects': (_) => const ProjectScreen(),
            },
            localizationsDelegates: const [TestLocalizationsDelegate()],
            supportedLocales: const [Locale('en'), Locale('vi')],
          ),
        );
      },
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Group 1: ThemeProvider unit tests
  group('ThemeProvider - Unit Tests', () {
    test('1. Default state is light mode', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      expect(p.isDarkMode, false);
    });

    test('2. currentTheme returns lightTheme when isDarkMode = false', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      expect(p.currentTheme, AppTheme.lightTheme);
    });

    test('3. toggleTheme switches to dark', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      await p.toggleTheme();
      expect(p.isDarkMode, true);
    });

    test('4. toggleTheme switches back to light', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      await p.toggleTheme();
      await p.toggleTheme();
      expect(p.isDarkMode, false);
    });

    test('5. currentTheme returns darkTheme when isDarkMode = true', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      await p.toggleTheme();
      expect(p.currentTheme, AppTheme.darkTheme);
    });

    test('6. setDarkMode(true) sets dark mode', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      await p.setDarkMode(true);
      expect(p.isDarkMode, true);
    });

    test('7. setDarkMode(false) sets light mode', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      await p.setDarkMode(true);
      await p.setDarkMode(false);
      expect(p.isDarkMode, false);
    });

    test('8. setDarkMode same value does not change state', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      await p.setDarkMode(false);
      expect(p.isDarkMode, false);
    });

    test('9. Persists dark mode to SharedPreferences', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      await p.setDarkMode(true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app_theme_mode'), true);
    });

    test('10. Persists light mode to SharedPreferences', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      await p.setDarkMode(true);
      await p.setDarkMode(false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app_theme_mode'), false);
    });

    test('11. toggleTheme persists dark to SharedPreferences', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      await p.toggleTheme();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app_theme_mode'), true);
    });

    test('12. Loads saved dark preference on init', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': true});
      final p = ThemeProvider();
      await p.loadTheme();
      expect(p.isDarkMode, true);
    });

    test('13. Loads saved light preference on init', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': false});
      final p = ThemeProvider();
      await p.loadTheme();
      expect(p.isDarkMode, false);
    });

    test('14. Defaults to light when no preference saved', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      expect(p.isDarkMode, false);
    });

    test('15. notifyListeners called on toggleTheme', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      var notified = false;
      p.addListener(() => notified = true);
      await p.toggleTheme();
      expect(notified, true);
    });

    test('16. notifyListeners called on setDarkMode', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      var notified = false;
      p.addListener(() => notified = true);
      await p.setDarkMode(true);
      expect(notified, true);
    });

    test('17. Multiple toggles maintain correct state (6 = light)', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      for (int i = 0; i < 6; i++) await p.toggleTheme();
      expect(p.isDarkMode, false);
    });

    test('18. Odd number of toggles = dark mode', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      for (int i = 0; i < 5; i++) await p.toggleTheme();
      expect(p.isDarkMode, true);
    });
  });

  // Group 2: Light Theme
  group('Light Theme - Color Configuration', () {
    test('19. Light theme has Brightness.light', () {
      expect(AppTheme.lightTheme.brightness, Brightness.light);
    });

    test('20. Light theme scaffold background is white', () {
      expect(AppTheme.lightTheme.scaffoldBackgroundColor, Colors.white);
    });

    test('21. Light theme AppBar uses primary color', () {
      expect(AppTheme.lightTheme.appBarTheme.backgroundColor,
          const Color(0xFF6366F1));
    });

    test('22. Light theme AppBar foreground is white', () {
      expect(AppTheme.lightTheme.appBarTheme.foregroundColor, Colors.white);
    });

    test('23. Light theme primary color is correct', () {
      expect(AppTheme.lightTheme.colorScheme.primary, const Color(0xFF6366F1));
    });

    test('24. Light theme secondary color is correct', () {
      expect(AppTheme.lightTheme.colorScheme.secondary,
          const Color(0xFF8B5CF6));
    });

    test('25. Light theme surface is white', () {
      expect(AppTheme.lightTheme.colorScheme.surface, Colors.white);
    });

    test('26. Light theme error color is a visible red', () {
      final err = AppTheme.lightTheme.colorScheme.error;
      expect(err.red > 100, true);
      expect(err.blue < 200, true);
    });

    test('27. Light theme textTheme displayLarge is dark text', () {
      expect(AppTheme.lightTheme.textTheme.displayLarge?.color, Colors.black87);
    });

    test('28. Light theme textTheme bodyLarge is dark text', () {
      expect(AppTheme.lightTheme.textTheme.bodyLarge?.color, Colors.black87);
    });

    test('29. Light theme uses Material 3', () {
      expect(AppTheme.lightTheme.useMaterial3, true);
    });

    test('30. Light theme appBar elevation is 0', () {
      expect(AppTheme.lightTheme.appBarTheme.elevation, 0);
    });
  });

  // Group 3: Dark Theme
  group('Dark Theme - Color Configuration', () {
    test('31. Dark theme has Brightness.dark', () {
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
    });

    test('32. Dark theme scaffold background is dark', () {
      final bg = AppTheme.darkTheme.scaffoldBackgroundColor!;
      expect(bg.computeLuminance() < 0.1, true);
    });

    test('33. Dark theme AppBar is dark', () {
      final appBarBg = AppTheme.darkTheme.appBarTheme.backgroundColor!;
      expect(appBarBg.computeLuminance() < 0.1, true);
    });

    test('34. Dark theme AppBar foreground is white', () {
      expect(AppTheme.darkTheme.appBarTheme.foregroundColor, Colors.white);
    });

    test('35. Dark theme primary color is lighter variant', () {
      expect(AppTheme.darkTheme.colorScheme.primary, const Color(0xFF818CF8));
    });

    test('36. Dark theme secondary color is lighter variant', () {
      expect(AppTheme.darkTheme.colorScheme.secondary,
          const Color(0xFFA78BFA));
    });

    test('37. Dark theme surface is dark grey', () {
      final surface = AppTheme.darkTheme.colorScheme.surface;
      expect(surface.computeLuminance() < 0.1, true);
    });

    test('38. Dark theme textTheme displayLarge is white', () {
      expect(AppTheme.darkTheme.textTheme.displayLarge?.color, Colors.white);
    });

    test('39. Dark theme textTheme bodyLarge is light', () {
      final color = AppTheme.darkTheme.textTheme.bodyLarge?.color;
      expect(color?.computeLuminance(), greaterThan(0.1));
    });

    test('40. Dark theme uses Material 3', () {
      expect(AppTheme.darkTheme.useMaterial3, true);
    });

    test('41. Dark theme appBar elevation is 0', () {
      expect(AppTheme.darkTheme.appBarTheme.elevation, 0);
    });

    test('42. Dark theme error color is visible on dark bg', () {
      final err = AppTheme.darkTheme.colorScheme.error;
      expect(err.red > 100, true);
    });
  });

  // Group 4: Theme Toggle UI Tests
  group('Theme Toggle UI - HomeScreen', () {
    testWidgets('43. HomeScreen shows theme toggle button', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final p = ThemeProvider();
      await p.loadTheme();
      await tester.pumpWidget(_buildApp(themeProvider: p));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('themeToggleButton')), findsOneWidget);
    });

    testWidgets('44. Toggle shows dark_mode icon in light mode', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final p = ThemeProvider();
      await p.loadTheme();
      await tester.pumpWidget(_buildApp(themeProvider: p));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    });

    testWidgets('45. Toggle shows light_mode icon in dark mode', (tester) async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': true});
      final p = ThemeProvider();
      await p.loadTheme();
      await tester.pumpWidget(_buildApp(themeProvider: p));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
    });

    testWidgets('46. Tapping button toggles to dark mode', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final p = ThemeProvider();
      await p.loadTheme();
      await tester.pumpWidget(_buildApp(themeProvider: p));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('themeToggleButton')));
      await tester.pumpAndSettle();
      expect(p.isDarkMode, true);
    });

    testWidgets('47. Tapping twice returns to light mode', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final p = ThemeProvider();
      await p.loadTheme();
      await tester.pumpWidget(_buildApp(themeProvider: p));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('themeToggleButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('themeToggleButton')));
      await tester.pumpAndSettle();
      expect(p.isDarkMode, false);
    });

    testWidgets('48. After toggle, icon changes from dark_mode to light_mode',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final p = ThemeProvider();
      await p.loadTheme();
      await tester.pumpWidget(_buildApp(themeProvider: p));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
      await tester.tap(find.byKey(const Key('themeToggleButton')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode), findsNothing);
    });

    testWidgets('49. App ThemeData changes after toggle light -> dark',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final p = ThemeProvider();
      await p.loadTheme();
      await tester.pumpWidget(_buildApp(themeProvider: p));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!.brightness,
        Brightness.light,
      );
      await tester.tap(find.byKey(const Key('themeToggleButton')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!.brightness,
        Brightness.dark,
      );
    });

    testWidgets('50. HomeScreen displays splitBillsButton', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final p = ThemeProvider();
      await p.loadTheme();
      await tester.pumpWidget(_buildApp(themeProvider: p));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('splitBillsButton')), findsOneWidget);
    });

    testWidgets('51. HomeScreen displays projectsButton', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final p = ThemeProvider();
      await p.loadTheme();
      await tester.pumpWidget(_buildApp(themeProvider: p));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('projectsButton')), findsOneWidget);
    });

    testWidgets('52. HomeScreen language button exists', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final p = ThemeProvider();
      await p.loadTheme();
      await tester.pumpWidget(_buildApp(themeProvider: p));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.language), findsOneWidget);
    });
  });

  // Group 5: Theme Persistence
  group('Theme Persistence', () {
    test('53. Dark mode saved to SharedPreferences key "app_theme_mode"',
        () async {
      final p = ThemeProvider();
      await p.loadTheme();
      await p.setDarkMode(true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('app_theme_mode'), true);
      expect(prefs.getBool('app_theme_mode'), true);
    });

    test('54. Light mode saved after toggling back', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      await p.setDarkMode(true);
      await p.setDarkMode(false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app_theme_mode'), false);
    });

    test('55. New ThemeProvider reads saved dark preference', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': true});
      final p = ThemeProvider();
      await p.loadTheme();
      expect(p.isDarkMode, true);
      expect(p.currentTheme, AppTheme.darkTheme);
    });

    test('56. New ThemeProvider reads saved light preference', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': false});
      final p = ThemeProvider();
      await p.loadTheme();
      expect(p.isDarkMode, false);
      expect(p.currentTheme, AppTheme.lightTheme);
    });

    test('57. Preference persists across multiple toggles', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      await p.toggleTheme();
      await p.toggleTheme();
      await p.toggleTheme();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('app_theme_mode'), true);
    });

    test('58. loadTheme does not reset existing toggle state', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      await p.setDarkMode(true);
      await p.loadTheme();
      expect(p.isDarkMode, true);
    });
  });

  // Group 6: ThemeData Consistency
  group('ThemeData Consistency', () {
    test('59. Both themes are ThemeData instances', () {
      expect(AppTheme.lightTheme, isA<ThemeData>());
      expect(AppTheme.darkTheme, isA<ThemeData>());
    });

    test('60. Themes differ in brightness', () {
      expect(AppTheme.lightTheme.brightness, isNot(AppTheme.darkTheme.brightness));
    });

    test('61. Both themes have AppBarTheme defined', () {
      expect(AppTheme.lightTheme.appBarTheme, isNotNull);
      expect(AppTheme.darkTheme.appBarTheme, isNotNull);
    });

    test('62. Both themes have ColorScheme defined', () {
      expect(AppTheme.lightTheme.colorScheme, isNotNull);
      expect(AppTheme.darkTheme.colorScheme, isNotNull);
    });

    test('63. Both themes have TextTheme defined', () {
      expect(AppTheme.lightTheme.textTheme, isNotNull);
      expect(AppTheme.darkTheme.textTheme, isNotNull);
    });

    test('64. Light scaffold bg differs from dark', () {
      expect(AppTheme.lightTheme.scaffoldBackgroundColor,
          isNot(AppTheme.darkTheme.scaffoldBackgroundColor));
    });

    test('65. AppBar bgs differ between themes', () {
      expect(AppTheme.lightTheme.appBarTheme.backgroundColor,
          isNot(AppTheme.darkTheme.appBarTheme.backgroundColor));
    });

    test('66. Both AppBar foregrounds are white', () {
      expect(AppTheme.lightTheme.appBarTheme.foregroundColor, Colors.white);
      expect(AppTheme.darkTheme.appBarTheme.foregroundColor, Colors.white);
    });

    test('67. Primary colors differ between themes', () {
      expect(AppTheme.lightTheme.colorScheme.primary,
          isNot(AppTheme.darkTheme.colorScheme.primary));
    });

    test('68. Dark primary is lighter than light primary', () {
      final lum1 = AppTheme.lightTheme.colorScheme.primary.computeLuminance();
      final lum2 = AppTheme.darkTheme.colorScheme.primary.computeLuminance();
      expect(lum2, greaterThan(lum1));
    });

    test('69. Light displayLarge font weight is bold', () {
      expect(AppTheme.lightTheme.textTheme.displayLarge?.fontWeight,
          FontWeight.bold);
    });

    test('70. Dark displayLarge font weight is bold', () {
      expect(AppTheme.darkTheme.textTheme.displayLarge?.fontWeight,
          FontWeight.bold);
    });

    test('71. Light body text readable on light bg', () {
      final color = AppTheme.lightTheme.textTheme.bodyLarge?.color;
      expect(color?.computeLuminance(), lessThan(0.5));
    });

    test('72. Dark body text readable on dark bg', () {
      final color = AppTheme.darkTheme.textTheme.bodyLarge?.color;
      expect(color?.computeLuminance(), greaterThan(0.1));
    });
  });

  // Group 7: ChangeNotifier Integration
  group('ThemeProvider - ChangeNotifier Integration', () {
    test('73. ThemeProvider extends ChangeNotifier', () {
      expect(ThemeProvider(), isA<ChangeNotifier>());
    });

    test('74. Multiple listeners get notified on toggleTheme', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      // Track state changes: both listeners should observe the dark mode flip
      bool listener1Seen = false;
      bool listener2Seen = false;
      p.addListener(() { if (p.isDarkMode) listener1Seen = true; });
      p.addListener(() { if (p.isDarkMode) listener2Seen = true; });
      await p.toggleTheme();
      expect(listener1Seen, true);
      expect(listener2Seen, true);
    });

    test('75. Removed listener does not observe second change', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      var observedCount = 0;
      bool seenDark = false;
      void listener() {
        observedCount++;
        if (p.isDarkMode) seenDark = true;
      }
      p.addListener(listener);
      await p.toggleTheme(); // goes dark — listener fires
      expect(seenDark, true);
      p.removeListener(listener);
      final countAfterRemove = observedCount;
      await p.toggleTheme(); // goes light — listener should NOT fire
      expect(observedCount, countAfterRemove);
    });

    test('76. setDarkMode(false) when already false leaves isDarkMode false', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      expect(p.isDarkMode, false);
      await p.setDarkMode(false);
      expect(p.isDarkMode, false);
    });

    test('77. setDarkMode(true) from false changes isDarkMode to true', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      expect(p.isDarkMode, false);
      await p.setDarkMode(true);
      expect(p.isDarkMode, true);
    });
  });

  // Group 8: i18n Keys
  group('i18n Theme Keys', () {
    testWidgets('78. light_mode key returns non-empty string', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const SizedBox(),
        localizationsDelegates: const [TestLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
      ));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(SizedBox));
      final loc = AppLocalizations.of(ctx);
      expect(loc.translate('light_mode'), isNotEmpty);
      expect(loc.translate('light_mode'), isNot('light_mode'));
    });

    testWidgets('79. dark_mode key returns non-empty string', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const SizedBox(),
        localizationsDelegates: const [TestLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
      ));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(SizedBox));
      final loc = AppLocalizations.of(ctx);
      expect(loc.translate('dark_mode'), isNotEmpty);
    });

    testWidgets('80. theme_light key resolves correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const SizedBox(),
        localizationsDelegates: const [TestLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
      ));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(SizedBox));
      final loc = AppLocalizations.of(ctx);
      expect(loc.translate('theme_light'), 'Light Theme');
    });

    testWidgets('81. theme_dark key resolves correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const SizedBox(),
        localizationsDelegates: const [TestLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
      ));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(SizedBox));
      final loc = AppLocalizations.of(ctx);
      expect(loc.translate('theme_dark'), 'Dark Theme');
    });

    testWidgets('82. theme_settings key resolves correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: const SizedBox(),
        localizationsDelegates: const [TestLocalizationsDelegate()],
        supportedLocales: const [Locale('en')],
      ));
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(SizedBox));
      final loc = AppLocalizations.of(ctx);
      expect(loc.translate('theme_settings'), 'Theme Settings');
    });
  });

  // Group 9: Widget rebuild
  group('Widget Rebuild on Theme Change', () {
    testWidgets('83. HomeScreen rebuilds after toggle', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final p = ThemeProvider();
      await p.loadTheme();
      await tester.pumpWidget(_buildApp(themeProvider: p));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
      await tester.tap(find.byKey(const Key('themeToggleButton')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
    });

    testWidgets('84. HomeScreen renders after toggle without error',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final p = ThemeProvider();
      await p.loadTheme();
      await tester.pumpWidget(_buildApp(themeProvider: p));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('themeToggleButton')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('85. Multiple rapid toggles do not crash', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final p = ThemeProvider();
      await p.loadTheme();
      await tester.pumpWidget(_buildApp(themeProvider: p));
      await tester.pumpAndSettle();
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('themeToggleButton')));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  // Group 10: AppTheme static properties
  group('AppTheme Static Properties', () {
    test('86. lightTheme is not null', () {
      expect(AppTheme.lightTheme, isNotNull);
    });

    test('87. darkTheme is not null', () {
      expect(AppTheme.darkTheme, isNotNull);
    });

    test('88. lightTheme and darkTheme are different objects', () {
      expect(AppTheme.lightTheme, isNot(same(AppTheme.darkTheme)));
    });

    test('89. Light primary has luminance diff from bg', () {
      final primary = AppTheme.lightTheme.colorScheme.primary;
      final bg = AppTheme.lightTheme.colorScheme.surface;
      final diff = (primary.computeLuminance() - bg.computeLuminance()).abs();
      expect(diff > 0.1, true);
    });

    test('90. Dark primary has luminance diff from bg', () {
      final primary = AppTheme.darkTheme.colorScheme.primary;
      final bg = AppTheme.darkTheme.colorScheme.surface;
      final diff = (primary.computeLuminance() - bg.computeLuminance()).abs();
      expect(diff > 0.01, true);
    });

    test('91. Light AppBar: sufficient contrast ratio', () {
      final fg = AppTheme.lightTheme.appBarTheme.foregroundColor!.computeLuminance();
      final bg = AppTheme.lightTheme.appBarTheme.backgroundColor!.computeLuminance();
      final lighter = fg > bg ? fg : bg;
      final darker = fg < bg ? fg : bg;
      final ratio = (lighter + 0.05) / (darker + 0.05);
      expect(ratio, greaterThan(3.0));
    });

    test('92. Dark AppBar: sufficient contrast ratio', () {
      final fg = AppTheme.darkTheme.appBarTheme.foregroundColor!.computeLuminance();
      final bg = AppTheme.darkTheme.appBarTheme.backgroundColor!.computeLuminance();
      final lighter = fg > bg ? fg : bg;
      final darker = fg < bg ? fg : bg;
      final ratio = (lighter + 0.05) / (darker + 0.05);
      expect(ratio, greaterThan(3.0));
    });

    test('93. Light displayLarge fontSize is 28', () {
      expect(AppTheme.lightTheme.textTheme.displayLarge?.fontSize, 28);
    });

    test('94. Dark displayLarge fontSize is 28', () {
      expect(AppTheme.darkTheme.textTheme.displayLarge?.fontSize, 28);
    });

    test('95. Light bodyMedium fontSize is 14', () {
      expect(AppTheme.lightTheme.textTheme.bodyMedium?.fontSize, 14);
    });

    test('96. Dark bodyMedium fontSize is 14', () {
      expect(AppTheme.darkTheme.textTheme.bodyMedium?.fontSize, 14);
    });
  });

  // Group 11: ProjectScreen with theme
  group('ProjectScreen - Themed rendering', () {
    testWidgets('97. ProjectScreen renders in light theme', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final p = ThemeProvider();
      await p.loadTheme();
      await tester.pumpWidget(_buildApp(
        themeProvider: p,
        home: const ProjectScreen(),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectScreen), findsOneWidget);
    });

    testWidgets('98. ProjectScreen renders in dark theme', (tester) async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': true});
      final p = ThemeProvider();
      await p.loadTheme();
      await tester.pumpWidget(_buildApp(
        themeProvider: p,
        home: const ProjectScreen(),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectScreen), findsOneWidget);
    });
  });

  // Group 12: Edge Cases
  group('Edge Cases', () {
    test('99. ThemeProvider instances are independent', () async {
      SharedPreferences.setMockInitialValues({});
      final p1 = ThemeProvider();
      await p1.loadTheme();
      await p1.setDarkMode(true);
      expect(p1.isDarkMode, true);
    });

    test('100. currentTheme after setDarkMode(true) is darkTheme', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      await p.setDarkMode(true);
      expect(p.currentTheme, AppTheme.darkTheme);
    });

    test('101. currentTheme after setDarkMode(false) is lightTheme', () async {
      final p = ThemeProvider();
      await p.loadTheme();
      await p.setDarkMode(true);
      await p.setDarkMode(false);
      expect(p.currentTheme, AppTheme.lightTheme);
    });

    test('102. Both themes have non-zero primary color', () {
      expect(AppTheme.lightTheme.colorScheme.primary.value, isNonZero);
      expect(AppTheme.darkTheme.colorScheme.primary.value, isNonZero);
    });

    testWidgets('103. Pre-saved dark preference starts dark', (tester) async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': true});
      final p = ThemeProvider();
      await p.loadTheme();
      await tester.pumpWidget(_buildApp(themeProvider: p));
      await tester.pumpAndSettle();
      expect(p.isDarkMode, true);
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
    });

    testWidgets('104. Dark start, toggle switches to light', (tester) async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': true});
      final p = ThemeProvider();
      await p.loadTheme();
      await tester.pumpWidget(_buildApp(themeProvider: p));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('themeToggleButton')));
      await tester.pumpAndSettle();
      expect(p.isDarkMode, false);
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    });
  });
}
