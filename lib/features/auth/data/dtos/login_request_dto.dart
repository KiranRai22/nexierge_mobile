/// JSON shape sent to `POST /auth/login/password_login`.
class EmailLoginRequestDto {
  final String email;
  final String password;
  final String fcm_token; // Optional FCM token for push notifications

  const EmailLoginRequestDto({
    required this.email,
    required this.password,
    required this.fcm_token,
  });

  Map<String, dynamic> toJson() {
    final json = {'email': email, 'password': password};
    if (fcm_token.isNotEmpty) {
      json['fcm_token'] = fcm_token;
    }
    return json;
  }
}

/// JSON shape sent to `POST /auth/login/code`.
class CodeLoginRequestDto {
  final String employee_code;
  final String code;
  final String fcm_token; // Optional FCM token for push notifications

  const CodeLoginRequestDto({
    required this.employee_code,
    required this.code,
    required this.fcm_token,
  });

  Map<String, dynamic> toJson() {
    final json = {'employee_code': employee_code, 'code': code};
    if (fcm_token.isNotEmpty) {
      json['fcm_token'] = fcm_token;
    }
    return json;
  }
}
