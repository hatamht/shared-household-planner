# Shared-34: Search & Filter Bills

## 1. Overview
As households and projects record more and more shared expenses, finding specific transactions becomes difficult without search and filter capabilities. Shared-34 introduces a real-time search and multi-criteria filtering system directly on the bills list screen (`BillsListScreen`).

## 2. Acceptance Criteria
1. **Search by bill title/description (real-time as you type)**: Instant filtering as characters are typed into the search bar, with a clear query button.
2. **Filter by person (dropdown, multi-select)**: Multi-select filtering for involved persons (payer and participants).
3. **Filter by category (dropdown, multi-select)**: Multi-select filtering for bill categories.
4. **Filter by date range (From/To date picker)**: From Date and To Date pickers with full inclusive boundary filtering.
5. **Filter by amount range (Min/Max slider)**: Interactive dual-thumb RangeSlider with Min and Max bounds based on bill amounts.
6. **Combine multiple filters (all must match)**: Strict AND logic across all active criteria.
7. **Display result count**: Clear feedback indicator showing e.g., "12 bills found" or "1 bill found".
8. **Clear all filters button**: One-tap button resetting all criteria back to default.
9. **Persist search/filter state on screen leave/return**: Search and filter criteria persist across screen transitions, tab switches, and app restarts via `BillFilterPersistenceService` and `SharedPreferences`.
10. **Tests**: 100+ tests covering unit logic, serialization, UI interactions, and filter combinations.

## 3. Architecture & Implementation
- `BillFilter` (`lib/features/split_bills/domain/entities/bill_filter.dart`): Immutable value object encapsulating all filter dimensions, evaluation predicate `matches(Bill)`, list transform `apply(List<Bill>)`, count helpers, and JSON serialization.
- `BillFilterPersistenceService` (`lib/features/split_bills/domain/services/bill_filter_persistence_service.dart`): In-memory caching and SharedPreferences persistent store.
- `BillSearchFilterBar` (`lib/features/split_bills/presentation/widgets/bill_search_filter_bar.dart`): Compact search input, quick horizontal filter chips, result count, and clear all actions.
- `BillFilterBottomSheet` (`lib/features/split_bills/presentation/widgets/bill_filter_bottom_sheet.dart`): Comprehensive modal bottom sheet supporting person multi-select, category multi-select, date pickers, and amount range slider.
- `BillsListScreen` (`lib/features/split_bills/presentation/pages/bills_list_screen.dart`): Integrates search and filtering seamlessly with backward compatibility for existing tests and routes.
