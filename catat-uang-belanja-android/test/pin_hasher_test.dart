import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:catat_uang_belanja/services/pin_hasher.dart';

void main() {
  test('hash() is deterministic for the same PIN and salt', () async {
    final salt = Uint8List.fromList(List.generate(16, (i) => i));
    final hashA = await PinHasher.hash('123456', salt);
    final hashB = await PinHasher.hash('123456', salt);

    expect(PinHasher.constantTimeEquals(hashA, hashB), isTrue);
  });

  test('hash() differs for different PINs with the same salt', () async {
    final salt = Uint8List.fromList(List.generate(16, (i) => i));
    final hashA = await PinHasher.hash('123456', salt);
    final hashB = await PinHasher.hash('654321', salt);

    expect(PinHasher.constantTimeEquals(hashA, hashB), isFalse);
  });

  test('hash() differs for the same PIN with different salts', () async {
    final saltA = Uint8List.fromList(List.generate(16, (i) => i));
    final saltB = Uint8List.fromList(List.generate(16, (i) => i + 1));
    final hashA = await PinHasher.hash('123456', saltA);
    final hashB = await PinHasher.hash('123456', saltB);

    expect(PinHasher.constantTimeEquals(hashA, hashB), isFalse);
  });

  test('generateSalt() returns 16 random bytes, different each call', () {
    final saltA = PinHasher.generateSalt();
    final saltB = PinHasher.generateSalt();

    expect(saltA.length, 16);
    expect(saltB.length, 16);
    expect(PinHasher.constantTimeEquals(saltA, saltB), isFalse);
  });

  test('constantTimeEquals rejects different-length inputs', () {
    expect(PinHasher.constantTimeEquals([1, 2, 3], [1, 2]), isFalse);
  });
}
