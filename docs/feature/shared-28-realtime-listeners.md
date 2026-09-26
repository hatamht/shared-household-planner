# Shared-28: Real-time Listeners & Remote Change Notifications

## Overview

Phase 4 of **Multi-Device Sync & Group Project Sharing** for `shared-household-planner` (HomeSplit).
This task implements Firestore real-time snapshot listeners for shared projects, instantly reflecting bills and updates made by other members without needing to leave or refresh the screen.

## Key Requirements

### 1. Firestore Real-Time Streams
- When a user opens a shared project, attach a stream listener to:
  - `projects/{projectId}/bills`
  - `projects/{projectId}`
- Automatically update local SQLite store and UI state when remote changes arrive.
- Efficient stream disposal (`cancel()`) when navigating away from the project to save battery and network bandwidth.

### 2. Live Collaboration Feedback
- When another user adds or edits an expense:
  - Subtle highlight animation on the newly added/updated bill item in the list.
  - In-app SnackBar notification:
    - E.g., *"Minh vừa thêm chi tiêu: 120.000đ [Vé tham quan]"*
- Total project expenditure and member balances update automatically.

### 3. Testing & Verification
- Stream lifecycle tests: verify subscriptions are canceled on screen disposal.
- Multi-subscriber tests: verify multiple listeners receive updates properly.
- UI widget tests verifying list auto-updates upon incoming snapshot stream events.
- ≥80 unit & widget tests.

## Acceptance Criteria

1. Firestore snapshot listeners integrated with BLoC state management.
2. Shared project screens update automatically when remote changes occur.
3. In-app banner/toast notifications for incoming member additions and updates.
4. Proper lifecycle management: listeners cleanly canceled on screen disposal.
5. Battery and network optimized: zero active cloud listeners when app is backgrounded.
6. Test suite (≥80 tests) validating stream events, UI updates, and disposal.
