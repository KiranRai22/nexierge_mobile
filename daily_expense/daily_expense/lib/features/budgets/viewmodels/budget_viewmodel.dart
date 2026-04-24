import 'package:stacked/stacked.dart';
import '../models/budget_model.dart';
import '../repositories/budget_repository.dart';
import 'package:uuid/uuid.dart';

class BudgetViewModel extends BaseViewModel {
  final BudgetRepository _budgetRepo = BudgetRepository();
  final Uuid _uuid = Uuid();

  List<Budget> _budgets = [];
  List<Budget> get budgets => _budgets;

  Future<void> loadBudgets() async {
    setBusy(true);
    _budgets = await _budgetRepo.getAllBudgets();
    setBusy(false);
    notifyListeners();
  }

  Future<void> addBudget(String category, double limit) async {
    final budget = Budget(
      id: _uuid.v4(),
      category: category,
      limit: limit,
    );
    await _budgetRepo.addBudget(budget);
    await loadBudgets();
  }

  Future<void> updateBudget(Budget budget) async {
    await _budgetRepo.updateBudget(budget);
    await loadBudgets();
  }

  Future<void> deleteBudget(String id) async {
    await _budgetRepo.deleteBudget(id);
    await loadBudgets();
  }
}