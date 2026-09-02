import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/core/language/language_provider.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/bills_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.translate('app_name')),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (String languageCode) {
              languageProvider.setLanguage(languageCode);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'en',
                child: Text('🇬🇧 English'),
              ),
              const PopupMenuItem<String>(
                value: 'vi',
                child: Text('🇻🇳 Tiếng Việt'),
              ),
            ],
            tooltip: appLocalizations.translate('language'),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: IconButton(
                icon: Icon(
                  Theme.of(context).brightness == Brightness.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  color: Theme.of(context).appBarTheme.foregroundColor ??
                      Colors.white,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Theme toggle (inherited from app level)',
                      ),
                    ),
                  );
                },
                tooltip: Theme.of(context).brightness == Brightness.dark
                    ? 'Light Mode'
                    : 'Dark Mode',
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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BillsListScreen(),
                  ),
                );
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
          ],
        ),
      ),
    );
  }
}
