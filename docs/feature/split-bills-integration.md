# Shared-5.5: Split Bills App Integration

**Layer:** Presentation Integration (routing, DI, app setup)

**Scope:**  
Integrate Shared-4 (UI) + Shared-5 (Data) into main app. Set up dependency injection, navigation routes, and app entry point (main.dart).

---

## Acceptance Criteria

1. ✅ **Update main.dart**
   - Replace MyApp boilerplate with BLoC setup (GetIt or manual DI)
   - Set home to dashboard/home screen (not BillsListScreen directly)
   - Material theme from Shared-2 applied globally

2. ✅ **Dependency Injection Setup**
   - BillsBloc, AddBillBloc registered (GetIt singleton or provider)
   - DatabaseHelper instance created at app startup
   - BillRepository instantiated with SQLite DataSource (from Shared-5)
   - UseCases (GetBillsUseCase, AddBillUseCase) wired to BLoC

3. ✅ **Database Initialization**
   - DatabaseHelper.initialize() called in main()
   - SQLite db file created at app launch (lib/data/database.db or app docs dir)
   - Schema migration (bills, bill_participants tables) executed
   - No crashes if db file already exists

4. ✅ **Navigation Routes**
   - Home screen: "Chia Tiền Hóa Đơn" button → BillsListScreen
   - Floating action button: "Thêm Hóa Đơn" → AddBillScreen (or dialog in BillsListScreen)
   - Back navigation works correctly (pop/push tested manually)

5. ✅ **AddBillScreen Implementation** (if not in Shared-4)
   - Form: title, amount, category, paidBy, participants
   - Validates input before submit
   - Calls AddBillUseCase → AddBillBloc.add(AddBillEvent(bill))
   - Pops back to BillsListScreen on success; shows error if fails

6. ✅ **i18n Integration Verification**
   - All UI strings use AppLocalizations.of(context).translate()
   - English (en.json) + Vietnamese (vi.json) strings for new screens
   - Language switch (if app supports it) reflects in Bills UI immediately

7. ✅ **Theme Integration Verification**
   - Light/Dark theme toggle (from Shared-2) applied to Bills screens
   - BillCard, StatsCard colors adapt to current theme
   - No hardcoded colors (all from theme context)

8. ✅ **Manual Testing Checklist**
   - App launches without crashes
   - Navigate to Bills screen and see empty state
   - Add bill via form → persisted to SQLite
   - Navigate back/forth; bill still there after reopen
   - Delete bill (if implemented) works
   - i18n + theme switches reflect in all screens

9. ✅ **Integration Test** (at least 2 scenarios)
   - Test 1: Launch app → tap Bills button → see BlocBuilder listening to BillsBloc
   - Test 2: Add bill via AddBillDialog → verify AddBillBloc event fired → Bills list updates
   - Verify BLoC events flow from UI → domain → data layers

10. ✅ **Code Review**
    - No unused imports
    - No console errors/warnings
    - Bloc pattern consistent (events, states, listeners)
    - DI setup documented (if custom)
    - All 10 tests pass

---

## Technical Notes

- **Main entry point:** `lib/main.dart`
- **DI pattern:** GetIt recommended (pub.dev/packages/get_it) or manual setup in main()
- **Database path:** `app docs directory` (use `path_provider` package)
- **Navigation:** Named routes or direct push (Material Navigation)
- **Depends on:** Shared-2 (theme/i18n), Shared-4 (UI), Shared-5 (data)
- **Blocks:** None (all layers ready)

---

## File Structure After Completion

```
lib/
├── main.dart                          ← Updated: DI setup, home screen
├── core/
│   ├── localization/app_localizations.dart
│   └── theme/                          ← From Shared-2
├── features/split_bills/
│   ├── domain/                         ← From Shared-3
│   ├── presentation/
│   │   ├── bloc/
│   │   ├── pages/
│   │   │   ├── bills_list_screen.dart  ← From Shared-4
│   │   │   └── add_bill_screen.dart    ← May update
│   │   └── widgets/
│   ├── data/                           ← From Shared-5
│   │   ├── database_helper.dart
│   │   ├── models/
│   │   └── datasources/
│   └── split_bills_module.dart         ← Optional: module setup if using modular
├── common/
│   └── home_screen.dart                ← NEW: App home/dashboard
└── assets/
    ├── i18n/en.json
    └── i18n/vi.json
```

---

## Owner & Next Step

- **Task ID:** Shared-5.5 (seq after Shared-5)
- **Assigned to:** Member (`member:shared-household`)
- **Expected effort:** 3-4 hours (DI setup + navigation + testing)
- **Blockers:** Shared-5 (data layer must be done first)
- **Deliverable:** Commit with all 10 acceptance criteria met, ≥10 integration tests passing
