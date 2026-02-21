import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/models/license_status.dart';
import 'package:controlzukis/core/providers/core_providers.dart';
import 'package:controlzukis/core/services/device_service.dart';
import 'package:controlzukis/features/license/domain/services/license_codec.dart';
import 'package:controlzukis/features/license/domain/services/license_crypto_service.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final licenseCryptoProvider = Provider<LicenseCryptoService>(
  (ref) => const LicenseCryptoService(),
);
final licenseCodecProvider = Provider<LicenseCodec>(
  (ref) => LicenseCodec(ref.watch(licenseCryptoProvider)),
);

final licenseControllerProvider = Provider<LicenseController>((ref) {
  return LicenseController(
    db: ref.watch(appDatabaseProvider),
    codec: ref.watch(licenseCodecProvider),
    deviceService: const DeviceService(),
  );
});

class LicenseController {
  LicenseController({
    required AppDatabase db,
    required LicenseCodec codec,
    required DeviceService deviceService,
  }) : _db = db,
       _codec = codec,
       _deviceService = deviceService;

  final AppDatabase _db;
  final LicenseCodec _codec;
  final DeviceService _deviceService;
  final Uuid _uuid = const Uuid();

  Future<String> getDeviceId() => _deviceService.getDeviceId();

  Future<bool> activateOfflineKey(String rawKey) async {
    final payload = _codec.decodeAndVerify(rawKey.trim());
    if (payload == null) return false;

    final deviceId = await _deviceService.getDeviceId();
    if (payload.deviceId != deviceId) return false;
    if (payload.expiresAt != null &&
        DateTime.now().isAfter(payload.expiresAt!)) {
      return false;
    }

    final meta = await _db.getAppMeta();
    if (meta == null) return false;

    await _db.upsertAppMeta(
      AppMetasCompanion(
        id: Value(meta.id),
        installedAt: Value(meta.installedAt),
        trialEndsAt: Value(meta.trialEndsAt),
        lastSeenAt: Value(DateTime.now()),
        licenseStatus: Value(LicenseStatus.active.dbValue),
        demoMode: Value(meta.demoMode),
        currentTenantId: Value(payload.tenantId),
        currentBranchId: Value(meta.currentBranchId),
        currentUserId: Value(meta.currentUserId),
        sessionActive: Value(meta.sessionActive),
        businessType: Value(meta.businessType),
        maintenanceMode: Value(meta.maintenanceMode),
        allowNegativeStock: Value(meta.allowNegativeStock),
        schemaVersion: Value(meta.schemaVersion),
        createdAt: Value(meta.createdAt),
        updatedAt: Value(DateTime.now()),
      ),
    );

    await _db.writeLicenseAudit(
      LicenseAuditsCompanion.insert(
        id: _uuid.v4(),
        tenantId: Value(payload.tenantId),
        deviceId: deviceId,
        action: 'ACTIVATION',
        statusBefore: Value(meta.licenseStatus),
        statusAfter: Value(LicenseStatus.active.dbValue),
        keyMasked: Value(_mask(rawKey)),
        payloadJson: Value(payload.toJson().toString()),
      ),
    );

    return true;
  }

  String _mask(String key) {
    final trimmed = key.trim();
    if (trimmed.length <= 10) return '***';
    return '${trimmed.substring(0, 6)}***${trimmed.substring(trimmed.length - 4)}';
  }
}
