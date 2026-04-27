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

/// JSON shape sent to `POST /auth/login/code_login`.
class CodeLoginRequestDto {
  final String employeeCode;
  final String loginCode;
  final String fcm_token; // Optional FCM token for push notifications  

  const CodeLoginRequestDto({
    required this.employeeCode,
    required this.loginCode,
    required this.fcm_token,
  });

  Map<String, dynamic> toJson() {
    final json = {'employee_code': employeeCode, 'login_code': loginCode};
    if (fcm_token.isNotEmpty) {
      json['fcm_token'] = fcm_token;
    }
    return json;
  }
}
