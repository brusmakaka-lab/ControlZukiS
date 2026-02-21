import 'package:controlzukis/core/models/license_status.dart';

enum AppRoutePhase { unknown, onboarding, activation, ready }

class RoutingSnapshot {
  const RoutingSnapshot({
    required this.phase,
    required this.licenseStatus,
    required this.daysRemaining,
    required this.hasSession,
    required this.maintenanceMode,
  });

  final AppRoutePhase phase;
  final LicenseStatus licenseStatus;
  final int daysRemaining;
  final bool hasSession;
  final bool maintenanceMode;

  bool get isReadOnly =>
      licenseStatus == LicenseStatus.expired ||
      licenseStatus == LicenseStatus.tamper;

  static const unknown = RoutingSnapshot(
    phase: AppRoutePhase.unknown,
    licenseStatus: LicenseStatus.trial,
    daysRemaining: 0,
    hasSession: false,
    maintenanceMode: false,
  );
}
