class CustomFieldSeed {
  const CustomFieldSeed({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.optionsJson,
  });

  final String key;
  final String label;
  final String type;
  final bool required;
  final String? optionsJson;
}
