import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/expense_provider.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import 'add_transaction_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppTheme.accentPurple,
            ),
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildBalanceCard(provider),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${provider.transactions.length} total',
                      style: AppTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: provider.transactions.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: provider.transactions.length,
                          itemBuilder: (context, index) {
                            final tx = provider.transactions[index];
                            return _buildTransactionItem(context, tx, provider);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        label: const Text('Add Transaction'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBalanceCard(ExpenseProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentPurple.withOpacity(0.8),
            AppTheme.accentPurple.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentPurple.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${provider.totalBalance.toStringAsFixed(2)}',
            style: AppTheme.balanceLarge,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildSummaryItem(
                label: 'Income',
                amount: provider.totalIncome,
                icon: Icons.arrow_downward,
                color: Colors.greenAccent,
              ),
              const SizedBox(width: 20),
              _buildSummaryItem(
                label: 'Expenses',
                amount: provider.totalExpenses,
                icon: Icons.arrow_upward,
                color: Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
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

  Widget _buildTransactionItem(
    BuildContext context,
    Transaction tx,
    ExpenseProvider provider,
  ) {
    final isExpense = tx.type == TransactionType.expense;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isExpense ? AppTheme.expenseRed : AppTheme.incomeGreen)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isExpense ? Icons.north_east : Icons.south_west,
              color: isExpense ? AppTheme.expenseRed : AppTheme.incomeGreen,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(tx.date),
                  style: AppTheme.labelMedium,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isExpense ? "-" : "+"} \$${tx.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isExpense ? AppTheme.expenseRed : AppTheme.incomeGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      (isExpense ? AppTheme.expenseRed : AppTheme.incomeGreen)
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isExpense ? 'Expense' : 'Income',
                  style: TextStyle(
                    color: isExpense
                        ? AppTheme.expenseRed
                        : AppTheme.incomeGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              provider.deleteTransaction(tx.id);
            },
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppTheme.textGrey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No transactions yet',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
