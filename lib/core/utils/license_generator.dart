import 'dart:io';

import 'package:controlzukis/features/license/domain/models/license_payload.dart';
import 'package:controlzukis/features/license/domain/services/license_codec.dart';
import 'package:controlzukis/features/license/domain/services/license_crypto_service.dart';

void main(List<String> args) {
  final params = <String, String>{};
  for (final arg in args) {
    final parts = arg.split('=');
    if (parts.length == 2) {
      params[parts[0].replaceFirst('--', '')] = parts[1];
    }
  }

  final tenantId = params['tenantId'];
  final deviceId = params['deviceId'];
  final plan = params['plan'] ?? 'PRO';
  final maxDevices = int.tryParse(params['maxDevices'] ?? '1') ?? 1;
  final expiresAtRaw = params['expiresAt'];
  final appVersionMin = params['appVersionMin'];

  if (tenantId == null || deviceId == null) {
    stdout.writeln(
      'Uso: dart run lib/core/utils/license_generator.dart --tenantId=... --deviceId=... [--plan=PRO] [--maxDevices=1] [--expiresAt=2027-01-01T00:00:00Z] [--appVersionMin=1.0.0]',
    );
    exit(1);
  }

  final payload = LicensePayload(
    tenantId: tenantId,
    deviceId: deviceId,
    plan: plan,
    maxDevices: maxDevices,
    issuedAt: DateTime.now().toUtc(),
    expiresAt: expiresAtRaw == null
        ? null
        : DateTime.parse(expiresAtRaw).toUtc(),
    appVersionMin: appVersionMin,
  );

  final codec = LicenseCodec(const LicenseCryptoService());
  final key = codec.encode(payload);
  stdout.writeln(key);
}
