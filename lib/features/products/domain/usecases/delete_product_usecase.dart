import 'package:controlzukis/features/products/domain/repositories/products_repository.dart';

class DeleteProductUseCase {
  const DeleteProductUseCase(this._repository);

  final ProductsRepository _repository;

  Future<void> call(String productId) => _repository.delete(productId);
}
