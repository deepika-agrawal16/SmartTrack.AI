// features/reports/presentation/screens/pocket_screen.dart (create this new file)
import 'package:aifinanceapp/features/transactions/presentation/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart
import 'package:aifinanceapp/features/transactions/presentation/providers/financial_data_providers.dart'; // To fetch transactions

class PocketScreen extends ConsumerWidget {
  const PocketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsyncValue = ref.watch(userTransactionsProvider);

    const Color primaryColor = Color(0xFF3062CE);
    const Color incomeColor = Color(0xFF4CAF50); // Green for income
    const Color expenseColor = Color(0xFFF44336); // Red for expense

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Report',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: transactionsAsyncValue.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Text(
                "No transactions to display yet. Add some to see your pocket overview!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Process data for charts
          final Map<String, double> monthlyIncome = {};
          final Map<String, double> monthlyExpense = {};
          final Map<String, double> categoryExpense = {};
          double totalIncome = 0.0;
          double totalExpense = 0.0;

          // Sort transactions by date in ascending order for monthly trend
          transactions.sort((a, b) => a.date.compareTo(b.date));

          for (var t in transactions) {
            final monthYear = DateFormat('MMM yyyy').format(t.date);

            if (t.type == 'Income') {
              totalIncome += t.amount;
              monthlyIncome[monthYear] = (monthlyIncome[monthYear] ?? 0) + t.amount;
            } else { // Assuming 'Expense' or 'Debit & Loan'
              totalExpense += t.amount;
              monthlyExpense[monthYear] = (monthlyExpense[monthYear] ?? 0) + t.amount;

              if (t.category != null) {
                categoryExpense[t.category!] = (categoryExpense[t.category!] ?? 0) + t.amount;
              }
            }
          }

          // Prepare data for BarChart
          final List<String> sortedMonths = monthlyIncome.keys.toSet().union(monthlyExpense.keys.toSet()).toList()
            ..sort((a, b) => DateFormat('MMM yyyy').parse(a).compareTo(DateFormat('MMM yyyy').parse(b)));

          final List<BarChartGroupData> barGroups = [];
          for (int i = 0; i < sortedMonths.length; i++) {
            final month = sortedMonths[i];
            final income = monthlyIncome[month] ?? 0.0;
            final expense = monthlyExpense[month] ?? 0.0;

            barGroups.add(
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: income,
                    color: incomeColor,
                    width: 8,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  BarChartRodData(
                    toY: expense,
                    color: expenseColor,
                    width: 8,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
                showingTooltipIndicators: [],
              ),
            );
          }


          // Prepare data for PieChart (Top 5 expenses + "Others")
          final sortedCategoryExpenses = categoryExpense.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final List<PieChartSectionData> pieSections = [];
          double otherExpenses = 0.0;
          int maxCategories = 5; // Show top 5 categories

          List<Color> pieColors = [
            Colors.purple, Colors.orange, Colors.teal, Colors.brown, Colors.indigo,
            Colors.blueGrey, Colors.lime, Colors.pinkAccent
          ]; // More colors if needed

          for (int i = 0; i < sortedCategoryExpenses.length; i++) {
            if (i < maxCategories) {
              pieSections.add(
                PieChartSectionData(
                  color: pieColors[i % pieColors.length],
                  value: sortedCategoryExpenses[i].value,
                  title: '${sortedCategoryExpenses[i].key}\n${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(sortedCategoryExpenses[i].value)}',
                  radius: 80,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  titlePositionPercentageOffset: 0.55,
                ),
              );
            } else {
              otherExpenses += sortedCategoryExpenses[i].value;
            }
          }

          if (otherExpenses > 0) {
            pieSections.add(
              PieChartSectionData(
                color: Colors.grey, // Color for "Others"
                value: otherExpenses,
                title: 'Others\n${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(otherExpenses)}',
                radius: 80,
                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                titlePositionPercentageOffset: 0.55,
              ),
            );
          }


          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall Summary Boxes
                SummaryBoxes(income: totalIncome, expense: totalExpense),
                const SizedBox(height: 20),

                // Monthly Income vs Expense Bar Chart
                Text(
                  'Monthly Trends',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      barGroups: barGroups,
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (monthlyIncome.values.followedBy(monthlyExpense.values).reduce((a, b) => a > b ? a : b)) * 1.2, // Max Y based on max income/expense
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < sortedMonths.length) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  space: 4,
                                  child: Text(
                                    sortedMonths[value.toInt()].split(' ')[0], // Show month abbreviation
                                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                            reservedSize: 30,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹').format(value),
                                style: const TextStyle(fontSize: 10, color: Colors.black54),
                              );
                            },
                            reservedSize: 40,
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(enabled: false), // Disable touch for simplicity
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Expense Categories Pie Chart
                Text(
                  'Expense Categories',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: pieSections,
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            pieTouchData: PieTouchData(enabled: false), // Disable touch for simplicity
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: pieSections.map((section) {
                          if (section.title.contains('\n')) {
                            final parts = section.title.split('\n');
                            return _buildLegendItem(section.color, parts[0], parts[1]);
                          }
                          return const SizedBox(); // Should not happen with current title format
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Recent Transactions List
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                // Re-using the TransactionsList widget from dashboard_screen for consistency
                // Filter to show only recent 5-10 transactions if needed, or all.
                // For now, let's show all, as it's a dedicated report screen.
                ListView.builder(
                  shrinkWrap: true, // Important to prevent unbounded height error inside SingleChildScrollView
                  physics: const NeverScrollableScrollPhysics(), // Important to disable inner scrolling
                  itemCount: transactions.length, // Display all
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    final isExpense = transaction.type == 'Expense' || transaction.type == 'Debit & Loan';
                    final iconColor = isExpense ? expenseColor : incomeColor; // Consistent colors
                    final amountColor = isExpense ? expenseColor : incomeColor;
                    final sign = isExpense ? '-' : '+';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                getCategoryIcon(transaction.category), // Use static helper
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
                                    transaction.category ?? transaction.type,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(transaction.date),
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$sign ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(transaction.amount)}',
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
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text, String amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
        const SizedBox(width: 4),
        Text(
          amount,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}

// Re-using SummaryBoxes and InfoBox for consistency in display
class SummaryBoxes extends StatelessWidget {
  final double income;
  final double expense;

  const SummaryBoxes({super.key, required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    return Row(
      children: [
        Expanded(
          child: InfoBox(
            title: "Total Income",
            amount: currencyFormatter.format(income),
            color: const Color(0xFFD9E6FE), // Consistent with dashboard
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InfoBox(
            title: "Total Expense",
            amount: currencyFormatter.format(expense),
            color: const Color(0xFFFFE2E2), // Consistent with dashboard
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
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 5),
          Text(amount, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Category icon mapping utility
final Map<String, IconData> _categoryIcons = {
  'Run': Icons.directions_run, 'Doctor': Icons.medical_services, 'Medicine': Icons.medication,
  'Exercise': Icons.fitness_center, 'Cycling': Icons.directions_bike, 'Swim': Icons.pool,
  'Grocery': Icons.local_grocery_store, 'Tea & Coffees': Icons.coffee, 'Drinks': Icons.local_bar,
  'Restaurants': Icons.restaurant, 'Phone Bill': Icons.phone_android, 'Water Bill': Icons.water_drop,
  'Gas Bill': Icons.local_fire_department, 'Internet Bill': Icons.wifi, 'Rentals': Icons.home_work,
  'TV Bill': Icons.tv, 'Electricity Bill': Icons.flash_on, 'Pets': Icons.pets, 'House': Icons.house,
  'Children': Icons.child_care, 'Gifts': Icons.card_giftcard, 'Marriage': Icons.people_alt,
  'Funeral': Icons.group_off, 'Charity': Icons.volunteer_activism, 'Clothings': Icons.checkroom,
  'Footwear': Icons.roller_skating, 'Gadgets': Icons.devices, 'Electronics': Icons.electrical_services,
  'Furniture': Icons.single_bed, 'Vehicles': Icons.directions_car, 'Accessories': Icons.headset,
  'default': Icons.category,
};

IconData getCategoryIcon(String? categoryName) {
  if (categoryName == null) return _categoryIcons['default']!;
  return _categoryIcons[categoryName] ?? _categoryIcons['default']!;
}