import 'package:controlzukis/features/settings/domain/repositories/settings_repository.dart';

class SetUserActiveUseCase {
  const SetUserActiveUseCase(this._repository);

  final SettingsRepository _repository;

  Future<void> call({required String userId, required bool isActive}) {
    return _repository.setUserActive(userId: userId, isActive: isActive);
  }
}
