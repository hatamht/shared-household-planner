import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';

enum DateRangeFilter { allTime, thisMonth, last3Months }

class StatisticsScreen extends StatefulWidget {
  final List<Bill>? initialBills;

  const StatisticsScreen({super.key, this.initialBills});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateRangeFilter _selectedFilter = DateRangeFilter.allTime;

  List<Bill> _filterBills(List<Bill> bills) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case DateRangeFilter.thisMonth:
        return bills.where((b) {
          return b.date.year == now.year && b.date.month == now.month;
        }).toList();
      case DateRangeFilter.last3Months:
        final threeMonthsAgo = DateTime(now.year, now.month - 2, 1);
        return bills.where((b) {
          return b.date.isAfter(threeMonthsAgo) ||
              (b.date.year == threeMonthsAgo.year && b.date.month == threeMonthsAgo.month);
        }).toList();
      case DateRangeFilter.allTime:
      default:
        return bills;
    }
  }

  Color _parseColor(String? colorHex, int fallbackIndex) {
    const fallbackPalette = [
      Color(0xFF6366F1), // Indigo
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber
      Color(0xFFEC4899), // Pink
      Color(0xFF8B5CF6), // Purple
      Color(0xFF3B82F6), // Blue
      Color(0xFF14B8A6), // Teal
      Color(0xFFEF4444), // Red
      Color(0xFFF97316), // Orange
      Color(0xFF06B6D4), // Cyan
    ];

    if (colorHex != null && colorHex.isNotEmpty) {
      try {
        String clean = colorHex.replaceFirst('#', '');
        if (clean.length == 6) clean = 'FF$clean';
        return Color(int.parse(clean, radix: 16));
      } catch (_) {}
    }
    return fallbackPalette[fallbackIndex % fallbackPalette.length];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    List<Bill> allBills = widget.initialBills ?? [];
    if (widget.initialBills == null) {
      try {
        final state = context.watch<BillsBloc>().state;
        if (state is BillsLoaded) {
          allBills = state.bills;
        }
      } catch (_) {}
    }

    final filteredBills = _filterBills(allBills);

    // Compute Summary Stats
    final double totalSpent = filteredBills.fold(0.0, (sum, b) => sum + b.amount);

    final Set<String> uniquePeople = {};
    final Map<String, double> paidByMap = {};
    final Map<String, double> categoryMap = {};
    final Map<String, String> categoryColorMap = {};
    final Map<String, double> monthlyMap = {};

    for (final b in filteredBills) {
      uniquePeople.add(b.paidBy);
      for (final p in b.participants) {
        uniquePeople.add(p.name);
      }
      paidByMap[b.paidBy] = (paidByMap[b.paidBy] ?? 0.0) + b.amount;
      categoryMap[b.category] = (categoryMap[b.category] ?? 0.0) + b.amount;
      categoryColorMap[b.category] = b.effectiveCategoryColor;

      final monthKey = DateFormat('MMM yyyy').format(b.date);
      monthlyMap[monthKey] = (monthlyMap[monthKey] ?? 0.0) + b.amount;
    }

    final double avgPerPerson = uniquePeople.isNotEmpty ? (totalSpent / uniquePeople.length) : 0.0;

    String highestSpender = 'N/A';
    double highestAmount = 0.0;
    paidByMap.forEach((person, amount) {
      if (amount > highestAmount) {
        highestAmount = amount;
        highestSpender = person;
      }
    });

    final currencyFormatter = NumberFormat.currency(symbol: '€', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        centerTitle: false,
        titleSpacing: 16,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1F1F1F), const Color(0xFF141414)]
                  : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.insights_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                loc.translate('statistics_charts'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (filteredBills.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_outlined, size: 15, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '${filteredBills.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Date Range Filter Chips
          _buildFilterSection(loc),
          const SizedBox(height: 16),

          if (filteredBills.isEmpty)
            _buildEmptyDataState(loc, isDark)
          else ...[
            // 2. Summary Stats Cards
            _buildSummaryMetrics(
              context,
              loc,
              isDark,
              currencyFormatter.format(totalSpent),
              currencyFormatter.format(avgPerPerson),
              highestSpender,
              currencyFormatter.format(highestAmount),
            ),
            const SizedBox(height: 20),

            // 3. Category Breakdown Chart (AC 3)
            _buildCategoryBreakdownCard(
              context,
              loc,
              isDark,
              categoryMap,
              categoryColorMap,
              totalSpent,
              currencyFormatter,
            ),
            const SizedBox(height: 20),

            // 4. Person Breakdown Chart (AC 4)
            _buildPersonBreakdownCard(
              context,
              loc,
              isDark,
              paidByMap,
              totalSpent,
              currencyFormatter,
            ),
            const SizedBox(height: 20),

            // 5. Monthly Expense Breakdown Chart (AC 2)
            _buildMonthlyBreakdownCard(
              context,
              loc,
              isDark,
              monthlyMap,
              currencyFormatter,
            ),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Filter Section (AC 5)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFilterSection(AppLocalizations loc) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            key: const Key('filterChip_all_time'),
            label: Text(loc.translate('all_time')),
            selected: _selectedFilter == DateRangeFilter.allTime,
            onSelected: (val) {
              if (val) setState(() => _selectedFilter = DateRangeFilter.allTime);
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: const Key('filterChip_this_month'),
            label: Text(loc.translate('this_month')),
            selected: _selectedFilter == DateRangeFilter.thisMonth,
            onSelected: (val) {
              if (val) setState(() => _selectedFilter = DateRangeFilter.thisMonth);
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: const Key('filterChip_last_3_months'),
            label: Text(loc.translate('last_3_months')),
            selected: _selectedFilter == DateRangeFilter.last3Months,
            onSelected: (val) {
              if (val) setState(() => _selectedFilter = DateRangeFilter.last3Months);
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Empty Data State
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyDataState(AppLocalizations loc, bool isDark) {
    return Container(
      key: const Key('emptyStatsState'),
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.query_stats, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            loc.translate('no_stats_data'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Summary Metrics (AC 6)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSummaryMetrics(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
    String totalFormatted,
    String avgFormatted,
    String highestSpender,
    String highestFormatted,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            keyName: 'statsTotalSpent',
            title: loc.translate('total_spent'),
            value: totalFormatted,
            icon: Icons.account_balance_wallet,
            color: const Color(0xFF6366F1),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            keyName: 'statsAveragePerPerson',
            title: loc.translate('average_per_person'),
            value: avgFormatted,
            icon: Icons.people_outline,
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            keyName: 'statsHighestSpender',
            title: loc.translate('highest_spender'),
            value: highestSpender,
            subtitle: highestFormatted,
            icon: Icons.emoji_events_outlined,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String keyName,
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Card(
      key: Key(keyName),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Category Breakdown Card (AC 3)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCategoryBreakdownCard(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
    Map<String, double> categoryMap,
    Map<String, String> categoryColorMap,
    double totalSpent,
    NumberFormat currencyFormatter,
  ) {
    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      key: const Key('categoryExpenseChart'),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.translate('expense_by_category'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedCategories.asMap().entries.map((entry) {
              final idx = entry.key;
              final cat = entry.value;
              final double percentage = totalSpent > 0 ? (cat.value / totalSpent) : 0.0;
              final color = _parseColor(categoryColorMap[cat.key], idx);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            () {
                              final catKey = 'category_${cat.key.toLowerCase()}';
                              final translated = loc.translate(catKey);
                              final hasTrans = translated.isNotEmpty &&
                                  translated != catKey &&
                                  !translated.startsWith('[');
                              return Text(
                                hasTrans ? translated : cat.key,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              );
                            }(),
                          ],
                        ),
                        Text(
                          '${currencyFormatter.format(cat.value)} (${(percentage * 100).toStringAsFixed(1)}%)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 8,
                        backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Person Breakdown Card (AC 4) - Custom Painted Donut / Pie Chart
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPersonBreakdownCard(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
    Map<String, double> paidByMap,
    double totalSpent,
    NumberFormat currencyFormatter,
  ) {
    final entries = paidByMap.entries.toList();

    return Card(
      key: const Key('personExpenseChart'),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.translate('expense_by_person'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Donut Pie Chart Canvas
            Center(
              child: SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(
                  painter: _PieChartPainter(
                    entries: entries,
                    total: totalSpent,
                    colorGetter: (idx) => _parseColor(null, idx),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: entries.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final color = _parseColor(null, idx);
                final double pct = totalSpent > 0 ? (item.value / totalSpent * 100) : 0.0;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${item.key}: ${currencyFormatter.format(item.value)} (${pct.toStringAsFixed(0)}%)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Monthly Breakdown Card (AC 2)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMonthlyBreakdownCard(
    BuildContext context,
    AppLocalizations loc,
    bool isDark,
    Map<String, double> monthlyMap,
    NumberFormat currencyFormatter,
  ) {
    final sortedMonths = monthlyMap.entries.toList();
    final double maxMonthAmount = sortedMonths.fold(0.0, (max, e) => e.value > max ? e.value : max);

    return Card(
      key: const Key('monthlyExpenseChart'),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.translate('monthly_expense'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Bar Chart Columns
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: sortedMonths.map((entry) {
                  final double ratio = maxMonthAmount > 0 ? (entry.value / maxMonthAmount) : 0.0;
                  final double barHeight = max(10.0, ratio * 100);

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormatter.format(entry.value),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 36,
                        height: barHeight,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.key,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Pie / Donut Chart Painter
// ─────────────────────────────────────────────────────────────────────────────
class _PieChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> entries;
  final double total;
  final Color Function(int index) colorGetter;

  _PieChartPainter({
    required this.entries,
    required this.total,
    required this.colorGetter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0 || entries.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    double startAngle = -pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32;

    for (int i = 0; i < entries.length; i++) {
      final sweepAngle = (entries[i].value / total) * 2 * pi;
      paint.color = colorGetter(i);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 16),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) =>
      oldDelegate.total != total || oldDelegate.entries != entries;
}
