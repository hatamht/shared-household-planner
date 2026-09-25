# Shared-60: [BUG] Fix Currency Symbol & Font Glyph Rendering in Export PDF/Report

## Problem Statement

When exporting data to PDF ("Household Expense Report"), users reported:
1. In the "Expenses Breakdown" and "Settlement Summary" tables, the currency symbol is displayed incorrectly as `¤` (U+00A4 currency fallback) or broken/corrupted glyphs instead of the correct currency symbol (e.g., `₫` or `VND`).
2. The export function defaults to `€` instead of respecting the project's configured currency (`project.currency`) or the active project context.
3. Standard 14 PDF fonts (Helvetica) lack Unicode coverage for Vietnamese currency glyphs (`₫`), resulting in glyph substitution or encoding errors in generated PDF files.
4. Decimal formatting forces `.00` on zero-decimal currencies like `VND`, cluttering the expense summary.

## Root Cause Analysis

1. **`lib/features/export/presentation/pages/export_data_screen.dart`**:
   - When calling `widget.exportService.exportAndShare(...)` or `widget.exportService.exportToFile(...)`, the caller does not pass `currencySymbol`.
   - It defaults to `currencySymbol = '€'` in `ExportService`.
   - It does not look up the selected project's currency from `ProjectBloc` or `project.currency` (configured in Shared-53).

2. **`lib/features/export/domain/services/pdf_generator.dart`**:
   - Uses default standard PDF fonts (Helvetica) without UTF-8 / TrueType font support for `₫` (Vietnamese dong sign `\u20AB`).
   - Standard PDF fonts map unsupported Unicode characters to `¤` or produce broken rendering.
   - Prepends the symbol unconditionally (`$currencySymbol${numberFormat.format(b.amount)}`), whereas VND is typically formatted as a suffix or with code (e.g., `100,126,205 ₫` or `100,126,205 VND`).

## Solution Requirements

1. **Project Currency Binding**:
   - In `ExportDataScreen`, resolve the currency symbol from the selected project (or the active project's `project.currency`). If "All Projects" is selected, resolve from the active project or default project currency (`VND` / `₫`).
   - Pass the resolved currency symbol/code into `ExportService.exportToFile` and `ExportService.exportAndShare`.

2. **PDF Font & Glyph Safety**:
   - Ensure the PDF document uses a Unicode-safe font or safe currency representation so that `₫`, `đ`, or `VND` renders cleanly without `¤` or font corruption.
   - Support standard currencies (`VND`, `USD`, `EUR`, `JPY`, etc.).
   - Support appropriate symbol placement (prefix for `$`, suffix or code for `VND`).

3. **Number Formatting**:
   - Format whole amounts appropriately without unnecessary `.00` for VND.

4. **Testing**:
   - Add/update unit and widget tests in `test/features/export/` validating:
     - Project currency is correctly passed to `PdfGenerator`.
     - PDF generation with `₫` / `VND` succeeds without errors.
     - Currency symbol and amounts appear correctly in generated PDF data.
