/// Model representing the currently authenticated user
class CurrentUser {
  final String id;
  final String email;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? profilePictureUrl;
  final List<String> roles;
  final String? status;
  final DateTime? createdAt;

  CurrentUser({
    required this.id,
    required this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.profilePictureUrl,
    this.roles = const [],
    this.status,
    this.createdAt,
  });

  /// Full name of the user
  String get fullName {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) return firstName!;
    if (lastName != null) return lastName!;
    return email;
  }

  /// Creates instance from JSON response
  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    final roles = json['roles'];

    return CurrentUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      displayName: (json['displayName'] ?? json['fullName'])?.toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      profilePictureUrl: json['profilePictureUrl']?.toString(),
      roles: roles is List
          ? roles.map((role) => role.toString()).toList()
          : const [],
      status: json['status']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  /// Converts model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'profilePictureUrl': profilePictureUrl,
      'roles': roles,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'CurrentUser(id: $id, email: $email, fullName: $fullName)';
}
