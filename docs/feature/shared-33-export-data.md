# Shared-33: Export Data (CSV & PDF)

**Layer:** Presentation, Domain Services, I/O & Sharing  
**Priority:** High  
**Type:** Feature / Data Portability & Export

---

## Overview

Implemented a complete offline data export and sharing system for **Shared Household Planner**, allowing users to generate formatted reports of their household and project expenses in both **CSV** (spreadsheet-compatible) and **PDF** (printable, professional layout) formats.

The Export feature enables users to:
1. **Export to CSV:** Outputs RFC 4180 compliant CSV tables with standard columns (`Date,Person,Amount,Category,Description`) and an appended Settlement Summary section.
2. **Export to PDF:** Generates clean, publication-quality PDF documents complete with title header, generation timestamp, date range context, total expense and bill count metric cards, full expenses table, and a dedicated Settlement Summary section ("Who Owes Whom").
3. **Date Range Filtering:** Supports "All Time", "This Month", "Last Month", and "Custom Range" (with interactive start and end date pickers).
4. **Project Scope Filtering:** Supports exporting either "All Projects" or a specific chosen project.
5. **Settlement Integration:** Computes debt minimization across bills in scope, detailing who owes whom and net balances.
6. **System Share Sheet Integration:** Integrates with `share_plus` to easily send exported files via messaging apps (Zalo, Telegram, WhatsApp), email, or cloud storage.
7. **Clean Standardized File Naming:** Files are named predictably as `project-name-YYYY-MM-DD.csv` or `.pdf` with ASCII slugification.
8. **Settings Integration:** Seamlessly accessible from the Settings tab via dedicated "Export to CSV" and "Export to PDF" options.

---

## Acceptance Criteria & Implementation Details

1. ✅ **Export bills to CSV format (columns: Date, Person, Amount, Category, Description):**
   - Implemented in `CsvGenerator`.
   - Generates compliant RFC 4180 CSV with headers `Date,Person,Amount,Category,Description`.
   - Handles quotes, commas, newlines, and Vietnamese unicode characters safely.
2. ✅ **Export bills to PDF with formatting (title, date, table, totals):**
   - Implemented in `PdfGenerator` using `package:pdf`.
   - Professional styling with summary cards, table with alternating row colors, proper margins, and page numbers.
3. ✅ **Export selected date range (month/custom):**
   - Options for `All Time`, `This Month`, `Last Month`, and `Custom Range`.
   - Date pickers for Start Date and End Date with auto-correction for inverted ranges.
4. ✅ **Export single project or all projects:**
   - Scope dropdown in `ExportDataScreen` allows choosing "All Projects" or any specific project.
5. ✅ **Export includes settlement summary:**
   - `ExportSettlementHelper` calculates debts and net balances using debt minimization.
   - Appended to CSV reports and included as a distinct table in PDF reports.
6. ✅ **Share exported file via Share sheet (email, messaging):**
   - `ShareService` interface with `SharePlusService` implementation.
   - Immediate sharing via primary "Export & Share" button, plus "Export File" option.
7. ✅ **File naming: project-name-YYYY-MM-DD.csv/.pdf:**
   - `ExportFilenameBuilder` creates filesystem-safe slugs (e.g., `apartment-4b-2026-09-13.csv`, `all-projects-2026-09-13.pdf`).
8. ✅ **Tests: 80+ covering CSV/PDF generation, filtering, sharing:**
   - **106 tests** written in `test/features/export/export_data_test.dart` (exceeds the 80+ requirement).
   - **854 total tests** in project passing with 100% success rate (0 failures).

---

## Verification Results

- `test/features/export/export_data_test.dart`: 106/106 passed.
- `test/features/settings/settings_navigation_test.dart`: 75/75 passed.
- Entire project test suite: **854/854 passed (0 failures)**.
