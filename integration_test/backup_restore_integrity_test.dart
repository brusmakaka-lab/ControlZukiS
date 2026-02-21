import 'dart:io';

import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/guards/role_guard.dart';
import 'package:controlzukis/core/models/license_status.dart';
import 'package:controlzukis/core/services/device_service.dart';
import 'package:controlzukis/features/superadmin/data/superadmin_repository_impl.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('backup restore integrity', () {
    late AppDatabase db;
    late SuperAdminRepositoryImpl repo;

    setUp(() async {
      db = AppDatabase();
      await db.customStatement('PRAGMA foreign_keys = OFF');
      await db.customStatement('DELETE FROM sale_items');
      await db.customStatement('DELETE FROM sales');
      await db.customStatement('DELETE FROM product_custom_field_values');
      await db.customStatement('DELETE FROM product_images');
      await db.customStatement('DELETE FROM products');
      await db.customStatement('DELETE FROM customers');
      await db.customStatement('DELETE FROM expenses');
      await db.customStatement('DELETE FROM users');
      await db.customStatement('DELETE FROM branches');
      await db.customStatement('DELETE FROM categories');
      await db.customStatement('DELETE FROM tenants');
      await db.customStatement('DELETE FROM app_metas');
      await db.customStatement('DELETE FROM activity_logs');
      await db.customStatement('DELETE FROM license_audits');
      await db.customStatement('PRAGMA foreign_keys = ON');
      await db.delete(db.appMetas).go();
      repo = SuperAdminRepositoryImpl(
        db: db,
        roleGuard: RoleGuard(db),
        deviceService: const DeviceService(),
      );
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('backup generado + restore corrupto rechazado', (tester) async {
      final now = DateTime.now();
      await db.upsertAppMeta(
        AppMetasCompanion.insert(
          id: 'meta-backup',
          installedAt: now,
          trialEndsAt: now.add(const Duration(days: 10)),
          lastSeenAt: now,
          licenseStatus: LicenseStatus.active.dbValue,
          currentTenantId: const Value('t1'),
          currentBranchId: const Value('b1'),
          currentUserId: const Value('u1'),
          sessionActive: const Value(true),
          businessType: const Value('ferreteria'),
          maintenanceMode: const Value(false),
        ),
      );
      await db
          .into(db.tenants)
          .insert(TenantsCompanion.insert(id: 't1', name: 'T1'));
      await db
          .into(db.branches)
          .insert(
            BranchesCompanion.insert(id: 'b1', tenantId: 't1', name: 'B1'),
          );
      await db
          .into(db.users)
          .insert(
            UsersCompanion.insert(
              id: 'u1',
              tenantId: 't1',
              branchId: 'b1',
              name: 'Root',
              email: 'root@test.com',
              role: 'SUPER_ADMIN',
              passwordHash: 'x',
            ),
          );

      final backup = await repo.createBackupZip();

      final original = File(backup.filePath);
      final bytes = await original.readAsBytes();
      bytes[bytes.length ~/ 2] = (bytes[bytes.length ~/ 2] + 1) % 255;
      final corrupt = File('${backup.filePath}.corrupt.zip');
      await corrupt.writeAsBytes(bytes, flush: true);

      Object? error;
      try {
        await repo.restoreBackupZip(corrupt.path);
      } catch (e) {
        error = e;
      }
      expect(error != null, true);
      await corrupt.delete();
    });
  });
}
