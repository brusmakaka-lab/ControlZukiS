import 'package:controlzukis/features/products/domain/models/product_input.dart';
import 'package:controlzukis/features/products/domain/repositories/products_repository.dart';

class UpdateProductUseCase {
  const UpdateProductUseCase(this._repository);

  final ProductsRepository _repository;

  Future<void> call(String productId, ProductInput input) =>
      _repository.update(productId, input);
}
