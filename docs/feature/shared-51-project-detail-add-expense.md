# Feature Specification: Shared-51 Add Expense Button in ProjectDetailScreen with Navigation to AddBillScreen

## 1. Overview
In `ProjectDetailScreen`, users need a direct, convenient way to create expenses linked to the project currently being viewed without having to manually navigate away or re-select the project in `AddBillScreen`.

This feature provides:
1. A primary `FloatingActionButton` ("Tạo yêu cầu chi tiêu" / "Add Expense") on `ProjectDetailScreen` with `Key("addExpenseFromProjectButton")`.
2. An inline action button in the Bills tab empty state (`no_bills_in_project`) with `Key("emptyStateAddExpenseButton")` and `Key("inlineAddBillButton")` with label "Tạo chi tiêu" / "Create Expense".
3. Navigation from either button to `AddBillScreen`, pre-passing:
   - `projectId: project.id`
   - `projectName: project.name`
   - `projectSettings: ProjectSettings(members: project.members)`
4. `AddBillScreen` pre-selects the project and pre-fills participants and payer using `project.members`.
5. Returning to `ProjectDetailScreen` reloads the project data (bills list, settlements, and statistics).

---

## 2. Acceptance Criteria
1. `FloatingActionButton` or primary action button "Tạo yêu cầu chi tiêu" is added to `ProjectDetailScreen` with `Key("addExpenseFromProjectButton")`.
2. Button is accessible from `ProjectDetailScreen` (FAB accessible across tabs).
3. Tapping button navigates to `AddBillScreen` passing `projectId`, `projectName`, and `projectSettings` with `project.members`.
4. `AddBillScreen` opens with the current project pre-selected without needing manual selection.
5. Participants/Members in `AddBillScreen` are pre-filled with the members of the selected project.
6. Empty state in Bills tab (`no_bills_in_project`) also provides an inline "Tạo chi tiêu" button (`Key("emptyStateAddExpenseButton")`, `Key("inlineAddBillButton")`).
7. Returning to `ProjectDetailScreen` after saving a new bill triggers data refresh (bills list and statistics update).
8. Dark and Light theme support with proper styling and contrast.
9. Full EN/VI i18n for button labels and hints (`add_expense_button`, `create_first_bill`).
10. Widget and integration tests (15+ tests) verifying button visibility, navigation, parameter passing, and refresh callback.

---

## 3. Architecture & Implementation

### 3.1 Project Settings Domain Layer
- Updated `ProjectSettings` (`lib/features/projects/domain/entities/project_settings.dart`):
  - Added `final List<String> members;` with default `const []`.
  - Props updated to include `members`.

### 3.2 Presentation Layer (`ProjectDetailScreen`)
- Added `FloatingActionButton.extended` on `Scaffold` with:
  - `key: const Key('addExpenseFromProjectButton')`
  - `icon: const Icon(Icons.add)`
  - `label: Text(loc.translate('add_expense_button'))`
  - `onPressed: _navigateToAddBill`
- Added inline button in `_BillsTab` when `bills.isEmpty`:
  - `KeyedSubtree(key: const Key('inlineAddBillButton'), child: ElevatedButton.icon(key: const Key('emptyStateAddExpenseButton'), ...))`
  - `label: Text(loc.translate('create_first_bill'))`
- Added navigation handler `_navigateToAddBill()`:
  - Pushes `MaterialPageRoute(builder: (_) => AddBillScreen(projectId: widget.project.id, projectName: widget.project.name, projectSettings: ProjectSettings(members: widget.project.members)))`
  - Upon return (`await Navigator.push(...)`), calls `refreshData()` to reload `_loadData()`.
- Added public `refreshData()` on `ProjectDetailScreenState`.

### 3.3 AddBillScreen Integration (`AddBillScreen`)
- Initialized `selectedProject`, `projectMembers`, `selectedParticipants`, and `paidByController.text` when `widget.projectId != null` and `widget.projectSettings.members.isNotEmpty`.
- `BlocConsumer` synchronizes with `matching.members` upon `ProjectLoaded`.

### 3.4 Localization (i18n)
- `lib/core/localization/translations/en.json`:
  - `"add_expense_button": "Add Expense"`
  - `"create_first_bill": "Create Expense"`
- `lib/core/localization/translations/vi.json`:
  - `"add_expense_button": "Tạo yêu cầu chi tiêu"`
  - `"create_first_bill": "Tạo chi tiêu"`

---

## 4. Test Verification
- 22 comprehensive tests in `test/features/projects/project_detail_add_expense_test.dart` covering:
  - Button presence and accessibility across all tabs
  - English and Vietnamese translation rendering
  - Empty state button rendering and hiding when bills exist
  - Dark and Light theme rendering
  - Navigation to `AddBillScreen`
  - Correct passing of `projectId`, `projectName`, and `projectSettings.members`
  - Pre-selected project name in `AddBillScreen`
  - Pre-filled participants and payer
  - Data refresh triggering on pop and state update of bills and statistics
  - Edge cases with 1 member and multiple members
