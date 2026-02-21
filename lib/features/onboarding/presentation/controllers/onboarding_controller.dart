import 'package:controlzukis/core/providers/core_providers.dart';
import 'package:controlzukis/features/onboarding/data/onboarding_repository_impl.dart';
import 'package:controlzukis/features/onboarding/domain/models/onboarding_input.dart';
import 'package:controlzukis/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:controlzukis/features/onboarding/domain/usecases/complete_onboarding_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return OnboardingRepositoryImpl(db);
});

final completeOnboardingUseCaseProvider = Provider<CompleteOnboardingUseCase>((
  ref,
) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return CompleteOnboardingUseCase(repository);
});

final onboardingControllerProvider = Provider<OnboardingController>(
  OnboardingController.new,
);

class OnboardingController {
  OnboardingController(this._ref);

  final Ref _ref;

  Future<void> submit(OnboardingInput input) async {
    final useCase = _ref.read(completeOnboardingUseCaseProvider);
    await useCase(input);
  }
}
