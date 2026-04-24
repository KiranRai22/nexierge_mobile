import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import '../viewmodels/expense_entry_viewmodel.dart';

class ExpenseEntryView extends StatelessWidget {
  const ExpenseEntryView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ExpenseEntryViewModel>.reactive(
      viewModelBuilder: () => ExpenseEntryViewModel(),
      onViewModelReady: (viewModel) => viewModel.loadExpenses(),
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Expense Entry')),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: viewModel.expenses.length,
                  itemBuilder: (context, index) {
                    final expense = viewModel.expenses[index];
                    return ListTile(
                      title: Text('${expense.category}: \$${expense.amount}'),
                      subtitle: Text(expense.date.toString()),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => viewModel.deleteExpense(expense.id),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => _showAddExpenseDialog(context, viewModel),
                  child: const Text('Add Expense'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddExpenseDialog(BuildContext context, ExpenseEntryViewModel viewModel) {
    final amountController = TextEditingController();
    final categoryController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) selectedDate = picked;
                },
                child: const Text('Select Date'),
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
                final amount = double.tryParse(amountController.text) ?? 0.0;
                final category = categoryController.text;
                final notes = notesController.text;
                viewModel.addExpense(amount, category, selectedDate, notes);
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