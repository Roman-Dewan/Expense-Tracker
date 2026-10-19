import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../viewmodels/expense_provider.dart';
import '../services/import_service.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

class ImportDialog extends StatefulWidget {
  const ImportDialog({super.key});

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  bool _isLoading = false;
  ImportAnalysisResult? _analysisResult;
  bool _skipDuplicates = true;
  bool _isCommitting = false;

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final result = await provider.pickFileForImport();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _analysisResult = result;
      });
    }
  }

  Future<void> _commitImport() async {
    if (_analysisResult == null) return;

    setState(() {
      _isCommitting = true;
    });

    final provider = Provider.of<ExpenseProvider>(context, listen: false);

    // Filter which items to commit based on user choice
    final itemsToCommit = _skipDuplicates
        ? _analysisResult!.newTransactions
        : _analysisResult!.allTransactions;

    final importedCount = await provider.commitImport(
      itemsToCommit,
      overwriteExisting: !_skipDuplicates,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent),
              const SizedBox(width: 8),
              Text('Successfully imported $importedCount transactions!'),
            ],
          ),
          backgroundColor: const Color(0xFF2B2930),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _analysisResult == null
              ? _buildPickFileState()
              : _buildPreviewState(),
        ),
      ),
    );
  }

  Widget _buildPickFileState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accentPurple.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.file_upload_outlined,
            color: AppTheme.accentPurple,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Import Previous Expense Data',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select a previously exported CSV, Excel (.xlsx), or JSON backup file from your device.',
          textAlign: TextAlign.center,
          style: AppTheme.labelMedium,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2930),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _FormatTag(title: 'CSV', color: Colors.orangeAccent),
              _FormatTag(title: 'Excel (.xlsx)', color: Colors.greenAccent),
              _FormatTag(title: 'JSON Backup', color: Colors.blueAccent),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _pickFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.folder_open),
                label: Text(_isLoading ? 'Loading...' : 'Browse File'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewState() {
    final res = _analysisResult!;
    final total = res.allTransactions.length;
    final duplicates = res.duplicateTransactions.length;
    final newItems = res.newTransactions.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Import Preview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        Text(
          res.fileName,
          style: const TextStyle(color: AppTheme.accentPurple, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),

        // Analysis Summary Cards
        Row(
          children: [
            _buildStatCard('Found', total.toString(), Colors.blueAccent),
            const SizedBox(width: 8),
            _buildStatCard('New', newItems.toString(), Colors.greenAccent),
            const SizedBox(width: 8),
            _buildStatCard(
              'Duplicates',
              duplicates.toString(),
              Colors.orangeAccent,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Conflict resolution toggle
        if (duplicates > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orangeAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orangeAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _skipDuplicates
                        ? 'Skipping $duplicates duplicate items'
                        : 'Overwriting $duplicates existing items',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
                Switch(
                  value: _skipDuplicates,
                  activeThumbColor: Colors.orangeAccent,
                  onChanged: (val) {
                    setState(() {
                      _skipDuplicates = val;
                    });
                  },
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        const Text(
          'Transactions to be added:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),

        // List Preview
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2B2930),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: res.allTransactions.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: Colors.white10, height: 1),
              itemBuilder: (context, idx) {
                final tx = res.allTransactions[idx];
                final isDup = res.duplicateTransactions.any(
                  (d) => d.id == tx.id,
                );
                final isExp = tx.type == TransactionType.expense;

                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        (isExp ? AppTheme.expenseRed : AppTheme.incomeGreen)
                            .withValues(alpha: 0.2),
                    child: Icon(
                      isExp ? Icons.north_east : Icons.south_west,
                      size: 14,
                      color: isExp ? AppTheme.expenseRed : AppTheme.incomeGreen,
                    ),
                  ),
                  title: Text(
                    tx.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('yyyy-MM-dd').format(tx.date),
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 11,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDup)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Duplicate',
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Text(
                        AppTheme.formatSignedAmount(
                          tx.amount,
                          isExpense: isExp,
                          isIncome: !isExp,
                        ),
                        style: TextStyle(
                          color: isExp
                              ? AppTheme.expenseRed
                              : AppTheme.incomeGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Bottom Actions
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _analysisResult = null;
                  });
                },
                child: const Text(
                  'Change File',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isCommitting ? null : _commitImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isCommitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Import ${_skipDuplicates ? newItems : total} Items',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2B2930),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatTag extends StatelessWidget {
  final String title;
  final Color color;
  const _FormatTag({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
