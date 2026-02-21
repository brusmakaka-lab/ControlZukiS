import 'package:controlzukis/core/config/app_env.dart';
import 'package:controlzukis/features/license/domain/models/license_payload.dart';
import 'package:controlzukis/features/license/domain/services/license_crypto_service.dart';

class LicenseCodec {
  const LicenseCodec(this._crypto);

  final LicenseCryptoService _crypto;

  String encode(LicensePayload payload) {
    final payloadB64 = payload.toBase64Payload();
    final signatureB64 = _crypto.signPayload(payloadB64);
    return '${AppEnv.licenseFormatPrefix}$payloadB64.$signatureB64';
  }

  LicensePayload? decodeAndVerify(String key) {
    if (!key.startsWith(AppEnv.licenseFormatPrefix)) {
      return null;
    }
    final body = key.substring(AppEnv.licenseFormatPrefix.length);
    final parts = body.split('.');
    if (parts.length != 2) return null;
    final payloadB64 = parts[0];
    final sigB64 = parts[1];
    if (!_crypto.verify(payloadB64, sigB64)) return null;
    return LicensePayload.fromBase64Payload(payloadB64);
  }
}
