import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/features/products/domain/models/product_input.dart';

abstract class ProductsRepository {
  Future<List<Product>> list({
    required int limit,
    required int offset,
    String? search,
    String? categoryId,
  });

  Future<int> count({String? search, String? categoryId});

  Future<void> create(ProductInput input);
  Future<void> update(String productId, ProductInput input);
  Future<void> delete(String productId);

  Future<List<ProductCustomFieldDefinition>> listCustomFieldDefinitions();
  Future<List<ProductCustomFieldValue>> listCustomFieldValues(String productId);
  Future<void> createCustomFieldDefinition({
    required String key,
    required String label,
    required String type,
    required bool required,
    String? optionsJson,
  });

  Future<List<ProductImage>> listImages(String productId);
  Future<void> addImage({
    required String productId,
    required String sourcePath,
  });
  Future<void> setPrimaryImage({
    required String productId,
    required String imageId,
  });
  Future<void> deleteImage({required String imageId});
}
