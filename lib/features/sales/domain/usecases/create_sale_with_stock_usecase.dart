import 'package:controlzukis/features/sales/domain/models/create_sale_input.dart';
import 'package:controlzukis/features/sales/domain/repositories/sales_repository.dart';

class CreateSaleWithStockUseCase {
  const CreateSaleWithStockUseCase(this._repository);

  final SalesRepository _repository;

  Future<void> call(CreateSaleInput input) {
    return _repository.createSaleWithStock(input);
  }
}
