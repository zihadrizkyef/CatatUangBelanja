import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Salted SHA-256 PIN hashing. The app-lock PIN (doc 4.11) exists to keep
/// family members from casually opening the app, not to resist an attacker
/// doing offline brute-force on a stolen device — so unlike a real password
/// hash, this deliberately skips PBKDF2/bcrypt-style iteration stretching:
/// a single hash keeps every unlock instant, and the salt still stops the
/// stored hash from being a rainbow-table lookup.
class PinHasher {
  PinHasher._();

  static Uint8List generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
  }

  static Future<Uint8List> hash(String pin, Uint8List salt) async {
    return Uint8List.fromList(sha256.convert([...salt, ...utf8.encode(pin)]).bytes);
  }

  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
