import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../viewmodels/expense_provider.dart';
import '../theme/app_theme.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final Transaction? transactionToEdit;

  const AddEditTransactionScreen({super.key, this.transactionToEdit});

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  late DateTime _selectedDate;
  late TransactionType _selectedType;
  String? _selectedCategoryId;
  late String _selectedAccountId;
  String? _selectedToAccountId; // For transfer

  bool get isEditing => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    final tx = widget.transactionToEdit;
    _titleController = TextEditingController(text: tx?.title ?? '');
    _amountController = TextEditingController(
      text: tx != null ? tx.amount.round().toString() : '',
    );
    _notesController = TextEditingController(text: tx?.notes ?? '');
    _selectedDate = tx?.date ?? DateTime.now();
    _selectedType = tx?.type ?? TransactionType.expense;
    _selectedCategoryId = tx?.categoryId;
    _selectedAccountId = tx?.accountId ?? 'acc_cash';
    _selectedToAccountId = tx?.toAccountId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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

    if (pickedDate != null) {
      final now = DateTime.now();
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          now.hour,
          now.minute,
        );
      });
    }
  }

  void _submitData() {
    if (_formKey.currentState!.validate()) {
      final enteredTitle = _titleController.text.trim();
      final enteredAmount = (double.tryParse(_amountController.text.trim()) ?? 0.0).roundToDouble();
      final enteredNotes = _notesController.text.trim();

      final provider = Provider.of<ExpenseProvider>(context, listen: false);

      if (isEditing) {
        final updatedTx = widget.transactionToEdit!.copyWith(
          title: enteredTitle,
          amount: enteredAmount,
          date: _selectedDate,
          type: _selectedType,
          categoryId: _selectedCategoryId,
          accountId: _selectedAccountId,
          toAccountId: _selectedType == TransactionType.transfer
              ? _selectedToAccountId
              : null,
          notes: enteredNotes.isNotEmpty ? enteredNotes : null,
        );
        provider.updateTransaction(updatedTx);
      } else {
        final newTx = Transaction(
          id: const Uuid().v4(),
          title: enteredTitle,
          amount: enteredAmount,
          date: _selectedDate,
          type: _selectedType,
          categoryId: _selectedCategoryId,
          accountId: _selectedAccountId,
          toAccountId: _selectedType == TransactionType.transfer
              ? _selectedToAccountId
              : null,
          notes: enteredNotes.isNotEmpty ? enteredNotes : null,
        );
        provider.addTransaction(newTx);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final availableCategories = provider.categories
        .where((c) => c.type == _selectedType)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Transaction Type Selector
              Row(
                children: [
                  _buildTypeButton(
                    label: 'Expense',
                    icon: Icons.north_east,
                    type: TransactionType.expense,
                    activeColor: AppTheme.expenseRed,
                  ),
                  const SizedBox(width: 8),
                  _buildTypeButton(
                    label: 'Income',
                    icon: Icons.south_west,
                    type: TransactionType.income,
                    activeColor: AppTheme.incomeGreen,
                  ),
                  const SizedBox(width: 8),
                  _buildTypeButton(
                    label: 'Transfer',
                    icon: Icons.sync_alt,
                    type: TransactionType.transfer,
                    activeColor: AppTheme.accentPurple,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Amount Input
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Amount', style: AppTheme.labelMedium),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        filled: false,
                        prefixText: '৳ ',
                        prefixStyle: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentPurple,
                        ),
                        hintText: '0',
                        hintStyle: TextStyle(color: Colors.white30),
                        border: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        final parsed = double.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid amount greater than 0';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Title Input
              const Text(
                'Title / Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'e.g. Weekly Grocery, Client Invoice',
                  prefixIcon: Icon(Icons.edit_outlined, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 4. Categories Selector (if Expense or Income)
              if (_selectedType != TransactionType.transfer) ...[
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: availableCategories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, idx) {
                      final cat = availableCategories[idx];
                      final isSelected = _selectedCategoryId == cat.id;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = cat.id;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 80,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cat.color.withValues(alpha: 0.25)
                                : const Color(0xFF2B2930),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? cat.color : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(cat.icon, color: cat.color, size: 24),
                              const SizedBox(height: 6),
                              Text(
                                cat.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 5. Account / Wallet Selection
              Text(
                _selectedType == TransactionType.transfer
                    ? 'From Account'
                    : 'Payment Account / Wallet',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildAccountDropdown(provider),
              const SizedBox(height: 20),

              // If Transfer, show "To Account"
              if (_selectedType == TransactionType.transfer) ...[
                const Text(
                  'To Account',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildToAccountDropdown(provider),
                const SizedBox(height: 20),
              ],

              // 6. Date Picker
              const Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _presentDatePicker,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B2930),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: AppTheme.textGrey,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 15, color: Colors.white),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_calendar, color: AppTheme.accentPurple, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 7. Notes / Remarks
              const Text(
                'Notes (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Add extra details, tags, receipt info...',
                  prefixIcon: Icon(Icons.sticky_note_2_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 36),

              // 8. Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedType == TransactionType.expense
                        ? AppTheme.expenseRed
                        : (_selectedType == TransactionType.income
                            ? AppTheme.incomeGreen
                            : AppTheme.accentPurple),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isEditing ? Icons.save : Icons.check_circle_outline),
                      const SizedBox(width: 8),
                      Text(
                        isEditing ? 'Update Transaction' : 'Save Transaction',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountDropdown(ExpenseProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2930),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: provider.accounts.any((a) => a.id == _selectedAccountId)
              ? _selectedAccountId
              : (provider.accounts.isNotEmpty ? provider.accounts.first.id : null),
          dropdownColor: const Color(0xFF2B2930),
          isExpanded: true,
          items: provider.accounts.map((acc) {
            return DropdownMenuItem<String>(
              value: acc.id,
              child: Row(
                children: [
                  Icon(acc.icon, color: acc.color, size: 20),
                  const SizedBox(width: 10),
                  Text(acc.name, style: const TextStyle(color: Colors.white)),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedAccountId = val;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildToAccountDropdown(ExpenseProvider provider) {
    final availableAccounts =
        provider.accounts.where((a) => a.id != _selectedAccountId).toList();
    if (_selectedToAccountId == null && availableAccounts.isNotEmpty) {
      _selectedToAccountId = availableAccounts.first.id;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2930),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: availableAccounts.any((a) => a.id == _selectedToAccountId)
              ? _selectedToAccountId
              : (availableAccounts.isNotEmpty ? availableAccounts.first.id : null),
          dropdownColor: const Color(0xFF2B2930),
          isExpanded: true,
          items: availableAccounts.map((acc) {
            return DropdownMenuItem<String>(
              value: acc.id,
              child: Row(
                children: [
                  Icon(acc.icon, color: acc.color, size: 20),
                  const SizedBox(width: 10),
                  Text(acc.name, style: const TextStyle(color: Colors.white)),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedToAccountId = val;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required IconData icon,
    required TransactionType type,
    required Color activeColor,
  }) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _selectedCategoryId = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.15)
                : const Color(0xFF2B2930),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? activeColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : AppTheme.textGrey,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : AppTheme.textGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
