// lib/core/api_policy.dart
typedef ErrorMessageFn = String Function(dynamic json);

class EndpointPolicy {
  // HTTP status handling
  final Set<int> successCodes;               // empty => any 2xx
  final Map<int, ErrorMessageFn> errorMessages;

  // In-body business-code handling (opt-in)
  final bool useBodyCodes;                   // if true, read code/message from body
  final String bodyCodeKey;                  // e.g. 'responseCode'
  final String bodyMessageKey;               // e.g. 'message'
  final Set<String> bodySuccessCodes;        // empty => {0,200,OK,SUCCESS}
  final Map<String, int> bodyCodeToHttpStatus;
  final Map<String, ErrorMessageFn> bodyCodeMessages;

  const EndpointPolicy({
    this.successCodes = const {},
    this.errorMessages = const {},
    this.useBodyCodes = false,
    this.bodyCodeKey = 'responseCode',
    this.bodyMessageKey = 'message',
    this.bodySuccessCodes = const {},
    this.bodyCodeToHttpStatus = const {},
    this.bodyCodeMessages = const {},
  });

  // HTTP-only check
  bool isSuccess(int status) =>
      successCodes.isEmpty ? (status >= 200 && status < 300) : successCodes.contains(status);

  String messageFor(int status, dynamic json) {
    final fn = errorMessages[status];
    if (fn != null) return fn(json);
    if (json is Map) {
      final m = json['message'] ?? json['error'] ?? json['detail'];
      if (m != null) return m.toString();
    }
    if (json is String) return json;
    return 'Request failed ($status)';
  }

  // Body-code helpers
  bool bodyCodeIsSuccess(String code) {
    final defaults = {'0', '200', 'OK', 'SUCCESS'};
    final allow = bodySuccessCodes.isEmpty ? defaults : bodySuccessCodes.map((e)=>e.toUpperCase()).toSet();
    return allow.contains(code.toUpperCase());
  }

  int statusForBodyCode(String code, int fallbackHttpStatus) {
    return bodyCodeToHttpStatus[code] ?? fallbackHttpStatus;
  }

  String messageForBodyCode(String code, dynamic json) {
    final fn = bodyCodeMessages[code];
    if (fn != null) return fn(json);
    if (json is Map) {
      final m = json[bodyMessageKey] ?? json['message'] ?? json['error'] ?? json['detail'];
      if (m != null) return m.toString();
    }
    if (json is String) return json;
    return 'Request failed (code $code)';
  }
}