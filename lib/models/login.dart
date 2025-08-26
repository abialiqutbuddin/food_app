import 'package:project_structure/models/user.dart';

/// Adjust to your real login payload (tokens, profile, etc.)
class LoginResponse {
  final UserModel user;
  // final String accessToken;
  // final String refreshToken;

  LoginResponse({required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> j) {
    // If your API is { "user": {...} } change to j['user']
    return LoginResponse(user: UserModel.fromJson(j));
  }
}