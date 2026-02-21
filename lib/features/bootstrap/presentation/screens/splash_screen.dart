import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:controlzukis/app/router/routing_snapshot.dart';
import 'package:controlzukis/features/bootstrap/presentation/controllers/bootstrap_controller.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<RoutingSnapshot>>(bootstrapControllerProvider, (
      _,
      next,
    ) {
      next.whenData((snapshot) {
        final target = switch (snapshot.phase) {
          AppRoutePhase.onboarding => '/onboarding',
          AppRoutePhase.activation => '/activation',
          AppRoutePhase.ready => '/dashboard',
          AppRoutePhase.unknown => '/splash',
        };

        if (context.mounted && GoRouterState.of(context).uri.path != target) {
          context.go(target);
        }
      });
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Inicializando ControlZukiS...'),
            const SizedBox(height: 8),
            Text(
              ref
                  .watch(bootstrapControllerProvider)
                  .maybeWhen(
                    loading: () => 'Preparando base local y licencia...',
                    orElse: () => '',
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
