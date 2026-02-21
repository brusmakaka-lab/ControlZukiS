import 'package:controlzukis/features/settings/domain/repositories/settings_repository.dart';

class SetAllowNegativeStockUseCase {
  const SetAllowNegativeStockUseCase(this._repository);

  final SettingsRepository _repository;

  Future<void> call(bool enabled) => _repository.setAllowNegativeStock(enabled);
}
