# i18n (Internationalization) + Theme Selection - V1.0

## Overview
Implement multi-language support (Vietnamese & English) and theme selection (Light/Dark) with persistent storage. Support switching languages and themes at runtime with immediate UI updates.

## Acceptance Criteria

1. ✓ Folder structure: `lib/core/localization/` + `lib/core/theme/` with proper organization
2. ✓ `localization_delegate.dart` implements `AppLocalizationsDelegate`, supports Vietnamese + English
3. ✓ Translation files: `translations/en.json` + `translations/vi.json` with ≥20 basic strings
   - App name, menu items, buttons, common messages
4. ✓ `app_theme.dart` defines Light + Dark `ThemeData`
   - Color palette (primary, secondary, background)
   - Typography (headline, body, caption styles)
5. ✓ `theme_provider.dart` (BLoC or StateNotifier) manages theme state
   - Toggles between light/dark modes
   - Persists preference via `shared_preferences`
6. ✓ `main.dart` updated with:
   - `localizationsDelegates` (Flutter localizations + custom delegate)
   - `supportedLocales` (en, vi)
   - `theme` and `darkTheme` from provider
7. ✓ Runtime behavior on emulator/device:
   - Language switch → UI updates immediately
   - Theme toggle → UI updates immediately
   - Preferences persist after app restart
8. ✓ Unit tests (≥3 test cases) for theme provider + localization
   - Test theme persistence
   - Test locale switching
   - Test default theme/locale
9. ✓ `pubspec.yaml` dependencies added:
   - `flutter_localizations`
   - `intl` (for date/time formatting)
   - `shared_preferences` (for persistence)
10. ✓ Push to GitHub, test from fresh clone, all tests pass

## Implementation Notes

### Package Options
- **Localization:** Use built-in `flutter_localizations` + `intl` OR `easy_localization` (simpler)
- **State Management:** BLoC or StateNotifier for theme provider
- **Persistence:** `shared_preferences` for theme/locale preference
- **Single-user app:** No auth/permissions needed

### File Structure
```
lib/
├── core/
│   ├── localization/
│   │   ├── app_localizations.dart
│   │   ├── localization_delegate.dart
│   │   └── translations/
│   │       ├── en.json
│   │       └── vi.json
│   └── theme/
│       ├── app_theme.dart
│       └── theme_provider.dart (or theme_bloc.dart)
├── main.dart (updated)
└── ...
```

### Testing
- Theme provider persistence
- Locale switching
- Theme switching
- Default values
- Preferences restoration after restart
