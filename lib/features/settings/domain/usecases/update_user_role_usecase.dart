import 'package:controlzukis/features/settings/domain/repositories/settings_repository.dart';

class UpdateUserRoleUseCase {
  const UpdateUserRoleUseCase(this._repository);

  final SettingsRepository _repository;

  Future<void> call({required String userId, required String role}) {
    return _repository.updateUserRole(userId: userId, role: role);
  }
}
