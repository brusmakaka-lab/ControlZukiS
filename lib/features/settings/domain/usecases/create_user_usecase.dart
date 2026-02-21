import 'package:controlzukis/features/settings/domain/models/user_input.dart';
import 'package:controlzukis/features/settings/domain/repositories/settings_repository.dart';

class CreateUserUseCase {
  const CreateUserUseCase(this._repository);

  final SettingsRepository _repository;

  Future<void> call(UserInput input) => _repository.createUser(input);
}
