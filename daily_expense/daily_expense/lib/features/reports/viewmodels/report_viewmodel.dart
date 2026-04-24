import 'package:stacked/stacked.dart';
import '../../expense_entry/models/expense_model.dart';
import '../repositories/report_repository.dart';

class ReportViewModel extends BaseViewModel {
  final ReportRepository _reportRepo = ReportRepository();

  Map<String, double> _expensesByCategory = {};
  Map<String, double> get expensesByCategory => _expensesByCategory;

  double _totalExpenses = 0.0;
  double get totalExpenses => _totalExpenses;

  List<Map<String, dynamic>> _budgetsWithProgress = [];
  List<Map<String, dynamic>> get budgetsWithProgress => _budgetsWithProgress;

  List<Expense> _filteredExpenses = [];
  List<Expense> get filteredExpenses => _filteredExpenses;

  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  List<String> _allCategories = [];
  List<String> get availableCategories => _allCategories;

  DateTime? _startDate;
  DateTime? get startDate => _startDate;

  DateTime? _endDate;
  DateTime? get endDate => _endDate;

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    _filterData();
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    loadReports();
  }

  Future<void> loadReports() async {
    setBusy(true);
    final allExpenses = await _reportRepo.getAllExpenses();
    _allCategories = allExpenses.map((e) => e.category).toSet().toList();
    _filteredExpenses = _filterExpensesByDate(allExpenses);

    _expensesByCategory = _calculateExpensesByCategory(_filteredExpenses);
    _totalExpenses = _filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);

    final budgets = await _reportRepo.getBudgetsWithProgress();
    _budgetsWithProgress = budgets.map((b) => {
      'category': b.category,
      'limit': b.limit,
      'spent': b.spent,
      'progress': b.limit > 0 ? b.spent / b.limit : 0.0,
    }).toList();

    _filterData();
    setBusy(false);
    notifyListeners();
  }

  List<Expense> _filterExpensesByDate(List<Expense> expenses) {
    if (_startDate == null && _endDate == null) return expenses;
    return expenses.where((e) {
      final expenseDate = e.date;
      if (_startDate != null && expenseDate.isBefore(_startDate!)) return false;
      if (_endDate != null && expenseDate.isAfter(_endDate!)) return false;
      return true;
    }).toList();
  }

  Map<String, double> _calculateExpensesByCategory(List<Expense> expenses) {
    final map = <String, double>{};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  void _filterData() {
    if (_selectedCategory == null || _selectedCategory == 'All') {
      // No category filter
    } else {
      _expensesByCategory = {_selectedCategory!: _expensesByCategory[_selectedCategory!] ?? 0.0};
      _budgetsWithProgress = _budgetsWithProgress.where((b) => b['category'].toLowerCase() == _selectedCategory!.toLowerCase()).toList();
      _filteredExpenses = _filteredExpenses.where((e) => e.category.toLowerCase() == _selectedCategory!.toLowerCase()).toList();
      _totalExpenses = _filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
    }
  }
}