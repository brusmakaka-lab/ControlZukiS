import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/providers/core_providers.dart';
import 'package:controlzukis/core/providers/guard_providers.dart';
import 'package:controlzukis/features/products/data/products_repository_impl.dart';
import 'package:controlzukis/features/products/domain/models/product_input.dart';
import 'package:controlzukis/features/products/domain/repositories/products_repository.dart';
import 'package:controlzukis/features/products/domain/usecases/count_products_usecase.dart';
import 'package:controlzukis/features/products/domain/usecases/create_product_usecase.dart';
import 'package:controlzukis/features/products/domain/usecases/delete_product_usecase.dart';
import 'package:controlzukis/features/products/domain/usecases/list_products_usecase.dart';
import 'package:controlzukis/features/products/domain/usecases/update_product_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    writeAccess: ref.watch(writeAccessServiceProvider),
  );
});

final listProductsUseCaseProvider = Provider<ListProductsUseCase>(
  (ref) => ListProductsUseCase(ref.watch(productsRepositoryProvider)),
);
final countProductsUseCaseProvider = Provider<CountProductsUseCase>(
  (ref) => CountProductsUseCase(ref.watch(productsRepositoryProvider)),
);
final createProductUseCaseProvider = Provider<CreateProductUseCase>(
  (ref) => CreateProductUseCase(ref.watch(productsRepositoryProvider)),
);
final updateProductUseCaseProvider = Provider<UpdateProductUseCase>(
  (ref) => UpdateProductUseCase(ref.watch(productsRepositoryProvider)),
);
final deleteProductUseCaseProvider = Provider<DeleteProductUseCase>(
  (ref) => DeleteProductUseCase(ref.watch(productsRepositoryProvider)),
);

class ProductsPageState {
  const ProductsPageState({required this.total, required this.items});
  final int total;
  final List<Product> items;
}

class ProductsController {
  ProductsController(this._ref);

  final Ref _ref;

  Future<ProductsPageState> fetch({
    required int page,
    required int pageSize,
    String? search,
    String? categoryId,
  }) async {
    final offset = page * pageSize;
    final listUseCase = _ref.read(listProductsUseCaseProvider);
    final countUseCase = _ref.read(countProductsUseCaseProvider);
    final total = await countUseCase(search: search, categoryId: categoryId);
    final items = await listUseCase(
      limit: pageSize,
      offset: offset,
      search: search,
      categoryId: categoryId,
    );
    return ProductsPageState(total: total, items: items);
  }

  Future<void> create(ProductInput input) =>
      _ref.read(createProductUseCaseProvider)(input);
  Future<void> update(String id, ProductInput input) =>
      _ref.read(updateProductUseCaseProvider)(id, input);
  Future<void> delete(String id) => _ref.read(deleteProductUseCaseProvider)(id);

  Future<List<ProductImage>> listImages(String productId) {
    return _ref.read(productsRepositoryProvider).listImages(productId);
  }

  Future<void> addImage({
    required String productId,
    required String sourcePath,
  }) {
    return _ref
        .read(productsRepositoryProvider)
        .addImage(productId: productId, sourcePath: sourcePath);
  }

  Future<void> setPrimaryImage({
    required String productId,
    required String imageId,
  }) {
    return _ref
        .read(productsRepositoryProvider)
        .setPrimaryImage(productId: productId, imageId: imageId);
  }

  Future<void> deleteImage({required String imageId}) {
    return _ref.read(productsRepositoryProvider).deleteImage(imageId: imageId);
  }

  Future<List<ProductCustomFieldDefinition>> listCustomFieldDefinitions() {
    return _ref.read(productsRepositoryProvider).listCustomFieldDefinitions();
  }

  Future<List<ProductCustomFieldValue>> listCustomFieldValues(
    String productId,
  ) {
    return _ref
        .read(productsRepositoryProvider)
        .listCustomFieldValues(productId);
  }

  Future<void> createCustomFieldDefinition({
    required String key,
    required String label,
    required String type,
    required bool required,
    String? optionsJson,
  }) {
    return _ref
        .read(productsRepositoryProvider)
        .createCustomFieldDefinition(
          key: key,
          label: label,
          type: type,
          required: required,
          optionsJson: optionsJson,
        );
  }
}

final productsControllerProvider = Provider<ProductsController>(
  ProductsController.new,
);
