import 'dart:convert';

class LicensePayload {
  const LicensePayload({
    required this.tenantId,
    required this.deviceId,
    required this.plan,
    required this.maxDevices,
    required this.issuedAt,
    this.expiresAt,
    this.appVersionMin,
  });

  final String tenantId;
  final String deviceId;
  final String plan;
  final int maxDevices;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final String? appVersionMin;

  Map<String, dynamic> toJson() => {
    'tenantId': tenantId,
    'deviceId': deviceId,
    'plan': plan,
    'maxDevices': maxDevices,
    'issuedAt': issuedAt.toIso8601String(),
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    if (appVersionMin != null) 'appVersionMin': appVersionMin,
  };

  factory LicensePayload.fromJson(Map<String, dynamic> json) {
    return LicensePayload(
      tenantId: json['tenantId'] as String,
      deviceId: json['deviceId'] as String,
      plan: json['plan'] as String,
      maxDevices: (json['maxDevices'] as num).toInt(),
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      appVersionMin: json['appVersionMin'] as String?,
    );
  }

  String toBase64Payload() =>
      base64Url.encode(utf8.encode(jsonEncode(toJson())));

  static LicensePayload fromBase64Payload(String input) {
    final decoded = utf8.decode(base64Url.decode(input));
    return LicensePayload.fromJson(jsonDecode(decoded) as Map<String, dynamic>);
  }
}
