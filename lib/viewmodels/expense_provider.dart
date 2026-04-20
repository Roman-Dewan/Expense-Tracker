import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class ExpenseProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  double get totalIncome {
    return _transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpenses {
    return _transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalBalance {
    return totalIncome - totalExpenses;
  }

  ExpenseProvider() {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final String? transactionsString = prefs.getString('transactions');

    if (transactionsString != null) {
      final List<dynamic> jsonList = jsonDecode(transactionsString);
      _transactions = jsonList
          .map((json) => Transaction.fromJson(json))
          .toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransaction(Transaction transaction) async {
    _transactions.insert(0, transaction);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((tx) => tx.id == id);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String transactionsString = jsonEncode(
      _transactions.map((tx) => tx.toJson()).toList(),
    );
    await prefs.setString('transactions', transactionsString);
  }
}
