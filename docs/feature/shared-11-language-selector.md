# Shared-11: Language Selector UI (English ↔ Vietnamese)

**Layer:** Presentation (Language picker)

**Scope:** Add language selector to app to switch between English and Vietnamese at runtime.

---

## Acceptance Criteria

1. ✅ **Add language selector UI**
   - Location: AppBar menu (icon button + dropdown) or settings screen
   - Options: English 🇬🇧, Vietnamese 🇻🇳
   - Current language highlighted/checked
   - Recommended: Use PopupMenuButton in AppBar (same as theme toggle)

2. ✅ **Language persistence**
   - Save selected language to SharedPreferences (same as theme)
   - Load on app startup: `await loadLanguage()`
   - Default: English if not saved

3. ✅ **Change i18n locale at runtime**
   - Create LanguageProvider (ChangeNotifier) similar to ThemeProvider
   - Expose: `currentLocale`, `setLanguage(Locale)`
   - Trigger rebuild when language changes: `notifyListeners()`

4. ✅ **Update AppLocalizations to respect currentLocale**
   - Load correct JSON file based on currentLocale (en.json or vi.json)
   - AppLocalizations.of(context).translate() uses current language

5. ✅ **Wrap app with LanguageProvider**
   - main.dart: ChangeNotifierProvider<LanguageProvider>
   - Similar to ThemeProvider wrapping
   - Pass locale to MaterialApp: `locale: languageProvider.currentLocale`

6. ✅ **Update AppBar UI**
   - Keep theme toggle icon
   - Add language selector (e.g., dropdown or icon menu)
   - Tooltip: "English" or "Tiếng Việt"
   - Both icons in AppBar actions

7. ✅ **Test language switching**
   - App launch → default English
   - Tap language selector → Vietnamese
   - All text updates (buttons, labels, messages)
   - Close + reopen app → language persisted
   - Switch theme → language still correct

8. ✅ **No hardcoded strings**
   - All UI text (button labels, dropdowns, tooltips) from i18n
   - AppBar title, messages, errors all localized

9. ✅ **Code quality**
   - No compilation errors
   - `flutter analyze` passes
   - No unused imports
   - LanguageProvider documented (similar to ThemeProvider)

---

## Technical Notes

- **New file:** `lib/core/language/language_provider.dart` (similar to ThemeProvider)
- **Update:** 
  - `lib/core/localization/app_localizations.dart` (read from provider)
  - `lib/main.dart` (wrap with LanguageProvider, set MaterialApp locale)
  - `pubspec.yaml` (if needed: shared_preferences already added)
- **Pattern:** Use locale = Locale('en') or Locale('vi')
- **SharedPreferences key:** 'language' or 'selected_language'

---

## File Structure

```
lib/
├── main.dart                          ← Update: LanguageProvider wrap, MaterialApp locale
├── core/
│   ├── language/                      ← NEW
│   │   └── language_provider.dart     ← NEW: LanguageProvider class
│   └── localization/
│       └── app_localizations.dart     ← Update: read from provider
```

---

## Owner & Next Step

- **Task ID:** Shared-11
- **Assigned to:** Member (`member:shared-household`)
- **Expected effort:** 2-3 hours (provider setup + AppBar UI + testing)
- **Blockers:** Shared-10 (missing i18n keys) should be done first
- **Deliverable:** Commit with LanguageProvider, AppBar language selector, persistence. 0 warnings.
- **End goal:** User can switch English ↔ Vietnamese, app updates instantly, choice persists
