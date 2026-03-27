import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../core/constants.dart';

class EncryptionService {
  // ─── Singleton ────────────────────────────────────────────────
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  // ─── Secure Storage ───────────────────────────────────────────
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Encrypter? _encrypter;
  IV? _iv;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ─── Initialize ───────────────────────────────────────────────
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      String? storedKey = await _secureStorage.read(
        key: AppConstants.encryptionKeyName,
      );

      if (storedKey == null) {
        final key = Key.fromSecureRandom(32);
        storedKey = base64Encode(key.bytes);
        await _secureStorage.write(
          key: AppConstants.encryptionKeyName,
          value: storedKey,
        );
      }

      final keyBytes = base64Decode(storedKey);
      final paddedKey = Uint8List(32);
      paddedKey.setRange(0, keyBytes.length.clamp(0, 32), keyBytes);

      final ivBytes = paddedKey.sublist(0, 16);

      _encrypter = Encrypter(AES(
        Key(paddedKey),
        mode: AESMode.cbc,
        padding: 'PKCS7',
      ));
      _iv = IV(ivBytes);
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
    }
  }

  // ─── Encrypt / Decrypt (Basic) ────────────────────────────────
  String encrypt(String plainText) {
    if (!_isInitialized || _encrypter == null || _iv == null) {
      return plainText;
    }
    if (plainText.isEmpty) return plainText;
    try {
      return _encrypter!.encrypt(plainText, iv: _iv!).base64;
    } catch (_) {
      return plainText;
    }
  }

  String decrypt(String encryptedText) {
    if (!_isInitialized || _encrypter == null || _iv == null) {
      return encryptedText;
    }
    if (encryptedText.isEmpty) return encryptedText;
    try {
      return _encrypter!.decrypt(Encrypted.fromBase64(encryptedText), iv: _iv!);
    } catch (_) {
      return encryptedText;
    }
  }

  // ─── Encrypt Secure (IV عشوائي لكل رسالة) ────────────────────
  String encryptSecure(String plainText) {
    if (!_isInitialized || _encrypter == null) return plainText;
    if (plainText.isEmpty) return plainText;
    try {
      final randomIV = IV.fromSecureRandom(16);
      final encrypted = _encrypter!.encrypt(plainText, iv: randomIV);
      return '${base64Encode(randomIV.bytes)}:${encrypted.base64}';
    } catch (_) {
      return plainText;
    }
  }

  String decryptSecure(String encryptedText) {
    if (!_isInitialized || _encrypter == null) return encryptedText;
    if (encryptedText.isEmpty) return encryptedText;
    try {
      final colonIndex = encryptedText.indexOf(':');
      if (colonIndex == -1 || colonIndex == 0) {
        return decrypt(encryptedText);
      }
      final ivPart = encryptedText.substring(0, colonIndex);
      final dataPart = encryptedText.substring(colonIndex + 1);
      final iv = IV(base64Decode(ivPart));
      final encrypted = Encrypted.fromBase64(dataPart);
      return _encrypter!.decrypt(encrypted, iv: iv);
    } catch (_) {
      return decrypt(encryptedText);
    }
  }

  // ─── Hash ─────────────────────────────────────────────────────
  String hashContent(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool verifyContent(String content, String hash) =>
      hashContent(content) == hash;

  String shortHash(String content) => hashContent(content).substring(0, 8);

  // ─── Helpers ──────────────────────────────────────────────────
  bool isEncrypted(String text) {
    if (text.isEmpty || text.length < 24) return false;
    try {
      final decoded = base64Decode(text);
      return decoded.length >= 16 &&
          !text.contains(' ') &&
          !text.contains('\n');
    } catch (_) {
      return false;
    }
  }

  static String generateSecurePassword({int length = 20}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
        r'0123456789!@#$%^&*()_+-=';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // ─── Key Management ───────────────────────────────────────────
  Future<void> deleteEncryptionKey() async {
    try {
      await _secureStorage.delete(key: AppConstants.encryptionKeyName);
    } catch (_) {}
    _encrypter = null;
    _iv = null;
    _isInitialized = false;
  }

  Future<bool> hasEncryptionKey() async {
    try {
      final key =
          await _secureStorage.read(key: AppConstants.encryptionKeyName);
      return key != null && key.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> regenerateKey() async {
    await deleteEncryptionKey();
    await initialize();
  }

  Future<String?> exportKey() async {
    try {
      return await _secureStorage.read(key: AppConstants.encryptionKeyName);
    } catch (_) {
      return null;
    }
  }

  Future<bool> importKey(String keyBase64) async {
    try {
      final bytes = base64Decode(keyBase64);
      if (bytes.length < 16) return false;
      await _secureStorage.write(
        key: AppConstants.encryptionKeyName,
        value: keyBase64,
      );
      _isInitialized = false;
      await initialize();
      return true;
    } catch (_) {
      return false;
    }
  }
}
