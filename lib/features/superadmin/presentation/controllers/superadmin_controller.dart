import 'package:controlzukis/core/guards/role_guard.dart';
import 'package:controlzukis/core/providers/core_providers.dart';
import 'package:controlzukis/core/services/device_service.dart';
import 'package:controlzukis/features/superadmin/data/superadmin_repository_impl.dart';
import 'package:controlzukis/features/superadmin/domain/models/backup_info.dart';
import 'package:controlzukis/features/superadmin/domain/models/superadmin_state_snapshot.dart';
import 'package:controlzukis/features/superadmin/domain/repositories/superadmin_repository.dart';
import 'package:controlzukis/features/superadmin/domain/usecases/create_backup_zip_usecase.dart';
import 'package:controlzukis/features/superadmin/domain/usecases/export_logs_usecase.dart';
import 'package:controlzukis/features/superadmin/domain/usecases/get_superadmin_snapshot_usecase.dart';
import 'package:controlzukis/features/superadmin/domain/usecases/reset_demo_usecase.dart';
import 'package:controlzukis/features/superadmin/domain/usecases/restore_backup_zip_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final superAdminRepositoryProvider = Provider<SuperAdminRepository>((ref) {
  return SuperAdminRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    roleGuard: RoleGuard(ref.watch(appDatabaseProvider)),
    deviceService: const DeviceService(),
  );
});

final getSuperAdminSnapshotUseCaseProvider =
    Provider<GetSuperAdminSnapshotUseCase>(
      (ref) =>
          GetSuperAdminSnapshotUseCase(ref.watch(superAdminRepositoryProvider)),
    );
final exportLogsUseCaseProvider = Provider<ExportLogsUseCase>(
  (ref) => ExportLogsUseCase(ref.watch(superAdminRepositoryProvider)),
);
final resetDemoUseCaseProvider = Provider<ResetDemoUseCase>(
  (ref) => ResetDemoUseCase(ref.watch(superAdminRepositoryProvider)),
);
final createBackupZipUseCaseProvider = Provider<CreateBackupZipUseCase>(
  (ref) => CreateBackupZipUseCase(ref.watch(superAdminRepositoryProvider)),
);
final restoreBackupZipUseCaseProvider = Provider<RestoreBackupZipUseCase>(
  (ref) => RestoreBackupZipUseCase(ref.watch(superAdminRepositoryProvider)),
);

class SuperAdminController {
  const SuperAdminController(this._ref);

  final Ref _ref;

  Future<SuperAdminStateSnapshot> fetch() {
    return _ref.read(getSuperAdminSnapshotUseCaseProvider)();
  }

  Future<String> exportLogs() {
    return _ref.read(exportLogsUseCaseProvider)();
  }

  Future<void> resetDemo() {
    return _ref.read(resetDemoUseCaseProvider)();
  }

  Future<BackupInfo> createBackupZip() {
    return _ref.read(createBackupZipUseCaseProvider)();
  }

  Future<void> restoreBackupZip(String path) {
    return _ref.read(restoreBackupZipUseCaseProvider)(path);
  }
}

final superAdminControllerProvider = Provider<SuperAdminController>(
  SuperAdminController.new,
);
