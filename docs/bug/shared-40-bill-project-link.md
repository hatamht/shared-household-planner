# Shared-40: Bug Fix - Bills Not Linked to Project After Edit/Add

## Problem Statement

Users reported that:
1. When creating a new bill with a project pre-selected or via `AddBillScreen(projectId: '...')`, the saved bill would lose its `projectId` (saved as `null`) if the dropdown wasn't manually touched.
2. When editing an existing bill that was linked to a project, the project link could be unintentionally reset or out-of-sync with the dropdown ("No Project" displayed).
3. The Bill Detail screen did not display project association information even when a bill belonged to a project.

## Root Cause Analysis

In `lib/features/split_bills/presentation/pages/add_bill_screen.dart`:
- `_saveBill` constructed the `Bill` entity with:
  ```dart
  projectId: selectedProject?.id ?? widget.billToEdit?.projectId,
  ```
  `widget.projectId` was completely ignored on save, so when creating a bill with `AddBillScreen(projectId: '...')`, if `selectedProject` had not been manually selected in the UI dropdown, `projectId` evaluated to `null`.
- In `initState`, `selectedProject` was not pre-populated from `widget.projectId` or `widget.billToEdit?.projectId` even if `ProjectBloc` was already in the `ProjectLoaded` state.
- If `ProjectBloc` finished loading asynchronously after `initState`, `_buildProjectDropdown` used `BlocBuilder` without updating `selectedProject` or synchronizing project members/participants for the target project.
- In `lib/features/split_bills/presentation/pages/bill_detail_screen.dart`:
  - There was no UI element rendering the associated project name or badge.
  - When tapping Edit, `bill.projectId` was not explicitly passed forward in the route builder.

## Solution

1. **`AddBillScreen` (`lib/features/split_bills/presentation/pages/add_bill_screen.dart`)**:
   - Added `_hasUserExplicitlySelectedProject` state tracking flag to differentiate between "user intentionally picked 'No Project'" vs "user has not changed project selection".
   - In `initState`: Pre-select `selectedProject` and project members from `widget.billToEdit?.projectId ?? widget.projectId` if `ProjectBloc` is already in `ProjectLoaded`.
   - In `_buildProjectDropdown`: Converted from `BlocBuilder` to `BlocConsumer` with a listener that automatically resolves and links the project when `ProjectLoaded` emits asynchronously.
   - Updated dropdown value resolution to guarantee the selected project instance matches the items list.
   - In `_saveBill` and `_saveAsTemplate`:
     ```dart
     final String? resolvedProjectId = _hasUserExplicitlySelectedProject
         ? selectedProject?.id
         : (selectedProject?.id ?? widget.billToEdit?.projectId ?? widget.projectId);
     ```
2. **`BillDetailScreen` (`lib/features/split_bills/presentation/pages/bill_detail_screen.dart`)**:
   - Added optional `projectName` constructor parameter.
   - Added `_buildProjectBadge` widget (`key: Key('billDetailProject')` & `Key('billDetailProjectName')`) that dynamically resolves the project name via `ProjectBloc` or displays `bill.projectId`.
   - Updated `_navigateToEdit` to pass `AddBillScreen(billToEdit: bill, projectId: bill.projectId)`.
3. **Data Isolation & Settlement**:
   - Deleting a bill from a project deletes only that specific bill (`deleteBill(billId)`), keeping other bills and other projects intact.
   - Settlement calculation (`CalculateSettlementUseCase`) strictly filters by `b.projectId == project.id`, ensuring only bills linked to the active project contribute to debt minimization and net balances.

## Acceptance Criteria Verification

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Creating new bill via `AddBillScreen` saves with `projectId` | ✅ Verified |
| 2 | Editing existing bill retains `projectId` (not reset to null) | ✅ Verified |
| 3 | Deleting bill from project removes it from that project only | ✅ Verified |
| 4 | Bill detail screen shows correct project association | ✅ Verified (`billDetailProject` badge) |
| 5 | Settlement calculation uses only bills from selected project | ✅ Verified |
| 6 | Comprehensive test suite (50+ tests) covering bill-project operations | ✅ Verified |
