import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xl;
import 'package:uuid/uuid.dart';

import '../models/transaction.dart';
import '../models/category.dart';
import 'database_helper.dart';

class ImportAnalysisResult {
  final String fileName;
  final List<Transaction> allTransactions;
  final List<Transaction> newTransactions;
  final List<Transaction> duplicateTransactions;
  final List<String> errorMessages;

  ImportAnalysisResult({
    required this.fileName,
    required this.allTransactions,
    required this.newTransactions,
    required this.duplicateTransactions,
    required this.errorMessages,
  });

  bool get hasData => allTransactions.isNotEmpty;
}

class ImportService {
  static final ImportService instance = ImportService._internal();
  ImportService._internal();

  /// Prompts user to pick a CSV, XLSX, or JSON file and analyzes it
  Future<ImportAnalysisResult?> pickAndAnalyzeFile(List<Category> categories) async {
    final pickedFiles = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls', 'json'],
    );

    if (pickedFiles.isEmpty) {
      return null;
    }

    final platformFile = pickedFiles.first;
    final path = platformFile.path;
    if (path == null) return null;

    final file = File(path);
    final ext = (platformFile.extension ?? '').toLowerCase();

    List<Transaction> parsedTransactions = [];
    final errors = <String>[];

    final categoryMapByName = {
      for (var c in categories) c.name.toLowerCase(): c.id
    };

    try {
      if (ext == 'csv') {
        parsedTransactions = await _parseCsv(file, categoryMapByName, errors);
      } else if (ext == 'xlsx' || ext == 'xls') {
        parsedTransactions = await _parseExcel(file, categoryMapByName, errors);
      } else if (ext == 'json') {
        parsedTransactions = await _parseJson(file, errors);
      } else {
        errors.add('Unsupported file format: .$ext');
      }
    } catch (e) {
      errors.add('Failed to parse file: $e');
    }

    // Run Duplicate Check against SQLite
    final duplicates = await DatabaseHelper.instance.findDuplicates(parsedTransactions);
    final duplicateIds = duplicates.map((d) => d.id).toSet();

    final newItems = parsedTransactions.where((tx) => !duplicateIds.contains(tx.id)).toList();

    return ImportAnalysisResult(
      fileName: platformFile.name,
      allTransactions: parsedTransactions,
      newTransactions: newItems,
      duplicateTransactions: duplicates,
      errorMessages: errors,
    );
  }

  // ================= 1. CSV PARSER ================= //
  Future<List<Transaction>> _parseCsv(
    File file,
    Map<String, String> categoryMapByName,
    List<String> errors,
  ) async {
    final rawString = await file.readAsString();
    final rows = csv.decode(rawString);

    if (rows.isEmpty) {
      errors.add('CSV file is empty');
      return [];
    }

    // Determine column indices from header
    final header = rows.first.map((c) => c.toString().trim().toLowerCase()).toList();
    int dateIdx = header.indexOf('date');
    int titleIdx = header.indexOf('title');
    if (titleIdx == -1) titleIdx = header.indexOf('description');
    int typeIdx = header.indexOf('type');
    int amountIdx = header.indexOf('amount');
    int catIdx = header.indexOf('category');
    int notesIdx = header.indexOf('notes');

    // Default fallback if headers were slightly different
    if (dateIdx == -1 || titleIdx == -1 || amountIdx == -1) {
      // Try positional: ID=0, Date=1, Title=2, Type=3, Category=4, Account=5, Amount=6, Notes=7
      if (header.length >= 7) {
        dateIdx = 1;
        titleIdx = 2;
        typeIdx = 3;
        catIdx = 4;
        amountIdx = 6;
        notesIdx = header.length > 7 ? 7 : -1;
      } else {
        errors.add('Missing required columns: Date, Title, Amount');
        return [];
      }
    }

    final transactions = <Transaction>[];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((element) => element.toString().trim().isEmpty)) {
        continue;
      }

      try {
        final dateStr = row[dateIdx].toString().trim();
        final title = row[titleIdx].toString().trim();
        final rawAmount = row[amountIdx].toString().replaceAll(RegExp(r'[^0-9.]'), '');
        final amount = double.tryParse(rawAmount) ?? 0.0;

        if (title.isEmpty || amount <= 0) continue;

        DateTime date = DateTime.tryParse(dateStr) ?? DateTime.now();

        TransactionType type = TransactionType.expense;
        if (typeIdx != -1 && typeIdx < row.length) {
          final tStr = row[typeIdx].toString().trim().toLowerCase();
          if (tStr.contains('inc')) {
            type = TransactionType.income;
          } else if (tStr.contains('trans')) {
            type = TransactionType.transfer;
          }
        }

        String? categoryId;
        if (catIdx != -1 && catIdx < row.length) {
          final cName = row[catIdx].toString().trim().toLowerCase();
          categoryId = categoryMapByName[cName];
        }

        String? notes;
        if (notesIdx != -1 && notesIdx < row.length) {
          notes = row[notesIdx].toString().trim();
          if (notes.isEmpty) notes = null;
        }

        transactions.add(
          Transaction(
            id: const Uuid().v4(),
            title: title,
            amount: amount,
            date: date,
            type: type,
            categoryId: categoryId,
            notes: notes,
          ),
        );
      } catch (err) {
        errors.add('Row $i could not be parsed: $err');
      }
    }

    return transactions;
  }

  // ================= 2. EXCEL PARSER ================= //
  Future<List<Transaction>> _parseExcel(
    File file,
    Map<String, String> categoryMapByName,
    List<String> errors,
  ) async {
    final bytes = await file.readAsBytes();
    final excel = xl.Excel.decodeBytes(bytes);

    // Prefer "Transactions" sheet, or fallback to first sheet
    String targetSheet = 'Transactions';
    if (!excel.tables.containsKey(targetSheet)) {
      if (excel.tables.isEmpty) {
        errors.add('Excel workbook has no sheets');
        return [];
      }
      targetSheet = excel.tables.keys.first;
    }

    final table = excel.tables[targetSheet];
    if (table == null || table.rows.isEmpty) {
      errors.add('Sheet "$targetSheet" has no rows');
      return [];
    }

    final rows = table.rows;
    final headerRow = rows.first;
    final header = headerRow.map((cell) => cell?.value?.toString().trim().toLowerCase() ?? '').toList();

    int dateIdx = header.indexOf('date');
    int titleIdx = header.indexOf('title');
    if (titleIdx == -1) titleIdx = header.indexOf('description');
    int typeIdx = header.indexOf('type');
    int amountIdx = header.indexOf('amount');
    int catIdx = header.indexOf('category');
    int notesIdx = header.indexOf('notes');

    if (dateIdx == -1 || titleIdx == -1 || amountIdx == -1) {
      if (header.length >= 7) {
        dateIdx = 1;
        titleIdx = 2;
        typeIdx = 3;
        catIdx = 4;
        amountIdx = 6;
        notesIdx = header.length > 7 ? 7 : -1;
      } else {
        errors.add('Required columns (Date, Title, Amount) not detected in Excel.');
        return [];
      }
    }

    final transactions = <Transaction>[];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      try {
        final dateVal = row.length > dateIdx ? row[dateIdx]?.value?.toString().trim() : '';
        final titleVal = row.length > titleIdx ? row[titleIdx]?.value?.toString().trim() : '';
        final amountVal = row.length > amountIdx ? row[amountIdx]?.value?.toString().trim() : '';

        if (titleVal == null || titleVal.isEmpty) continue;
        final rawAmount = (amountVal ?? '').replaceAll(RegExp(r'[^0-9.]'), '');
        final amount = double.tryParse(rawAmount) ?? 0.0;
        if (amount <= 0) continue;

        DateTime date = DateTime.tryParse(dateVal ?? '') ?? DateTime.now();

        TransactionType type = TransactionType.expense;
        if (typeIdx != -1 && row.length > typeIdx) {
          final tStr = row[typeIdx]?.value?.toString().trim().toLowerCase() ?? '';
          if (tStr.contains('inc')) {
            type = TransactionType.income;
          } else if (tStr.contains('trans')) {
            type = TransactionType.transfer;
          }
        }

        String? categoryId;
        if (catIdx != -1 && row.length > catIdx) {
          final cName = row[catIdx]?.value?.toString().trim().toLowerCase() ?? '';
          categoryId = categoryMapByName[cName];
        }

        String? notes;
        if (notesIdx != -1 && row.length > notesIdx) {
          notes = row[notesIdx]?.value?.toString().trim();
          if (notes != null && notes.isEmpty) notes = null;
        }

        transactions.add(
          Transaction(
            id: const Uuid().v4(),
            title: titleVal,
            amount: amount,
            date: date,
            type: type,
            categoryId: categoryId,
            notes: notes,
          ),
        );
      } catch (e) {
        errors.add('Excel row $i parsing failed: $e');
      }
    }

    return transactions;
  }

  // ================= 3. JSON PARSER ================= //
  Future<List<Transaction>> _parseJson(File file, List<String> errors) async {
    final content = await file.readAsString();
    final decoded = jsonDecode(content);

    List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map && decoded['transactions'] is List) {
      list = decoded['transactions'];
    } else {
      errors.add('JSON does not contain a valid transaction array');
      return [];
    }

    return list.map((item) => Transaction.fromJson(item as Map<String, dynamic>)).toList();
  }

  // ================= 4. COMMIT IMPORT ================= //
  Future<int> commitImport(
    List<Transaction> transactions, {
    bool overwriteExisting = false,
  }) async {
    await DatabaseHelper.instance.batchInsertTransactions(
      transactions,
      overwriteExisting: overwriteExisting,
    );
    return transactions.length;
  }
}
