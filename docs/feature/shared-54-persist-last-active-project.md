# Shared-54: Persist Last Active Project & Auto-Restore on App Launch

## 1. Overview
Persist the last active project (`last_active_project_id`) across app sessions using `SharedPreferences`.
When the user reopens the app:
- If a valid project exists with that ID, auto-navigate to `ProjectDetailScreen` for that project.
- If the project no longer exists (e.g., deleted) or no ID was stored, start safely on `HomeScreen`.
- The user can press Back from `ProjectDetailScreen` to return to `HomeScreen` smoothly.
- Updating or deleting projects updates/clears the stored ID accordingly.

## 2. Acceptance Criteria
1. Save `last_active_project_id` to `SharedPreferences` whenever user opens `ProjectDetailScreen` or saves a bill for a project.
2. On app startup, read `last_active_project_id` from `SharedPreferences`.
3. If valid project found in database, automatically navigate to `ProjectDetailScreen` for that project on launch.
4. If project no longer exists (deleted) or id is null, start on default `HomeScreen` safely.
5. User can press Back from auto-restored `ProjectDetailScreen` to return to `HomeScreen` cleanly.
6. Updating or deleting projects updates/clears the stored `last_active_project_id` accordingly.
7. Provide smooth transition without flickering or white screen during initial route resolution.
8. Dark and Light theme support across app launch and state restoration.
9. Full EN/VI localization support.
10. Unit and widget tests (15+ tests) covering state saving, auto-restore navigation, and deleted project fallback.

## 3. Architecture & Implementation Plan
- **Service Layer**:
  - `LastActiveProjectService`:
    - Storage key: `last_active_project_id`.
    - Methods: `getLastActiveProjectId()`, `setLastActiveProjectId(String id)`, `clearLastActiveProjectId()`, `onProjectDeleted(String id)`.
    - In-memory caching for synchronous checks and fallback handling.
- **Trigger Points for Saving State**:
  - `ProjectDetailScreen.initState`: called whenever user enters project details.
  - `AddBillScreen._submitForm`: called whenever a bill is saved with an associated project.
- **Trigger Points for Clearing / Updating State**:
  - `ProjectBloc.DeleteProject`: if deleted project matches `last_active_project_id`, clears it.
  - `ProjectBloc.UpdateProject`: verifies and maintains state consistency.
- **Startup Auto-Restoration**:
  - `HomeScreen`: in post-frame callback, checks `last_active_project_id`.
  - If project found in `ProjectBloc` or `ProjectRepository`, pushes `ProjectDetailScreen`.
  - Pressing Back cleanly pops back to `HomeScreen`.
- **Localization**:
  - Add keys `last_active_project` and `auto_restoring_project` to `en.json` and `vi.json`.
