import 'package:controlzukis/features/auth/domain/models/login_input.dart';

abstract class AuthRepository {
  Future<void> login(LoginInput input);
  Future<void> logout();
}
