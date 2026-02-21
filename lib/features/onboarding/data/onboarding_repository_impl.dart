import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/utils/password_hasher.dart';
import 'package:controlzukis/features/onboarding/data/onboarding_seed_data.dart';
import 'package:controlzukis/features/onboarding/domain/models/business_type.dart';
import 'package:controlzukis/features/onboarding/domain/models/onboarding_input.dart';
import 'package:controlzukis/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._db);

  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  @override
  Future<void> completeOnboarding(OnboardingInput input) async {
    final now = DateTime.now();
    final tenantId = _uuid.v4();
    final branchId = _uuid.v4();
    final userId = _uuid.v4();

    await _db
        .into(_db.tenants)
        .insert(
          TenantsCompanion.insert(
            id: tenantId,
            name: input.companyName,
            legalName: Value(input.companyName),
          ),
        );

    await _db
        .into(_db.branches)
        .insert(
          BranchesCompanion.insert(
            id: branchId,
            tenantId: tenantId,
            name: input.branchName,
            code: const Value('MAIN'),
          ),
        );

    await _db
        .into(_db.users)
        .insert(
          UsersCompanion.insert(
            id: userId,
            tenantId: tenantId,
            branchId: branchId,
            name: input.adminName,
            email: input.adminEmail,
            role: 'SUPER_ADMIN',
            passwordHash: PasswordHasher.hash(input.adminPassword),
          ),
        );

    final categories = OnboardingSeedData.categories(input.businessType);
    for (var i = 0; i < categories.length; i++) {
      await _db
          .into(_db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: _uuid.v4(),
              tenantId: tenantId,
              name: categories[i],
              businessType: input.businessType.code,
              sortOrder: Value(i),
            ),
          );
    }

    final fields = OnboardingSeedData.customFields(input.businessType);
    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      await _db
          .into(_db.productCustomFieldDefinitions)
          .insert(
            ProductCustomFieldDefinitionsCompanion.insert(
              id: _uuid.v4(),
              tenantId: tenantId,
              businessType: input.businessType.code,
              key: field.key,
              label: field.label,
              type: field.type,
              required: Value(field.required),
              optionsJson: Value(field.optionsJson),
              order: Value(i),
            ),
          );
    }

    final meta = await _db.getAppMeta();
    if (meta != null) {
      await _db.upsertAppMeta(
        AppMetasCompanion(
          id: Value(meta.id),
          installedAt: Value(meta.installedAt),
          trialEndsAt: Value(meta.trialEndsAt),
          lastSeenAt: Value(now),
          licenseStatus: Value(meta.licenseStatus),
          demoMode: Value(meta.demoMode),
          currentTenantId: Value(tenantId),
          currentBranchId: Value(branchId),
          currentUserId: Value(userId),
          sessionActive: const Value(false),
          businessType: Value(input.businessType.code),
          maintenanceMode: Value(meta.maintenanceMode),
          allowNegativeStock: Value(meta.allowNegativeStock),
          schemaVersion: Value(meta.schemaVersion),
          createdAt: Value(meta.createdAt),
          updatedAt: Value(now),
        ),
      );
    }
  }
}
