# Feature Specification: Shared-52 Persist Project Icon & Color and Apply to ProjectScreen & ProjectDetailScreen

## 1. Overview
In previous iterations, `CreateProjectScreen` provided a visual icon and color selector for projects, but the selected choices were neither persisted into the SQLite database nor displayed across other project screens (`ProjectScreen`, `ProjectDetailScreen`, and `AddBillScreen` project selector).

This feature completes the end-to-end icon and color theming capability by:
1. Adding `iconIndex` (int) and `colorIndex` (int) to the `Project` entity and `ProjectModel` with fallback to default index 0.
2. Updating the SQLite database schema (`version: 10`) to store and retrieve `iconIndex` and `colorIndex`.
3. Updating `CreateProjectScreen` to persist selected indices upon creating or editing, and pre-selecting existing project icon and color when opened in edit mode.
4. Displaying the chosen project icon and color on `ProjectScreen` leading `CircleAvatar` (and on `HomeScreen` project cards).
5. Adapting `ProjectDetailScreen` AppBar and header to the project's chosen color (with dynamic gradient accent and contrast-aware foreground/icon).
6. Enhancing `AddBillScreen` project selector container and project picker bottom sheet with project icon and color chips for instant identification.
7. Ensuring strict contrast and legibility across both dark and light modes.
8. Preserving backward compatibility for existing records without icon/color indices.

---

## 2. Acceptance Criteria
1. **Entity & Model**: `Project` entity and `ProjectModel` include `iconIndex` (int) and `colorIndex` (int) with default fallback `0`.
2. **Database Persistence**: SQLite `projects` table updated (DB version 10) with migration and `iconIndex`, `colorIndex` columns with default `0`.
3. **Creation & Update**: `CreateProjectScreen` persists `_selectedIconIndex` and `_selectedColorIndex` into the created/updated `Project`.
4. **Edit Mode Pre-selection**: `CreateProjectScreen` pre-selects existing project `iconIndex` and `colorIndex` when editing.
5. **ProjectScreen Rendering**: `ProjectScreen` displays chosen `iconData` and `color` in the card leading `CircleAvatar`.
6. **ProjectDetailScreen Theming**: `ProjectDetailScreen` AppBar adapts project color gradient and shows the project icon alongside its name.
7. **AddBillScreen Selector**: `AddBillScreen` project selector and bottom sheet show project icon and color chips.
8. **Legibility & Contrast**: High-contrast icon and typography (luminance check dynamically switching between white and dark labels).
9. **Backward Compatibility**: Projects created prior to this update default gracefully to index 0 without crashes or database errors.
10. **Automated Tests**: Comprehensive suite (20+ tests) verifying entity serialization, database schema migration, and UI widget rendering across screens.

---

## 3. Architecture & Implementation

### 3.1 Domain Layer
- Created `ProjectPalette` (`lib/features/projects/domain/entities/project_palette.dart`):
  - Standardized list of 8 project icons: apartment, home, flight takeoff, restaurant, celebration, school, work, shopping bag.
  - Standardized list of 6 project colors: Indigo, Teal, Deep Orange, Amber, Purple, Blue.
  - Safe accessors `getIcon(int index)` and `getColor(int index)`.
- Updated `Project` entity (`lib/features/projects/domain/entities/project.dart`):
  - Added `final int iconIndex;` and `final int colorIndex;` (default 0).
  - Getters `iconData` and `color`.
  - Updated `copyWith` and `props`.

### 3.2 Data Layer
- Updated `ProjectModel` (`lib/features/projects/data/models/project_model.dart`):
  - `fromJson`, `toJson`, `toSqliteMap`, and `fromEntity` serialize `iconIndex` and `colorIndex`.
- Updated `DatabaseHelper` (`lib/features/split_bills/data/datasources/database_helper.dart`):
  - Bumped version to `10`.
  - Added migration `oldVersion < 10` altering `projects` table with `iconIndex INTEGER DEFAULT 0` and `colorIndex INTEGER DEFAULT 0`.
  - Updated `_createTables` projects schema.

### 3.3 Presentation Layer
- `CreateProjectScreen`:
  - Pre-selects `_selectedIconIndex` and `_selectedColorIndex` in `initState` from `widget.project`.
  - Passes `iconIndex` and `colorIndex` into `Project` in `_saveProject`.
- `ProjectScreen`:
  - Displays `project.color` and `project.iconData` with luminance-aware contrast in `CircleAvatar`.
- `HomeScreen`:
  - Displays `project.color` and `project.iconData` in project cards.
- `ProjectDetailScreen`:
  - AppBar title contains `project.iconData` and `project.name`.
  - AppBar `backgroundColor` and `flexibleSpace` use project color gradient.
  - Luminance calculation adjusts `onProjectColor` and TabBar label colors for contrast.
- `AddBillScreen`:
  - Top `projectSelector` displays project icon and `selectedProjectColorChip`.
  - `projectPickerBottomSheet` items show project icon, color avatar, and color chips.
