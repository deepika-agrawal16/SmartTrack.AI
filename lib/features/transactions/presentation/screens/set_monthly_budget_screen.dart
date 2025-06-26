import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifinanceapp/features/transactions/presentation/providers/financial_data_providers.dart'; // Ensure this import is correct

class SetMonthlyBudgetScreen extends ConsumerStatefulWidget {
  const SetMonthlyBudgetScreen({super.key});

  @override
  ConsumerState<SetMonthlyBudgetScreen> createState() => _SetMonthlyBudgetScreenState();
}

class _SetMonthlyBudgetScreenState extends ConsumerState<SetMonthlyBudgetScreen> {
  final TextEditingController _monthlyBudgetController = TextEditingController();
  final Color _primaryColor = const Color.fromARGB(255, 48, 98, 206);
  final Color _secondaryColor = const Color(0xFFF7F7F7);

  @override
  void initState() {
    super.initState();
    // Delay the budget retrieval until after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pre-fill with current budget from the financialDataNotifierProvider
      _monthlyBudgetController.text =
          ref.read(financialDataNotifierProvider).monthlyBudget.toStringAsFixed(0);
    });
  }

  @override
  void dispose() {
    _monthlyBudgetController.dispose();
    super.dispose();
  }

  void _saveBudget() {
    final double? budget = double.tryParse(_monthlyBudgetController.text);
    if (budget != null && budget >= 0) {
      // Update the monthly budget using the notifier
      ref.read(financialDataNotifierProvider.notifier).setMonthlyBudgetAndPersist(budget);
      Navigator.of(context).pop(); // Go back after saving
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget amount.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _secondaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Set Monthly Budget',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveBudget,
            child: Text(
              'Save',
              style: TextStyle(color: _primaryColor, fontSize: 18),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Monthly Budget',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _monthlyBudgetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'e.g., 4000',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: _secondaryColor,
                prefixText: '₹ ',
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
            Center(
              child: Text(
                'This budget helps you track your spending against a set limit.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}