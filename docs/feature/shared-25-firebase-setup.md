# Shared-25: Firebase Auth (1-Tap Google/Email) & Cloud Schema (Multi-Device Sync - Phase 1)

## Overview

Phase 1 of **Multi-Device Sync & Group Project Sharing** for `shared-household-planner` (HomeSplit).
This task sets up Firebase Authentication and Cloud Firestore schema, enabling users to optionally sign in (Google 1-Tap or Email/Password) when sharing or joining projects, while maintaining complete offline-first usability for non-authenticated users.

## Key Requirements & Philosophy

### 1. Offline-First Non-Intrusive Auth
- **No mandatory login**: Users can use the entire app offline (create projects, log bills, split debts, view charts, export PDF) with local SQLite without ever creating an account.
- **Contextual Auth Prompt**: When a user taps **"Chia sẻ dự án"** (Share Project) or **"Tham gia dự án"** (Join Project), a modal/bottom-sheet appears explaining why an account is needed (to link across devices) and offers:
  - 1-Tap Google Sign-In (`google_sign_in` / Firebase Google credential).
  - Quick Email & Password registration / sign in.
- **Guest / Anonymous Upgrade**: When an offline user signs in, their existing local projects can seamlessly sync with their new account.

### 2. Firestore Schema & Security Rules
- Collections:
  - `users/{uid}`: Profile info (email, displayName, photoUrl, createdAt, lastLoginAt).
  - `projects/{projectId}`:
    - Metadata: `id`, `name`, `currency`, `category`, `color`, `icon`, `ownerId`, `memberIds: [uid1, uid2...]`, `inviteCode`, `createdAt`, `updatedAt`.
  - `projects/{projectId}/bills/{billId}`:
    - Bills belonging to this project (amount, description, payerId, splitMethod, splits, date, createdAt, updatedAt, createdBy).
  - `projects/{projectId}/settlements/{settlementId}`:
    - Settlement debt payments between members.
  - `share_invites/{inviteCode}`:
    - Unique 6-character code (e.g., `DL-8899`), `projectId`, `createdBy`, `createdAt`, `expiresAt`, `isActive`.
- Security Rules:
  - Only authenticated users can read/write.
  - Users can only read/write documents in `projects/{projectId}` if `request.auth.uid in resource.data.memberIds` (or request resource).
  - Only `ownerId` can delete projects or remove members.

### 3. Presentation Layer
- **Account / Profile in Settings**:
  - Displays user profile badge (avatar, name, email) or "Dùng ngoại tuyến (Chưa đăng nhập)".
  - Button to Sign In / Register or Log Out.
- **Contextual Sign-In Sheet**:
  - Modal bottom sheet with friendly UX when tapping "Share" or "Join" from project screens.

### 4. Testing & Mock Architecture
- All Firebase services wrapped in repository interfaces (`AuthRepository`, `CloudSyncRepository`).
- Comprehensive unit and widget tests (≥80 tests) using mocks (no real network required during tests).

## Acceptance Criteria

1. Firebase Auth integration supporting 1-Tap Google Sign-In & Email/Password.
2. Complete offline-first support: app operates 100% offline without requiring login.
3. Contextual sign-in sheet when tapping "Chia sẻ dự án" or "Tham gia dự án".
4. Cloud Firestore schema designed with collections `users`, `projects`, `bills`, `settlements`, `share_invites`.
5. Security rules defined restricting access to project members only.
6. Settings screen includes Profile / Auth management section.
7. Unit & Widget test suite (≥80 tests) with clean mocking and 100% pass rate.
