import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../viewmodels/expense_provider.dart';
import '../theme/app_theme.dart';
import 'add_edit_transaction_screen.dart';
import 'export_dialog.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal(BuildContext context, ExpenseProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter Transactions',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            provider.resetFilters();
                            setModalState(() {});
                          },
                          child: const Text('Reset All', style: TextStyle(color: AppTheme.accentPurple)),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),

                    // 1. Transaction Type
                    const Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterChoice(
                          label: 'All Types',
                          isSelected: provider.selectedTypeFilter == null,
                          onSelected: () => provider.setTypeFilter(null),
                        ),
                        _buildFilterChoice(
                          label: 'Expenses Only',
                          isSelected: provider.selectedTypeFilter == TransactionType.expense,
                          onSelected: () => provider.setTypeFilter(TransactionType.expense),
                        ),
                        _buildFilterChoice(
                          label: 'Income Only',
                          isSelected: provider.selectedTypeFilter == TransactionType.income,
                          onSelected: () => provider.setTypeFilter(TransactionType.income),
                        ),
                        _buildFilterChoice(
                          label: 'Transfers',
                          isSelected: provider.selectedTypeFilter == TransactionType.transfer,
                          onSelected: () => provider.setTypeFilter(TransactionType.transfer),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 2. Date Range
                    const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.date_range, size: 18),
                      label: Text(
                        provider.customDateRange != null
                            ? '${DateFormat('MMM dd').format(provider.customDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(provider.customDateRange!.end)}'
                            : 'Select Custom Date Range',
                      ),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppTheme.accentPurple,
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          provider.setCustomDateRange(picked);
                          setModalState(() {});
                        }
                      },
                    ),
                    if (provider.customDateRange != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            provider.setCustomDateRange(null);
                            setModalState(() {});
                          },
                          child: const Text('Clear Date Range', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // 3. Category Filter
                    const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: provider.categories.map((cat) {
                        final isSel = provider.selectedCategoryIds.contains(cat.id);
                        return FilterChip(
                          avatar: Icon(cat.icon, size: 16, color: isSel ? Colors.white : cat.color),
                          label: Text(cat.name),
                          selected: isSel,
                          selectedColor: AppTheme.accentPurple.withValues(alpha: 0.5),
                          backgroundColor: const Color(0xFF2B2930),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : Colors.white70,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            provider.toggleCategoryFilter(cat.id);
                            setModalState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // 4. Accounts Filter
                    const Text('Account / Wallet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterChoice(
                          label: 'All Accounts',
                          isSelected: provider.selectedAccountId == null,
                          onSelected: () => provider.setAccountFilter(null),
                        ),
                        ...provider.accounts.map((acc) {
                          return _buildFilterChoice(
                            label: acc.name,
                            isSelected: provider.selectedAccountId == acc.id,
                            onSelected: () => provider.setAccountFilter(acc.id),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChoice({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.accentPurple.withValues(alpha: 0.5),
      backgroundColor: const Color(0xFF2B2930),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => onSelected(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        final transactions = provider.filteredTransactions;
        final hasActiveFilters = provider.searchQuery.isNotEmpty ||
            provider.selectedTypeFilter != null ||
            provider.selectedCategoryIds.isNotEmpty ||
            provider.selectedAccountId != null ||
            provider.customDateRange != null;

        // Group transactions by Date (YYYY-MM-DD)
        final grouped = <String, List<Transaction>>{};
        for (final tx in transactions) {
          final dateKey = DateFormat('yyyy-MM-dd').format(tx.date);
          grouped.putIfAbsent(dateKey, () => []).add(tx);
        }

        final sortedDateKeys = grouped.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return Scaffold(
          appBar: AppBar(
            title: _showSearch
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search title, note, category...',
                      border: InputBorder.none,
                      filled: false,
                    ),
                    onChanged: (val) => provider.setSearchQuery(val),
                  )
                : const Text('Transaction History'),
            actions: [
              IconButton(
                icon: Icon(_showSearch ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) {
                      _searchController.clear();
                      provider.setSearchQuery('');
                    }
                  });
                },
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () => _showFilterModal(context, provider),
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentPurple,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
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
          body: Column(
            children: [
              // Active filter indicators
              if (hasActiveFilters)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppTheme.surfaceDark,
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt, size: 16, color: AppTheme.accentPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Showing ${transactions.length} filtered results',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          provider.resetFilters();
                        },
                        child: const Text('Clear Filters', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: transactions.isEmpty
                    ? _buildEmptyState(hasActiveFilters)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: sortedDateKeys.length,
                        itemBuilder: (context, index) {
                          final dateKey = sortedDateKeys[index];
                          final dayTransactions = grouped[dateKey]!;
                          final date = DateTime.parse(dateKey);

                          // Daily sum
                          double dayTotalExpense = 0;
                          double dayTotalIncome = 0;
                          for (final tx in dayTransactions) {
                            if (tx.type == TransactionType.expense) dayTotalExpense += tx.amount;
                            if (tx.type == TransactionType.income) dayTotalIncome += tx.amount;
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sticky Date Header
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDateHeader(date),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        if (dayTotalIncome > 0)
                                          Text(
                                            '+ ${AppTheme.formatAmount(dayTotalIncome)}  ',
                                            style: const TextStyle(
                                              color: Colors.greenAccent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        if (dayTotalExpense > 0)
                                          Text(
                                            '- ${AppTheme.formatAmount(dayTotalExpense)}',
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Transactions in this day
                              ...dayTransactions.map((tx) {
                                return _buildHistoryItem(context, tx, provider);
                              }),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return 'Today • ${DateFormat('MMM dd, yyyy').format(date)}';
    } else if (itemDate == yesterday) {
      return 'Yesterday • ${DateFormat('MMM dd, yyyy').format(date)}';
    }
    return DateFormat('EEEE • MMM dd, yyyy').format(date);
  }

  Widget _buildHistoryItem(
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

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        provider.deleteTransaction(tx.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${tx.title}"'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                provider.addTransaction(tx);
              },
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditTransactionScreen(transactionToEdit: tx),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (category?.color ?? itemColor).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  category?.icon ??
                      (isExpense
                          ? Icons.north_east
                          : (isIncome ? Icons.south_west : Icons.sync_alt)),
                  color: category?.color ?? itemColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Title and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (category != null)
                          Text(
                            '${category.name} • ',
                            style: AppTheme.labelMedium.copyWith(fontSize: 11),
                          ),
                        Text(
                          account?.name ?? 'Cash',
                          style: AppTheme.labelMedium.copyWith(fontSize: 11),
                        ),
                        if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.notes, size: 12, color: AppTheme.textGrey),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Amount
              Column(
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
                    DateFormat('h:mm a').format(tx.date),
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool hasFilters) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.search_off : Icons.history,
            size: 70,
            color: AppTheme.textGrey.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No transactions match filters' : 'No transactions recorded yet',
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
