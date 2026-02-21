import 'package:controlzukis/features/onboarding/domain/models/onboarding_input.dart';

abstract class OnboardingRepository {
  Future<void> completeOnboarding(OnboardingInput input);
}
