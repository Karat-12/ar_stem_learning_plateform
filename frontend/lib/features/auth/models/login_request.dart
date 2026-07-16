/// Request model for login endpoint
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  /// Converts model to JSON for API request
  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }

  @override
  String toString() => 'LoginRequest(email: $email)';
}
