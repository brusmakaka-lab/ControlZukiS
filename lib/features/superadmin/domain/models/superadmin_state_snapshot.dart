import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/features/superadmin/domain/models/superadmin_diagnostics.dart';

class SuperAdminStateSnapshot {
  const SuperAdminStateSnapshot({
    required this.logs,
    required this.licenseAudits,
    required this.diagnostics,
  });

  final List<ActivityLog> logs;
  final List<LicenseAudit> licenseAudits;
  final SuperAdminDiagnostics diagnostics;
}
