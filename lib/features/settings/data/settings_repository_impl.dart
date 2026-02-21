import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/guards/write_access_service.dart';
import 'package:controlzukis/features/settings/domain/models/company_profile_input.dart';
import 'package:controlzukis/features/settings/domain/models/settings_snapshot.dart';
import 'package:controlzukis/features/settings/domain/models/user_input.dart';
import 'package:controlzukis/features/settings/domain/repositories/settings_repository.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({
    required AppDatabase db,
    required WriteAccessService writeAccess,
  }) : _db = db,
       _writeAccess = writeAccess;

  final AppDatabase _db;
  final WriteAccessService _writeAccess;
  final Uuid _uuid = const Uuid();

  Future<AppMeta> _meta() async {
    final meta = await _db.getAppMeta();
    if (meta == null) {
      throw StateError('Metadatos no inicializados');
    }
    return meta;
  }

  Future<(String tenantId, String branchId)> _ctx() async {
    final meta = await _meta();
    final tenantId = meta.currentTenantId;
    final branchId = meta.currentBranchId;
    if (tenantId == null || branchId == null) {
      throw StateError('Tenant/sucursal no configurados');
    }
    return (tenantId, branchId);
  }

  Future<void> _updateMeta(AppMeta meta, {bool? allowNegativeStock}) async {
    await _db.upsertAppMeta(
      AppMetasCompanion(
        id: Value(meta.id),
        installedAt: Value(meta.installedAt),
        trialEndsAt: Value(meta.trialEndsAt),
        lastSeenAt: Value(meta.lastSeenAt),
        licenseStatus: Value(meta.licenseStatus),
        demoMode: Value(meta.demoMode),
        currentTenantId: Value(meta.currentTenantId),
        currentBranchId: Value(meta.currentBranchId),
        currentUserId: Value(meta.currentUserId),
        sessionActive: Value(meta.sessionActive),
        businessType: Value(meta.businessType),
        maintenanceMode: Value(meta.maintenanceMode),
        allowNegativeStock: Value(
          allowNegativeStock ?? meta.allowNegativeStock,
        ),
        schemaVersion: Value(meta.schemaVersion),
        createdAt: Value(meta.createdAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<SettingsSnapshot> getSnapshot() async {
    final meta = await _meta();
    final tenantId = meta.currentTenantId;
    if (tenantId == null) {
      throw StateError('Tenant no configurado');
    }

    final tenant = await (_db.select(
      _db.tenants,
    )..where((t) => t.id.equals(tenantId))).getSingle();
    final users =
        await (_db.select(_db.users)
              ..where((u) => u.tenantId.equals(tenantId))
              ..orderBy([(u) => OrderingTerm.asc(u.createdAt)]))
            .get();

    return SettingsSnapshot(tenant: tenant, meta: meta, users: users);
  }

  @override
  Future<void> updateCompanyProfile(CompanyProfileInput input) async {
    final guard = await _writeAccess.ensure(
      roles: const ['SUPER_ADMIN', 'ADMIN'],
    );
    if (!guard.allowed) throw StateError(guard.reason!);

    final (tenantId, _) = await _ctx();
    await (_db.update(_db.tenants)..where((t) => t.id.equals(tenantId))).write(
      TenantsCompanion(
        name: Value(input.name),
        legalName: Value(input.legalName),
        taxId: Value(input.taxId),
        email: Value(input.email),
        phone: Value(input.phone),
        address: Value(input.address),
      ),
    );
  }

  @override
  Future<void> setAllowNegativeStock(bool enabled) async {
    final guard = await _writeAccess.ensure(
      roles: const ['SUPER_ADMIN', 'ADMIN'],
    );
    if (!guard.allowed) throw StateError(guard.reason!);

    final meta = await _meta();
    await _updateMeta(meta, allowNegativeStock: enabled);
  }

  @override
  Future<void> createUser(UserInput input) async {
    final guard = await _writeAccess.ensure(
      roles: const ['SUPER_ADMIN', 'ADMIN'],
    );
    if (!guard.allowed) throw StateError(guard.reason!);

    final (tenantId, branchId) = await _ctx();
    await _db
        .into(_db.users)
        .insert(
          UsersCompanion.insert(
            id: _uuid.v4(),
            tenantId: tenantId,
            branchId: branchId,
            name: input.name,
            email: input.email,
            role: input.role,
            passwordHash: input.password,
          ),
        );
  }

  @override
  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    final guard = await _writeAccess.ensure(roles: const ['SUPER_ADMIN']);
    if (!guard.allowed) throw StateError(guard.reason!);

    await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(role: Value(role)),
    );
  }

  @override
  Future<void> setUserActive({
    required String userId,
    required bool isActive,
  }) async {
    final guard = await _writeAccess.ensure(
      roles: const ['SUPER_ADMIN', 'ADMIN'],
    );
    if (!guard.allowed) throw StateError(guard.reason!);

    await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(isActive: Value(isActive)),
    );
  }

  @override
  Future<void> logout() async {
    final meta = await _meta();
    await _db.upsertAppMeta(
      AppMetasCompanion(
        id: Value(meta.id),
        installedAt: Value(meta.installedAt),
        trialEndsAt: Value(meta.trialEndsAt),
        lastSeenAt: Value(DateTime.now()),
        licenseStatus: Value(meta.licenseStatus),
        demoMode: Value(meta.demoMode),
        currentTenantId: Value(meta.currentTenantId),
        currentBranchId: Value(meta.currentBranchId),
        currentUserId: const Value.absent(),
        sessionActive: const Value(false),
        businessType: Value(meta.businessType),
        maintenanceMode: Value(meta.maintenanceMode),
        allowNegativeStock: Value(meta.allowNegativeStock),
        schemaVersion: Value(meta.schemaVersion),
        createdAt: Value(meta.createdAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
