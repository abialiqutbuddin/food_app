// lib/core/repository.dart
import 'dart:typed_data';
import '../config/env.dart';
import 'api_keys.dart';
import '../models/login.dart';
import '../models/user.dart';
import '../models/update_profile.dart';
import '../models/upload_image.dart';
import 'handling/api.dart';
import 'handling/error_handling.dart';

class ApiRepository {
  Map<String, String> _headersJson() => {'Accept': 'application/json'};
  Map<String, String> _headersJsonBody() =>
      {'Accept': 'application/json', 'Content-Type': 'application/json'};
  Map<String, String> _headersPng() => {'Accept': 'image/png'};

  // -------- LOGIN -------- (body-code enabled by policy)
  Future<ApiResult<LoginResponse>> login({
    required String email,
    required String password,
  }) async {
    final r = await api.postJson(
      endpoint: Endpoints.login,
      endpointKey: ApiKeys.login,
      body: {'email': email, 'password': password},
      headers: _headersJsonBody(),
      useAuthToken: false,
    );
    if (r.isOk) {
      return ApiResult.ok(
        LoginResponse.fromJson(r.data as Map<String, dynamic>),
        status: r.status,
        headers: r.headers,
      );
    }
    return ApiResult.err(r.error!, status: r.status, headers: r.headers);
  }

  // -------- GET USER --------
  Future<ApiResult<UserModel>> getUser({
    required String id,
    bool useAuth = true,
  }) async {
    final r = await api.getJson(
      endpoint: Endpoints.userById(id),
      endpointKey: ApiKeys.getUser,
      headers: _headersJson(),
      useAuthToken: useAuth,
    );
    if (r.isOk) {
      return ApiResult.ok(
        UserModel.fromJson(r.data as Map<String, dynamic>),
        status: r.status,
        headers: r.headers,
      );
    }
    return ApiResult.err(r.error!, status: r.status, headers: r.headers);
  }

  // -------- UPDATE PROFILE --------
  Future<ApiResult<UpdateProfileResponse>> updateProfile({
    required String name,
    required String email,
  }) async {
    final r = await api.putJson(
      endpoint: Endpoints.updateProfile,
      endpointKey: ApiKeys.updateProfile,
      body: {'name': name, 'email': email},
      headers: _headersJsonBody(),
      useAuthToken: true,
    );
    if (r.isOk) {
      if (r.data == null) {
        return ApiResult.ok(
          UpdateProfileResponse(user: UserModel(id: '', name: '', email: ''), message: 'Updated'),
          status: r.status,
          headers: r.headers,
        );
      }
      return ApiResult.ok(
        UpdateProfileResponse.fromJson(r.data as Map<String, dynamic>),
        status: r.status,
        headers: r.headers,
      );
    }
    return ApiResult.err(r.error!, status: r.status, headers: r.headers);
  }

  // -------- UPLOAD IMAGE --------
  Future<ApiResult<UploadImageResponse>> uploadImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final r = await api.postMultipart(
      endpoint: Endpoints.uploadImage,
      endpointKey: ApiKeys.uploadImage,
      fieldName: 'file',
      fileName: fileName,
      bytes: bytes,
      headers: _headersJson(),
      useAuthToken: true,
    );
    if (r.isOk) {
      return ApiResult.ok(
        UploadImageResponse.fromJson(r.data as Map<String, dynamic>),
        status: r.status,
        headers: r.headers,
      );
    }
    return ApiResult.err(r.error!, status: r.status, headers: r.headers);
  }

  // -------- DOWNLOAD IMAGE (demo bytes key passed) --------
  Future<ApiResult<Uint8List>> downloadImage({
    required String idOrAssetPath,
    bool useAuth = true,
  }) async {
    final endpoint = kEnv == Env.demo
        ? 'media/$idOrAssetPath'
        : Endpoints.downloadImageById(idOrAssetPath);

    return api.getBytes(
      endpoint: endpoint,
      endpointKey: ApiKeys.downloadImage,
      headers: _headersPng(),
      demoKeyWithExt: 'media_download.png', // ensures demo bytes load
      useAuthToken: useAuth,
    );
  }
}