import '../../../core/services/database_service.dart';
import '../models/budget_model.dart';
import '../../expense_entry/repositories/expense_repository.dart';

class BudgetRepository {
  final _dbService = DatabaseService.instance;
  final _expenseRepo = ExpenseRepository();

  Future<List<Budget>> getAllBudgets() async {
    final db = await _dbService.database;
    final result = await db.query('budgets', orderBy: 'category ASC');
    final budgets = result.map((map) => Budget.fromMap(map)).toList();
    final expenses = await _expenseRepo.getAllExpenses();

    return budgets.map((budget) {
      final spent = expenses
          .where((expense) => expense.category.toLowerCase() == budget.category.toLowerCase())
          .fold(0.0, (sum, expense) => sum + expense.amount);
      return budget.copyWith(spent: spent);
    }).toList();
  }

  Future<void> addBudget(Budget budget) async {
    final db = await _dbService.database;
    await db.insert('budgets', budget.toMap());
  }

  Future<void> updateBudget(Budget budget) async {
    final db = await _dbService.database;
    await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<void> deleteBudget(String id) async {
    final db = await _dbService.database;
    await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Budget?> getBudgetById(String id) async {
    final db = await _dbService.database;
    final result = await db.query(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) {
      return null;
    }

    final budget = Budget.fromMap(result.first);
    final expenses = await _expenseRepo.getAllExpenses();
    final spent = expenses
        .where((expense) => expense.category == budget.category)
        .fold(0.0, (sum, expense) => sum + expense.amount);
    return budget.copyWith(spent: spent);
  }
}
