import 'package:controlzukis/features/onboarding/domain/models/business_type.dart';

class OnboardingInput {
  const OnboardingInput({
    required this.companyName,
    required this.branchName,
    required this.adminName,
    required this.adminEmail,
    required this.adminPassword,
    required this.businessType,
  });

  final String companyName;
  final String branchName;
  final String adminName;
  final String adminEmail;
  final String adminPassword;
  final BusinessType businessType;
}
