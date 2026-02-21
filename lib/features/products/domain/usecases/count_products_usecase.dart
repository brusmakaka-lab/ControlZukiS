import 'package:controlzukis/features/products/domain/repositories/products_repository.dart';

class CountProductsUseCase {
  const CountProductsUseCase(this._repository);

  final ProductsRepository _repository;

  Future<int> call({String? search, String? categoryId}) {
    return _repository.count(search: search, categoryId: categoryId);
  }
}
