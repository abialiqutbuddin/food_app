import 'package:project_structure/models/user.dart';

class UpdateProfileResponse {
  final UserModel user;
  final String? message;

  UpdateProfileResponse({required this.user, this.message});

  factory UpdateProfileResponse.fromJson(Map<String, dynamic> j) {
    if (j['user'] is Map<String, dynamic>) {
      return UpdateProfileResponse(
        user: UserModel.fromJson(j['user']),
        message: j['message']?.toString(),
      );
    }
    return UpdateProfileResponse(
      user: UserModel.fromJson(j),
      message: j['message']?.toString(),
    );
  }
}