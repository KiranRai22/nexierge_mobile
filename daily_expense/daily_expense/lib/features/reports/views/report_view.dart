import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:fl_chart/fl_chart.dart';
import '../viewmodels/report_viewmodel.dart';

class ReportView extends StatelessWidget {
  const ReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ReportViewModel>.reactive(
      viewModelBuilder: () => ReportViewModel(),
      onViewModelReady: (viewModel) => viewModel.loadReports(),
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Reports'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: viewModel.loadReports,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Filter by Category:'),
                    DropdownButton<String>(
                      value: viewModel.selectedCategory ?? 'All',
                      items: ['All', ...viewModel.availableCategories].map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: viewModel.setSelectedCategory,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Start Date:'),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: viewModel.startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          viewModel.setDateRange(picked, viewModel.endDate);
                        }
                      },
                      child: Text(viewModel.startDate?.toString().split(' ')[0] ?? 'Select'),
                    ),
                    const SizedBox(width: 20),
                    const Text('End Date:'),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: viewModel.endDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          viewModel.setDateRange(viewModel.startDate, picked);
                        }
                      },
                      child: Text(viewModel.endDate?.toString().split(' ')[0] ?? 'Select'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Total Expenses: \$${viewModel.totalExpenses.toStringAsFixed(2)}'),
                const SizedBox(height: 20),
                const Text('Expenses by Category'),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 40,
                      sections: viewModel.expensesByCategory.entries.map((entry) {
                        return PieChartSectionData(
                          value: entry.value,
                          title: '${entry.key}\n\$${entry.value.toStringAsFixed(2)}',
                          color: Colors.primaries[viewModel.expensesByCategory.keys.toList().indexOf(entry.key) % Colors.primaries.length],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Budget Progress'),
                ...viewModel.budgetsWithProgress.map((budget) {
                  return ListTile(
                    title: Text(budget['category']),
                    subtitle: Text('Spent: \$${budget['spent'].toStringAsFixed(2)} / \$${budget['limit'].toStringAsFixed(2)}'),
                    trailing: CircularProgressIndicator(
                      value: budget['progress'],
                    ),
                  );
                }),
                const SizedBox(height: 20),
                const Text('Expense List'),
                ...viewModel.filteredExpenses.map((expense) {
                  return ListTile(
                    title: Text('${expense.category} - \$${expense.amount.toStringAsFixed(2)}'),
                    subtitle: Text('Date: ${expense.date}'),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}