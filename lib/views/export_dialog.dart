import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../viewmodels/expense_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  late DateTime _selectedMonth;
  ExportFormat _selectedFormat = ExportFormat.pdf;
  bool _isExporting = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    _selectedMonth = provider.selectedMonth;
  }

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
      _statusMessage = 'Preparing export file...';
    });

    try {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      final result = await provider.exportMonth(
        format: _selectedFormat,
        targetMonth: _selectedMonth,
      );

      if (!mounted) return;

      setState(() {
        _isExporting = false;
        _statusMessage = null;
      });

      if (result.success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.greenAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saved to Device Storage',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        result.fileName ?? result.filePath ?? 'File saved successfully',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2B2930),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        if (result.message != null && result.message != 'Export cancelled by user') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message!),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _statusMessage = 'Error: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final monthTransactions = provider.allTransactions.where((tx) {
      return tx.date.year == _selectedMonth.year && tx.date.month == _selectedMonth.month;
    }).toList();
    final int transactionCount = monthTransactions.length;
    final bool hasNoData = transactionCount == 0;

    final monthStr = DateFormat('MMMM yyyy').format(_selectedMonth);

    return Dialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.save_alt_rounded,
                    color: AppTheme.accentPurple,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Expenses',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Save directly to device storage',
                        style: AppTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Select Target Month
            const Text(
              'Select Month',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2B2930),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white70),
                    onPressed: _isExporting
                        ? null
                        : () {
                            setState(() {
                              _selectedMonth = DateTime(
                                _selectedMonth.year,
                                _selectedMonth.month - 1,
                              );
                            });
                          },
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
                    onPressed: _isExporting
                        ? null
                        : () {
                            setState(() {
                              _selectedMonth = DateTime(
                                _selectedMonth.year,
                                _selectedMonth.month + 1,
                              );
                            });
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Month Data Status Indicator
            if (hasNoData)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amberAccent, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No transactions found for this month. Export is disabled.',
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentPurple.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppTheme.accentPurple, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '$transactionCount transaction${transactionCount > 1 ? "s" : ""} ready to export',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Select Format
            const Text(
              'Export Format',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildFormatOption(
                  format: ExportFormat.pdf,
                  title: 'PDF',
                  subtitle: 'Statement',
                  icon: Icons.picture_as_pdf,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 8),
                _buildFormatOption(
                  format: ExportFormat.excel,
                  title: 'Excel',
                  subtitle: '.xlsx Sheet',
                  icon: Icons.table_chart,
                  color: Colors.greenAccent,
                ),
                const SizedBox(width: 8),
                _buildFormatOption(
                  format: ExportFormat.csv,
                  title: 'CSV',
                  subtitle: 'Raw Data',
                  icon: Icons.code,
                  color: Colors.orangeAccent,
                ),
              ],
            ),
            const SizedBox(height: 28),

            if (_statusMessage != null) ...[
              Center(
                child: Text(
                  _statusMessage!,
                  style: const TextStyle(color: AppTheme.accentPurple, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isExporting ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
                ),
                // const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_isExporting || hasNoData) ? null : _handleExport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPurple,
                      disabledBackgroundColor: const Color(0xFF2B2930),
                      disabledForegroundColor: Colors.white30,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            hasNoData ? 'No Data' : 'Save to Device',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption({
    required ExportFormat format,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedFormat == format;

    return Expanded(
      child: GestureDetector(
        onTap: _isExporting
            ? null
            : () {
                setState(() {
                  _selectedFormat = format;
                });
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.accentPurple.withValues(alpha: 0.2)
                : const Color(0xFF2B2930),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.accentPurple : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppTheme.accentPurple : color, size: 28),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
