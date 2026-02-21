import 'dart:convert';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  const PasswordHasher._();

  static String hash(String raw) {
    return sha256.convert(utf8.encode(raw)).toString();
  }

  static bool verify(String raw, String storedHash) {
    return hash(raw) == storedHash;
  }
}
