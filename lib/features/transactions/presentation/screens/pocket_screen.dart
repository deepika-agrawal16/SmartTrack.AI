import 'package:aifinanceapp/features/transactions/presentation/providers/financial_data_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class PocketScreen extends ConsumerWidget {
  const PocketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsyncValue = ref.watch(filteredTransactionsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Report'),
        centerTitle: true,
      ),
      body: transactionsAsyncValue.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(child: Text("No transactions to display"));
          }

          // Process data
          double totalExpense = 0.0;
          final Map<String, double> categoryExpense = {};

          for (var t in transactions) {
            if (t.type.toLowerCase() == 'expense' || t.type.toLowerCase() == 'debit & loan') {
              totalExpense += t.amount;
              if (t.category != null) {
                categoryExpense[t.category!] = (categoryExpense[t.category!] ?? 0) + t.amount;
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Expense Categories Pie Chart - Improved version
                _buildExpensePieChart(totalExpense, categoryExpense),
                const SizedBox(height: 20),
                
                // Category breakdown list
                _buildCategoryList(categoryExpense, totalExpense),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildExpensePieChart(double totalExpense, Map<String, double> categoryExpense) {
    // Sort categories by amount descending
    final sortedCategories = categoryExpense.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Group small expenses into "Others"
    const int maxMainCategories = 5; // Show top 5 categories explicitly
    const double minPercentage = 5.0; // Minimum percentage to show separately
    double othersAmount = 0.0;
    
    // Prepare pie sections
    final List<PieChartSectionData> pieSections = [];
    final List<Color> pieColors = [
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.redAccent,
      Colors.tealAccent,
    ];

    for (int i = 0; i < sortedCategories.length; i++) {
      final entry = sortedCategories[i];
      final percentage = (entry.value / totalExpense) * 100;
      
      if (i < maxMainCategories && percentage >= minPercentage) {
        pieSections.add(
          PieChartSectionData(
            color: pieColors[i % pieColors.length],
            value: entry.value,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 60, // Smaller radius for compact size
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      } else {
        othersAmount += entry.value;
      }
    }

    // Add "Others" section if needed
    if (othersAmount > 0) {
      final othersPercentage = (othersAmount / totalExpense) * 100;
      pieSections.add(
        PieChartSectionData(
          color: Colors.grey,
          value: othersAmount,
          title: '${othersPercentage.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Expense Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200, // Compact size
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: pieSections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(totalExpense),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildPieChartLegend(pieSections, sortedCategories),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartLegend(List<PieChartSectionData> sections, List<MapEntry<String, double>> categories) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: sections.asMap().entries.map((entry) {
        final index = entry.key;
        final section = entry.value;
        String label;
        
        // For the "Others" section (last one)
        if (index == sections.length - 1 && index >= 5) {
          label = 'Others';
        } else {
          label = categories[index].key;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: section.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCategoryList(Map<String, double> categoryExpense, double totalExpense) {
    final sortedCategories = categoryExpense.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...sortedCategories.map((entry) {
              final percentage = (entry.value / totalExpense) * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(entry.value),
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}