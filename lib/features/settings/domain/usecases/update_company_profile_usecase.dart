import 'package:controlzukis/features/settings/domain/models/company_profile_input.dart';
import 'package:controlzukis/features/settings/domain/repositories/settings_repository.dart';

class UpdateCompanyProfileUseCase {
  const UpdateCompanyProfileUseCase(this._repository);

  final SettingsRepository _repository;

  Future<void> call(CompanyProfileInput input) {
    return _repository.updateCompanyProfile(input);
  }
}
