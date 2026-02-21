import 'package:controlzukis/features/products/domain/models/product_input.dart';
import 'package:controlzukis/features/products/domain/repositories/products_repository.dart';

class CreateProductUseCase {
  const CreateProductUseCase(this._repository);

  final ProductsRepository _repository;

  Future<void> call(ProductInput input) => _repository.create(input);
}
