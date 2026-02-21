class CustomerInput {
  const CustomerInput({
    required this.fullName,
    this.dniCuit,
    this.email,
    this.phone,
    this.address,
  });

  final String fullName;
  final String? dniCuit;
  final String? email;
  final String? phone;
  final String? address;
}
