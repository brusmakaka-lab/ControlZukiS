import 'package:controlzukis/features/sales/domain/models/sale_item_input.dart';

class CreateSaleInput {
  const CreateSaleInput({
    required this.items,
    this.customerId,
    this.discount = 0,
    this.tax = 0,
    this.notes,
  });

  final List<SaleItemInput> items;
  final String? customerId;
  final double discount;
  final double tax;
  final String? notes;
}
