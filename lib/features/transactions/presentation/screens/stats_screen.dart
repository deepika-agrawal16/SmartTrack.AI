// features/reports/presentation/screens/stats_screen.dart
// ignore_for_file: unused_element, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:aifinanceapp/features/transactions/data/models/transaction_model.dart';
import 'package:aifinanceapp/features/transactions/presentation/providers/financial_data_providers.dart'; // To fetch transactions

// Re-using the category icon map (you might want to put this in a shared utility file)
extension on List<Transaction> {
  static final Map<String, IconData> _categoryIcons = {
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
}

// State provider for the selected category for the trend chart
final selectedCategoryForTrendProvider = StateProvider<String?>((ref) => null);

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsyncValue = ref.watch(userTransactionsProvider);
    final selectedCategory = ref.watch(selectedCategoryForTrendProvider);

    // Define consistent colors for the app
    const Color primaryColor = Color(0xFF3062CE);
    const Color incomeColor = Colors.green; // More vibrant green
    const Color expenseColor = Colors.red; // More vibrant red
    const Color cardBgColor = Colors.white;
    const Color chartGridColor = Colors.grey; // Subtle grey for grid lines

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Lighter background for the whole screen
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Your Financial Stats',
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      "No transactions yet! Add some to see your financial stats here.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          // --- Data Processing for Charts ---

          // Get the last 12 months for consistent chart display, ordered chronologically
          final List<String> last12MonthsFormatted = []; // e.g., 'Jan 24', 'Feb 24'
          final List<DateTime> last12MonthDates = [];
          // Calculate the first day of the current month
          DateTime now = DateTime.now();
          DateTime firstDayCurrentMonth = DateTime(now.year, now.month, 1);

          for (int i = 11; i >= 0; i--) {
            // Subtract 'i' months from the first day of the current month
            DateTime date = DateTime(firstDayCurrentMonth.year, firstDayCurrentMonth.month - i, 1);
            last12MonthDates.add(date);
          }
          // Sort these dates to ensure proper chronological order (already implicitly sorted by loop, but good practice)
          last12MonthDates.sort((a, b) => a.compareTo(b));

          // Now format them into strings for display and map keys
          for (DateTime date in last12MonthDates) {
            last12MonthsFormatted.add(DateFormat('MMM yy').format(date));
          }

          final Map<String, double> monthlyIncome = {};
          final Map<String, double> monthlyExpense = {};
          final Map<String, double> spendingByDayOfWeek = {
            'Mon': 0.0, 'Tue': 0.0, 'Wed': 0.0, 'Thu': 0.0, 'Fri': 0.0, 'Sat': 0.0, 'Sun': 0.0
          };
          final Set<String> uniqueExpenseCategories = {};

          double totalIncome = 0.0;
          double totalExpense = 0.0;

          for (var t in transactions) {
            final monthYearFormatted = DateFormat('MMM yy').format(t.date); // Use 'MMM yy' for consistency
            final dayOfWeek = DateFormat('EEE').format(t.date); // e.g., 'Mon', 'Tue'

            // Calculate total income/expense for summary (for all data)
            if (t.type == 'Income') {
              totalIncome += t.amount;
            } else {
              totalExpense += t.amount;
            }

            // For monthly trends (only include transactions within the last 12 months considered for the chart)
            if (last12MonthsFormatted.contains(monthYearFormatted)) {
              if (t.type == 'Income') {
                monthlyIncome[monthYearFormatted] = (monthlyIncome[monthYearFormatted] ?? 0) + t.amount;
              } else { // Expense or Debit & Loan
                monthlyExpense[monthYearFormatted] = (monthlyExpense[monthYearFormatted] ?? 0) + t.amount;
              }
            }

            // For spending by day of week (include all expense transactions)
            if (t.type != 'Income' && t.category != null) {
              uniqueExpenseCategories.add(t.category!);
              spendingByDayOfWeek[dayOfWeek] = (spendingByDayOfWeek[dayOfWeek] ?? 0) + t.amount;
            }
          }

          // Filter transactions for the selected category trend
          final Map<String, double> selectedCategoryMonthlySpending = {};
          if (selectedCategory != null && selectedCategory != 'All Categories') {
            for (var t in transactions) {
              if (t.type != 'Income' && t.category == selectedCategory && last12MonthsFormatted.contains(DateFormat('MMM yy').format(t.date))) {
                final monthYearFormatted = DateFormat('MMM yy').format(t.date);
                selectedCategoryMonthlySpending[monthYearFormatted] = (selectedCategoryMonthlySpending[monthYearFormatted] ?? 0) + t.amount;
              }
            }
          }

          // Determine max Y for charts
          double maxMonthlyValue = 0;
          if (monthlyIncome.values.isNotEmpty) maxMonthlyValue = monthlyIncome.values.reduce((a, b) => a > b ? a : b);
          if (monthlyExpense.values.isNotEmpty) maxMonthlyValue = monthlyExpense.values.fold(maxMonthlyValue, (prev, e) => e > prev ? e : prev);
          double chartMaxY = maxMonthlyValue > 0 ? maxMonthlyValue * 1.4 : 100.0; // Give more space above the lines, handle zero case

          // --- UI Building ---
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall Summary (re-using SummaryBoxes)
                SummaryBoxes(income: totalIncome, expense: totalExpense),
                const SizedBox(height: 20),

                // Monthly Financial Flow (Line Chart)
                _buildChartCard(
                  context,
                  title: 'Monthly Financial Flow (Last 12 Months)',
                  chart: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: chartMaxY, // Apply dynamic max Y
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: chartGridColor.withOpacity(0.2),
                          strokeWidth: 0.5,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final int index = value.toInt();
                              if (index >= 0 && index < last12MonthsFormatted.length) {
                                // Only show label for every second month
                                if (index % 2 == 0) { // Show labels for 0, 2, 4, 6, 8, 10
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    space: 15, // Increased space
                                    child: Text(
                                      last12MonthsFormatted[index], // Show full "MMM yy"
                                      style: const TextStyle(fontSize: 9, color: Colors.black54),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }
                              }
                              return const SizedBox(); // Hide other labels
                            },
                            reservedSize: 45, // More vertical space for labels
                            interval: 1.0, // FlChart calculates positions, we control which to show
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
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData( // Income Line
                          spots: last12MonthsFormatted.asMap().entries.map((entry) {
                            final int index = entry.key;
                            final String month = entry.value;
                            return FlSpot(index.toDouble(), monthlyIncome[month] ?? 0.0);
                          }).toList(),
                          isCurved: true,
                          color: incomeColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                        LineChartBarData( // Expense Line
                          spots: last12MonthsFormatted.asMap().entries.map((entry) {
                            final int index = entry.key;
                            final String month = entry.value;
                            return FlSpot(index.toDouble(), monthlyExpense[month] ?? 0.0);
                          }).toList(),
                          isCurved: true,
                          color: expenseColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      lineTouchData: const LineTouchData(enabled: false), // Disable touch for simplicity
                    ),
                  ),
                  legend: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendIndicator(incomeColor, 'Income'),
                      const SizedBox(width: 16),
                      _buildLegendIndicator(expenseColor, 'Expense'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Spending by Category Over Time (Dynamic Chart based on dropdown)
                _buildChartCard(
                  context,
                  title: 'Spending Trend by Category',
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedCategory ?? (uniqueExpenseCategories.isNotEmpty ? uniqueExpenseCategories.first : null),
                        hint: const Text('Select a Category'),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        isExpanded: true,
                        items: ['All Categories', ...uniqueExpenseCategories.toList()..sort()] // Sort categories
                            .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        )).toList(),
                        onChanged: (newValue) {
                          ref.read(selectedCategoryForTrendProvider.notifier).state = newValue;
                        },
                      ),
                      const SizedBox(height: 16), // Increased spacing
                      SizedBox(
                        height: 200, // Fixed height for the chart
                        child: selectedCategory == null || selectedCategory == 'All Categories'
                            ? Center(
                                child: Text(
                                  'Select a specific category from the dropdown above to see its spending trend over time.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                              )
                            : LineChart(
                                LineChartData(
                                  minY: 0,
                                  maxY: (selectedCategoryMonthlySpending.values.isNotEmpty ? selectedCategoryMonthlySpending.values.reduce((a, b) => a > b ? a : b) : 100) * 1.4,
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (value) => FlLine(
                                      color: chartGridColor.withOpacity(0.2),
                                      strokeWidth: 0.5,
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final int index = value.toInt();
                                          if (index >= 0 && index < last12MonthsFormatted.length) {
                                            // Only show label for every second month
                                            if (index % 2 == 0) {
                                              return SideTitleWidget(
                                                axisSide: meta.axisSide,
                                                space: 15, // Increased space
                                                child: Text(
                                                  last12MonthsFormatted[index],
                                                  style: const TextStyle(fontSize: 9, color: Colors.black54),
                                                  textAlign: TextAlign.center,
                                                ),
                                              );
                                            }
                                          }
                                          return const SizedBox();
                                        },
                                        reservedSize: 45, // More vertical space
                                        interval: 1.0,
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
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: last12MonthsFormatted.asMap().entries.map((entry) {
                                        final int index = entry.key;
                                        final String month = entry.value;
                                        return FlSpot(index.toDouble(), selectedCategoryMonthlySpending[month] ?? 0.0);
                                      }).toList(),
                                      isCurved: true,
                                      color: primaryColor,
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(show: false),
                                    ),
                                  ],
                                  lineTouchData: const LineTouchData(enabled: false),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Spending Distribution by Day of Week (Bar Chart)
                _buildChartCard(
                  context,
                  title: 'Spending Distribution by Day of Week',
                  chart: BarChart(
                    BarChartData(
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: spendingByDayOfWeek['Mon'] ?? 0, color: primaryColor, width: 14, borderRadius: BorderRadius.circular(4))]),
                        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: spendingByDayOfWeek['Tue'] ?? 0, color: primaryColor, width: 14, borderRadius: BorderRadius.circular(4))]),
                        BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: spendingByDayOfWeek['Wed'] ?? 0, color: primaryColor, width: 14, borderRadius: BorderRadius.circular(4))]),
                        BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: spendingByDayOfWeek['Thu'] ?? 0, color: primaryColor, width: 14, borderRadius: BorderRadius.circular(4))]),
                        BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: spendingByDayOfWeek['Fri'] ?? 0, color: primaryColor, width: 14, borderRadius: BorderRadius.circular(4))]),
                        BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: spendingByDayOfWeek['Sat'] ?? 0, color: primaryColor, width: 14, borderRadius: BorderRadius.circular(4))]),
                        BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: spendingByDayOfWeek['Sun'] ?? 0, color: primaryColor, width: 14, borderRadius: BorderRadius.circular(4))]),
                      ],
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (spendingByDayOfWeek.values.isNotEmpty ? spendingByDayOfWeek.values.reduce((a, b) => a > b ? a : b) : 100) * 1.3, // Adjusted max Y
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: chartGridColor.withOpacity(0.2),
                          strokeWidth: 0.5,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 4,
                                child: Text(days[value.toInt()], style: const TextStyle(fontSize: 10, color: Colors.black54)),
                              );
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
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(enabled: false),
                    ),
                  ),
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

  // Helper method to build a consistent chart card
  Widget _buildChartCard(BuildContext context, {required String title, Widget? chart, Widget? child, Widget? legend}) {
    const Color cardBgColor = Colors.white; // Define the card background color locally
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor, // Consistent card background
        borderRadius: BorderRadius.circular(16), // More rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15), // Slightly more pronounced shadow
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4), // Deeper shadow
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87, // Slightly darker text for titles
              ),
            ),
          if (title.isNotEmpty) const SizedBox(height: 16), // Increased spacing below title
          if (chart != null) SizedBox(height: 200, child: chart), // Fixed height for charts
          if (child != null) child, // For cases like the dropdown + chart combo
          if (legend != null) ...[
            const SizedBox(height: 16), // Increased spacing above legend
            legend,
          ],
        ],
      ),
    );
  }

  // Helper for chart legend indicators
  Widget _buildLegendIndicator(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12, // Slightly larger indicator
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6), // Increased spacing
        Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)), // Slightly larger text
      ],
    );
  }
}

// Re-using SummaryBoxes and InfoBox from dashboard_screen for consistency
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

// ignore_for_file: unused_element_parameter

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 5),
          Text(amount, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }
}
