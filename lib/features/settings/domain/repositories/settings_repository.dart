import 'package:controlzukis/features/settings/domain/models/company_profile_input.dart';
import 'package:controlzukis/features/settings/domain/models/settings_snapshot.dart';
import 'package:controlzukis/features/settings/domain/models/user_input.dart';

abstract class SettingsRepository {
  Future<SettingsSnapshot> getSnapshot();
  Future<void> updateCompanyProfile(CompanyProfileInput input);
  Future<void> setAllowNegativeStock(bool enabled);
  Future<void> createUser(UserInput input);
  Future<void> updateUserRole({required String userId, required String role});
  Future<void> setUserActive({required String userId, required bool isActive});
  Future<void> logout();
}
