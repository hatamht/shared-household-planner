# Shared-25: Firebase Setup & Authentication (Multi-Device Sync - Phase 1)

## Overview

Phase 1 of **Hướng 3: Multi-Device Sync & Group Sharing** for `shared-household-planner`.
This task sets up the cloud backend infrastructure with Firebase Authentication and Cloud Firestore schema, enabling users to create accounts, sign in, manage profile info, and prepare data models for multi-device synchronization.

## Scope & Requirements

### 1. Firebase Core & Auth Setup
- Configure Firebase dependencies (`firebase_core`, `firebase_auth`, `cloud_firestore` or mock/abstracted cloud repository interfaces for offline-first architecture).
- Implement Authentication repository and use cases:
  - Email & Password registration / sign in.
  - Google Sign-in flow (or guest/anonymous auth upgrade).
  - Sign out, password reset, and auth state stream (`Stream<User?>`).
- Ensure offline-first fallback: users can continue using local SQLite storage without signing in, and optionally link/login to sync.

### 2. Firestore Schema & Security Rules
- Define Firestore collection structure:
  - `users/{uid}`: Profile info (email, displayName, photoUrl, createdAt).
  - `projects/{projectId}`: Project metadata, ownerId, memberIds, permissions, currency, color, icon, updatedAt.
  - `projects/{projectId}/bills/{billId}`: Bills synchronized with local SQLite entities.
  - `projects/{projectId}/settlements/{settlementId}`: Settlement records.
  - `share_invites/{inviteId}`: Invite codes / join links for group sharing.
- Document security rules ensuring only authorized project members can read/write project bills and settlements.

### 3. Presentation Layer
- Authentication screens / bottom sheets or settings integration:
  - Login / Register screen or dialog.
  - User profile badge & account management in Settings screen.
  - Clean error handling (weak password, email already in use, network error).

### 4. Testing & Verification
- Unit tests covering `AuthRepository`, `AuthBloc`, and user entity mappings.
- Widget tests for Login/Register forms with validation and error states.
- Mock Firebase dependencies to guarantee fast and deterministic tests in CI/CD without requiring live network access.

## Acceptance Criteria

1. Firebase project configuration and auth service interfaces integrated.
2. Sign-in, sign-up, sign-out, and auth state listeners implemented with clean BLoC/Repository pattern.
3. Firestore schema defined and documented with security rules.
4. User profile UI available in Settings / Account section.
5. Graceful offline-first operation when user is not signed in.
6. Comprehensive test suite (80+ assertions/tests) for auth flows and schema validation.
