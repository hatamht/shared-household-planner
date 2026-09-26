# Shared-30: Multi-Device Sync Integration Testing, Edge Cases & Polish

## Overview

Final phase of **Multi-Device Sync & Group Project Sharing** for `shared-household-planner` (HomeSplit).
This task performs comprehensive end-to-end integration testing across simulated multiple devices, handles extreme edge cases (offline transitions, simultaneous updates), and polishes the user interface.

## Key Requirements & Scenarios

### 1. Multi-Device End-to-End Test Suite
- Scenario 1: **Travel Trip Collaboration**:
  - User A (Owner) creates "Du lịch Phú Quốc".
  - User A generates invite code `PQ-9988` and shares with User B.
  - User B joins project with code `PQ-9988`.
  - User A adds bill "Vé máy bay: 3.500.000đ".
  - User B sees bill automatically (or taps Sync 🔄) within 2 seconds.
  - User B adds bill "Ăn tối hải sản: 1.200.000đ".
  - Both users see updated balance calculations and debt settlement.

### 2. Edge Case & Stress Testing
- **Airplane Mode / Offline-Online transition**:
  - User logs 5 bills while on airplane (offline).
  - Turns on Wi-Fi upon landing -> All 5 bills automatically sync to cloud without duplicate entries.
- **Rapid Simultaneous Edits**:
  - Both users edit bill notes at the exact same second -> Safe merge without crashes or lost data.
- **Flaky / Intermittent Network**:
  - Network timeout simulation during sync -> Automatic retry with exponential backoff.

### 3. UI/UX Polish & Feedback
- Manual Sync Button (🔄) animations:
  - Smooth 360-degree continuous rotation during active sync.
  - Success feedback (green checkmark flash) upon sync completion.
- Badges:
  - Clear "Đã đồng bộ" vs "Chưa đồng bộ" indicator badges.
- SnackBar alerts with actionable hints if sync is interrupted.

### 4. Verification & Metrics
- Integration test suite (≥100 tests) testing multi-device interaction models.
- Total app test suite passes with zero regressions.

## Acceptance Criteria

1. End-to-end multi-device sharing and expense logging flow verified by automated integration tests.
2. Robust offline-to-online transitions with queue deduplication.
3. Smooth manual sync button animation and clear visual status indicators.
4. Latency under 2 seconds for cloud propagation under normal network conditions.
5. 100+ tests covering integration scenarios, edge cases, and animations.
