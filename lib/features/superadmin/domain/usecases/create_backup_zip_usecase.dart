import 'package:controlzukis/features/superadmin/domain/models/backup_info.dart';
import 'package:controlzukis/features/superadmin/domain/repositories/superadmin_repository.dart';

class CreateBackupZipUseCase {
  const CreateBackupZipUseCase(this._repository);

  final SuperAdminRepository _repository;

  Future<BackupInfo> call() => _repository.createBackupZip();
}
