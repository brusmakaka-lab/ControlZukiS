import 'package:controlzukis/app/router/routing_snapshot.dart';
import 'package:controlzukis/core/config/app_env.dart';
import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/models/license_status.dart';
import 'package:controlzukis/core/services/device_service.dart';
import 'package:controlzukis/features/bootstrap/data/bootstrap_repository_impl.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('routing guards bootstrap', () {
    late AppDatabase db;
    late BootstrapRepositoryImpl bootstrap;

    setUp(() async {
      db = AppDatabase();
      await db.delete(db.appMetas).go();
      bootstrap = BootstrapRepositoryImpl(
        database: db,
        deviceService: const DeviceService(),
      );
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('db vacía => onboarding', (tester) async {
      final snapshot = await bootstrap.initialize();
      expect(snapshot.phase, AppRoutePhase.onboarding);
    });

    testWidgets(
      'tenant sin sesión => ready + hasSession false (router debe mandar login)',
      (tester) async {
        final now = DateTime.now();
        await db.upsertAppMeta(
          AppMetasCompanion.insert(
            id: 'meta-1',
            installedAt: now,
            trialEndsAt: now.add(const Duration(days: AppEnv.trialDays)),
            lastSeenAt: now,
            licenseStatus: LicenseStatus.trial.dbValue,
            currentTenantId: const Value('t1'),
            currentBranchId: const Value('b1'),
            currentUserId: const Value('u1'),
            sessionActive: const Value(false),
            businessType: const Value('ferreteria'),
            maintenanceMode: const Value(false),
          ),
        );
        final snapshot = await bootstrap.initialize();
        expect(snapshot.phase, AppRoutePhase.ready);
        expect(snapshot.hasSession, false);
      },
    );

    testWidgets('tamper => activation obligatoria', (tester) async {
      final now = DateTime.now();
      await db.upsertAppMeta(
        AppMetasCompanion.insert(
          id: 'meta-2',
          installedAt: now.subtract(const Duration(days: 1)),
          trialEndsAt: now.add(const Duration(days: 10)),
          lastSeenAt: now.add(const Duration(days: 1)),
          licenseStatus: LicenseStatus.trial.dbValue,
          currentTenantId: const Value('t1'),
          currentBranchId: const Value('b1'),
          currentUserId: const Value('u1'),
          sessionActive: const Value(true),
          businessType: const Value('ferreteria'),
          maintenanceMode: const Value(false),
        ),
      );
      final snapshot = await bootstrap.initialize();
      expect(snapshot.phase, AppRoutePhase.activation);
      expect(snapshot.licenseStatus, LicenseStatus.tamper);
    });

    testWidgets('expired => read-only', (tester) async {
      final now = DateTime.now();
      await db.upsertAppMeta(
        AppMetasCompanion.insert(
          id: 'meta-3',
          installedAt: now.subtract(const Duration(days: 30)),
          trialEndsAt: now.subtract(const Duration(days: 1)),
          lastSeenAt: now,
          licenseStatus: LicenseStatus.trial.dbValue,
          currentTenantId: const Value('t1'),
          currentBranchId: const Value('b1'),
          currentUserId: const Value('u1'),
          sessionActive: const Value(true),
          businessType: const Value('ferreteria'),
          maintenanceMode: const Value(false),
        ),
      );
      final snapshot = await bootstrap.initialize();
      expect(snapshot.licenseStatus, LicenseStatus.expired);
      expect(snapshot.isReadOnly, true);
    });
  });
}
