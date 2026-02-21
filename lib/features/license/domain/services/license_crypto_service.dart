import 'dart:convert';

import 'package:crypto/crypto.dart';

class LicenseCryptoService {
  const LicenseCryptoService();

  static const String _hmacSecret = 'ZKS_LOCAL_OFFLINE_SECRET_v1';

  String signPayload(String payloadBase64) {
    final bytes = utf8.encode(payloadBase64);
    final key = utf8.encode(_hmacSecret);
    final digest = Hmac(sha256, key).convert(bytes);
    return base64Url.encode(digest.bytes);
  }

  bool verify(String payloadBase64, String signatureBase64) {
    final expected = signPayload(payloadBase64);
    return expected == signatureBase64;
  }
}
