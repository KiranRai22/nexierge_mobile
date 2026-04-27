/// JSON shape sent to `POST /auth/login/password_login`.
class EmailLoginRequestDto {
  final String email;
  final String password;
  final String deviceToken;

  const EmailLoginRequestDto({
    required this.email,
    required this.password,
    required this.deviceToken,
  });

  Map<String, dynamic> toJson() {
    final json = {'email': email, 'password': password};
    if (deviceToken.isNotEmpty) {
      json['device_token'] = deviceToken;
    }
    return json;
  }
}

/// JSON shape sent to `POST /auth/login/code_login`.
class CodeLoginRequestDto {
  final String employeeCode;
  final String loginCode;
  final String deviceToken;

  const CodeLoginRequestDto({
    required this.employeeCode,
    required this.loginCode,
    required this.deviceToken,
  });

  Map<String, dynamic> toJson() {
    final json = {'employee_code': employeeCode, 'login_code': loginCode};
    if (deviceToken.isNotEmpty) {
      json['device_token'] = deviceToken;
    }
    return json;
  }
}
