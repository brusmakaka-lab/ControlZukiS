import 'package:controlzukis/core/guards/guard_result.dart';
import 'package:controlzukis/core/guards/license_write_guard.dart';
import 'package:controlzukis/core/guards/role_guard.dart';

class WriteAccessService {
  const WriteAccessService({
    required RoleGuard roleGuard,
    required LicenseWriteGuard licenseGuard,
  }) : _roleGuard = roleGuard,
       _licenseGuard = licenseGuard;

  final RoleGuard _roleGuard;
  final LicenseWriteGuard _licenseGuard;

  Future<GuardResult> ensure({required List<String> roles}) async {
    final licenseResult = await _licenseGuard.canWrite();
    if (!licenseResult.allowed) return licenseResult;

    final roleResult = await _roleGuard.canWrite(allowedRoles: roles);
    if (!roleResult.allowed) return roleResult;

    return const GuardResult.allow();
  }
}
