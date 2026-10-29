import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Hashing password dengan salt acak dan SHA-256 berulang.
/// Format tersimpan: "salt:hash" (keduanya Base64).
class PasswordHasher {
  PasswordHasher._();

  static const int _iterations = 10000;
  static const int _saltLength = 16;

  static String hash(String password) {
    final String salt = _generateSalt();
    return '$salt:${_derive(password, salt)}';
  }

  static bool verify(String password, String storedHash) {
    final List<String> parts = storedHash.split(':');
    if (parts.length != 2) return false;
    final String computed = _derive(password, parts[0]);
    return _constantTimeEquals(computed, parts[1]);
  }

  static String _generateSalt() {
    final Random random = Random.secure();
    final List<int> bytes = List<int>.generate(
      _saltLength,
      (_) => random.nextInt(256),
    );
    return base64Encode(bytes);
  }

  static String _derive(String password, String salt) {
    final List<int> saltBytes = utf8.encode(salt);
    List<int> digest = sha256.convert(utf8.encode('$salt:$password')).bytes;
    for (int i = 0; i < _iterations; i++) {
      digest = sha256.convert(<int>[...digest, ...saltBytes]).bytes;
    }
    return base64Encode(digest);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
