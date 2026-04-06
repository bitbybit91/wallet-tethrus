import 'dart:typed_data';
import 'dart:math';
import 'package:bip39/bip39.dart' as bip39;
import 'package:pointycastle/export.dart';
import 'package:convert/convert.dart';

class WalletCrypto {
  List<String> generateMnemonic() {
    final mnemonic = bip39.generateMnemonic(strength: 128);
    return mnemonic.split(' ');
  }

  bool validateMnemonic(List<String> words) {
    return bip39.validateMnemonic(words.join(' '));
  }

  Uint8List mnemonicToSeed(List<String> words) {
    return Uint8List.fromList(bip39.mnemonicToSeed(words.join(' ')));
  }

  /// Derives a TRON private key from the seed using BIP44 path m/44'/195'/0'/0/0
  String derivePrivateKey(Uint8List seed) {
    final masterKey = _deriveMasterKey(seed);
    final childKey = _deriveChildKey(masterKey, [
      0x8000002C, // 44'
      0x800000C3, // 195'
      0x80000000, // 0'
      0x00000000, // 0
      0x00000000, // 0
    ]);
    return hex.encode(childKey);
  }

  /// Generates a TRON address from a private key
  String privateKeyToAddress(String privateKeyHex) {
    final privateKeyBytes = Uint8List.fromList(hex.decode(privateKeyHex));
    final ecParams = ECCurve_secp256k1();
    final privateKey =
        ECPrivateKey(BigInt.parse(hex.encode(privateKeyBytes), radix: 16), ecParams);
    final publicKeyPoint = ecParams.G * privateKey.d;
    if (publicKeyPoint == null) throw Exception('Failed to derive public key');

    final pubKeyBytes = publicKeyPoint.getEncoded(false);
    // Remove the 0x04 prefix
    final pubKeyNoPrefix = pubKeyBytes.sublist(1);

    // Keccak-256 hash
    final keccak = KeccakDigest(256);
    final hashBytes = Uint8List(32);
    keccak.update(pubKeyNoPrefix, 0, pubKeyNoPrefix.length);
    keccak.doFinal(hashBytes, 0);

    // Take the last 20 bytes, prepend 0x41 (TRON mainnet prefix)
    final addressBytes = Uint8List(21);
    addressBytes[0] = 0x41;
    addressBytes.setRange(1, 21, hashBytes.sublist(12));

    return _base58CheckEncode(addressBytes);
  }

  String _base58CheckEncode(Uint8List payload) {
    // Double SHA-256 for checksum
    final sha256 = SHA256Digest();
    final hash1 = Uint8List(32);
    sha256.update(payload, 0, payload.length);
    sha256.doFinal(hash1, 0);

    final sha256_2 = SHA256Digest();
    final hash2 = Uint8List(32);
    sha256_2.update(hash1, 0, hash1.length);
    sha256_2.doFinal(hash2, 0);

    final checksum = hash2.sublist(0, 4);
    final fullPayload = Uint8List(payload.length + 4);
    fullPayload.setAll(0, payload);
    fullPayload.setAll(payload.length, checksum);

    return _base58Encode(fullPayload);
  }

  static const _base58Alphabet =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  String _base58Encode(Uint8List bytes) {
    var number = BigInt.zero;
    for (final byte in bytes) {
      number = number * BigInt.from(256) + BigInt.from(byte);
    }

    final chars = <String>[];
    while (number > BigInt.zero) {
      final remainder = (number % BigInt.from(58)).toInt();
      number = number ~/ BigInt.from(58);
      chars.add(_base58Alphabet[remainder]);
    }

    // Leading zeros
    for (final byte in bytes) {
      if (byte == 0) {
        chars.add('1');
      } else {
        break;
      }
    }

    return chars.reversed.join();
  }

  Uint8List _deriveMasterKey(Uint8List seed) {
    final hmac = HMac(SHA512Digest(), 128);
    hmac.init(KeyParameter(Uint8List.fromList('Bitcoin seed'.codeUnits)));
    final result = Uint8List(64);
    hmac.update(seed, 0, seed.length);
    hmac.doFinal(result, 0);
    return result.sublist(0, 32);
  }

  Uint8List _deriveChildKey(Uint8List parentKey, List<int> path) {
    var key = parentKey;
    for (final index in path) {
      final hmac = HMac(SHA512Digest(), 128);
      hmac.init(KeyParameter(key));
      final data = Uint8List(4);
      data[0] = (index >> 24) & 0xFF;
      data[1] = (index >> 16) & 0xFF;
      data[2] = (index >> 8) & 0xFF;
      data[3] = index & 0xFF;
      final result = Uint8List(64);
      hmac.update(data, 0, data.length);
      hmac.doFinal(result, 0);
      key = result.sublist(0, 32);
    }
    return key;
  }
}
