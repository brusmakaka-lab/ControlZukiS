import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/providers/core_providers.dart';
import 'package:controlzukis/core/providers/guard_providers.dart';
import 'package:controlzukis/features/expenses/data/expenses_repository_impl.dart';
import 'package:controlzukis/features/expenses/domain/models/expense_input.dart';
import 'package:controlzukis/features/expenses/domain/repositories/expenses_repository.dart';
import 'package:controlzukis/features/expenses/domain/usecases/create_expense_or_purchase_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  return ExpensesRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    writeAccess: ref.watch(writeAccessServiceProvider),
  );
});

final createExpenseOrPurchaseUseCaseProvider =
    Provider<CreateExpenseOrPurchaseUseCase>(
      (ref) =>
          CreateExpenseOrPurchaseUseCase(ref.watch(expensesRepositoryProvider)),
    );

class ExpensesPageState {
  const ExpensesPageState({required this.total, required this.items});
  final int total;
  final List<Expense> items;
}

class ExpensesController {
  const ExpensesController(this._ref);

  final Ref _ref;

  Future<ExpensesPageState> fetch({
    required int page,
    required int pageSize,
  }) async {
    final offset = page * pageSize;
    final repo = _ref.read(expensesRepositoryProvider);
    final total = await repo.count();
    final items = await repo.list(limit: pageSize, offset: offset);
    return ExpensesPageState(total: total, items: items);
  }

  Future<List<Product>> listProducts({String? search}) {
    return _ref.read(expensesRepositoryProvider).listProducts(search: search);
  }

  Future<void> create(ExpenseInput input) {
    return _ref.read(createExpenseOrPurchaseUseCaseProvider)(input);
  }
}

final expensesControllerProvider = Provider<ExpensesController>(
  ExpensesController.new,
);
