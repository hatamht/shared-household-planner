# Shared-38: Payment History & Settlement Log

## Overview
Provides an audit trail for household and project expense settlements. Whenever household members settle debts (e.g., Alice pays Bob €25 via bank transfer), they can record the transaction, mark it as paid or pending, attach payment notes, track running balance evolution, and export the settlement history alongside bill reports.

## Acceptance Criteria
1. **Payment history screen in Settings or Details**:
   - Accessible via SettingsScreen under preferences/data sections.
   - Accessible via ProjectDetailScreen on the Settlement tab.
2. **Log each settlement**:
   - Record fields: `payer` (who paid), `payee` (whom), `amount`, `date`, `status` (`paid` or `pending`), `note`, `projectId`.
3. **Mark settlement as paid or pending**:
   - Toggle status between `paid` and `pending` directly with instantaneous feedback.
4. **Display timeline (oldest settlement first)**:
   - Chronological timeline ordering oldest to newest to reflect historical evolution.
5. **Filter by person, date range, status**:
   - Filter by involved person (payer or payee matches).
   - Filter by date range (allTime, thisMonth, lastMonth, custom).
   - Filter by status (all, paid, pending).
6. **Add payment note**:
   - Support descriptive notes (e.g. "Paid via bank transfer", "Cash settlement").
7. **Show balance evolution**:
   - Compute and display cumulative running total after each payment in chronological sequence.
8. **Undo mark-as-paid (revert to pending)**:
   - Actionable undo capability to revert a paid settlement back to pending.
9. **Export payment history with bills export**:
   - CsvGenerator and PdfGenerator include settlement history logs.
10. **Comprehensive tests (80+)**:
    - Complete test suite covering entity validation, repository persistence, timeline sequencing, filtering, balance evolution calculation, UI interaction, dark/light theme, and i18n.
