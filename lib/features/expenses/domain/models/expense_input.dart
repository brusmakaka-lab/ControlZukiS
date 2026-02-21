class ExpenseInput {
  const ExpenseInput({
    required this.category,
    required this.amount,
    this.notes,
    this.affectsStock = false,
    this.productId,
    this.stockQuantity,
  });

  final String category;
  final double amount;
  final String? notes;
  final bool affectsStock;
  final String? productId;
  final double? stockQuantity;
}
