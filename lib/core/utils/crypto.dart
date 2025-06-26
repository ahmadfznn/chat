import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';
import 'dart:convert';
import 'dart:typed_data';

Future<String> generateKeyPair() async {
  final keyGen = RSAKeyGenerator()
    ..init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 5),
      _secureRandom(),
    ));

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  final pair = keyGen.generateKeyPair();
  final publicKey = pair.publicKey;
  final privateKey = pair.privateKey;
  final encodePublic = encodePublicKeyToPem(publicKey);
  final encodePrivate = encodePrivateKeyToPem(privateKey);

  await storage.write(key: 'private_key', value: encodePrivate);
  return encodePublic;
}

SecureRandom _secureRandom() {
  final secureRandom = FortunaRandom();
  final seed = Uint8List.fromList(
      List.generate(32, (_) => DateTime.now().millisecondsSinceEpoch % 256));
  secureRandom.seed(KeyParameter(seed));
  return secureRandom;
}

String encodePublicKeyToPem(RSAPublicKey publicKey) {
  final modulusBytes = base64Encode(bigIntToBytes(publicKey.modulus!));
  return '''-----BEGIN PUBLIC KEY-----
${_chunk(modulusBytes, 64)}
-----END PUBLIC KEY-----''';
}

String encodePrivateKeyToPem(RSAPrivateKey privateKey) {
  final exponentBytes =
      base64Encode(bigIntToBytes(privateKey.privateExponent!));
  return '''-----BEGIN PRIVATE KEY-----
${_chunk(exponentBytes, 64)}
-----END PRIVATE KEY-----''';
}

String _chunk(String str, int size) {
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i += size) {
    buffer.writeln(
        str.substring(i, i + size > str.length ? str.length : i + size));
  }
  return buffer.toString();
}

List<int> bigIntToBytes(BigInt bigInt) {
  final bytes = <int>[];
  BigInt value = bigInt;

  while (value != BigInt.zero) {
    bytes.insert(0, (value & BigInt.from(0xff)).toInt());
    value = value >> 8;
  }

  return bytes;
}

String encryptData(String data, RSAPublicKey publicKey) {
  final encryptor = OAEPEncoding(RSAEngine())
    ..init(
      true,
      PublicKeyParameter<RSAPublicKey>(publicKey),
    );

  final inputBytes = Uint8List.fromList(utf8.encode(data));
  final encryptedBytes = _processBlocks(encryptor, inputBytes);

  return base64Encode(encryptedBytes);
}

String decryptData(String encryptedData, RSAPrivateKey privateKey) {
  final decryptor = OAEPEncoding(RSAEngine())
    ..init(
      false,
      PrivateKeyParameter<RSAPrivateKey>(privateKey),
    );

  final encryptedBytes = base64Decode(encryptedData);
  final decryptedBytes = _processBlocks(decryptor, encryptedBytes);

  return utf8.decode(decryptedBytes);
}

Uint8List _processBlocks(AsymmetricBlockCipher engine, Uint8List input) {
  final output = <int>[];
  final blockSize = engine.inputBlockSize;

  for (var i = 0; i < input.length; i += blockSize) {
    final chunkSize =
        (i + blockSize > input.length) ? input.length - i : blockSize;
    final chunk = input.sublist(i, i + chunkSize);
    output.addAll(engine.process(Uint8List.fromList(chunk)));
  }

  return Uint8List.fromList(output);
}
