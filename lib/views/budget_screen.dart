import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../viewmodels/expense_provider.dart';
import '../theme/app_theme.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  void _showSetBudgetDialog(
    BuildContext context,
    Category category,
    ExpenseProvider provider,
    double currentLimit,
  ) {
    final controller = TextEditingController(
      text: currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(category.icon, color: category.color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Set Budget for ${category.name}',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter monthly limit:',
              style: AppTheme.labelMedium,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 20, color: Colors.white),
              decoration: const InputDecoration(
                prefixText: '৳ ',
                prefixStyle: TextStyle(fontSize: 20, color: AppTheme.accentPurple),
                hintText: '500',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final amount = double.tryParse(controller.text.trim()) ?? 0.0;
              provider.setBudget(categoryId: category.id, limit: amount);
              Navigator.pop(ctx);
            },
            child: const Text('Save Limit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final monthStr = DateFormat('MMMM yyyy').format(provider.selectedMonth);
        final expenseCategories = provider.categories
            .where((c) => c.type == TransactionType.expense)
            .toList();
        final expenseMap = provider.monthExpensesByCategory;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Category Budgets'),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

              const Text(
                'Set and track monthly limits for your expense categories.',
                style: AppTheme.labelMedium,
              ),
              const SizedBox(height: 16),

              ...expenseCategories.map((category) {
                final budget = provider.getBudgetForCategory(category.id);
                final limit = budget?.amountLimit ?? 0.0;
                final spent = expenseMap[category.id] ?? 0.0;

                final hasBudget = limit > 0;
                final percentage = hasBudget ? (spent / limit) : 0.0;

                Color progressColor = Colors.greenAccent;
                if (percentage >= 1.0) {
                  progressColor = Colors.redAccent;
                } else if (percentage >= 0.8) {
                  progressColor = Colors.orangeAccent;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: percentage >= 1.0
                          ? Colors.redAccent.withValues(alpha: 0.5)
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: category.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(category.icon, color: category.color, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hasBudget
                                      ? 'Spent: ${AppTheme.formatAmount(spent)} of ${AppTheme.formatAmount(limit)}'
                                      : 'Spent: ${AppTheme.formatAmount(spent)} (No limit set)',
                                  style: AppTheme.labelMedium.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_note, color: AppTheme.accentPurple),
                            onPressed: () => _showSetBudgetDialog(
                              context,
                              category,
                              provider,
                              limit,
                            ),
                          ),
                        ],
                      ),
                      if (hasBudget) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage.clamp(0.0, 1.0),
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation(progressColor),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              percentage >= 1.0
                                  ? 'Exceeded by ${AppTheme.formatAmount(spent - limit)}'
                                  : '${AppTheme.formatAmount(limit - spent)} remaining',
                              style: TextStyle(
                                color: progressColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${(percentage * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(color: AppTheme.textGrey, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
