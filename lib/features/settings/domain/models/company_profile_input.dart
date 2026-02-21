class CompanyProfileInput {
  const CompanyProfileInput({
    required this.name,
    this.legalName,
    this.taxId,
    this.email,
    this.phone,
    this.address,
  });

  final String name;
  final String? legalName;
  final String? taxId;
  final String? email;
  final String? phone;
  final String? address;
}
