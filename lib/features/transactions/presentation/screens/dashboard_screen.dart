// ignore_for_file: unused_import, deprecated_member_use

import 'dart:io';
import 'package:aifinanceapp/features/transactions/presentation/screens/pocket_screen.dart';
import 'package:aifinanceapp/features/transactions/presentation/screens/stats_screen.dart';
import 'package:aifinanceapp/features/transactions/presentation/screens/wallet_screen.dart';
import 'package:aifinanceapp/services/ai_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Keep this import for getting current user ID
import 'package:cloud_firestore/cloud_firestore.dart'
    hide
        Transaction; // Keep hide Transaction for now, though not strictly needed here
import 'package:aifinanceapp/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:aifinanceapp/features/transactions/presentation/providers/financial_data_providers.dart'
    hide currentUserProfileProvider; // Import all providers
import 'package:aifinanceapp/features/transactions/presentation/screens/set_monthly_budget_screen.dart';
import 'package:aifinanceapp/features/onboarding/presentation/providers/user_profile_providers.dart';
import 'package:aifinanceapp/features/transactions/data/models/transaction_model.dart'; // Import Transaction model
// You'll need this if CategoryIconMapping is defined in pocket_screen.dart
import 'package:aifinanceapp/features/transactions/presentation/screens/pocket_screen.dart'
    as pocket_screen;

class DashboardScreen extends ConsumerStatefulWidget {
  static const double _bottomNavHeight = 56.0;

  final String userName;
  final File?
      profileImage; // This might be used for initial display right after setup

  const DashboardScreen({super.key, required this.userName, this.profileImage});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule the provider modifications to run after the current frame is built.
    // This prevents the "Tried to modify a provider while the widget tree was building" error.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch user profile when the dashboard initializes to get the latest data (including image URL)
      ref.read(userProfileNotifierProvider.notifier).fetchUserProfile();
      // Set the default period for the dashboard summaries to 'month'
      ref.read(selectedTimePeriodNotifierProvider.notifier).setPeriod(TimePeriod.month); // Or TimePeriod.all
    });
  }

  @override
  Widget build(BuildContext context) {
    // financialState will give us current month's budget details
    final financialState = ref.watch(financialDataNotifierProvider);
    // periodSummary will give us income/expense/debit/repay for the selected period (defaulting to month)
    final periodSummary = ref.watch(filteredPeriodSummaryNotifierProvider);

    final userProfileAsyncValue = ref.watch(currentUserProfileProvider);
    final userTransactionsAsyncValue =
        ref.watch(filteredTransactionsProvider); // Use filtered transactions here

    String currentUserName = widget.userName;
    String? currentProfileImageUrl;
    File? currentProfileImageFile = widget.profileImage;

    userProfileAsyncValue.whenOrNull(
      data: (profileData) {
        if (profileData != null) {
          currentUserName = profileData['userName'] ?? widget.userName;
          currentProfileImageUrl = profileData['profileImageUrl'];
        }
      },
    );

    // Get the current user's ID
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      // Pass the userId to the AskAlButton
      floatingActionButton: AskAlButton(userId: currentUserId),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const BottomNav(),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: HeaderSection(
                userName: currentUserName,
                profileImage: currentProfileImageFile,
                profileImageUrl: currentProfileImageUrl,
              ),
            ),
            const SizedBox(height: 20),
            // Removed TimeTabs here as requested
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SummaryBoxes(
                income: periodSummary.totalIncome, // Use periodSummary for these totals
                expense: periodSummary.totalExpense, // Use periodSummary for these totals
              ),
            ),
            const SizedBox(height: 10), // Reduced space slightly
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LoanRepaySummaryBoxes(
                // New widget for Debit & Loan and Repay
                debitAndLoan:
                    periodSummary.totalDebitAndLoan, // Use periodSummary for these totals
                repay: periodSummary.totalRepay, // Use periodSummary for these totals
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: BudgetBox(
                monthlyBudget: financialState.monthlyBudget,
                totalExpense: financialState
                    .totalExpense, // This is current month's expense for budget comparison
                dailyBudget: financialState.dailyBudget,
                onSetBudget: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SetMonthlyBudgetScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Transactions",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to PocketScreen and set its filter to TimePeriod.all
                        ref
                            .read(selectedTimePeriodNotifierProvider.notifier)
                            .setPeriod(TimePeriod.all);
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const PocketScreen()));
                      },
                      child: const Text(
                        "See all",
                        style: TextStyle(
                          color: Color(0xFF3062CE),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: userTransactionsAsyncValue.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Text(
                            "No transactions added yet.",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      );
                    }
                    // Show only a few recent transactions on the dashboard, e.g., last 5
                    final recentTransactions = transactions.take(5).toList();
                    return TransactionsList(transactions: recentTransactions);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) =>
                      Center(child: Text('Error loading transactions: $err')),
                ),
              ),
            ),
            SizedBox(height: DashboardScreen._bottomNavHeight + 20),
          ],
        ),
      ),
    );
  }
}

// HeaderSection remains unchanged
class HeaderSection extends StatelessWidget {
  final String userName;
  final File? profileImage;
  final String? profileImageUrl;

  const HeaderSection({
    super.key,
    required this.userName,
    this.profileImage,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF3062CE);

    ImageProvider? avatarProvider;
    if (profileImage != null) {
      avatarProvider = FileImage(profileImage!);
    } else if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      avatarProvider = NetworkImage(profileImageUrl!);
    } else {
      avatarProvider = const AssetImage('assets/avatar.png');
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[200],
          backgroundImage: avatarProvider,
          onBackgroundImageError: (exception, stackTrace) {
            debugPrint('Error loading profile image: $exception');
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Hi, $userName!',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle, color: blue, size: 32),
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AddTransaction()));
          },
        ),
      ],
    );
  }
}

// Removed TimeTabs and TimeTab as requested

class SummaryBoxes extends StatelessWidget {
  final double income;
  final double expense;

  const SummaryBoxes({super.key, required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
    );
    return Row(
      children: [
        Expanded(
          child: InfoBox(
            title: "Income",
            amount: currencyFormatter.format(income),
            color: const Color(0xFFD9E6FE),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InfoBox(
            title: "Expense",
            amount: currencyFormatter.format(expense),
            color: const Color(0xFFFFE2E2),
          ),
        ),
      ],
    );
  }
}

// NEW Widget for Debit & Loan and Repay summary boxes
class LoanRepaySummaryBoxes extends StatelessWidget {
  final double debitAndLoan;
  final double repay;

  const LoanRepaySummaryBoxes({
    super.key,
    required this.debitAndLoan,
    required this.repay,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
    );
    return Row(
      children: [
        Expanded(
          child: InfoBox(
            title: "Debit & Loan",
            amount: currencyFormatter.format(debitAndLoan),
            color: const Color(0xFFF0E0FF), // Light purple/pink for outflows
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InfoBox(
            title: "Repay",
            amount: currencyFormatter.format(repay),
            color: const Color(0xFFE0FCE0), // Light green for inflows
          ),
        ),
      ],
    );
  }
}

class InfoBox extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;

  const InfoBox({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 5),
          Text(
            amount,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class BudgetBox extends StatelessWidget {
  final double monthlyBudget;
  final double totalExpense;
  final double dailyBudget;
  final VoidCallback onSetBudget;

  const BudgetBox({
    super.key,
    required this.monthlyBudget,
    required this.totalExpense,
    required this.dailyBudget,
    required this.onSetBudget,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF3062CE);
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
    );

    String budgetText;
    String expenseText;
    Color expenseColor;

    if (monthlyBudget > 0) {
      budgetText =
          '${currencyFormatter.format(dailyBudget)} / Day\nOf ${currencyFormatter.format(monthlyBudget)}';
      double remaining = monthlyBudget - totalExpense;
      expenseText = '${currencyFormatter.format(totalExpense)} Exp';
      expenseColor = (remaining < 0) ? Colors.red : Colors.green;
    } else {
      budgetText = 'Set Monthly Budget';
      expenseText = '';
      expenseColor = Colors.black54;
    }

    return GestureDetector(
      onTap: onSetBudget,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.water_drop_outlined,
              size: 40,
              color: blue,
            ), // Placeholder icon
            const SizedBox(width: 15),
            Expanded(
              child: Text(budgetText, style: const TextStyle(fontSize: 14)),
            ),
            Text(
              expenseText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: expenseColor,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}

// Category icon mapping for transaction categories
class CategoryIconMapping {
  static const Map<String, IconData> _categoryIcons = {
    'Run': Icons.directions_run,
    'Doctor': Icons.medical_services,
    'Medicine': Icons.medication,
    'Exercise': Icons.fitness_center,
    'Cycling': Icons.directions_bike,
    'Swim': Icons.pool,
    'Grocery': Icons.local_grocery_store,
    'Tea & Coffees': Icons.coffee,
    'Drinks': Icons.local_bar,
    'Restaurants': Icons.restaurant,
    'Phone Bill': Icons.phone_android,
    'Water Bill': Icons.water_drop,
    'Gas Bill': Icons.local_fire_department,
    'Internet Bill': Icons.wifi,
    'Rentals': Icons.home_work,
    'TV Bill': Icons.tv,
    'Electricity Bill': Icons.flash_on,
    'Pets': Icons.pets,
    'House': Icons.house,
    'Children': Icons.child_care,
    'Gifts': Icons.card_giftcard,
    'Marriage': Icons.people_alt,
    'Funeral': Icons.group_off,
    'Charity': Icons.volunteer_activism,
    'Clothings': Icons.checkroom,
    'Footwear': Icons.roller_skating,
    'Gadgets': Icons.devices,
    'Electronics': Icons.electrical_services,
    'Furniture': Icons.single_bed,
    'Vehicles': Icons.directions_car,
    'Accessories': Icons.headset,
    'default': Icons.category,
  };

  static IconData getCategoryIconStatic(String? categoryName) {
    if (categoryName == null) return _categoryIcons['default']!;
    return _categoryIcons[categoryName] ?? _categoryIcons['default']!;
  }
}

// NEW: Widget to display the list of transactions
class TransactionsList extends ConsumerWidget {
  final List<Transaction> transactions;

  const TransactionsList({super.key, required this.transactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
    );

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        // Correctly determine if it's an expense or debit for icon/color
        final isExpenseOrDebit =
            transaction.type.toLowerCase() == 'expense' || transaction.type.toLowerCase() == 'debit & loan';
        final isRepay = transaction.type.toLowerCase() == 'repay'; // Check for repay specifically
        final isIncome = transaction.type.toLowerCase() == 'income'; // Define isIncome

        Color iconColor;
        Color amountColor;
        String sign;

        if (isExpenseOrDebit) {
          iconColor = Colors.red;
          amountColor = Colors.red;
          sign = '-';
        } else if (isRepay) {
          iconColor = Colors.blueGrey; // Or a specific color for repay
          amountColor = Colors.blueGrey; // Or a specific color for repay
          sign = '-'; // Repay is also an outflow
        } else if (isIncome) {
          iconColor = Colors.green;
          amountColor = Colors.green;
          sign = '+';
        } else {
          // Default for any other type
          iconColor = Colors.grey;
          amountColor = Colors.grey;
          sign = '';
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    // Access the static getter for category icons from pocket_screen
                    CategoryIconMapping.getCategoryIconStatic(transaction.category),
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // Display category or type based on availability
                        transaction.category ?? transaction.type,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(transaction.date), // Corrected format to 'yyyy'
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$sign ${currencyFormatter.format(transaction.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: amountColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Rest of the existing widgets (BottomNav, _NavItem, AskAlButton) remain unchanged

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: DashboardScreen._bottomNavHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              onTap: () {
                // Navigate back to Dashboard. Current state should be preserved.
                // For simplicity, just popping if it's not the first route, or navigating directly.
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => DashboardScreen(userName: 'User'),
                    ),
                  );
                }
              },
            ), // Home functionality as before
            _NavItem(
              icon: Icons.pie_chart, // Icon for Report/Pocket
              label: 'Report', // Label for the button
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const PocketScreen()),
                );
              },
            ),
            const SizedBox(width: 36), // Spacer for FAB
            _NavItem(
              icon: Icons.insert_chart_outlined,
              label: 'Stats',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const StatsScreen()),
                );
              },
            ), // Stats functionality
            _NavItem(
              icon: Icons.credit_card_outlined,
              label: 'Wallet',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const WalletScreen()),
                );
              },
            ), // Wallet functionality
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _NavItem({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class AskAlButton extends StatelessWidget {
  final String? userId; // Make userId nullable

  const AskAlButton({super.key, this.userId}); // Update constructor

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      width: 58,
      decoration: BoxDecoration(
        color: const Color(0xFF3062CE), // Use a prominent blue for AI button
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            // Only navigate if userId is not null (i.e., a user is logged in)
            if (userId != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  // Navigate to AIChatScreen, passing the user's ID
                  builder: (_) => AIChatScreen(userId: userId!),
                ),
              );
            } else {
              // Show a message to the user if they try to use AI without logging in
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please log in to use the AI Assistant.'),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(
            29,
          ), // Ensures the ripple effect is circular
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 26,
                color: Colors.white,
              ), // AI or Sparkle icon
              Text(
                'AI',
                style: TextStyle(fontSize: 11, color: Colors.white),
              ), // "AI" text
            ],
          ),
        ),
      ),
    );
  }
}