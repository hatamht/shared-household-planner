# Shared-8: Dependency Injection Setup (GetIt + BLoC Registration)

**Layer:** Presentation Integration (DI container)

**Scope:** Set up GetIt service locator, register BillsBloc, AddBillBloc, DatabaseHelper, BillRepository, and UseCases.

---

## Acceptance Criteria

1. ✅ **Add GetIt package**
   - Update pubspec.yaml: `get_it: ^7.5.0` (or latest)
   - `flutter pub get` succeeds

2. ✅ **Create DI setup file**
   - File: `lib/core/injection_container.dart` (or `service_locator.dart`)
   - Function: `void setupServiceLocator()` or `Future<void> setupServiceLocator()`
   - Called in main() before runApp()

3. ✅ **Register DatabaseHelper singleton**
   - `getIt.registerSingleton<DatabaseHelper>(...)`
   - Initialize database before BLoC registration

4. ✅ **Register BillLocalDataSource**
   - `getIt.registerSingleton<BillLocalDataSource>(...)`
   - Pass DatabaseHelper instance to constructor

5. ✅ **Register BillRepository**
   - `getIt.registerSingleton<BillRepository>(...)`
   - Pass BillLocalDataSource instance

6. ✅ **Register UseCases**
   - `getIt.registerSingleton<GetBillsUseCase>(...)`
   - `getIt.registerSingleton<AddBillUseCase>(...)`
   - `getIt.registerSingleton<UpdateBillUseCase>(...)`
   - `getIt.registerSingleton<DeleteBillUseCase>(...)`
   - Each receives BillRepository instance

7. ✅ **Register BloCs**
   - `getIt.registerSingleton<BillsBloc>(...)`
   - `getIt.registerSingleton<AddBillBloc>(...)`
   - Each receives UseCase instances

8. ✅ **Update main.dart**
   - Import: `import 'core/injection_container.dart';`
   - Call in main(): `await setupServiceLocator();` or `setupServiceLocator();`
   - Wrap app with MultiBlocProvider using getIt instances:
     ```dart
     runApp(
       MultiBlocProvider(
         providers: [
           BlocProvider<BillsBloc>(create: (_) => getIt<BillsBloc>()),
           BlocProvider<AddBillBloc>(create: (_) => getIt<AddBillBloc>()),
         ],
         child: const MyApp(),
       ),
     );
     ```

9. ✅ **Test DI resolution**
   - App launches without crashes
   - BillsBloc instance accessible via getIt
   - Add debug print: `print('BillsBloc: ${getIt<BillsBloc>()}');` at startup (remove before commit)

10. ✅ **No warnings + documentation**
    - `flutter analyze` passes
    - Add comment in injection_container.dart explaining setup
    - No unused imports

---

## Technical Notes

- **DI Pattern:** GetIt (simple, no codegen needed)
- **Singleton vs Lazy:** Use singleton for stateless services (DB, repo, usecases), lazy for BLoCs (if multiple instances needed)
- **DatabaseHelper.initialize():** Must complete before BillRepository creation
- **MultiBlocProvider:** Wrap in main() so BLoCs available to all screens
- **Files to create:**
  - `lib/core/injection_container.dart` (new)
- **Files to update:**
  - `lib/main.dart` (add imports, setupServiceLocator call, MultiBlocProvider)
  - `pubspec.yaml` (add get_it)

---

## File Structure

```
lib/
├── main.dart                          ← Update: import injection, call setupServiceLocator, wrap with MultiBlocProvider
├── core/
│   └── injection_container.dart       ← NEW: DI setup
├── features/split_bills/
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   ├── presentation/
│   │   └── bloc/
│   └── data/
│       ├── datasources/
│       ├── repositories/
│       └── models/
└── pubspec.yaml                       ← Add get_it dependency
```

---

## Owner & Next Step

- **Task ID:** Shared-8
- **Assigned to:** Member (`member:shared-household`)
- **Expected effort:** 2-3 hours
- **Blockers:** Shared-7 (home dashboard) should be done first for context
- **Deliverable:** Commit with injection_container.dart, main.dart updated, pubspec.yaml updated. 0 warnings. App launches.
- **Next:** Shared-9 (AddBillScreen + integration tests) after t8 approved
