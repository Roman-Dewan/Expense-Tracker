import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/account.dart';
import 'package:expense_tracker/services/export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExportService Tests', () {
    test('Empty transaction list fails with proper message and does not export', () async {
      final result = await ExportService.instance.exportMonthTransactions(
        month: DateTime(2026, 10, 1),
        transactions: [],
        categories: Category.defaultCategories,
        accounts: Account.defaultAccounts,
        format: ExportFormat.pdf,
      );

      expect(result.success, isFalse);
      expect(result.message, contains('No transactions found'));
    });

    test('Non-empty transactions can export PDF and Excel locally without crashing', () async {
      final sampleTransactions = [
        Transaction(
          id: 'tx_1',
          title: 'Groceries',
          amount: 550,
          date: DateTime(2026, 10, 5, 12, 30),
          categoryId: 'food',
          accountId: 'cash',
          type: TransactionType.expense,
        ),
        Transaction(
          id: 'tx_2',
          title: 'Salary',
          amount: 50000,
          date: DateTime(2026, 10, 1, 9, 0),
          categoryId: 'salary',
          accountId: 'bank',
          type: TransactionType.income,
        ),
      ];

      // Test PDF export
      final pdfResult = await ExportService.instance.exportMonthTransactions(
        month: DateTime(2026, 10, 1),
        transactions: sampleTransactions,
        categories: Category.defaultCategories,
        accounts: Account.defaultAccounts,
        format: ExportFormat.pdf,
      );

      // On desktop / test environment, it saves to Downloads folder or returns result
      expect(pdfResult.success, isTrue);
      expect(pdfResult.fileName, 'Expense_Report_2026_10.pdf');

      // Test Excel export
      final excelResult = await ExportService.instance.exportMonthTransactions(
        month: DateTime(2026, 10, 1),
        transactions: sampleTransactions,
        categories: Category.defaultCategories,
        accounts: Account.defaultAccounts,
        format: ExportFormat.excel,
      );

      expect(excelResult.success, isTrue);
      expect(excelResult.fileName, 'Expense_Report_2026_10.xlsx');

      // Test CSV export
      final csvResult = await ExportService.instance.exportMonthTransactions(
        month: DateTime(2026, 10, 1),
        transactions: sampleTransactions,
        categories: Category.defaultCategories,
        accounts: Account.defaultAccounts,
        format: ExportFormat.csv,
      );

      expect(csvResult.success, isTrue);
      expect(csvResult.fileName, 'Expense_Report_2026_10.csv');
    });
  });
}
