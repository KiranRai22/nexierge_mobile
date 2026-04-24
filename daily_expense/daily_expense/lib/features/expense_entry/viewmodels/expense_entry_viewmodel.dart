import 'package:stacked/stacked.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';
import 'package:uuid/uuid.dart';

class ExpenseEntryViewModel extends BaseViewModel {
  final ExpenseRepository _expenseRepo = ExpenseRepository();
  final Uuid _uuid = Uuid();

  List<Expense> _expenses = [];
  List<Expense> get expenses => _expenses;

  Future<void> loadExpenses() async {
    setBusy(true);
    _expenses = await _expenseRepo.getAllExpenses();
    setBusy(false);
    notifyListeners();
  }

  Future<void> addExpense(double amount, String category, DateTime date, String notes) async {
    final expense = Expense(
      id: _uuid.v4(),
      amount: amount,
      category: category,
      date: date,
      notes: notes,
    );
    await _expenseRepo.addExpense(expense);
    await loadExpenses();
  }

  Future<void> updateExpense(Expense expense) async {
    await _expenseRepo.updateExpense(expense);
    await loadExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await _expenseRepo.deleteExpense(id);
    await loadExpenses();
  }
}