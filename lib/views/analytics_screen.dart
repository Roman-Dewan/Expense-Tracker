import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../viewmodels/expense_provider.dart';
import '../theme/app_theme.dart';
import 'export_dialog.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final monthStr = DateFormat('MMMM yyyy').format(provider.selectedMonth);
        final categoryMap = provider.monthExpensesByCategory;
        final totalExpense = provider.monthExpenses;
        final totalIncome = provider.monthIncome;
        final netSavings = provider.monthBalance;

        final sortedCategories = categoryMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Spending Analytics'),
            actions: [
              IconButton(
                icon: const Icon(Icons.file_download_outlined),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const ExportDialog(),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white70),
                        onPressed: () => provider.previousMonth(),
                      ),
                      Text(
                        monthStr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.white70),
                        onPressed: () => provider.nextMonth(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Cash Flow Bar Indicator
                _buildCashFlowSummary(totalIncome, totalExpense, netSavings),
                const SizedBox(height: 24),

                // Category Breakdown Title
                const Text(
                  'Expense by Category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),

                if (totalExpense <= 0)
                  _buildNoExpenseCard()
                else ...[
                  // Interactive Pie Chart
                  SizedBox(
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedPieIndex = -1;
                                    return;
                                  }
                                  _touchedPieIndex = pieTouchResponse
                                      .touchedSection!
                                      .touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 65,
                            sections: List.generate(sortedCategories.length, (i) {
                              final isTouched = i == _touchedPieIndex;
                              final fontSize = isTouched ? 16.0 : 12.0;
                              final radius = isTouched ? 48.0 : 40.0;
                              final entry = sortedCategories[i];
                              final cat = provider.getCategoryById(entry.key);
                              final color = cat?.color ?? Colors.grey;
                              final pct = (entry.value / totalExpense) * 100;

                              return PieChartSectionData(
                                color: color,
                                value: entry.value,
                                title: isTouched ? '${pct.toStringAsFixed(0)}%' : '',
                                radius: radius,
                                titleStyle: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Total Spent',
                              style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppTheme.formatAmount(totalExpense),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category Breakdown List
                  ...sortedCategories.map((entry) {
                    final cat = provider.getCategoryById(entry.key);
                    final color = cat?.color ?? Colors.grey;
                    final pct = (entry.value / totalExpense) * 100;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(cat?.icon ?? Icons.category, color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      cat?.name ?? 'Other',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      AppTheme.formatAmount(entry.value),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Stack(
                                  children: [
                                    Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: (pct / 100).clamp(0.0, 1.0),
                                      child: Container(
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCashFlowSummary(double income, double expense, double net) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFlowColumn('Income', income, Colors.greenAccent, Icons.arrow_downward),
              Container(width: 1, height: 40, color: Colors.white10),
              _buildFlowColumn('Expense', expense, Colors.redAccent, Icons.arrow_upward),
              Container(width: 1, height: 40, color: Colors.white10),
              _buildFlowColumn(
                'Net Savings',
                net,
                net >= 0 ? AppTheme.accentPurple : Colors.redAccent,
                Icons.savings_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlowColumn(String label, double amount, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          AppTheme.formatAmount(amount),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildNoExpenseCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.pie_chart_outline, size: 48, color: AppTheme.textGrey.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text(
            'No expenses recorded this month',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
