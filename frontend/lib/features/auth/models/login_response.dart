import 'current_user.dart';

/// Response model for login endpoint
class LoginResponse {
  final String token;
  final String tokenType;
  final CurrentUser? user;

  LoginResponse({required this.token, required this.tokenType, this.user});

  /// Creates instance from JSON response
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];

    return LoginResponse(
      token: json['token']?.toString() ?? '',
      tokenType: json['tokenType']?.toString() ?? 'Bearer',
      user: userJson is Map
          ? CurrentUser.fromJson(Map<String, dynamic>.from(userJson))
          : null,
    );
  }

  /// Converts model to JSON
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'tokenType': tokenType,
      if (user != null) 'user': user!.toJson(),
    };
  }

  @override
  String toString() => 'LoginResponse(token: $token, tokenType: $tokenType)';
}
