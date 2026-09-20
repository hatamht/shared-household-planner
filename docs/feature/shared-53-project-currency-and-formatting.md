# Shared-53: Project-level Currency Binding & Full Amount Formatting

## 1. Overview & Problem Statement
Currently, projects do not persist a dedicated currency; instead, individual bills may have different currencies or default to arbitrary symbols. Additionally, `ProjectDetailScreen` was abbreviating amounts with `k` and `M` (e.g. `52k` or `600kđ`) and hardcoding the `đ` suffix, causing user confusion and non-standard number representations.

This feature introduces:
1. Project-level currency binding (`currency` field defaulting to `'VND'`).
2. A currency selector in `CreateProjectScreen` supporting `VND`, `USD`, `EUR`, `JPY`, `GBP`.
3. Currency badge on project cards in `ProjectScreen`.
4. Removal of `k` and `M` abbreviations from `ProjectDetailScreen`: amounts are formatted with standard thousand separators (e.g. `52,000`, `600,000`).
5. Dynamic project currency symbol display instead of hardcoded `đ`.
6. Bill creation in `AddBillScreen` inheriting the project's currency.
7. 100% backward compatibility and comprehensive automated tests.

---

## 2. Technical Specifications

### 2.1 Domain & Entity Layer
- **`Project` Entity**:
  - `final String currency`: Supported values `VND`, `USD`, `EUR`, `JPY`, `GBP`, default `'VND'`.
  - Getter `String get currencySymbol => currencySymbols[currency] ?? (currency == 'VND' ? '₫' : currency);`.
  - Updated `copyWith` and `props`.

### 2.2 Data Layer & SQLite Schema
- **`ProjectModel`**:
  - Serialization: `fromJson`, `toJson`, `toSqliteMap`, `fromEntity`.
  - Defaults to `'VND'` when `currency` key is null or missing.
- **`DatabaseHelper`**:
  - Bumped database version to `11`.
  - Added migration: `ALTER TABLE projects ADD COLUMN currency TEXT DEFAULT 'VND'`.
  - Updated table creation script.

### 2.3 Presentation Layer
- **`CreateProjectScreen`**:
  - Currency selection chips/dropdown supporting `VND`, `USD`, `EUR`, `JPY`, `GBP`.
  - Pre-selects `'VND'` for new projects or existing project currency in edit mode.
  - Persists `currency` when saving/updating project.
- **`ProjectScreen`**:
  - Renders currency badge (`Key('projectCurrencyBadge_${project.id}')`) on project cards.
- **`ProjectDetailScreen`**:
  - Replaces `_formatAmount` with standard `NumberFormat('#,##0', 'en_US')` formatting.
  - Replaces hardcoded `đ` with `${project.currencySymbol}` across bills list, balances, settlement cards, summary card, and statistics breakdown.
  - When navigating to `AddBillScreen`, passes `project.currency` so bill creation pre-selects the project's currency.
- **`AddBillScreen`**:
  - Accepts `initialCurrency` or sets `selectedCurrency = selectedProject!.currency` when a project is chosen.

---

## 3. Backward Compatibility & Localization
- Existing projects without currency default seamlessly to `'VND'` with symbol `'₫'`.
- All currency labels and hints support English (`en.json`) and Vietnamese (`vi.json`).
