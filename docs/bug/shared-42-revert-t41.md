# Shared-42: Revert t41 Changes - Remove Unnecessary Requests Feature

## Problem Statement

Task `t41` introduced a "Requests" tab and requests feature linked to projects. However, the requirement was identified as unnecessary/breaking and instructed to be completely reverted to maintain a clean, stable project architecture.

## Revert Scope

1. **Clean Architecture Modules (`lib/features/requests/`)**:
   - Removed Domain layer: `RequestItem` entity, `RequestRepository` interface, `RequestUseCases`.
   - Removed Data layer: `RequestModel`, `RequestLocalDataSource`, `RequestRepositoryImpl`.
   - Removed Presentation layer: `RequestBloc`, `RequestEvent`, `RequestState`, `RequestListScreen`, `CreateRequestBottomSheet`, `RequestCard`.

2. **Database & Migrations**:
   - Removed SQLite table `requests` creation and upgrade script from `database_helper.dart`.
   - Database schema returns to clean version 9.

3. **Dependency Injection & App Configuration**:
   - Removed all `Request*` service locator registrations in `lib/core/injection_container.dart`.
   - Removed `RequestBloc` and `RequestRepository` providers and `/requests` route from `lib/main.dart`.

4. **UI Restoration**:
   - Reverted `HomeScreen` (`lib/features/home/presentation/pages/home_screen.dart`): restored original Tab 1 layout (`BillsListScreen`), removed `requestsTabSegmentedButton`, removed `projectRequestBadge_<id>` and context menu request shortcuts.
   - Reverted `ProjectDetailScreen` (`lib/features/projects/presentation/pages/project_detail_screen.dart`): removed `projectRequestsButton`.
   - Removed unused translation strings from `en.json` and `vi.json`.

5. **Testing & Regression**:
   - Removed `test/features/requests/requests_feature_test.dart`.
   - Added comprehensive regression test suite (`test/features/home/revert_requests_regression_test.dart`) covering 50+ assertions to verify:
     - No Requests tab, buttons, or routes exist.
     - Projects, Bills, Categories, Settlements continue functioning smoothly.
     - Database helper and DI work without requests dependencies.
     - 100% test pass rate across the full project.

## Acceptance Criteria Verification

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Revert all commits from t41 that introduced Requests feature | ✅ Verified (`bf20bbb` reverted) |
| 2 | Remove Requests tab/navigation | ✅ Verified |
| 3 | Remove requests SQLite table and migrations | ✅ Verified |
| 4 | Remove RequestsBloc, RequestsScreen, related models/entities | ✅ Verified |
| 5 | Verify all original features still work (Projects, Bills, Categories, Settlement) | ✅ Verified |
| 6 | Ensure no broken imports or orphaned code remains | ✅ Verified (`flutter analyze` clean) |
| 7 | Run full test suite: 0 failures | ✅ Verified |
| 8 | Verify app builds and runs without errors | ✅ Verified |
| 9 | Tests: 50+ covering revert and regression | ✅ Verified |
