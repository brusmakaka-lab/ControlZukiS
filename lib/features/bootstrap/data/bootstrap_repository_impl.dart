import 'package:controlzukis/app/router/routing_snapshot.dart';
import 'package:controlzukis/core/config/app_env.dart';
import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/logging/app_logger.dart';
import 'package:controlzukis/core/models/license_status.dart';
import 'package:controlzukis/core/services/device_service.dart';
import 'package:drift/drift.dart';
import 'package:controlzukis/features/bootstrap/domain/repositories/bootstrap_repository.dart';
import 'package:uuid/uuid.dart';

class BootstrapRepositoryImpl implements BootstrapRepository {
  BootstrapRepositoryImpl({
    required AppDatabase database,
    required DeviceService deviceService,
  }) : _database = database,
       _deviceService = deviceService;

  final AppDatabase _database;
  final DeviceService _deviceService;
  final Uuid _uuid = const Uuid();

  @override
  Future<RoutingSnapshot> initialize() async {
    final now = DateTime.now();
    final meta = await _database.getAppMeta();

    if (meta == null) {
      final trialEndsAt = now.add(const Duration(days: AppEnv.trialDays));
      await _database.upsertAppMeta(
        AppMetasCompanion.insert(
          id: _uuid.v4(),
          installedAt: now,
          trialEndsAt: trialEndsAt,
          lastSeenAt: now,
          licenseStatus: LicenseStatus.trial.dbValue,
          demoMode: const Value(false),
          currentTenantId: const Value.absent(),
          currentBranchId: const Value.absent(),
          currentUserId: const Value.absent(),
          sessionActive: const Value(false),
          businessType: const Value.absent(),
          maintenanceMode: const Value(false),
        ),
      );

      AppLogger.log(
        LogLevel.info,
        'Trial inicializado en primer arranque',
        extra: {'trialEndsAt': trialEndsAt.toIso8601String()},
      );

      return RoutingSnapshot(
        phase: AppRoutePhase.onboarding,
        licenseStatus: LicenseStatus.trial,
        daysRemaining: AppEnv.trialDays,
        hasSession: false,
        maintenanceMode: false,
      );
    }

    final antiTamperDetected = now.isBefore(meta.lastSeenAt);
    final effectiveStatus = antiTamperDetected
        ? LicenseStatus.tamper
        : LicenseStatusX.fromDb(meta.licenseStatus);

    final expiredByDate =
        effectiveStatus == LicenseStatus.trial && now.isAfter(meta.trialEndsAt);

    final status = antiTamperDetected
        ? LicenseStatus.tamper
        : (expiredByDate ? LicenseStatus.expired : effectiveStatus);

    await _database.upsertAppMeta(
      AppMetasCompanion(
        id: Value(meta.id),
        installedAt: Value(meta.installedAt),
        trialEndsAt: Value(meta.trialEndsAt),
        lastSeenAt: Value(now),
        licenseStatus: Value(status.dbValue),
        demoMode: Value(meta.demoMode),
        currentTenantId: Value(meta.currentTenantId),
        currentBranchId: Value(meta.currentBranchId),
        currentUserId: Value(meta.currentUserId),
        sessionActive: Value(meta.sessionActive),
        businessType: Value(meta.businessType),
        maintenanceMode: Value(meta.maintenanceMode),
        allowNegativeStock: Value(meta.allowNegativeStock),
        schemaVersion: Value(meta.schemaVersion),
        createdAt: Value(meta.createdAt),
        updatedAt: Value(now),
      ),
    );

    final daysRemaining = meta.trialEndsAt.difference(now).inDays;
    final hasTenant =
        meta.currentTenantId != null && meta.currentTenantId!.isNotEmpty;
    final phase = switch (status) {
      LicenseStatus.tamper => AppRoutePhase.activation,
      _ => hasTenant ? AppRoutePhase.ready : AppRoutePhase.onboarding,
    };
    final hasSession =
        hasTenant && (meta.sessionActive && meta.currentUserId != null);

    if (antiTamperDetected) {
      final deviceId = await _deviceService.getDeviceId();
      await _database.writeLicenseAudit(
        LicenseAuditsCompanion.insert(
          id: _uuid.v4(),
          tenantId: Value(meta.currentTenantId),
          deviceId: deviceId,
          action: 'ANTI_TAMPER_DETECTED',
          statusBefore: Value(meta.licenseStatus),
          statusAfter: Value(LicenseStatus.tamper.dbValue),
          keyMasked: const Value.absent(),
          payloadJson: Value('{"reason":"clock_rollback"}'),
        ),
      );
    }

    return RoutingSnapshot(
      phase: phase,
      licenseStatus: status,
      daysRemaining: daysRemaining < 0 ? 0 : daysRemaining,
      hasSession: hasSession,
      maintenanceMode: meta.maintenanceMode,
    );
  }
}
