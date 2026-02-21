import 'package:controlzukis/features/onboarding/domain/models/onboarding_input.dart';
import 'package:controlzukis/features/onboarding/domain/repositories/onboarding_repository.dart';

class CompleteOnboardingUseCase {
  const CompleteOnboardingUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<void> call(OnboardingInput input) =>
      _repository.completeOnboarding(input);
}
