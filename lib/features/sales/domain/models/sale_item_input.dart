class SaleItemInput {
  const SaleItemInput({
    required this.productId,
    required this.quantity,
    this.unitPrice,
  });

  final String productId;
  final double quantity;
  final double? unitPrice;
}
