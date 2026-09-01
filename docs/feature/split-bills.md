# Split Bills Feature Specification - V1.0

## Overview
Track and manage shared household expenses. Single user can create bills, split them among household members, and view expense summaries.

## Acceptance Criteria

### Domain Layer (Phase 1 - THIS TASK)
- [ ] `Bill` entity with fields: id, title, amount, category, date, paidBy, participants
- [ ] `BillParticipant` entity: memberId, amount
- [ ] `BillRepository` interface: create, getAll, getById, update, delete
- [ ] `GetBillsUseCase`: fetch all bills
- [ ] `AddBillUseCase`: create new bill with participants
- [ ] Unit tests passing for all entities and use cases (80%+ coverage)

### Data Layer (Phase 2 - Follow-up)
- [ ] SQLite models mapping Bill entity
- [ ] BillRepositoryImpl implementing persistence

### Presentation Layer (Phase 3 - Follow-up)
- [ ] BillBloc state management
- [ ] UI for bill creation and listing

## Implementation Notes
- Follow Clean Architecture pattern strictly
- Place files under `lib/features/split_bills/domain/`
- Use Equatable for entity comparison
- Keep entities independent of framework
- Single-user app (V1.0) - no auth/permissions needed
- Local storage only via SQLite


## Implementation Notes (Continued)

### Data Layer (Phase 2 - NEXT TASK)
- SQLite model mapping Bill entity
- Local data source for SQLite operations
- BillRepositoryImpl implementation
- Place files under `lib/features/split_bills/data/`

### Presentation Layer (Phase 3)
- BillBloc for state management
- Bill list and creation screens
- Place files under `lib/features/split_bills/presentation/`
