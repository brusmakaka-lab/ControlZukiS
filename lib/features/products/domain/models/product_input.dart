class ProductInput {
  const ProductInput({
    required this.name,
    required this.sku,
    required this.isService,
    required this.stock,
    required this.buyPrice,
    required this.sellPrice,
    this.categoryId,
    this.description,
    this.customFields = const [],
  });

  final String name;
  final String? sku;
  final bool isService;
  final double stock;
  final double buyPrice;
  final double sellPrice;
  final String? categoryId;
  final String? description;
  final List<CustomFieldInput> customFields;
}

class CustomFieldInput {
  const CustomFieldInput({
    required this.fieldDefinitionId,
    required this.type,
    this.valueText,
    this.valueNumber,
    this.valueBool,
    this.valueDate,
    this.valueJson,
  });

  final String fieldDefinitionId;
  final String type;
  final String? valueText;
  final double? valueNumber;
  final bool? valueBool;
  final DateTime? valueDate;
  final String? valueJson;

  bool get hasAnyValue {
    if (valueBool != null) return true;
    if (valueNumber != null) return true;
    if (valueDate != null) return true;
    if (valueJson != null && valueJson!.trim().isNotEmpty) return true;
    return valueText != null && valueText!.trim().isNotEmpty;
  }
}
