# Shared-10: Add Missing i18n Keys (Validation Messages + UI Labels)

**Layer:** Localization (i18n)

**Scope:** Add all missing translation keys that are hardcoded in code or missing from en.json + vi.json.

---

## Acceptance Criteria

1. ✅ **Audit code for missing i18n keys**
   - Search all .dart files in lib/ for `translate('...')` calls
   - Identify keys that don't exist in assets/i18n/en.json or vi.json
   - List: bill_name_required, min_2_participants, add_participant, remove_participant, error_adding_bill, invalid_amount, category_food, category_transport, etc.

2. ✅ **Add validation error messages to en.json + vi.json**
   - bill_name_required: "Bill name is required"
   - invalid_amount: "Amount must be a positive number"
   - min_2_participants: "At least 2 participants required"
   - add_participant: "Add Participant"
   - remove_participant: "Remove"
   - error_adding_bill: "Error adding bill"
   - participant_name_required: "Participant name required"

3. ✅ **Add category labels to en.json + vi.json**
   - category_food: "Food"
   - category_transport: "Transport"
   - category_entertainment: "Entertainment"
   - category_utilities: "Utilities"
   - category_shopping: "Shopping"
   - category_health: "Health"
   - category_other: "Other"

4. ✅ **Add UI button/action labels to en.json + vi.json**
   - add_bill: "Add Bill"
   - edit_bill: "Edit Bill"
   - delete_bill: "Delete"
   - save: "Save"
   - cancel: "Cancel"
   - confirm: "Confirm"
   - success: "Success"
   - error: "Error"

5. ✅ **Verify all keys are consistent**
   - en.json and vi.json have same keys (no missing pairs)
   - No duplicate keys
   - All keys are used in code or documented as "reserved for future use"

6. ✅ **Update localization helper (if needed)**
   - AppLocalizations.translate() returns placeholder if key missing (e.g., "[MISSING: key_name]")
   - Or throw clear error for debugging

7. ✅ **Test all keys**
   - No compilation errors
   - All screens display localized text (not raw keys)
   - Switch between en.json + vi.json → verify text updates

8. ✅ **Documentation**
   - List all new keys added in commit message
   - Reference: lib/core/localization/app_localizations.dart

---

## Technical Notes

- **Files to update:**
  - `assets/i18n/en.json`
  - `assets/i18n/vi.json`
- **Pattern:** Use snake_case for all keys
- **Missing placeholder:** If key not found, show "[key_name]" for debugging
- **No code changes needed** — only JSON updates

---

## Owner & Next Step

- **Task ID:** Shared-10
- **Assigned to:** Member (`member:shared-household`)
- **Expected effort:** 1-2 hours (audit + update JSON files)
- **Blockers:** None
- **Deliverable:** Commit with complete i18n keys. All screens display localized text. 0 warnings.
- **Next:** Shared-11 (language selector UI)
