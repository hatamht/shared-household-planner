# Shared-9: AddBillScreen + Integration Tests

**Layer:** Presentation (Add Bill form + integration tests)

**Scope:** Implement AddBillScreen form widget, integrate with BLoC, and write integration tests to verify end-to-end flow.

---

## Acceptance Criteria

1. ✅ **Create AddBillScreen widget**
   - Location: `lib/features/split_bills/presentation/pages/add_bill_screen.dart`
   - StatefulWidget with form (TextFormField for title, amount, category, paidBy, participants)
   - Use Material Form + TextFormField with validation

2. ✅ **Form validation**
   - Title: required, min 1 char
   - Amount: required, must be double > 0
   - Category: required, dropdown or text
   - PaidBy: required, text field
   - Participants: required, at least 1 with name + amount

3. ✅ **BLoC integration**
   - Read AddBillBloc via `context.read<AddBillBloc>()`
   - Submit form → `AddBillBloc.add(AddBillEvent(bill))`
   - Listen to AddBillState (loading, success, error)
   - Show loading spinner while submitting
   - Show snackbar on success/error

4. ✅ **Navigation**
   - AddBillScreen pushed from HomeScreen or BillsListScreen (via FAB or button)
   - On success: Pop back to previous screen (HomeScreen or BillsListScreen)
   - On error: Stay on form, show error message

5. ✅ **Apply i18n**
   - Form labels from AppLocalizations: 
     - 'add_bill' (screen title)
     - 'title' (field label)
     - 'amount' (field label)
     - 'category' (field label)
     - 'paid_by' (field label)
     - 'participants' (section title)
     - 'submit' (button text)
   - Add strings to en.json + vi.json

6. ✅ **Apply theme**
   - Use Theme.of(context) for colors
   - TextFormField inherits input decoration from theme
   - Button uses theme colors
   - No hardcoded colors

7. ✅ **Integration test #1: Add bill happy path**
   - Test file: `test/integration/add_bill_test.dart`
   - Steps:
     1. Launch app (pump widgets)
     2. Navigate to AddBillScreen
     3. Enter bill data (title, amount, category, paidBy, participant)
     4. Tap submit button
     5. Wait for BLoC event and response
     6. Verify: Bill added event fired, BlocBuilder updates state
     7. Verify: Screen pops back to previous screen

8. ✅ **Integration test #2: Add bill error handling**
   - Test file: `test/integration/add_bill_error_test.dart`
   - Steps:
     1. Launch app
     2. Navigate to AddBillScreen
     3. Submit form with invalid data (missing title)
     4. Verify validation error shown
     5. Fix form (add title)
     6. Submit again
     7. Mock BLoC to return AddBillError state
     8. Verify error snackbar shown

9. ✅ **Manual testing**
   - App launch → HomeScreen
   - Navigate to BillsListScreen
   - Tap FAB or button → AddBillScreen
   - Fill form with valid data
   - Tap submit → bill persisted in SQLite (verify by navigating back + forward)
   - Check BillsListScreen shows new bill

10. ✅ **No warnings + code quality**
    - `flutter analyze` passes
    - No unused imports
    - Form validation logic testable and clear
    - Error handling includes try-catch where needed
    - All 2+ integration tests passing

---

## Technical Notes

- **Form Pattern:** StatefulWidget with TextFormField + GlobalKey<FormState>
- **Validation:** Use FormFieldValidator<T> or manual validate()
- **BLoC Pattern:** BlocListener for navigation/snackbar, BlocBuilder for loading/error
- **Participants:** Array of {memberId, amount} — can be simplified to {name, amount} for this MVP
- **Database:** AddBillUseCase calls BillRepository.create() → BillLocalDataSourceImpl.addBill() → SQLite insert
- **Integration Tests:** Use `testWidgets()` from flutter_test, `WidgetTester.pumpWidget()`

---

## File Structure

```
lib/
├── features/split_bills/
│   └── presentation/
│       └── pages/
│           └── add_bill_screen.dart   ← NEW
├── assets/
│   └── i18n/
│       ├── en.json                    ← Add i18n keys
│       └── vi.json                    ← Add i18n keys

test/
├── integration/                       ← NEW (or test/features/split_bills/add_bill_test.dart)
│   ├── add_bill_test.dart             ← NEW
│   └── add_bill_error_test.dart       ← NEW (optional if combined)
```

---

## Owner & Next Step

- **Task ID:** Shared-9
- **Assigned to:** Member (`member:shared-household`)
- **Expected effort:** 3-4 hours (form layout, BLoC integration, 2 integration tests)
- **Blockers:** Shared-7 (home navigation) + Shared-8 (DI setup) must be done
- **Deliverable:** Commit with AddBillScreen, i18n, theme, ≥2 integration tests passing. 0 warnings. Manual test verified.
- **End goal:** After t9 approved, app fully integrated: navigate home → bills → add bill → persisted

---

## Acceptance Handoff

Once t9 approved, all 3 subtasks (t7, t8, t9) complete the original t6 scope:
- ✅ HomeScreen with navigation
- ✅ DI setup (BLoCs, repos, usecases)
- ✅ AddBillScreen with form + integration tests
- ✅ Main.dart integrated (home, DI, BLoCs, theme, i18n)

Remaining: Market testing + QA.
