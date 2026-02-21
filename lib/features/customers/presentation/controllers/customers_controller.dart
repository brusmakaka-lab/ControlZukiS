import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/providers/core_providers.dart';
import 'package:controlzukis/core/providers/guard_providers.dart';
import 'package:controlzukis/features/customers/data/customers_repository_impl.dart';
import 'package:controlzukis/features/customers/domain/models/customer_input.dart';
import 'package:controlzukis/features/customers/domain/repositories/customers_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    writeAccess: ref.watch(writeAccessServiceProvider),
  );
});

class CustomersPageState {
  const CustomersPageState({required this.total, required this.items});
  final int total;
  final List<Customer> items;
}

class CustomersController {
  const CustomersController(this._ref);

  final Ref _ref;

  Future<CustomersPageState> fetch({
    required int page,
    required int pageSize,
    String? search,
  }) async {
    final offset = page * pageSize;
    final repo = _ref.read(customersRepositoryProvider);
    final total = await repo.count(search: search);
    final items = await repo.list(
      limit: pageSize,
      offset: offset,
      search: search,
    );
    return CustomersPageState(total: total, items: items);
  }

  Future<void> create(CustomerInput input) {
    return _ref.read(customersRepositoryProvider).create(input);
  }

  Future<void> update(String id, CustomerInput input) {
    return _ref.read(customersRepositoryProvider).update(id, input);
  }

  Future<void> delete(String id) {
    return _ref.read(customersRepositoryProvider).delete(id);
  }
}

final customersControllerProvider = Provider<CustomersController>(
  CustomersController.new,
);
