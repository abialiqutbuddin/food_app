// lib/core/api_keys.dart
import 'handling/api_policy.dart';

/// Keys to reference endpoints/policies
abstract class ApiKeys {
  // Auth
  static const login = 'auth_login';
  static const login2 = 'auth_login2';
  static const updateProfile = 'user_update';

  // Users
  static const getUser = 'users_get_by_id';

  // Media
  static const uploadImage = 'media_upload';
  static const downloadImage = 'media_download';

  // Example extra
  static const postsGetById = 'posts_get_by_id';
  static const postsCreate  = 'posts_create';
}

/// Paths
abstract class Endpoints {
  static const login = 'auth/login';
  static const login2 = 'auth/login';
  static const updateProfile = 'user/update';

  static const users = 'users';
  static String userById(String id) => 'users/$id';

  static const uploadImage = 'media/upload';
  static String downloadImageById(String id) => 'media/$id';

  // Examples
  static const posts = 'posts';
  static String postById(String id) => 'posts/$id';
}

/// Central policies per endpoint
class ApiPolicyRegistry {
  static final Map<String, EndpointPolicy> _policies = {
    // Login: HTTP 200, but backend may embed business code in body
    ApiKeys.login: const EndpointPolicy(
      successCodes: {200, 201},
      useBodyCodes: true,                 // enable body-code handling here
      bodyCodeKey: 'responseCode',
      bodyMessageKey: 'message',
      bodySuccessCodes: {'00'},
      bodyCodeToHttpStatus: {
        '014': 403,
        '015': 404,
        '016': 405,
      },
    ),

    ApiKeys.login2: EndpointPolicy(
      successCodes: const {200, 201},
      errorMessages: {
        403: (_) => 'Account is blocked',
        404: (_) => 'Invalid account',
        405: (_) => 'Account temporarily disabled',
      },
    ),

    // Get user: standard HTTP handling; explicit messages for 401/402/403
    ApiKeys.getUser: EndpointPolicy(
      successCodes: const {200},
      errorMessages: {
        401: (_) => 'Account is blocked',
        402: (_) => 'Invalid account',
        403: (_) => 'Account temporarily disabled',
      },
    ),

    ApiKeys.updateProfile: const EndpointPolicy(successCodes: {200, 204}),
    ApiKeys.uploadImage:   const EndpointPolicy(successCodes: {200, 201}),
    ApiKeys.downloadImage: const EndpointPolicy(),

    // Examples
    ApiKeys.postsGetById: const EndpointPolicy(successCodes: {200}),
    ApiKeys.postsCreate:  const EndpointPolicy(successCodes: {201, 200}),
  };

  static EndpointPolicy forKey(String key) => _policies[key] ?? const EndpointPolicy();
}

///EXAMPLE CALL
// somewhere in your UI (e.g., onPressed / onInit)
// final r = await repo.getUser(id: '1', useAuth: true);
//
// if (r.isOk) {
//   final user = r.data!;
//   // render/update state
//   setState(() { /* ... */ });
// } else {
//   final msg = r.error?.message ?? 'Something went wrong';
//
//   // Optional extras if you enabled body-codes on this endpoint later:
//   final bodyCode  = r.error?.meta?['bodyCode'];   // e.g., "301"
//   final httpRaw   = r.error?.meta?['httpStatus']; // e.g., 200 while effective is 403
//
//   // Branch on effective status (already mapped by client)
//   if (r.status >= 500) {
//     // server error (e.g., 500)
//     Get.snackbar('Server error', msg);
//   } else {
//     switch (r.status) {
//       case 401:
//         Get.snackbar('Blocked', msg);
//         break;
//       case 402:
//         Get.snackbar('Invalid account', msg);
//         break;
//       case 403:
//         // also covers body-code 301 → 403 if you configure that in policy
//         final details = bodyCode != null ? ' (code $bodyCode)' : '';
//         Get.snackbar('Temporarily disabled$details', msg);
//         break;
//       default:
//         Get.snackbar('Error', msg);
//     }
//   }
// }