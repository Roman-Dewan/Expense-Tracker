import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../models/budget.dart';
import '../services/database_helper.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';

class ExpenseProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ExportService _exportService = ExportService.instance;
  final ImportService _importService = ImportService.instance;

  List<Transaction> _allTransactions = [];
  List<Category> _categories = [];
  List<Account> _accounts = [];
  List<Budget> _budgets = [];

  bool _isLoading = false;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  // History filters
  String _searchQuery = '';
  final Set<String> _selectedCategoryIds = {};
  TransactionType? _selectedTypeFilter;
  String? _selectedAccountId;
  DateTimeRange? _customDateRange;

  // Getters
  bool get isLoading => _isLoading;
  DateTime get selectedMonth => _selectedMonth;
  List<Transaction> get allTransactions => _allTransactions;
  List<Category> get categories => _categories;
  List<Account> get accounts => _accounts;
  List<Budget> get budgets => _budgets;

  String get searchQuery => _searchQuery;
  Set<String> get selectedCategoryIds => _selectedCategoryIds;
  TransactionType? get selectedTypeFilter => _selectedTypeFilter;
  String? get selectedAccountId => _selectedAccountId;
  DateTimeRange? get customDateRange => _customDateRange;

  ExpenseProvider() {
    loadInitialData();
  }

  // ================= LOAD DATA ================= //

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    _categories = await _db.getCategories();
    _accounts = await _db.getAccounts();
    await _reloadTransactionsAndBudgets();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _reloadTransactionsAndBudgets() async {
    _allTransactions = await _db.getAllTransactions();
    final monthYearStr =
        '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
    _budgets = await _db.getBudgetsForMonth(monthYearStr);
    notifyListeners();
  }

  // ================= MONTH NAVIGATION ================= //

  void nextMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    _reloadTransactionsAndBudgets();
  }

  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    _reloadTransactionsAndBudgets();
  }

  void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month);
    _reloadTransactionsAndBudgets();
  }

  // ================= COMPUTED PROPERTIES ================= //

  /// All transactions in currently selected month
  List<Transaction> get monthTransactions {
    return _allTransactions.where((tx) {
      return tx.date.year == _selectedMonth.year &&
          tx.date.month == _selectedMonth.month;
    }).toList();
  }

  double get monthIncome {
    return monthTransactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get monthExpenses {
    return monthTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get monthBalance => monthIncome - monthExpenses;

  double get overallIncome {
    return _allTransactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get overallExpenses {
    return _allTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get overallBalance => overallIncome - overallExpenses;

  /// Monthly expense distribution by Category
  Map<String, double> get monthExpensesByCategory {
    final map = <String, double>{};
    for (final tx in monthTransactions) {
      if (tx.type == TransactionType.expense) {
        final catId = tx.categoryId ?? 'uncategorized';
        map[catId] = (map[catId] ?? 0.0) + tx.amount;
      }
    }
    return map;
  }

  Budget? getBudgetForCategory(String categoryId) {
    try {
      return _budgets.firstWhere((b) => b.categoryId == categoryId);
    } catch (_) {
      return null;
    }
  }

  Category? getCategoryById(String? id) {
    if (id == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Account? getAccountById(String? id) {
    if (id == null) return null;
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  // ================= FILTERED TRANSACTIONS FOR HISTORY ================= //

  List<Transaction> get filteredTransactions {
    return _allTransactions.where((tx) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = tx.title.toLowerCase().contains(query);
        final matchNotes = (tx.notes ?? '').toLowerCase().contains(query);
        final catName = getCategoryById(tx.categoryId)?.name.toLowerCase() ?? '';
        final matchCategory = catName.contains(query);
        if (!matchTitle && !matchNotes && !matchCategory) return false;
      }

      // 2. Type Filter
      if (_selectedTypeFilter != null && tx.type != _selectedTypeFilter) {
        return false;
      }

      // 3. Category Filter
      if (_selectedCategoryIds.isNotEmpty) {
        if (tx.categoryId == null || !_selectedCategoryIds.contains(tx.categoryId)) {
          return false;
        }
      }

      // 4. Account Filter
      if (_selectedAccountId != null &&
          tx.accountId != _selectedAccountId &&
          tx.toAccountId != _selectedAccountId) {
        return false;
      }

      // 5. Date Range Filter
      if (_customDateRange != null) {
        final start = DateTime(
          _customDateRange!.start.year,
          _customDateRange!.start.month,
          _customDateRange!.start.day,
        );
        final end = DateTime(
          _customDateRange!.end.year,
          _customDateRange!.end.month,
          _customDateRange!.end.day,
          23,
          59,
          59,
        );
        if (tx.date.isBefore(start) || tx.date.isAfter(end)) return false;
      }

      return true;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTypeFilter(TransactionType? type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  void toggleCategoryFilter(String categoryId) {
    if (_selectedCategoryIds.contains(categoryId)) {
      _selectedCategoryIds.remove(categoryId);
    } else {
      _selectedCategoryIds.add(categoryId);
    }
    notifyListeners();
  }

  void setAccountFilter(String? accountId) {
    _selectedAccountId = accountId;
    notifyListeners();
  }

  void setCustomDateRange(DateTimeRange? range) {
    _customDateRange = range;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCategoryIds.clear();
    _selectedTypeFilter = null;
    _selectedAccountId = null;
    _customDateRange = null;
    notifyListeners();
  }

  // ================= CRUD ACTIONS ================= //

  Future<void> addTransaction(Transaction transaction) async {
    await _db.insertTransaction(transaction);
    await _reloadTransactionsAndBudgets();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _db.updateTransaction(transaction);
    await _reloadTransactionsAndBudgets();
  }

  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    await _reloadTransactionsAndBudgets();
  }

  Future<void> setBudget({
    required String categoryId,
    required double limit,
  }) async {
    final monthYearStr =
        '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
    final existing = getBudgetForCategory(categoryId);
    final budget = Budget(
      id: existing?.id ?? 'b_${categoryId}_$monthYearStr',
      categoryId: categoryId,
      monthYear: monthYearStr,
      amountLimit: limit,
    );
    await _db.setBudget(budget);
    await _reloadTransactionsAndBudgets();
  }

  // ================= EXPORT & IMPORT ================= //

  Future<ExportResult> exportMonth({
    required ExportFormat format,
    DateTime? targetMonth,
  }) async {
    final month = targetMonth ?? _selectedMonth;
    final txs = _allTransactions.where((tx) {
      return tx.date.year == month.year && tx.date.month == month.month;
    }).toList();

    return await _exportService.exportMonthTransactions(
      month: month,
      transactions: txs,
      categories: _categories,
      accounts: _accounts,
      format: format,
    );
  }

  Future<ImportAnalysisResult?> pickFileForImport() async {
    return await _importService.pickAndAnalyzeFile(_categories);
  }

  Future<int> commitImport(
    List<Transaction> transactions, {
    bool overwriteExisting = false,
  }) async {
    final count = await _importService.commitImport(
      transactions,
      overwriteExisting: overwriteExisting,
    );
    await _reloadTransactionsAndBudgets();
    return count;
  }
}
