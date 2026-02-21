import 'package:controlzukis/core/guards/license_write_guard.dart';
import 'package:controlzukis/core/guards/role_guard.dart';
import 'package:controlzukis/core/guards/write_access_service.dart';
import 'package:controlzukis/core/providers/core_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final roleGuardProvider = Provider<RoleGuard>((ref) {
  return RoleGuard(ref.watch(appDatabaseProvider));
});

final licenseWriteGuardProvider = Provider<LicenseWriteGuard>((ref) {
  return LicenseWriteGuard(ref.watch(appDatabaseProvider));
});

final writeAccessServiceProvider = Provider<WriteAccessService>((ref) {
  return WriteAccessService(
    roleGuard: ref.watch(roleGuardProvider),
    licenseGuard: ref.watch(licenseWriteGuardProvider),
  );
});
