import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/utils/password_hasher.dart';
import 'package:controlzukis/features/auth/domain/models/login_input.dart';
import 'package:controlzukis/features/auth/domain/repositories/auth_repository.dart';
import 'package:drift/drift.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<void> login(LoginInput input) async {
    final meta = await _db.getAppMeta();
    if (meta == null) throw StateError('App meta no inicializada');

    final tenantId = meta.currentTenantId;
    if (tenantId == null) {
      throw StateError('Onboarding incompleto');
    }

    final normalizedEmail = input.email.trim().toLowerCase();
    final user =
        await (_db.select(_db.users)
              ..where(
                (u) =>
                    u.tenantId.equals(tenantId) &
                    u.email.lower().equals(normalizedEmail),
              )
              ..limit(1))
            .getSingleOrNull();

    if (user == null) {
      throw StateError('Usuario o contraseña inválidos');
    }
    if (!user.isActive) {
      throw StateError('Usuario inactivo');
    }
    if (!PasswordHasher.verify(input.password, user.passwordHash)) {
      throw StateError('Usuario o contraseña inválidos');
    }

    await _db.upsertAppMeta(
      AppMetasCompanion(
        id: Value(meta.id),
        installedAt: Value(meta.installedAt),
        trialEndsAt: Value(meta.trialEndsAt),
        lastSeenAt: Value(DateTime.now()),
        licenseStatus: Value(meta.licenseStatus),
        demoMode: Value(meta.demoMode),
        currentTenantId: Value(meta.currentTenantId),
        currentBranchId: Value(user.branchId),
        currentUserId: Value(user.id),
        sessionActive: const Value(true),
        businessType: Value(meta.businessType),
        maintenanceMode: Value(meta.maintenanceMode),
        allowNegativeStock: Value(meta.allowNegativeStock),
        schemaVersion: Value(meta.schemaVersion),
        createdAt: Value(meta.createdAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> logout() async {
    final meta = await _db.getAppMeta();
    if (meta == null) return;
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
