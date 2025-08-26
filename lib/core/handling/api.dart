// lib/core/api.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/env.dart';
import '../../config/env_config.dart';
import '../api_keys.dart';
import 'api_policy.dart';
import 'error_handling.dart';
import 'logs.dart';

class ApiClient {
  final Env env;
  final Uri _base;
  final Map<String, String> Function() _defaultHeaders;
  final http.Client _client;

  ApiClient({required this.env, http.Client? client})
      : _client = client ?? http.Client(),
        _base = baseUrl(kEnv),
        _defaultHeaders = commonHeaders;

  // ---------- JSON (GET) ----------
  Future<ApiResult<dynamic>> getJson({
    required String endpoint,
    required String endpointKey,
    Map<String, String>? headers,
    bool useAuthToken = false,
    EndpointPolicy? overridePolicy,
  }) async {
    final uri = _base.resolve(endpoint);
    ApiLogger.request('GET', uri, headers: headers);
    try {
      if (env == Env.demo) {
        final data = await demoLoadJsonByKey(endpointKey);
        ApiLogger.success('GET', uri, 200, data);
        return ApiResult.ok(data, status: 200);
      }

      final res = await _client
          .get(uri, headers: _merge(headers, useAuthToken))
          .timeout(const Duration(seconds: 60));
      final parsed = _parseJsonBody(res.body);
      final policy = overridePolicy ?? ApiPolicyRegistry.forKey(endpointKey);

      // Rule 1: hard HTTP failures (>=500) win
      if (res.statusCode >= 500) {
        ApiLogger.error('GET', uri, res.statusCode, parsed);
        return ApiResult.err(
          ApiError(policy.messageFor(res.statusCode, parsed), meta: {'httpStatus': res.statusCode}),
          status: res.statusCode,
          headers: res.headers,
        );
      }

      // Rule 2: body-code handling (opt-in)
      if (policy.useBodyCodes && parsed is Map) {
        final raw = parsed[policy.bodyCodeKey];
        final codeStr = raw?.toString();
        if (codeStr != null && codeStr.isNotEmpty) {
          if (policy.bodyCodeIsSuccess(codeStr)) {
            ApiLogger.success('GET', uri, res.statusCode, parsed);
            return ApiResult.ok(parsed, status: res.statusCode, headers: res.headers);
          } else {
            final effective = policy.statusForBodyCode(codeStr, res.statusCode);
            final msg = policy.messageForBodyCode(codeStr, parsed);
            ApiLogger.error('GET', uri, effective, {'code': codeStr, 'msg': msg});
            return ApiResult.err(
              ApiError(msg, meta: {'bodyCode': codeStr, 'httpStatus': res.statusCode}),
              status: effective,
              headers: res.headers,
            );
          }
        }
      }

      // Rule 3: fallback to HTTP policy
      if (policy.isSuccess(res.statusCode)) {
        ApiLogger.success('GET', uri, res.statusCode, parsed);
        return ApiResult.ok(parsed, status: res.statusCode, headers: res.headers);
      }
      ApiLogger.error('GET', uri, res.statusCode, parsed);
      return ApiResult.err(
        ApiError(policy.messageFor(res.statusCode, parsed), meta: {'httpStatus': res.statusCode}),
        status: res.statusCode,
        headers: res.headers,
      );
    } on TimeoutException {
      ApiLogger.exception('GET', uri, 'Request timed out (60s)');
      return ApiResult.err(ApiError('Request timed out (60s)'), status: 0);
    } catch (e) {
      ApiLogger.exception('GET', uri, e);
      return ApiResult.err(ApiError(e.toString(), cause: e), status: 0);
    }
  }

  // ---------- JSON (POST) ----------
  Future<ApiResult<dynamic>> postJson({
    required String endpoint,
    required String endpointKey,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    bool useAuthToken = false,
    EndpointPolicy? overridePolicy,
  }) async {
    final uri = _base.resolve(endpoint);
    ApiLogger.request('POST', uri, headers: headers, body: kDebugMode ? jsonEncode(body) : null);
    try {
      if (env == Env.demo) {
        final data = await demoLoadJsonByKey(endpointKey);
        ApiLogger.success('POST', uri, 200, data);
        return ApiResult.ok(data, status: 200);
      }

      final res = await _client
          .post(uri, headers: _merge(headers, useAuthToken), body: jsonEncode(body))
          .timeout(const Duration(seconds: 60));
      final parsed = _parseJsonBody(res.body);
      final policy = overridePolicy ?? ApiPolicyRegistry.forKey(endpointKey);

      if (res.statusCode >= 500) {
        ApiLogger.error('POST', uri, res.statusCode, parsed);
        return ApiResult.err(
          ApiError(policy.messageFor(res.statusCode, parsed), meta: {'httpStatus': res.statusCode}),
          status: res.statusCode,
          headers: res.headers,
        );
      }

      if (policy.useBodyCodes && parsed is Map) {
        final raw = parsed[policy.bodyCodeKey];
        final codeStr = raw?.toString();
        if (codeStr != null && codeStr.isNotEmpty) {
          if (policy.bodyCodeIsSuccess(codeStr)) {
            ApiLogger.success('POST', uri, res.statusCode, parsed);
            return ApiResult.ok(parsed, status: res.statusCode, headers: res.headers);
          } else {
            final effective = policy.statusForBodyCode(codeStr, res.statusCode);
            final msg = policy.messageForBodyCode(codeStr, parsed);
            ApiLogger.error('POST', uri, effective, {'code': codeStr, 'msg': msg});
            return ApiResult.err(
              ApiError(msg, meta: {'bodyCode': codeStr, 'httpStatus': res.statusCode}),
              status: effective,
              headers: res.headers,
            );
          }
        }
      }

      if (policy.isSuccess(res.statusCode)) {
        ApiLogger.success('POST', uri, res.statusCode, parsed);
        return ApiResult.ok(parsed, status: res.statusCode, headers: res.headers);
      }
      ApiLogger.error('POST', uri, res.statusCode, parsed);
      return ApiResult.err(
        ApiError(policy.messageFor(res.statusCode, parsed), meta: {'httpStatus': res.statusCode}),
        status: res.statusCode,
        headers: res.headers,
      );
    } on TimeoutException {
      ApiLogger.exception('POST', uri, 'Request timed out (60s)');
      return ApiResult.err(ApiError('Request timed out (60s)'), status: 0);
    } catch (e) {
      ApiLogger.exception('POST', uri, e);
      return ApiResult.err(ApiError(e.toString(), cause: e), status: 0);
    }
  }

  // ---------- JSON (PUT) ----------
  Future<ApiResult<dynamic>> putJson({
    required String endpoint,
    required String endpointKey,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    bool useAuthToken = false,
    EndpointPolicy? overridePolicy,
  }) async {
    final uri = _base.resolve(endpoint);
    ApiLogger.request('PUT', uri, headers: headers, body: kDebugMode ? jsonEncode(body) : null);
    try {
      if (env == Env.demo) {
        final data = await demoLoadJsonByKey(endpointKey);
        ApiLogger.success('PUT', uri, 200, data);
        return ApiResult.ok(data, status: 200);
      }

      final res = await _client
          .put(uri, headers: _merge(headers, useAuthToken), body: jsonEncode(body))
          .timeout(const Duration(seconds: 60));
      final parsed = _parseJsonBody(res.body);
      final policy = overridePolicy ?? ApiPolicyRegistry.forKey(endpointKey);

      if (res.statusCode >= 500) {
        ApiLogger.error('PUT', uri, res.statusCode, parsed);
        return ApiResult.err(
          ApiError(policy.messageFor(res.statusCode, parsed), meta: {'httpStatus': res.statusCode}),
          status: res.statusCode,
          headers: res.headers,
        );
      }

      if (policy.useBodyCodes && parsed is Map) {
        final raw = parsed[policy.bodyCodeKey];
        final codeStr = raw?.toString();
        if (codeStr != null && codeStr.isNotEmpty) {
          if (policy.bodyCodeIsSuccess(codeStr)) {
            ApiLogger.success('PUT', uri, res.statusCode, parsed);
            return ApiResult.ok(parsed, status: res.statusCode, headers: res.headers);
          } else {
            final effective = policy.statusForBodyCode(codeStr, res.statusCode);
            final msg = policy.messageForBodyCode(codeStr, parsed);
            ApiLogger.error('PUT', uri, effective, {'code': codeStr, 'msg': msg});
            return ApiResult.err(
              ApiError(msg, meta: {'bodyCode': codeStr, 'httpStatus': res.statusCode}),
              status: effective,
              headers: res.headers,
            );
          }
        }
      }

      if (policy.isSuccess(res.statusCode)) {
        ApiLogger.success('PUT', uri, res.statusCode, parsed);
        return ApiResult.ok(parsed, status: res.statusCode, headers: res.headers);
      }
      ApiLogger.error('PUT', uri, res.statusCode, parsed);
      return ApiResult.err(
        ApiError(policy.messageFor(res.statusCode, parsed), meta: {'httpStatus': res.statusCode}),
        status: res.statusCode,
        headers: res.headers,
      );
    } on TimeoutException {
      ApiLogger.exception('PUT', uri, 'Request timed out (60s)');
      return ApiResult.err(ApiError('Request timed out (60s)'), status: 0);
    } catch (e) {
      ApiLogger.exception('PUT', uri, e);
      return ApiResult.err(ApiError(e.toString(), cause: e), status: 0);
    }
  }

  // ---------- Multipart (POST) ----------
  Future<ApiResult<dynamic>> postMultipart({
    required String endpoint,
    required String endpointKey,
    required String fieldName,
    required String fileName,
    required Uint8List bytes,
    Map<String, String>? fields,
    Map<String, String>? headers,
    bool useAuthToken = false,
    EndpointPolicy? overridePolicy,
  }) async {
    final uri = _base.resolve(endpoint);
    ApiLogger.request('POST-multipart', uri, headers: headers, body: '[multipart $fieldName=$fileName]');
    try {
      if (env == Env.demo) {
        final data = await demoLoadJsonByKey(endpointKey);
        ApiLogger.success('POST-multipart', uri, 200, data);
        return ApiResult.ok(data, status: 200);
      }

      final req = http.MultipartRequest('POST', uri);
      final merged = _merge(headers, useAuthToken);
      merged.removeWhere((k, _) => k.toLowerCase() == 'content-type');
      req.headers.addAll(merged);
      (fields ?? {}).forEach((k, v) => req.fields[k] = v);
      req.files.add(http.MultipartFile.fromBytes(fieldName, bytes, filename: fileName));

      final streamed = await req.send().timeout(const Duration(seconds: 60));
      final res = await http.Response.fromStream(streamed);
      final parsed = _parseJsonBody(res.body);
      final policy = overridePolicy ?? ApiPolicyRegistry.forKey(endpointKey);

      if (res.statusCode >= 500) {
        ApiLogger.error('POST-multipart', uri, res.statusCode, parsed);
        return ApiResult.err(
          ApiError(policy.messageFor(res.statusCode, parsed), meta: {'httpStatus': res.statusCode}),
          status: res.statusCode,
          headers: res.headers,
        );
      }

      if (policy.useBodyCodes && parsed is Map) {
        final raw = parsed[policy.bodyCodeKey];
        final codeStr = raw?.toString();
        if (codeStr != null && codeStr.isNotEmpty) {
          if (policy.bodyCodeIsSuccess(codeStr)) {
            ApiLogger.success('POST-multipart', uri, res.statusCode, parsed);
            return ApiResult.ok(parsed, status: res.statusCode, headers: res.headers);
          } else {
            final effective = policy.statusForBodyCode(codeStr, res.statusCode);
            final msg = policy.messageForBodyCode(codeStr, parsed);
            ApiLogger.error('POST-multipart', uri, effective, {'code': codeStr, 'msg': msg});
            return ApiResult.err(
              ApiError(msg, meta: {'bodyCode': codeStr, 'httpStatus': res.statusCode}),
              status: effective,
              headers: res.headers,
            );
          }
        }
      }

      if (policy.isSuccess(res.statusCode)) {
        ApiLogger.success('POST-multipart', uri, res.statusCode, parsed);
        return ApiResult.ok(parsed, status: res.statusCode, headers: res.headers);
      }
      ApiLogger.error('POST-multipart', uri, res.statusCode, parsed);
      return ApiResult.err(
        ApiError(policy.messageFor(res.statusCode, parsed), meta: {'httpStatus': res.statusCode}),
        status: res.statusCode,
        headers: res.headers,
      );
    } on TimeoutException {
      ApiLogger.exception('POST-multipart', uri, 'Request timed out (60s)');
      return ApiResult.err(ApiError('Request timed out (60s)'), status: 0);
    } catch (e) {
      ApiLogger.exception('POST-multipart', uri, e);
      return ApiResult.err(ApiError(e.toString(), cause: e), status: 0);
    }
  }

  // ---------- Bytes (GET) ----------
  Future<ApiResult<Uint8List>> getBytes({
    required String endpoint,
    required String endpointKey,
    String? demoKeyWithExt, // pass explicit asset name for demo bytes
    Map<String, String>? headers,
    bool useAuthToken = false,
    EndpointPolicy? overridePolicy,
  }) async {
    final uri = _base.resolve(endpoint);
    ApiLogger.request('GET-bytes', uri, headers: headers);
    try {
      if (env == Env.demo) {
        final data = await demoLoadBytesByKey(demoKeyWithExt ?? 'missing.png');
        ApiLogger.success('GET-bytes', uri, 200, '[${data.lengthInBytes} bytes]');
        return ApiResult.ok(data, status: 200);
      }

      final res = await _client
          .get(uri, headers: _merge(headers, useAuthToken))
          .timeout(const Duration(seconds: 60));

      final policy = overridePolicy ?? ApiPolicyRegistry.forKey(endpointKey);
      if (policy.isSuccess(res.statusCode)) {
        ApiLogger.success('GET-bytes', uri, res.statusCode, '[${res.bodyBytes.length} bytes]');
        return ApiResult.ok(res.bodyBytes, status: res.statusCode, headers: res.headers);
      }
      ApiLogger.error('GET-bytes', uri, res.statusCode, '[binary error]');
      return ApiResult.err(
        ApiError('Binary request failed (${res.statusCode})', meta: {'httpStatus': res.statusCode}),
        status: res.statusCode,
        headers: res.headers,
      );
    } on TimeoutException {
      ApiLogger.exception('GET-bytes', uri, 'Request timed out (60s)');
      return ApiResult.err(ApiError('Request timed out (60s)'), status: 0);
    } catch (e) {
      ApiLogger.exception('GET-bytes', uri, e);
      return ApiResult.err(ApiError(e.toString(), cause: e), status: 0);
    }
  }

  // ---------- helpers ----------
  Map<String, String> _merge(Map<String, String>? extra, bool useAuthToken) {
    final base = _defaultHeaders(); // may include Authorization
    if (!useAuthToken) {
      base.removeWhere((k, _) => k.toLowerCase() == 'authorization');
    }
    return {...base, ...?extra};
  }

  dynamic _parseJsonBody(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body; // allow plain text
    }
  }
}

// Global instance
final api = ApiClient(env: kEnv);