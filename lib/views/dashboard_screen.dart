import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/expense_provider.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import 'add_edit_transaction_screen.dart';
import 'history_screen.dart';
import 'app_drawer.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, size: 26),
            tooltip: 'Open Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final monthStr = DateFormat('MMMM yyyy').format(provider.selectedMonth);
          final transactions = provider.monthTransactions;

          return RefreshIndicator(
            onRefresh: () => provider.loadInitialData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Sleek Month Selector
                  _buildMonthSelector(provider, monthStr),
                  const SizedBox(height: 18),

                  // 2. Hero Balance Card
                  _buildBalanceCard(provider),
                  const SizedBox(height: 24),

                  // 3. Recent Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (transactions.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HistoryScreen(),
                              ),
                            );
                          },
                          child: const Row(
                            children: [
                              Text(
                                'View All',
                                style: TextStyle(
                                  color: AppTheme.accentPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: AppTheme.accentPurple,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 4. Transaction List
                  transactions.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transactions.length > 6 ? 6 : transactions.length,
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            return _buildTransactionItem(context, tx, provider);
                          },
                        ),
                  const SizedBox(height: 80), // Padding for FAB
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditTransactionScreen(),
            ),
          );
        },
        label: const Text(
          'Add Transaction',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }

  // ================= 1. MONTH SELECTOR ================= //
  Widget _buildMonthSelector(ExpenseProvider provider, String monthStr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
            onPressed: () => provider.previousMonth(),
          ),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.accentPurple),
              const SizedBox(width: 8),
              Text(
                monthStr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            onPressed: () => provider.nextMonth(),
          ),
        ],
      ),
    );
  }

  // ================= 3. BALANCE CARD ================= //
  Widget _buildBalanceCard(ExpenseProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentPurple.withValues(alpha: 0.9),
            const Color(0xFF5A4FCF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentPurple.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Month Net Balance',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            AppTheme.formatAmount(provider.monthBalance),
            style: AppTheme.balanceLarge,
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _buildMetricPill(
                label: 'Income',
                amount: provider.monthIncome,
                icon: Icons.arrow_downward_rounded,
                color: Colors.greenAccent,
              ),
              const SizedBox(width: 14),
              _buildMetricPill(
                label: 'Expenses',
                amount: provider.monthExpenses,
                icon: Icons.arrow_upward_rounded,
                color: const Color(0xFFFF6B81),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppTheme.formatAmount(amount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 4. TRANSACTION ITEM ================= //
  Widget _buildTransactionItem(
    BuildContext context,
    Transaction tx,
    ExpenseProvider provider,
  ) {
    final isExpense = tx.type == TransactionType.expense;
    final isIncome = tx.type == TransactionType.income;
    final category = provider.getCategoryById(tx.categoryId);
    final account = provider.getAccountById(tx.accountId);

    final itemColor = isExpense
        ? AppTheme.expenseRed
        : (isIncome ? AppTheme.incomeGreen : AppTheme.accentPurple);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditTransactionScreen(transactionToEdit: tx),
            ),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (category?.color ?? itemColor).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            category?.icon ??
                (isExpense
                    ? Icons.north_east_rounded
                    : (isIncome ? Icons.south_west_rounded : Icons.sync_alt_rounded)),
            color: category?.color ?? itemColor,
            size: 20,
          ),
        ),
        title: Text(
          tx.title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          '${DateFormat('MMM dd').format(tx.date)} • ${account?.name ?? "Cash"}',
          style: AppTheme.labelMedium.copyWith(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppTheme.formatSignedAmount(
                tx.amount,
                isExpense: isExpense,
                isIncome: isIncome,
              ),
              style: TextStyle(
                color: itemColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tx.type.name.toUpperCase(),
              style: TextStyle(
                color: itemColor.withValues(alpha: 0.8),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 5. EMPTY STATE ================= //
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 54,
            color: AppTheme.textGrey.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 14),
          const Text(
            'No transactions this month',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap the button below to add your first expense or income.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
