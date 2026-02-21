import 'package:controlzukis/features/superadmin/domain/models/superadmin_state_snapshot.dart';
import 'package:controlzukis/features/superadmin/domain/models/backup_info.dart';

abstract class SuperAdminRepository {
  Future<SuperAdminStateSnapshot> getSnapshot();
  Future<String> exportLogs();
  Future<void> resetDemo();
  Future<BackupInfo> createBackupZip();
  Future<void> restoreBackupZip(String zipPath);
}
