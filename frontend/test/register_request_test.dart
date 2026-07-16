import 'package:flutter_test/flutter_test.dart';
import 'package:ar_stem_learning_prototype/features/auth/models/register_request.dart';

void main() {
  test('RegisterRequest serializes displayName, email and password', () {
    final request = RegisterRequest(
      displayName: 'Ada Lovelace',
      email: 'ada@example.com',
      password: 'secret123',
    );

    expect(request.toJson(), {
      'displayName': 'Ada Lovelace',
      'email': 'ada@example.com',
      'password': 'secret123',
    });
  });
}
