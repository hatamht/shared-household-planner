# Shared-32: Refactor Navigation - Merge Tab 3 & Tab 4 to Settings

**Layer:** Presentation (UI, Navigation, Architecture, Theming, Localization, State Management)  
**Priority:** High  
**Type:** Refactoring / Navigation & Settings Consolidation

---

## Overview

Refactored navigation and user settings experience by consolidating Tab 3 (User Profile / Account Info) and Tab 4 (Settings) into a unified, feature-packed **Settings** screen (`SettingsScreen`). The app's bottom navigation bar now features a clear, coherent 4-tab layout:
1. **Projects** (Tab 0: Home Dashboard)
2. **Requests / Bills** (Tab 1: Bill & Expense Management)
3. **Statistics** (Tab 2: Statistics & Charts)
4. **Settings** (Tab 3: Unified Settings & Account Management)

The consolidated Settings screen provides:
1. **Account Info:** User profile banner with avatar, username, email, "Owner" role badge, and edit profile action.
2. **Theme Settings:** Interactive theme mode switcher (Light Theme / Dark Theme) wired directly to `ThemeProvider`.
3. **Preferences:**
   - **Language Selector:** Seamless switching between English (`en`) and Vietnamese (`vi`) using `LanguageProvider`.
   - **Default Currency Selector:** Dropdown menu supporting EUR, USD, VND, GBP, and JPY with persistence in `SharedPreferences`.
4. **Export Options:** Quick export tiles for CSV (spreadsheet records) and PDF (formatted printable report) with snackbar feedback.
5. **Data Management:** Cache size indicator (`Cache size: 1.2 MB`), Clear Cache action with immediate feedback, and Reset Demo Data with confirmation dialog.
6. **About App:** Application branding, version (`1.0.0 (Build 42)`), verified SimSoft Studio developer badge, and license info.
7. **Dark / Light Theme Styling:** Comprehensive theme adaptability across all cards, dialogs, and controls.
8. **Bilingual Localization:** 100% i18n coverage in English (`en.json`) and Vietnamese (`vi.json`).

---

## Acceptance Criteria & Implementation Details

1. ✅ **Consolidate Tab 4 (old settings) + Tab 3 (old content) into single Settings tab:**
   - Merged user profile details (avatar, name, role badge, email) and settings controls into `SettingsScreen` at Tab 3.
   - Seamlessly integrated into `HomeScreen` with 4 indexed items in `IndexedStack` and `BottomNavigationBar`.
2. ✅ **Settings includes: Theme toggle, Currency, Language, About, Data Management:**
   - `themeSettingsCard` with Light and Dark radio tiles.
   - `currencySelector` dropdown supporting EUR, USD, VND, GBP, and JPY.
   - `languageTile_en` and `languageTile_vi` radio tiles.
   - `aboutAppCard` showing App Name, Version, and SimSoft Studio developer badge.
   - `dataManagementCard` offering Cache clearing and Demo Data reset dialog.
3. ✅ **Add Settings-specific UI sections: Account info, Export options:**
   - `accountCard` featuring circle avatar 'H', username, email, and "Owner" role chip.
   - `exportOptionsCard` with CSV and PDF export options and informative subtitles.
4. ✅ **Update BottomNavigationBar: 4 tabs → 4 tabs (Home/Projects, Requests/Bills, Statistics, Settings):**
   - Tab 0: `Icons.dashboard_outlined` / `Icons.dashboard` (Projects)
   - Tab 1: `Icons.receipt_long_outlined` / `Icons.receipt_long` (Requests)
   - Tab 2: `Icons.insights_outlined` / `Icons.insights` (Statistics)
   - Tab 3: `Icons.settings_outlined` / `Icons.settings` (Settings)
5. ✅ **Maintain all existing theme/language/currency functionality:**
   - Preserved `ThemeProvider` toggles and dark mode detection.
   - Preserved `LanguageProvider` locale changes and locale listeners.
   - Backward-compatible callbacks (`onCurrencyChanged`, `onClearCache`, `onResetData`) and standalone mode support (`showAppBar: true/false`).
6. ✅ **Navigation transitions smooth:**
   - Smooth index switching without state loss via `IndexedStack`.
   - Floating Action Button (FAB) intelligently shown only on Tab 0 (Projects) and hidden on Statistics (Tab 2) and Settings (Tab 3).
7. ✅ **Tests: 60+ covering navigation, tab switching (75 implemented):**
   - 75 comprehensive tests in `test/features/settings/settings_navigation_test.dart` covering 12 distinct functional groups.
   - 105 existing tests in `test/features/home/home_screen_redesign_test.dart` fully maintained and passing.
   - Project-wide test suite: 748+ tests passing with 0 failures.

---

## Verification Results

- `test/features/settings/settings_navigation_test.dart`: 75/75 passed.
- `test/features/home/home_screen_redesign_test.dart`: 105/105 passed.
- Full test suite: 748+ tests passed (100% pass rate, 0 failures).
