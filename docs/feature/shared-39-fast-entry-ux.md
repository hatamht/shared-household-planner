# Shared-39: AddBillScreen Fast Entry UX Redesign

## Overview

Redesigned bill entry experience focusing on minimum friction. CEO feedback: current `AddBillScreen` is too heavy. Target: go from open to saved in under 5 seconds.

## Acceptance Criteria (All Met ✅)

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Screen opens with keyboard active, cursor at description field | ✅ `autofocus` via `postFrameCallback` |
| 2 | Only 2 primary inputs: Description (large field) + Amount (large number) | ✅ Done |
| 3 | Compact secondary bar: Date chip (Today), Members chip, Camera icon, More | ✅ Done |
| 4 | Default split chip: "Paid by you and split equally" (tap to change) | ✅ Done |
| 5 | Date/Members open as modals or bottom sheets (not new screens) | ✅ Both use `showModalBottomSheet` / `showDatePicker` |
| 6 | Category auto-detected from description (silent, no UI required) | ✅ `detectCategoryFromText()` — keyword matching |
| 7 | Save button in header, disabled until Amount > 0 | ✅ `TextButton` with `onPressed: _canSave ? _submitBill : null` |
| 8 | Dark/light theme and i18n (EN/VI) support | ✅ Full theme + JSON translations |
| 9 | Tests: 80+ covering fast-entry flow, chip taps, keyboard behavior | ✅ **100 tests, 100 pass** |

## Architecture

```
lib/features/split_bills/presentation/pages/
  fast_add_bill_screen.dart     ← NEW screen (additive, backward-compat)
  add_bill_screen.dart          ← UNTOUCHED (old full form kept)
  bills_list_screen.dart        ← Updated FAB to use FastAddBillScreen
```

## Key Design Decisions

### Category Auto-Detection
- `detectCategoryFromText(text)` — pure function, exported for testing
- Checks keywords in priority order; default fallback = `restaurant`
- Uses Vietnamese-aware keywords (e.g., `cơm`, `phở`, `xe`, `xăng`)
- Category emoji animates via `AnimatedSwitcher` (no flash/blink)

### Bottom Sheets (not new screens)
- **Members**: `showModalBottomSheet` with `CheckboxListTile` per member
- **Date**: `showDatePicker` standard material dialog
- **Split**: Custom bottom sheet with paid-by chips + split mode chips

### Save Flow
- Amount-only required (description optional, defaults to category name)
- Bill created with `equal` split across selected members
- Dispatches `AddBillEvent` → `BillsBloc` → pops route

## New Files

| File | Purpose |
|------|---------|
| `lib/.../fast_add_bill_screen.dart` | New FastAddBillScreen widget |
| `test/.../fast_add_bill_screen_test.dart` | 100-test suite |
| `docs/feature/shared-39-fast-entry-ux.md` | This spec |

## Localization Keys Added

```
today, fast_description_hint, fast_split_equal_label,
fast_camera_hint, fast_more_hint, more, you, description
```
