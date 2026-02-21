import 'package:controlzukis/core/models/license_status.dart';
import 'package:controlzukis/core/theme/app_theme.dart';
import 'package:controlzukis/features/bootstrap/presentation/controllers/bootstrap_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LicenseBanner extends ConsumerWidget {
  const LicenseBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref
        .watch(bootstrapControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    if (snapshot == null) return const SizedBox.shrink();

    final color = switch (snapshot.licenseStatus) {
      LicenseStatus.active => Colors.green,
      LicenseStatus.trial => Colors.blue,
      LicenseStatus.expired => Colors.red,
      LicenseStatus.tamper => Colors.deepPurple,
    };

    final icon = switch (snapshot.licenseStatus) {
      LicenseStatus.active => Icons.verified_outlined,
      LicenseStatus.trial => Icons.timer_outlined,
      LicenseStatus.expired => Icons.lock_outline,
      LicenseStatus.tamper => Icons.gpp_bad_outlined,
    };

    final text = switch (snapshot.licenseStatus) {
      LicenseStatus.active => 'Licencia activa',
      LicenseStatus.trial => 'TRIAL (${snapshot.daysRemaining} días)',
      LicenseStatus.expired => 'Licencia expirada · solo lectura',
      LicenseStatus.tamper => 'Tamper detectado · activar requerido',
    };

    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          if (snapshot.licenseStatus == LicenseStatus.expired ||
              snapshot.licenseStatus == LicenseStatus.tamper)
            TextButton(
              onPressed: () => context.go('/activation'),
              child: const Text('Activar'),
            ),
        ],
      ),
    );
  }
}
