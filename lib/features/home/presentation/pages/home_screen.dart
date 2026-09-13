import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/core/theme/app_theme.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/bills_list_screen.dart';
import 'package:shared_household_planner/features/projects/presentation/pages/project_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    
    LanguageProvider? languageProvider;
    try {
      languageProvider = Provider.of<LanguageProvider>(context, listen: true);
    } catch (_) {
      languageProvider = null;
    }

    ThemeProvider? themeProvider;
    try {
      themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    } catch (_) {
      themeProvider = null;
    }

    final isDark = themeProvider?.isDarkMode ??
        (Theme.of(context).brightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.translate('app_name')),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (String languageCode) {
              languageProvider?.setLanguage(languageCode);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'en',
                child: Text('🇬🇧 ${appLocalizations.translate("english")}'),
              ),
              PopupMenuItem<String>(
                value: 'vi',
                child: Text('🇻🇳 ${appLocalizations.translate("vietnamese")}'),
              ),
            ],
            tooltip: appLocalizations.translate('language'),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: IconButton(
                key: const Key('themeToggleButton'),
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: Theme.of(context).appBarTheme.foregroundColor ??
                      Colors.white,
                ),
                onPressed: () => themeProvider?.toggleTheme(),
                tooltip: isDark
                    ? appLocalizations.translate('light_mode')
                    : appLocalizations.translate('dark_mode'),
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
            const SizedBox(height: 40),
            ElevatedButton.icon(
              key: const Key('splitBillsButton'),
              onPressed: () {
                Navigator.of(context).pushNamed('/bills');
              },
              icon: const Icon(Icons.receipt),
              label: Text(appLocalizations.translate('split_bills')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              key: const Key('projectsButton'),
              onPressed: () {
                Navigator.of(context).pushNamed('/projects');
              },
              icon: const Icon(Icons.folder_shared),
              label: Text(appLocalizations.translate('projects')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
