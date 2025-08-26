// lib/config/auth_store.dart
class AuthStore {
  static String? _token;
  static void setToken(String token) => _token = token;
  static String? get token => _token;
  static void clear() => _token = null;
}