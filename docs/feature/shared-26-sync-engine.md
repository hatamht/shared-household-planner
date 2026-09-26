# Shared-26: Sync Engine & Manual Sync Button (Upload, Download & Status)

## Overview

Phase 2 of **Multi-Device Sync & Group Project Sharing** for `shared-household-planner` (HomeSplit).
This task implements the bi-directional Sync Engine between local SQLite and Cloud Firestore, along with a prominent **Manual Sync Button (🔄)** and real-time sync status indicator across the UI.

## Key Requirements & Architecture

### 1. Sync Engine Core
- `SyncService` singleton managing synchronization queue:
  - Tracks local pending modifications: `sync_status` column in SQLite (`synced`, `pending_upload`, `conflict`).
  - `last_synced_at` timestamp recorded per project and globally.
- Background sync:
  - Triggers automatically when network connectivity is restored or changes occur locally while online.
  - Throttled debouncing to avoid excessive writes.

### 2. Manual Sync Button (🔄)
- **Placement**:
  - AppBar action on Project Detail screen.
  - Quick action on Home Screen header / Project Card.
- **Interactions**:
  - Tapping 🔄 immediately initiates upload of pending local changes and pulls latest remote changes.
  - While syncing, the icon spins smoothly (`RotationTransition`).
  - When sync completes, icon briefly pulses green with a tooltip / snackbar "Đồng bộ thành công".
  - If offline, tapping shows a non-intrusive toast: "Bạn đang ngoại tuyến. Dữ liệu đã lưu trên máy và sẽ đồng bộ khi có mạng."

### 3. Sync Status Indicator
- Displays current state:
  - **Đã đồng bộ** (Green check / synced badge).
  - **Đang đồng bộ...** (Spinning indicator).
  - **Chưa đồng bộ (N thay đổi)** (Yellow badge showing unsynced item count).
  - **Lần đồng bộ cuối: X phút trước / Vừa xong**.

### 4. Testing & Reliability
- Network mocking with connectivity state toggles (`online`, `offline`, `slow`).
- Unit and widget tests (≥80 tests) validating:
  - Queue operations (insert pending, mark synced).
  - Manual sync button triggers and UI animations.
  - Status indicator transitions.

## Acceptance Criteria

1. `SyncService` handles two-way sync between SQLite and Cloud Firestore.
2. Manual Sync Button (🔄) implemented with smooth spin animation during sync.
3. Sync status indicator visible on project details and home screen.
4. Offline handling: changes queued locally; clear offline feedback when user taps sync button.
5. Auto-sync on network reconnect and debounced write triggers.
6. Test suite (≥80 tests) covering sync engine, manual sync button, and indicators.
