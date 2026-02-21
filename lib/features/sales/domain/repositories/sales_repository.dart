import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/features/sales/domain/models/create_sale_input.dart';

abstract class SalesRepository {
  Future<List<Product>> listProducts({String? search});
  Future<void> createSaleWithStock(CreateSaleInput input);
}
