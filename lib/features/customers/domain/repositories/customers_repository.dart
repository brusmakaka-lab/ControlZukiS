import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/features/customers/domain/models/customer_input.dart';

abstract class CustomersRepository {
  Future<List<Customer>> list({
    required int limit,
    required int offset,
    String? search,
  });

  Future<int> count({String? search});

  Future<void> create(CustomerInput input);
  Future<void> update(String customerId, CustomerInput input);
  Future<void> delete(String customerId);
}
