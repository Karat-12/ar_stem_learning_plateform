import 'package:flutter_test/flutter_test.dart';
import 'package:ar_stem_learning_prototype/features/auth/models/current_user.dart';
import 'package:ar_stem_learning_prototype/features/auth/models/login_response.dart';

void main() {
  group('auth contract parsing', () {
    test('LoginResponse parses backend token payload', () {
      final response = LoginResponse.fromJson({
        'token': 'abc123',
        'tokenType': 'Bearer',
      });

      expect(response.token, 'abc123');
      expect(response.tokenType, 'Bearer');
    });

    test('CurrentUser parses backend profile payload', () {
      final user = CurrentUser.fromJson({
        'id': 'user-1',
        'displayName': 'Ada Lovelace',
        'email': 'ada@example.com',
        'roles': ['STUDENT'],
        'status': 'ACTIVE',
      });

      expect(user.id, 'user-1');
      expect(user.displayName, 'Ada Lovelace');
      expect(user.fullName, 'Ada Lovelace');
      expect(user.email, 'ada@example.com');
      expect(user.roles, contains('STUDENT'));
      expect(user.status, 'ACTIVE');
    });
  });
}
