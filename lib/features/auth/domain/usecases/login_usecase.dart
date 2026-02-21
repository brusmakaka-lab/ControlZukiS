import 'package:controlzukis/features/auth/domain/models/login_input.dart';
import 'package:controlzukis/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(LoginInput input) => _repository.login(input);
}
