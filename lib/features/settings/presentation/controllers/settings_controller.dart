import 'package:controlzukis/core/providers/core_providers.dart';
import 'package:controlzukis/core/providers/guard_providers.dart';
import 'package:controlzukis/features/settings/data/settings_repository_impl.dart';
import 'package:controlzukis/features/settings/domain/models/company_profile_input.dart';
import 'package:controlzukis/features/settings/domain/models/settings_snapshot.dart';
import 'package:controlzukis/features/settings/domain/models/user_input.dart';
import 'package:controlzukis/features/settings/domain/repositories/settings_repository.dart';
import 'package:controlzukis/features/settings/domain/usecases/create_user_usecase.dart';
import 'package:controlzukis/features/settings/domain/usecases/get_settings_snapshot_usecase.dart';
import 'package:controlzukis/features/settings/domain/usecases/set_allow_negative_stock_usecase.dart';
import 'package:controlzukis/features/settings/domain/usecases/set_user_active_usecase.dart';
import 'package:controlzukis/features/settings/domain/usecases/update_company_profile_usecase.dart';
import 'package:controlzukis/features/settings/domain/usecases/update_user_role_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    writeAccess: ref.watch(writeAccessServiceProvider),
  );
});

final getSettingsSnapshotUseCaseProvider = Provider<GetSettingsSnapshotUseCase>(
  (ref) => GetSettingsSnapshotUseCase(ref.watch(settingsRepositoryProvider)),
);
final updateCompanyProfileUseCaseProvider =
    Provider<UpdateCompanyProfileUseCase>(
      (ref) =>
          UpdateCompanyProfileUseCase(ref.watch(settingsRepositoryProvider)),
    );
final setAllowNegativeStockUseCaseProvider =
    Provider<SetAllowNegativeStockUseCase>(
      (ref) =>
          SetAllowNegativeStockUseCase(ref.watch(settingsRepositoryProvider)),
    );
final createUserUseCaseProvider = Provider<CreateUserUseCase>(
  (ref) => CreateUserUseCase(ref.watch(settingsRepositoryProvider)),
);
final updateUserRoleUseCaseProvider = Provider<UpdateUserRoleUseCase>(
  (ref) => UpdateUserRoleUseCase(ref.watch(settingsRepositoryProvider)),
);
final setUserActiveUseCaseProvider = Provider<SetUserActiveUseCase>(
  (ref) => SetUserActiveUseCase(ref.watch(settingsRepositoryProvider)),
);

class SettingsController {
  const SettingsController(this._ref);

  final Ref _ref;

  Future<SettingsSnapshot> fetch() =>
      _ref.read(getSettingsSnapshotUseCaseProvider)();

  Future<void> updateCompanyProfile(CompanyProfileInput input) {
    return _ref.read(updateCompanyProfileUseCaseProvider)(input);
  }

  Future<void> setAllowNegativeStock(bool enabled) {
    return _ref.read(setAllowNegativeStockUseCaseProvider)(enabled);
  }

  Future<void> createUser(UserInput input) {
    return _ref.read(createUserUseCaseProvider)(input);
  }

  Future<void> updateUserRole({required String userId, required String role}) {
    return _ref.read(updateUserRoleUseCaseProvider)(userId: userId, role: role);
  }

  Future<void> setUserActive({required String userId, required bool isActive}) {
    return _ref.read(setUserActiveUseCaseProvider)(
      userId: userId,
      isActive: isActive,
    );
  }

  Future<void> logout() {
    return _ref.read(settingsRepositoryProvider).logout();
  }
}

final settingsControllerProvider = Provider<SettingsController>(
  SettingsController.new,
);
