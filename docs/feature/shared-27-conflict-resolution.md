# Shared-27: Conflict Resolution & Safe Merge Logic

## Overview

Phase 3 of **Multi-Device Sync & Group Project Sharing** for `shared-household-planner` (HomeSplit).
This task handles edge cases where multiple users make concurrent changes to shared project bills, categories, or project details while offline or simultaneously online.

## Key Requirements

### 1. Conflict Resolution Strategy
- **Last-Write-Wins (LWW)** with millisecond timestamp + monotonic sequence number.
- Field-level merge where possible:
  - If User A edits bill description while User B edits bill amount, both non-conflicting fields are merged.
  - If both edit the same field, the one with the later `updatedAt` timestamp wins.
- **Delete vs Update Conflict**:
  - If User A deletes a bill while User B edits it:
    - If User B's edit happened after deletion timestamp, restore the bill with B's update.
    - Otherwise, bill remains deleted.

### 2. Data Safety & Local Rollback
- SQLite transactions ensure atomic merge: if remote data processing fails halfway, local SQLite rolls back to last known clean state without data corruption.
- No local data is ever silently lost without a local archive or audit trail.

### 3. User Feedback & Notifications
- SnackBar or non-modal banner informing the user when a conflict was resolved:
  - E.g., *"Đã cập nhật chi tiêu 'Ăn trưa' theo chỉnh sửa mới nhất."*

### 4. Testing Suite
- Comprehensive conflict scenario matrix:
  - Concurrent amount edits.
  - Concurrent participant split changes.
  - Concurrent deletion vs update.
  - Merge recovery on corrupted payload.
- ≥80 unit tests with 100% pass rate.

## Acceptance Criteria

1. Field-level and Last-Write-Wins conflict resolution implemented.
2. Handling of simultaneous bill edits across multiple devices.
3. Safe resolution for delete vs update conflicts.
4. Transactional SQLite rollback protecting local database integrity.
5. In-app feedback notifying users of conflict resolutions.
6. Test suite (≥80 tests) covering all conflict scenarios.
