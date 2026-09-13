# Feature Specification: Shared-36 Quick Bill Templates

## 1. Overview
The Quick Bill Templates feature allows users to save frequently occurring bills (such as rent, electricity, weekly groceries, subscriptions) as reusable templates. Users can create templates from scratch or directly from existing bills, manage them in a dedicated screen, mark favorites, get intelligent suggestions based on usage patterns, and spawn pre-filled bills with 1-2 taps without altering the original template.

## 2. Acceptance Criteria
- [x] **AC 1**: Create template from existing bill (with a dedicated "Save as Template" action).
- [x] **AC 2**: Template stores title, amount, category, categoryIcon, categoryColor, currency, split mode, paidBy, and participants.
- [x] **AC 3**: Template management screen supporting listing, searching/filtering, editing, and deleting templates with confirmation.
- [x] **AC 4**: Quick create bill from template with 1-2 taps from HomeScreen, SplitBillsScreen, or AddBillScreen.
- [x] **AC 5**: Pre-fill all fields in AddBillScreen from template, allowing user confirmation or immediate adjustment before saving.
- [x] **AC 6**: Mark / toggle favorite templates (`isFavorite`) for prioritized pinned access.
- [x] **AC 7**: Suggest templates based on recent and frequent usage patterns (`usageCount`, `lastUsedAt`).
- [x] **AC 8**: Editing bill values after spawning from template leaves the original template completely untouched.
- [x] **AC 9**: Comprehensive test suite (80+ unit and widget tests) covering template CRUD, persistence, state management, and quick-create workflows.

## 3. Data Model Schema
### Table: `bill_templates`
- `id TEXT PRIMARY KEY`
- `title TEXT NOT NULL`
- `amount REAL NOT NULL`
- `category TEXT NOT NULL`
- `categoryIcon TEXT`
- `categoryColor TEXT`
- `currency TEXT DEFAULT 'VND'`
- `paidBy TEXT`
- `participants TEXT NOT NULL` (JSON array of strings)
- `splitMode TEXT DEFAULT 'equal'`
- `projectId TEXT`
- `isFavorite INTEGER DEFAULT 0`
- `usageCount INTEGER DEFAULT 0`
- `lastUsedAt TEXT`
- `createdAt TEXT NOT NULL`

## 4. UI/UX Architecture
- `BillTemplatesScreen`: Complete management screen with tabs ("All", "Favorites", "Suggested"), search bar, favorite star toggle, edit modal dialog, delete dialog, and "Use" button.
- `AddBillScreen`: Quick template chips row (`Key('quickTemplateChips')`), "Save as template" button (`Key('saveAsTemplateButton')`), and template selector picker.
- `BillCard`: Action / icon button with "Save as Template" (`Key('saveAsTemplate_${bill.id}')`).
- `SettingsScreen`: Direct entry point to manage templates under Data Management (`Key('billTemplatesTile')`).
