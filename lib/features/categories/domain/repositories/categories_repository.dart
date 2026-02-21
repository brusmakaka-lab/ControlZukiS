import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/features/categories/domain/models/category_input.dart';

abstract class CategoriesRepository {
  Future<List<Category>> list({
    required int limit,
    required int offset,
    String? search,
  });
  Future<int> count({String? search});
  Future<void> create(CategoryInput input);
  Future<void> update(String id, CategoryInput input);
  Future<void> delete(String id);
}
