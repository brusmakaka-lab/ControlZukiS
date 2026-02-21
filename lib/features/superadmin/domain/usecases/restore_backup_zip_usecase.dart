import 'package:controlzukis/features/superadmin/domain/repositories/superadmin_repository.dart';

class RestoreBackupZipUseCase {
  const RestoreBackupZipUseCase(this._repository);

  final SuperAdminRepository _repository;

  Future<void> call(String zipPath) => _repository.restoreBackupZip(zipPath);
}
