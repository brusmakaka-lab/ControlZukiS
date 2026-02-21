import 'package:controlzukis/features/expenses/domain/models/expense_input.dart';
import 'package:controlzukis/features/expenses/domain/repositories/expenses_repository.dart';

class CreateExpenseOrPurchaseUseCase {
  const CreateExpenseOrPurchaseUseCase(this._repository);

  final ExpensesRepository _repository;

  Future<void> call(ExpenseInput input) {
    return _repository.createExpenseOrPurchase(input);
  }
}
