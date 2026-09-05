# Shared-7: Home Dashboard (Navigation Entry Point)

**Layer:** Presentation (Home/Dashboard screen)

**Scope:** Create app home screen with button to navigate to Split Bills feature.

---

## Acceptance Criteria

1. ✅ **Create HomeScreen widget**
   - StatelessWidget or StatefulWidget
   - Location: `lib/features/home/presentation/pages/home_screen.dart`
   - Display app title "Shared Household Planner"

2. ✅ **Add "Chia Tiền Hóa Đơn" button**
   - Button navigates to BillsListScreen
   - Use `Navigator.of(context).push()` or named route
   - Button placed prominently in center or as card

3. ✅ **Implement navigation**
   - HomeScreen is new app `home` (replace MyHomePage)
   - Update main.dart: `home: const HomeScreen()`
   - BillsListScreen pushed when button tapped
   - Back button returns to HomeScreen

4. ✅ **Apply i18n**
   - Button text: `AppLocalizations.of(context).translate('split_bills')`
   - Add "split_bills": "Chia Tiền Hóa Đơn" to en.json
   - Add "split_bills": "Chia Tiền Hóa Đơn" to vi.json (same)

5. ✅ **Apply theme**
   - Use `Theme.of(context)` for colors
   - Button inherits app theme (Light/Dark)
   - No hardcoded colors

6. ✅ **Test manual**
   - App launch → HomeScreen shows
   - Button visible and tappable
   - Tap button → navigate to BillsListScreen
   - Back → return to HomeScreen

7. ✅ **No compilation warnings**
   - `flutter analyze` passes
   - No unused imports
   - No console errors

---

## Technical Notes

- **Entry point:** main.dart line 41: `home: const HomeScreen()`
- **Navigation:** Push BillsListScreen (not replace)
- **File to create:** `lib/features/home/presentation/pages/home_screen.dart`
- **Files to update:** 
  - `lib/main.dart` (import + home line)
  - `assets/i18n/en.json` (add split_bills key)
  - `assets/i18n/vi.json` (add split_bills key)
- **Depends on:** Shared-2 (i18n + theme), Shared-4 (BillsListScreen)

---

## File Structure

```
lib/
├── main.dart                          ← Update home: const HomeScreen()
├── features/
│   ├── home/                          ← NEW
│   │   └── presentation/
│   │       └── pages/
│   │           └── home_screen.dart   ← NEW
│   └── split_bills/
│       ├── presentation/
│       │   └── pages/
│       │       └── bills_list_screen.dart
└── assets/
    └── i18n/
        ├── en.json                    ← Add split_bills key
        └── vi.json                    ← Add split_bills key
```

---

## Owner & Next Step

- **Task ID:** Shared-7 (after Shared-5.5.1)
- **Assigned to:** Member (`member:shared-household`)
- **Expected effort:** 1-2 hours
- **Blockers:** None (Shared-2, Shared-4 ready)
- **Deliverable:** Commit with HomeScreen, navigation, i18n, theme applied. 0 warnings.
- **Next:** Shared-8 (DI Setup) after t7 approved
