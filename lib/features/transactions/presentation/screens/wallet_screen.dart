// lib/features/transactions/presentation/screens/wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart

import 'package:aifinanceapp/features/transactions/data/models/transaction_model.dart';
import 'package:aifinanceapp/features/transactions/presentation/providers/financial_data_providers.dart' hide currentUserProfileProvider;
import 'package:aifinanceapp/features/onboarding/presentation/providers/user_profile_providers.dart';

// -----------------------------------------------------------------------------
// NEW: Provider for Monthly Financial Summary
// This provider will process transactions and budget data to create summaries per month.
// -----------------------------------------------------------------------------

class MonthlySummary {
  final DateTime month;
  final double totalIncome;
  final double totalExpense;
  final double monthlyBudget;
  final double netSavings; // income - expense
  final double budgetVsExpense; // budget - expense (how much left/over)
  final double budgetVsSavings; // income - budget (how much saved above budget)

  MonthlySummary({
    required this.month,
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.monthlyBudget = 0.0,
  })  : netSavings = totalIncome - totalExpense,
        budgetVsExpense = monthlyBudget - totalExpense,
        budgetVsSavings = totalIncome - monthlyBudget; // How much income is above the set budget

  // Helper to check if a month is within the same year/month as another DateTime
  bool isSameMonth(DateTime other) {
    return month.year == other.year && month.month == other.month;
  }
}

final monthlyFinancialSummaryProvider =
    Provider<AsyncValue<List<MonthlySummary>>>((ref) {
  final transactionsAsync = ref.watch(userTransactionsProvider);
  final userProfileAsync = ref.watch(currentUserProfileProvider);

  if (transactionsAsync.isLoading || userProfileAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (transactionsAsync.hasError) {
    return AsyncValue.error(transactionsAsync.error!, transactionsAsync.stackTrace ?? StackTrace.empty);
  }
  if (userProfileAsync.hasError) {
    return AsyncValue.error(userProfileAsync.error!, userProfileAsync.stackTrace ?? StackTrace.empty);
  }
  if (!transactionsAsync.hasValue || !userProfileAsync.hasValue) {
    return const AsyncValue.loading();
  }

  final List<Transaction> transactions = transactionsAsync.value!;
  final Map<String, dynamic>? userProfile = userProfileAsync.value;

  final double defaultMonthlyBudget =
      (userProfile?['monthlyBudget'] as num?)?.toDouble() ?? 0.0;

  // Group transactions by month
  Map<String, List<Transaction>> transactionsByMonth = {};
  for (var t in transactions) {
    String monthKey = DateFormat('yyyy-MM').format(t.date);
    transactionsByMonth.putIfAbsent(monthKey, () => []).add(t);
  }

  List<MonthlySummary> summaries = [];
  List<String> sortedMonthKeys = transactionsByMonth.keys.toList()
    ..sort(); // Sort months chronologically

  for (String monthKey in sortedMonthKeys) {
    List<Transaction> monthTransactions = transactionsByMonth[monthKey]!;
    double income = 0.0;
    double expense = 0.0;

    for (var t in monthTransactions) {
      if (t.type == 'Income') {
        income += t.amount;
      } else if (t.type == 'Expense' || t.type == 'Debit & Loan') {
        expense += t.amount;
      }
    }

    // Determine the budget for this specific month.
    // For simplicity, we are currently using the latest `defaultMonthlyBudget`
    // from the user profile. A more robust solution would store monthly budgets
    // with a timestamp in Firestore.
    summaries.add(
      MonthlySummary(
        month: DateFormat('yyyy-MM').parse(monthKey),
        totalIncome: income,
        totalExpense: expense,
        monthlyBudget: defaultMonthlyBudget, // Using the current budget for all months
      ),
    );
  }

  // Sort summaries by month in descending order (most recent first)
  summaries.sort((a, b) => b.month.compareTo(a.month));

  return AsyncValue.data(summaries);
});


// -----------------------------------------------------------------------------
// Wallet Screen
// -----------------------------------------------------------------------------

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlySummariesAsync = ref.watch(monthlyFinancialSummaryProvider);

    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: monthlySummariesAsync.when(
        data: (summaries) {
          if (summaries.isEmpty) {
            return const Center(
              child: Text(
                'No financial data recorded yet.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          // Calculate overall totals
          double overallIncome =
              summaries.fold(0.0, (sum, s) => sum + s.totalIncome);
          double overallExpense =
              summaries.fold(0.0, (sum, s) => sum + s.totalExpense);
          double overallSavings = overallIncome - overallExpense;

          // Find month with highest savings
          MonthlySummary? highestSavingMonth;
          if (summaries.isNotEmpty) {
            highestSavingMonth = summaries.reduce((a, b) =>
                a.netSavings > b.netSavings ? a : b);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Summary Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overall Financial Summary',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        ),
                        const SizedBox(height: 15),
                        _buildSummaryRow(
                            'Total Income', overallIncome, currencyFormatter, Colors.green),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                            'Total Expense', overallExpense, currencyFormatter, Colors.red),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                            'Net Savings', overallSavings, currencyFormatter,
                            overallSavings >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                            isBold: true),
                        if (highestSavingMonth != null && highestSavingMonth.netSavings > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              'Highest Saving Month: ${DateFormat('MMMM yyyy').format(highestSavingMonth.month)} '
                              '(${currencyFormatter.format(highestSavingMonth.netSavings)})',
                              style: const TextStyle(
                                  fontSize: 14, fontStyle: FontStyle.italic, color: Colors.indigo),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Monthly Breakdown',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: summaries.length,
                  itemBuilder: (context, index) {
                    final summary = summaries[index];
                    String budgetStatusText;
                    Color budgetStatusColor;

                    if (summary.monthlyBudget > 0) {
                      if (summary.budgetVsExpense < 0) {
                        budgetStatusText =
                            'Over Budget by ${currencyFormatter.format(summary.budgetVsExpense.abs())}';
                        budgetStatusColor = Colors.red.shade700;
                      } else {
                        budgetStatusText =
                            'Under Budget by ${currencyFormatter.format(summary.budgetVsExpense)}';
                        budgetStatusColor = Colors.green.shade700;
                      }
                    } else {
                      budgetStatusText = 'Budget Not Set';
                      budgetStatusColor = Colors.grey;
                    }


                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        title: Text(
                          DateFormat('MMMM yyyy').format(summary.month),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Savings: ${currencyFormatter.format(summary.netSavings)}',
                          style: TextStyle(
                            color: summary.netSavings >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              children: [
                                _buildDetailRow(
                                    'Income', summary.totalIncome, currencyFormatter, Colors.green),
                                _buildDetailRow(
                                    'Expense', summary.totalExpense, currencyFormatter, Colors.red),
                                _buildDetailRow(
                                    'Monthly Budget', summary.monthlyBudget, currencyFormatter, Colors.blue),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Budget Status:', style: TextStyle(fontSize: 14)),
                                      Text(budgetStatusText, style: TextStyle(fontSize: 14, color: budgetStatusColor)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, NumberFormat formatter, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.black : Colors.grey[800]),
        ),
        Text(
          formatter.format(amount),
          style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, double amount, NumberFormat formatter, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(formatter.format(amount), style: TextStyle(fontSize: 14, color: color)),
        ],
      ),
    );
  }
}