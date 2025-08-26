import 'auth_store.dart';
import 'env.dart';

Uri baseUrl(Env env) => switch (env) {
  Env.demo => Uri.parse('https://demo.local/'),
  Env.dev  => Uri.parse('https://dev.api.example.com/'),
  Env.qa   => Uri.parse('https://qa.api.example.com/'),
  Env.prod => Uri.parse('https://api.example.com/'),
};

Map<String, String> commonHeaders() {
  final headers = <String, String>{};
  final token = AuthStore.token;
  if (token != null && token.isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';
  }
  return headers;
}