import 'package:controlzukis/features/settings/domain/models/settings_snapshot.dart';
import 'package:controlzukis/features/settings/domain/repositories/settings_repository.dart';

class GetSettingsSnapshotUseCase {
  const GetSettingsSnapshotUseCase(this._repository);

  final SettingsRepository _repository;

  Future<SettingsSnapshot> call() => _repository.getSnapshot();
}
