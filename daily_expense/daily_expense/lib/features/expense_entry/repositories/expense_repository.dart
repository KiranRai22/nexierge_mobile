import '../../../core/services/database_service.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  final _dbService = DatabaseService.instance;

  Future<List<Expense>> getAllExpenses() async {
    final db = await _dbService.database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<void> addExpense(Expense expense) async {
    final db = await _dbService.database;
    await db.insert('expenses', expense.toMap());
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await _dbService.database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(String id) async {
    final db = await _dbService.database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Expense?> getExpenseById(String id) async {
    final db = await _dbService.database;
    final result = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) {
      return null;
    }
    return Expense.fromMap(result.first);
  }
}
