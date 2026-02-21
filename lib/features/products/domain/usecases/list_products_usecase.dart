import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/features/products/domain/repositories/products_repository.dart';

class ListProductsUseCase {
  const ListProductsUseCase(this._repository);

  final ProductsRepository _repository;

  Future<List<Product>> call({
    required int limit,
    required int offset,
    String? search,
    String? categoryId,
  }) {
    return _repository.list(
      limit: limit,
      offset: offset,
      search: search,
      categoryId: categoryId,
    );
  }
}
