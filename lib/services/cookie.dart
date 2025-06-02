import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CookieManager {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveSessionCookie(String cookie) async {
    await _storage.write(key: 'session_cookie', value: cookie);
  }

  Future<String?> getSessionCookie() async {
    return await _storage.read(key: 'session_cookie');
  }

  Future<void> clearSessionCookie() async {
    await _storage.delete(key: 'session_cookie');
  }

  String? extractCookieValue(String cookies, String cookieName) {
    final regex = RegExp('$cookieName=([^;]+)');
    final match = regex.firstMatch(cookies);
    return match?.group(1);
  }
}
