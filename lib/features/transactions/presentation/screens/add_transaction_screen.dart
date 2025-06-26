// ignore_for_file: unused_import

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction; // Import for Timestamp
import 'package:firebase_auth/firebase_auth.dart'; // Import for current user UID

import 'package:aifinanceapp/features/transactions/data/models/transaction_model.dart';
import 'package:aifinanceapp/features/transactions/presentation/screens/select_category_screen.dart';
import 'package:aifinanceapp/features/transactions/presentation/providers/financial_data_providers.dart';
import 'package:aifinanceapp/features/transactions/data/services/transaction_firestore_service.dart'; // Import the service

class AddTransaction extends ConsumerStatefulWidget {
  final String? initialType; // Initial type (Income/Expense) passed from Dashboard

  const AddTransaction({super.key, this.initialType});

  @override
  ConsumerState<AddTransaction> createState() => _AddTransactionState();
}

class _AddTransactionState extends ConsumerState<AddTransaction> {
  final Color _primaryColor = const Color.fromARGB(255, 48, 98, 206);
  final Color _secondaryColor = const Color(0xFFF7F7F7);
  String _selectedCurrency = 'INR';
  final _amountController = TextEditingController();
  String? _selectedCategory;
  String? _note;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  File? _receiptImage; // Local file path for receipt image (for now)
  late String _selectedType;

  final List<String> _transactionTypes = ['Income', 'Expense', 'Debit & Loan', 'Repay'];
  final Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'INR': '₹',
    'GBP': '£',
    'JPY': '¥',
    'AUD': 'A\$',
  };
  final Map<String, IconData> _currencyIcons = {
    'USD': Icons.attach_money,
    'EUR': Icons.euro,
    'INR': Icons.currency_rupee,
    'GBP': Icons.currency_pound,
    'JPY': Icons.currency_yen,
    'AUD': Icons.currency_bitcoin,
  };

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? 'Expense'; // Set initial type from argument
    _selectedDate = DateTime.now(); // Default to current date
    _selectedTime = TimeOfDay.now(); // Default to current time
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource src) async {
    final picked = await ImagePicker().pickImage(source: src);
    if (picked != null) {
      setState(() => _receiptImage = File(picked.path));
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: _primaryColor,
            colorScheme: ColorScheme.light(primary: _primaryColor),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: _primaryColor,
            colorScheme: ColorScheme.light(primary: _primaryColor),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // --- SAVE TRANSACTION LOGIC (UPDATED) ---
  void _saveTransaction() async {
    final double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }

    // Create a Transaction object
    final newTransaction = Transaction(
      userId: user.uid,
      type: _selectedType,
      amount: amount,
      currency: _selectedCurrency,
      category: _selectedType == 'Expense' ? _selectedCategory : null, // Category only for expenses
      note: _note,
      date: _selectedDate ?? DateTime.now(),
      time: _selectedTime,
      localImagePath: _receiptImage?.path, // Save local image path for now
      createdAt: Timestamp.now(), // Timestamp when transaction is created
    );

    try {
      // Use the TransactionFirestoreService to add the transaction to Firestore
      await ref.read(transactionFirestoreServiceProvider).addTransaction(newTransaction);

      // Removed the calls to financialNotifier.addIncome and financialNotifier.addExpense
      // as they are not defined and the financial data is updated via stream.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction added successfully!')),
        );
        Navigator.pop(context); // Go back to dashboard after saving
      }
    } catch (e) {
      debugPrint('Error saving transaction: $e'); // Print detailed error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add transaction: ${e.toString()}')),
        );
      }
    }

    // Clear fields after saving (or after failed attempt if you want user to re-enter)
    _amountController.clear();
    setState(() {
      _selectedCategory = null;
      _note = null;
      _receiptImage = null;
      _selectedDate = DateTime.now(); // Reset date
      _selectedTime = TimeOfDay.now(); // Reset time
    });
  }
  // --- END SAVE TRANSACTION LOGIC ---

  @override
  Widget build(BuildContext context) {
    String appBarTitle = 'Add Transaction';
    if (_selectedType == 'Income') {
      appBarTitle = 'Add Income';
    } else if (_selectedType == 'Expense') {
      appBarTitle = 'Add Expense';
    } else if (_selectedType == 'Debit & Loan') {
      appBarTitle = 'Add Debit & Loan';
    } else if (_selectedType == 'Repay') {
      appBarTitle = 'Add Repay';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          appBarTitle,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveTransaction,
            child: Text(
              'Save',
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _secondaryColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: _transactionTypes.map((type) {
                    return _buildTransactionTab(type);
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _currencyIcons[_selectedCurrency],
                        color: _primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedCurrency,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: _currencySymbols.keys.map((currency) {
                          return DropdownMenuItem(
                            value: currency,
                            child: Row(
                              children: [
                                Text(
                                  currency,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _currencySymbols[currency]!,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedCurrency = v!),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600, size: 24),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Enter Amount',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: _secondaryColor,
                prefixText: '${_currencySymbols[_selectedCurrency]} ',
                prefixStyle: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            // Conditionally show category selection for 'Expense' and 'Debit & Loan'
            if (_selectedType == 'Expense' || _selectedType == 'Debit & Loan') ...[
              _buildRow(Icons.category, _selectedCategory ?? 'Select Category', () async {
                final selected = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SelectCategoryScreen()),
                );
                if (selected != null && selected is String) {
                  setState(() {
                    _selectedCategory = selected;
                  });
                }
              }),
              const SizedBox(height: 16),
            ],
            _buildRow(Icons.edit_note, _note ?? 'Write Note', () async {
              final note = await _showTextInput(context, 'Write Note');
              if (note != null) setState(() => _note = note);
            }),
            const SizedBox(height: 16),
            _buildRow(
              Icons.calendar_today,
              _selectedDate == null
                  ? 'Set Date'
                  : DateFormat('MMM dd, yyyy').format(_selectedDate!), // Corrected format for year
              _pickDate,
            ),
            const SizedBox(height: 16),
            _buildRow(
              Icons.access_time,
              _selectedTime == null
                  ? 'Set Reminder'
                  : _selectedTime!.format(context),
              _pickTime,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera_alt, color: _primaryColor, size: 24),
                    label: Text(
                      'Camera',
                      style: TextStyle(color: _primaryColor, fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _primaryColor.withOpacity(0.1),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library, color: _primaryColor, size: 24),
                    label: Text(
                      'Gallery',
                      style: TextStyle(color: _primaryColor, fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _primaryColor.withOpacity(0.1),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildRow(IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _secondaryColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: _primaryColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade500, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTab(String title) {
    final bool isSelected = _selectedType == title;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedType = title;
        // Reset category when switching type to Income (if it was an expense category)
        if (title == 'Income') {
          _selectedCategory = null;
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<String?> _showTextInput(BuildContext context, String title) {
    final controller = TextEditingController(text: _note);
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text('Cancel', style: TextStyle(color: _primaryColor, fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            child: const Text('OK', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}