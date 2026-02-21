import 'package:controlzukis/core/providers/core_providers.dart';
import 'package:controlzukis/core/providers/guard_providers.dart';
import 'package:controlzukis/features/categories/data/categories_repository_impl.dart';
import 'package:controlzukis/features/categories/domain/models/category_input.dart';
import 'package:controlzukis/features/categories/domain/repositories/categories_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:controlzukis/core/database/app_database.dart';

class CategoriesPageState {
  const CategoriesPageState({required this.items, required this.total});

  final List<Category> items;
  final int total;
}

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    writeAccess: ref.watch(writeAccessServiceProvider),
  );
});

class CategoriesController {
  const CategoriesController(this._ref);

  final Ref _ref;

  Future<CategoriesPageState> fetch({
    required int page,
    required int pageSize,
    String? search,
  }) async {
    final repo = _ref.read(categoriesRepositoryProvider);
    final offset = page * pageSize;
    final items = await repo.list(
      limit: pageSize,
      offset: offset,
      search: search,
    );
    final total = await repo.count(search: search);
    return CategoriesPageState(items: items, total: total);
  }

  Future<void> create(CategoryInput input) =>
      _ref.read(categoriesRepositoryProvider).create(input);

  Future<void> update(String id, CategoryInput input) =>
      _ref.read(categoriesRepositoryProvider).update(id, input);

  Future<void> delete(String id) =>
      _ref.read(categoriesRepositoryProvider).delete(id);
}

final categoriesControllerProvider = Provider<CategoriesController>(
  CategoriesController.new,
);
