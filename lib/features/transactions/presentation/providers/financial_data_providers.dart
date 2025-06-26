// ignore_for_file: unused_import

import 'package:aifinanceapp/features/authentication/presentation/providers/auth_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:firebase_auth/firebase_auth.dart'; // Import for current user access
import 'package:cloud_firestore/cloud_firestore.dart'
    hide Transaction; // Import for Firestore types

import 'package:aifinanceapp/features/transactions/data/models/transaction_model.dart'; // Import Transaction model
import 'package:aifinanceapp/features/transactions/data/services/transaction_firestore_service.dart'; // Import TransactionFirestoreService

part 'financial_data_providers.g.dart';

// Enum to define time periods for filtering, now including 'all'
enum TimePeriod { week, month, year, all } // 'all' added here

// Class to hold overall financial state (income, expense, budget)
// This state specifically relates to the *monthly* budget and its derivatives.
class FinancialState {
  final double totalIncome; // This is the overall monthly income
  final double totalExpense; // This is the overall monthly expense
  final double monthlyBudget;
  final double dailyBudget;
  final double remainingBudget;

  FinancialState({
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.monthlyBudget = 0.0,
    this.dailyBudget = 0.0,
    this.remainingBudget = 0.0,
  });

  FinancialState copyWith({
    double? totalIncome,
    double? totalExpense,
    double? monthlyBudget,
    double? dailyBudget,
    double? remainingBudget,
  }) {
    return FinancialState(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      dailyBudget: dailyBudget ?? this.dailyBudget,
      remainingBudget: remainingBudget ?? this.remainingBudget,
    );
  }
}

// A simple class to hold summary for a given period (income and expense for the selected period)
// This will be used for 'This Week', 'This Month', 'This Year' summaries in the UI.
class PeriodSummary {
  final double totalIncome;
  final double totalExpense;
  final Map<String, double>
  categoryExpenses; // For charting - **will be removed if charts are removed from UI**

  PeriodSummary({
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.categoryExpenses = const {},
  });

  PeriodSummary copyWith({
    double? totalIncome,
    double? totalExpense,
    Map<String, double>? categoryExpenses,
  }) {
    return PeriodSummary(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      categoryExpenses: categoryExpenses ?? this.categoryExpenses,
    );
  }
}

// Provider for TransactionFirestoreService
@Riverpod(keepAlive: true)
TransactionFirestoreService transactionFirestoreService(
  TransactionFirestoreServiceRef ref,
) {
  return TransactionFirestoreService();
}

// StreamProvider for FirebaseAuth.instance.authStateChanges()
@Riverpod(keepAlive: true)
Stream<User?> authStateChanges(AuthStateChangesRef ref) {
  return FirebaseAuth.instance.authStateChanges();
}

// StreamProvider for all transactions of the current user
@Riverpod(keepAlive: true)
Stream<List<Transaction>> userTransactions(UserTransactionsRef ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        debugPrint(
          'userTransactionsProvider: No authenticated user for transaction stream. Returning empty stream.',
        );
        return Stream.value([]);
      }
      debugPrint(
        'userTransactionsProvider: Fetching transactions for user: ${user.uid}',
      );
      // Assuming TransactionFirestoreService.getTransactionsForUser() correctly filters by current user
      return ref
          .read(transactionFirestoreServiceProvider)
          .getTransactionsForUser();
    },
    loading: () {
      debugPrint(
        'userTransactionsProvider: Auth state loading, returning empty stream for now.',
      );
      return Stream.value([]);
    },
    error: (err, stack) {
      debugPrint('userTransactionsProvider: Error getting auth state: $err');
      return Stream.value([]);
    },
  );
}

// StreamProvider for the current user's profile data (to get monthlyBudget)
@Riverpod(keepAlive: true)
Stream<Map<String, dynamic>?> currentUserProfile(CurrentUserProfileRef ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        debugPrint(
          'currentUserProfileProvider: No authenticated user for profile stream. Returning empty stream.',
        );
        return Stream.value(null);
      }
      debugPrint(
        'currentUserProfileProvider: Fetching profile for user: ${user.uid}',
      );
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) => doc.data());
    },
    loading: () {
      debugPrint(
        'currentUserProfileProvider: Auth state loading, returning empty stream for now.',
      );
      return Stream.value(null);
    },
    error: (err, stack) {
      debugPrint(
        'currentUserProfileProvider: Error getting auth state for profile: $err',
      );
      return Stream.value(null);
    },
  );
}

// StateNotifier for the currently selected time period (This Week, This Month, This Year, All)
@Riverpod(keepAlive: true)
class SelectedTimePeriodNotifier extends _$SelectedTimePeriodNotifier {
  @override
  TimePeriod build() {
    return TimePeriod.all; // Default to 'All' transactions on dashboard open
  }

  void setPeriod(TimePeriod period) {
    state = period;
  }
}

// Provider for FILTERED transactions based on selected time period
@Riverpod(keepAlive: true)
Stream<List<Transaction>> filteredTransactions(FilteredTransactionsRef ref) {
  final allTransactionsAsyncValue = ref.watch(userTransactionsProvider);
  final selectedPeriod = ref.watch(selectedTimePeriodNotifierProvider);
  final now = DateTime.now();

  return allTransactionsAsyncValue.when(
    data: (allTransactions) {
      List<Transaction> filtered = [];
      if (selectedPeriod == TimePeriod.all) {
        filtered = allTransactions; // Return all transactions for 'All'
      } else if (selectedPeriod == TimePeriod.month) {
        filtered = allTransactions
            .where((t) => t.date.year == now.year && t.date.month == now.month)
            .toList();
      } else if (selectedPeriod == TimePeriod.week) {
        // Calculate start of the current week (Monday) and end of the week (Sunday)
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        startOfWeek = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        ); // Reset time to 00:00:00
        DateTime endOfWeek = startOfWeek.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );

        filtered = allTransactions
            .where(
              (t) =>
                  t.date.isAfter(
                    startOfWeek.subtract(const Duration(microseconds: 1)),
                  ) &&
                  t.date.isBefore(
                    endOfWeek.add(const Duration(microseconds: 1)),
                  ),
            )
            .toList();
      } else if (selectedPeriod == TimePeriod.year) {
        filtered = allTransactions
            .where((t) => t.date.year == now.year)
            .toList();
      }
      return Stream.value(filtered);
    },
    loading: () => Stream.value([]),
    error: (error, stack) {
      debugPrint('Error filtering transactions by period: $error');
      return Stream.value([]);
    },
  );
}

// Provider for filtered financial summary (income/expense/category breakdown) based on selected period
@Riverpod(keepAlive: true)
class FilteredPeriodSummaryNotifier extends _$FilteredPeriodSummaryNotifier {
  @override
  PeriodSummary build() {
    final filteredTransactionsAsync = ref.watch(filteredTransactionsProvider);

    return filteredTransactionsAsync.when(
      data: (transactions) {
        double totalIncome = 0.0;
        double totalExpense = 0.0;
        Map<String, double> categoryExpenses =
            {}; // Still keeping this for now, but if charts are removed, this might become redundant.

        for (var transaction in transactions) {
          if (transaction.type.toLowerCase() == 'income') {
            totalIncome += transaction.amount;
          } else if (transaction.type.toLowerCase() == 'expense' ||
              transaction.type.toLowerCase() == 'debit & loan') {
            totalExpense += transaction.amount;
            categoryExpenses.update(
              transaction.category ?? 'Uncategorized',
              (value) => value + transaction.amount,
              ifAbsent: () => transaction.amount,
            );
          }
        }
        return PeriodSummary(
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          categoryExpenses:
              categoryExpenses, // Still included, but can be removed if not used for anything else.
        );
      },
      loading: () => PeriodSummary(), // Return empty during loading
      error: (error, stack) {
        debugPrint('Error calculating period summary: $error');
        return PeriodSummary(); // Return empty on error
      },
    );
  }
}

// The main Notifier for overall financial state (income, expense, budget, daily budget, remaining budget)
// This notifier remains focused on the CURRENT MONTH's budget and associated calculations.
@Riverpod(keepAlive: true)
class FinancialDataNotifier extends _$FinancialDataNotifier {
  @override
  FinancialState build() {
    // Watch current user ID
    final user = ref.watch(authStateChangesProvider).valueOrNull;

    if (user == null) {
      debugPrint(
        'FinancialDataNotifier: No authenticated user. Returning empty state.',
      );
      return FinancialState();
    }

    // Watch both current user profile and user transactions.
    // Riverpod will automatically rebuild this provider whenever these dependencies change.
    final userProfile = ref.watch(currentUserProfileProvider).valueOrNull;
    final transactions = ref.watch(userTransactionsProvider).valueOrNull ?? [];

    debugPrint(
      'FinancialDataNotifier: Rebuilding with userProfile: ${userProfile != null ? 'present' : 'null'}, transactions count: ${transactions.length}',
    );

    // Calculate the state based on the current values of watched providers
    return _calculateFinancialState(transactions, userProfile);
  }

  void _updateFinancialState({
    required List<Transaction> transactions,
    required Map<String, dynamic>? userProfile,
  }) {
    state = _calculateFinancialState(transactions, userProfile);
  }

  FinancialState _calculateFinancialState(
    List<Transaction> transactions,
    Map<String, dynamic>? userProfile,
  ) {
    double totalIncomeForMonth = 0.0; // Specific to current month
    double totalExpenseForMonth = 0.0; // Specific to current month
    double monthlyBudget = userProfile?['monthlyBudget'] as double? ?? 0.0;

    final now = DateTime.now();
    // Filter transactions for the current month to calculate monthly totals
    final currentMonthTransactions = transactions.where((t) {
      return t.date.year == now.year && t.date.month == now.month;
    }).toList();

    for (var transaction in currentMonthTransactions) {
      if (transaction.type.toLowerCase() == 'income') {
        totalIncomeForMonth += transaction.amount;
      } else if (transaction.type.toLowerCase() == 'expense' ||
          transaction.type.toLowerCase() == 'debit & loan') {
        totalExpenseForMonth += transaction.amount;
      }
    }

    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final remainingDaysInMonth =
        lastDayOfMonth.day - now.day + 1; // Including today

    // Calculate remaining budget *before* daily budget
    double remainingBudget = monthlyBudget - totalExpenseForMonth;

    // Corrected dailyBudget calculation: based on remaining budget
    double dailyBudget = (remainingBudget > 0 && remainingDaysInMonth > 0)
        ? (remainingBudget / remainingDaysInMonth).roundToDouble()
        : 0.0;

    return FinancialState(
      totalIncome:
          totalIncomeForMonth, // This now reflects total income for the current month
      totalExpense:
          totalExpenseForMonth, // This now reflects total expense for the current month
      monthlyBudget: monthlyBudget,
      dailyBudget: dailyBudget,
      remainingBudget: remainingBudget,
    );
  }

  // Method to set monthly budget and persist to Firestore
  Future<void> setMonthlyBudgetAndPersist(double amount) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      debugPrint('Error: No authenticated user to save budget.');
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'monthlyBudget': amount,
      }, SetOptions(merge: true));
      debugPrint('Monthly budget saved to Firestore: $amount');
      // The state will automatically update because this provider watches currentUserProfileProvider
    } catch (e) {
      debugPrint('Error saving monthly budget to Firestore: $e');
      // Optionally, show an error to the user
    }
  }

  // Reset all financial data (optional, useful for testing/specific features)
  void resetFinancialData() {
    state = FinancialState();
    // Note: This only resets the local state, not data in Firestore.
    // To reset in Firestore, you'd need to call setMonthlyBudgetAndPersist(0.0)
    // and potentially clear transactions (which is more complex).
  }
}
