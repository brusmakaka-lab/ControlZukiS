import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/guards/license_write_guard.dart';
import 'package:controlzukis/core/models/license_status.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('license write enforcement', () {
    late AppDatabase db;
    late LicenseWriteGuard guard;

    setUp(() async {
      db = AppDatabase();
      await db.delete(db.appMetas).go();
      guard = LicenseWriteGuard(db);
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('expired bloquea escritura en lógica', (tester) async {
      final now = DateTime.now();
      await db.upsertAppMeta(
        AppMetasCompanion.insert(
          id: 'meta-expired',
          installedAt: now.subtract(const Duration(days: 20)),
          trialEndsAt: now.subtract(const Duration(days: 1)),
          lastSeenAt: now,
          licenseStatus: LicenseStatus.expired.dbValue,
          currentTenantId: const Value('t1'),
          currentBranchId: const Value('b1'),
          currentUserId: const Value('u1'),
          sessionActive: const Value(true),
          businessType: const Value('ferreteria'),
          maintenanceMode: const Value(false),
        ),
      );

      final result = await guard.canWrite();
      expect(result.allowed, false);
    });

    testWidgets('maintenance bloquea escritura en lógica', (tester) async {
      final now = DateTime.now();
      await db.upsertAppMeta(
        AppMetasCompanion.insert(
          id: 'meta-maintenance',
          installedAt: now,
          trialEndsAt: now.add(const Duration(days: 10)),
          lastSeenAt: now,
          licenseStatus: LicenseStatus.active.dbValue,
          currentTenantId: const Value('t1'),
          currentBranchId: const Value('b1'),
          currentUserId: const Value('u1'),
          sessionActive: const Value(true),
          businessType: const Value('ferreteria'),
          maintenanceMode: const Value(true),
        ),
      );

      final result = await guard.canWrite();
      expect(result.allowed, false);
    });
  });
}
