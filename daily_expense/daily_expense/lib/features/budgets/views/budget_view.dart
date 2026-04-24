import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import '../viewmodels/budget_viewmodel.dart';

class BudgetView extends StatelessWidget {
  const BudgetView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<BudgetViewModel>.reactive(
      viewModelBuilder: () => BudgetViewModel(),
      onViewModelReady: (viewModel) => viewModel.loadBudgets(),
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Budgets')),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: viewModel.budgets.length,
                  itemBuilder: (context, index) {
                    final budget = viewModel.budgets[index];
                    return ListTile(
                      title: Text('${budget.category}: \$${budget.limit}'),
                      subtitle: Text('Spent: \$${budget.spent}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => viewModel.deleteBudget(budget.id),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => _showAddBudgetDialog(context, viewModel),
                  child: const Text('Add Budget'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddBudgetDialog(BuildContext context, BudgetViewModel viewModel) {
    final categoryController = TextEditingController();
    final limitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: limitController,
                decoration: const InputDecoration(labelText: 'Limit'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final category = categoryController.text;
                final limit = double.tryParse(limitController.text) ?? 0.0;
                viewModel.addBudget(category, limit);
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}