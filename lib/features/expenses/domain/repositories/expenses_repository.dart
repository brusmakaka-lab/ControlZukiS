import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/features/expenses/domain/models/expense_input.dart';

abstract class ExpensesRepository {
  Future<List<Expense>> list({required int limit, required int offset});
  Future<int> count();
  Future<List<Product>> listProducts({String? search});
  Future<void> createExpenseOrPurchase(ExpenseInput input);
}
