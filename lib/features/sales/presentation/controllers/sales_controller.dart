import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/providers/core_providers.dart';
import 'package:controlzukis/core/providers/guard_providers.dart';
import 'package:controlzukis/features/sales/data/sales_repository_impl.dart';
import 'package:controlzukis/features/sales/domain/models/create_sale_input.dart';
import 'package:controlzukis/features/sales/domain/repositories/sales_repository.dart';
import 'package:controlzukis/features/sales/domain/usecases/create_sale_with_stock_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    writeAccess: ref.watch(writeAccessServiceProvider),
  );
});

final createSaleWithStockUseCaseProvider = Provider<CreateSaleWithStockUseCase>(
  (ref) => CreateSaleWithStockUseCase(ref.watch(salesRepositoryProvider)),
);

class SalesController {
  const SalesController(this._ref);

  final Ref _ref;

  Future<List<Product>> listProducts({String? search}) {
    return _ref.read(salesRepositoryProvider).listProducts(search: search);
  }

  Future<void> createSaleWithStock(CreateSaleInput input) {
    return _ref.read(createSaleWithStockUseCaseProvider)(input);
  }
}

final salesControllerProvider = Provider<SalesController>(SalesController.new);
