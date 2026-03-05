class INEData {
  final String fullName;
  final String address;
  final String postalCode;

  INEData({
    required this.fullName,
    required this.address,
    required this.postalCode,
  });

  bool get isValid => fullName.isNotEmpty && postalCode.isNotEmpty;

  @override
  String toString() =>
      'INEData(fullName: $fullName, address: $address, postalCode: $postalCode)';
}

