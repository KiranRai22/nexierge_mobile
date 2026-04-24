import '../../expense_entry/repositories/expense_repository.dart';
import '../../budgets/repositories/budget_repository.dart';
import '../../expense_entry/models/expense_model.dart';
import '../../budgets/models/budget_model.dart';

class ReportRepository {
  final ExpenseRepository _expenseRepo = ExpenseRepository();
  final BudgetRepository _budgetRepo = BudgetRepository();

  Future<List<Expense>> getAllExpenses() async {
    return await _expenseRepo.getAllExpenses();
  }

  Future<Map<String, double>> getExpensesByCategory() async {
    final expenses = await _expenseRepo.getAllExpenses();
    final Map<String, double> categoryTotals = {};

    for (final expense in expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    return categoryTotals;
  }

  Future<double> getTotalExpenses() async {
    final expenses = await _expenseRepo.getAllExpenses();
    double total = 0.0;
    for (final expense in expenses) {
      total += expense.amount;
    }
    return total;
  }

  Future<List<Budget>> getBudgetsWithProgress() async {
    final budgets = await _budgetRepo.getAllBudgets();
    final expenses = await _expenseRepo.getAllExpenses();

    return budgets.map((budget) {
      final spent = expenses
          .where((e) => e.category.toLowerCase() == budget.category.toLowerCase())
          .fold(0.0, (sum, e) => sum + e.amount);
      return budget.copyWith(spent: spent);
    }).toList();
  }
}