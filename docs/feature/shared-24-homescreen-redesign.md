# Shared-24: HomeScreen UI Redesign (Projects List + Navigation)

**Layer:** Presentation (UI, State Management, Navigation)  
**Priority:** High  
**Type:** Feature / Redesign (Tricount-style Dashboard)

---

## Overview

Redesigned `HomeScreen` to transform the app into a modern Tricount-style group expense sharing dashboard. The new home experience provides a bottom navigation bar with 4 tabs, a vertical scrollable list of project cards displaying real-time member & bill statistics, an overview stats card, a floating action button (FAB) for quick project creation, pull-to-refresh data synchronization, project quick actions (swipe-left to delete and long-press context menu), and full theme (light/dark) + i18n support.

---

## Acceptance Criteria & Implementation Details

1. ✅ **Header section:**
   - App title ("Shared Household Planner" / translated) in AppBar.
   - Preserves theme toggle button (`Key('themeToggleButton')`) and language dropdown selector.
   - Subtle 0.5 elevation for a polished header divider.
2. ✅ **Projects list:**
   - Vertical scrollable list of project cards.
   - Each card shows: colored circle avatar with initial, project name, brief stats (e.g., "3 members, 1 bills, €45.50 total"), and project description.
3. ✅ **Project card styling:**
   - Theme-adaptive background (dark #1E1E1E / light #FFFFFF).
   - Rounded corners (16px), subtle elevation shadow (2.0), ink ripple feedback on tap.
   - Tap navigates to `ProjectDetailScreen`.
4. ✅ **Empty state:**
   - Displayed when no projects exist.
   - Folder icon, "No projects yet" title, descriptive subtitle prompt, and "Add Project" button (`Key('emptyStateAddProjectButton')`).
5. ✅ **Floating Action Button (FAB):**
   - Blue circular button in bottom-right with `+` icon (`Key('addProjectButton')`).
   - Tapping opens `CreateProjectScreen`.
   - Hidden on non-projects tabs for clean tab UX.
6. ✅ **Bottom navigation bar:**
   - 4 tabs: (1) Projects (home/folder icon), (2) Requests/Bills (receipt icon), (3) Settings (gear icon), (4) Profile (user icon).
   - `Key('bottomNavigationBar')`.
7. ✅ **Bottom nav styling:**
   - Theme-adaptive background (dark #1E1E1E / light #FFFFFF) with top shadow.
   - Active tab highlighting in primary color, fixed layout, all labels shown.
8. ✅ **Summary Stats card:**
   - Overview card (`Key('statsSummaryCard')`) displaying 4 key metrics: Total Projects, Total Members (unique), Total Bills, and Total Spent (currency formatted).
9. ✅ **Pull-to-refresh:**
   - `RefreshIndicator` with `Key('pullToRefresh')` wraps projects list.
   - Pulling down triggers data reload on `ProjectBloc` and `BillsBloc`.
10. ✅ **Project quick actions:**
    - Swipe left (`Dismissible` `Key('dismissible_<id>')`) reveals delete action and triggers confirmation dialog.
    - Long press on project card opens modal bottom sheet context menu with Edit Project, Leave Project, and Delete Project.
11. ✅ **i18n:**
    - All labels (`requests`, `profile`, `add_project`, `all_projects`, `create_first_project_prompt`, `leave_project`, `total_members`, `total_bills_count`, `overview`) added to `en.json` and `vi.json`.
12. ✅ **Tests:**
    - 105 comprehensive tests in `test/features/home/home_screen_redesign_test.dart`.
    - Total test suite: 588 / 588 tests passing (100%).

---

## Verification Results

- `test/features/home/home_screen_redesign_test.dart`: 105/105 passed.
- Full suite: 588/588 passed.
