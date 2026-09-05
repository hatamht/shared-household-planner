import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String> _translations = {};

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  Future<bool> load() async {
    try {
      final jsonString = await rootBundle.loadString(
        'core/localization/translations/${locale.languageCode}.json',
      );
      _translations = Map<String, String>.from(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );
      return true;
    } catch (e) {
      print('🔴 Failed to load translations for ${locale.languageCode}: $e');
      return false;
    }
  }

  String translate(String key) {
    final result = _translations[key];
    if (result == null) {
      print('🟡 Missing translation key: "$key"');
    }
    return result ?? '[${key}]';
  }

  String t(String key) => translate(key);
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'vi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
