import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/guards/guard_result.dart';
import 'package:controlzukis/core/models/license_status.dart';
import 'package:controlzukis/core/storage/app_paths.dart';

class LicenseWriteGuard {
  const LicenseWriteGuard(this._db);

  final AppDatabase _db;

  Future<GuardResult> canWrite() async {
    final meta = await _db.getAppMeta();
    if (meta == null) {
      return const GuardResult.deny('App meta inexistente');
    }

    final maintenanceFlag = await AppPaths.maintenanceFlagFile();
    if (meta.maintenanceMode || maintenanceFlag.existsSync()) {
      return const GuardResult.deny('Modo mantenimiento activo');
    }

    final status = LicenseStatusX.fromDb(meta.licenseStatus);
    if (status == LicenseStatus.expired || status == LicenseStatus.tamper) {
      return const GuardResult.deny('Licencia en modo solo lectura');
    }

    return const GuardResult.allow();
  }
}
