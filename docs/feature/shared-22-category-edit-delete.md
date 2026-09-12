# Shared-22: Category Edit & Delete Specification

## 1. Overview
This specification details the Category Edit & Delete feature for `AddBillScreen` in the Shared Household Planner Flutter app. Users can edit existing custom categories (name, icon, color) and delete them with confirmation, while system default categories are protected against accidental deletion.

## 2. Acceptance Criteria
1. **Category edit:** Long-press or swipe category pill in selector opens edit bottom sheet pre-filled with current name, icon, and color.
2. **Edit bottom sheet:** Category name input, icon picker, color picker, save/cancel buttons, and delete button at the bottom (red warning style).
3. **Edit functionality:** User can change name, icon, or color. Tapping Save updates the category and all bills referencing this category.
4. **Category delete:** Tapping delete button in edit bottom sheet prompts a confirmation dialog (Title: "Delete category?", Message: "This action cannot be undone.", Buttons: Cancel / Delete).
5. **Delete confirmation:** Tapping Delete removes the category, and existing bills with this category are safely migrated to the default category (`restaurant`) or labeled as `(Deleted)`.
6. **Prevent delete of system categories:** 12 default categories (`restaurant`, `transport`, `shopping`, `health`, `entertainment`, `travel`, `utilities`, `education`, `party`, `office`, `pet`, `sport`) cannot be deleted. Shows toast/snackbar: "Cannot delete default categories".
7. **Category selector UI update:** Shows edit pencil affordance and context menu/hint on long-press.
8. **i18n:** Translations added to `en.json` and `vi.json` for all new UI strings.
9. **Edge cases handled:** Empty name, duplicate name, deleting selected category, cancelling delete, etc.
10. **Real-time update:** Category selector updates immediately after edit or delete without requiring a page refresh.
11. **Test Coverage:** Comprehensive unit and widget test suite covering all scenarios.
