# Shared-31: Statistics & Charts Tab (Replace Tab 3)

**Layer:** Presentation (UI, State Management, Custom Painting, Data Filtering)  
**Priority:** High  
**Type:** Feature / Statistics & Visualization

---

## Overview

Replaced Tab 3 of `HomeScreen` with a dedicated **Statistics & Charts** screen (`StatisticsScreen`), transforming raw expense and bill data into intuitive, visual insights. The previous profile tab contents were cleanly consolidated into the Settings tab (Tab 2), giving users a focused 4-tab experience: Projects, Requests/Bills, Statistics & Charts, and Settings.

The Statistics feature provides:
1. **Interactive Date Range Filter:** Filter spending metrics and charts by "All Time", "This Month", or "Last 3 Months" via chip selectors.
2. **Overview Metric Cards:** Total spending with currency formatting, average spending per person, and highest spender with their individual expenditure.
3. **Expense by Category:** Visual breakdown of expenses per category with colored horizontal indicator bars, percentage calculations, category color badges, and localization support.
4. **Expense by Person:** Custom-painted donut / pie chart (`_PieChartPainter`) displaying proportion spent by each member, paired with an interactive-style legend with color swatches, payer names, amounts, and percentage contributions.
5. **Monthly Expense Breakdown:** Monthly bar visualization tracking spending trends over time with gradient bars, month/year column labels, and amount tags.
6. **Adaptive Theme & Localization Support:** Complete Dark / Light theme styling with seamless support for English (`en`) and Vietnamese (`vi`).
7. **Graceful Empty State:** Clean, query_stats illustrated empty state when no expense data exists for the selected period.

---

## Acceptance Criteria & Implementation Details

1. ✅ **Replace Tab 3 with Statistics & Charts:**
   - Tab 3 updated from Profile to `StatisticsScreen()`.
   - BottomNavigationBar item 3 icon updated to `Icons.insights` with label `statistics`.
   - User profile content safely preserved and consolidated into Settings (Tab 2).
2. ✅ **Monthly expense breakdown (bar/pie chart):**
   - Monthly trend bar chart (`monthlyExpenseChart`) groups bills by `YYYY-MM`.
   - Renders proportional gradient vertical bars with rounded caps, amount indicators, and month-year labels.
3. ✅ **Expense by category (bar chart with category colors):**
   - Category chart card (`categoryExpenseChart`) groups bills by category.
   - Sorts categories in descending order of total expenditure.
   - Displays category color indicator, localized category title (with fallback to raw name), total amount, percentage, and horizontal bar progress.
4. ✅ **Expense by person (pie/donut chart with legend):**
   - Person chart card (`personExpenseChart`) with custom canvas donut rendering (`_PieChartPainter`).
   - Clean donut hole with adaptive center background.
   - Comprehensive legend listing every payer, colored circle indicator, amount, and integer/decimal percentage.
5. ✅ **Filter chart by date range:**
   - Filter chips: `filterChip_all_time`, `filterChip_this_month`, `filterChip_last_3_months`.
   - Instant dynamic recalculation of summary stats, category aggregates, person breakdown, and monthly charts upon filter change.
6. ✅ **Display summary stats:**
   - Total Spent card (`statsTotalSpent`) with currency formatting.
   - Average per person card (`statsAveragePerPerson`) calculated against unique participants across bills.
   - Highest Spender card (`statsHighestSpender`) displaying the top payer and their total contribution.
7. ✅ **Dark/Light theme support:**
   - All chart cards, background containers, filter chips, text styles, and borders dynamically adapt between Light Mode (pure white cards `#FFFFFF`, light scaffold `#F8FAFC`) and Dark Mode (dark surfaces `#1E1E1E`, scaffold `#121212`, soft contrast text `#E0E0E0`).
8. ✅ **Tests & Coverage:**
   - 85 dedicated widget, unit, edge case, and theme/i18n tests in `test/features/statistics/statistics_charts_test.dart`.
   - Total test suite: 673+ tests passing (100% pass rate, 0 failures).

---

## Verification Results

- `test/features/statistics/statistics_charts_test.dart`: 85/85 passed.
- `test/features/home/home_screen_redesign_test.dart`: 105/105 passed.
- Full test suite: 100% passed.
