import 'package:controlzukis/core/providers/core_providers.dart';
import 'package:controlzukis/features/auth/data/auth_repository_impl.dart';
import 'package:controlzukis/features/auth/domain/models/login_input.dart';
import 'package:controlzukis/features/auth/domain/repositories/auth_repository.dart';
import 'package:controlzukis/features/auth/domain/usecases/login_usecase.dart';
import 'package:controlzukis/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(appDatabaseProvider));
});

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
);

final logoutUseCaseProvider = Provider<LogoutUseCase>(
  (ref) => LogoutUseCase(ref.watch(authRepositoryProvider)),
);

class AuthController {
  const AuthController(this._ref);

  final Ref _ref;

  Future<void> login(LoginInput input) =>
      _ref.read(loginUseCaseProvider)(input);

  Future<void> logout() => _ref.read(logoutUseCaseProvider)();
}

final authControllerProvider = Provider<AuthController>(AuthController.new);
