# Feature Specification: Shared-43 AddBillScreen Project Selector with Member Filtering

## 1. Overview
The Project Selector feature enables users to explicitly select a project at the top of `AddBillScreen`. Once a project is selected, the participants list and member chips are automatically filtered to show only members of the selected project. The app remembers the user's last selected project across sessions, enforces project selection when adding bills, and displays the linked project as a badge in the `BillDetailScreen`.

---

## 2. Acceptance Criteria
1. **Top Placement**: Add Project selector button/dropdown at the top of `AddBillScreen` (before description/title).
2. **Current Selection Display**: Show current selected project name clearly with avatar/icon and label.
3. **Interactive Project Picker**: Tap to open project picker (bottom sheet modal) listing available projects.
4. **Member Chips Update**: After selecting a project, member chips dynamically update to show only members of that project.
5. **Member Filtering & Multi-select**: Participants multi-select filters and includes only members belonging to the selected project.
6. **Default Project**: Automatically remember last selected project via `SharedPreferences`, or default to the first available project.
7. **Required Project Validation**: Cannot add a new bill without selecting a project; validation error is shown.
8. **Persistence**: Bill saves with the correct `projectId`.
9. **Project Badge in Bill Detail**: Display linked project as a prominent badge in `BillDetailScreen`.
10. **Test Coverage**: 80+ comprehensive tests covering project selection, member filtering, defaults, validation, and persistence.

---

## 3. Architecture & Implementation

### 3.1 UI Layer (`AddBillScreen`)
- **Top Project Selector Card**:
  - Placed before the title/description section.
  - Widget keys: `Key('projectSelector')`, `Key('projectSelectorButton')`, `Key('projectDropdown')`.
  - Displays selected project name with `Key('selectedProjectName')`.
  - Tapping opens the Project Picker Bottom Sheet (`Key('projectPickerBottomSheet')`).
- **Project Picker Bottom Sheet**:
  - Lists projects with `Key('projectPickerItem_${p.id}')` and `Key('projectItem_${p.id}')`.
  - Shows project name, icon, member count, and checkmark for selected project.
  - Tapping a project selects it, updates persistence, and dismisses the bottom sheet.
- **Member Chips & Cards**:
  - `Key('member_chip_$member')` for quick multi-select toggle.
  - `Key('member_card_$member')` for detailed participant card.
  - Updates immediately when `selectedProject` changes.

### 3.2 State Management & Persistence
- **SharedPreferences**: Key `'last_selected_project_id'` stores the last chosen project.
- **ProjectBloc Integration**: Listens to `ProjectLoaded` state to resolve default project.
- **Form Validation**: `_validateForm()` verifies `selectedProject != null` when projects are present or `requireProject == true`.

### 3.3 Bill Detail Screen (`BillDetailScreen`)
- Project badge with keys `Key('billDetailProject')`, `Key('projectBadge')`, and `Key('billProjectBadge')`.
- Displays project name resolved from `ProjectBloc`.

---

## 4. Testing Plan
- 80+ tests in `test/features/split_bills/project_selector_test.dart`
- Full regression tests: 100% pass across entire test suite.
