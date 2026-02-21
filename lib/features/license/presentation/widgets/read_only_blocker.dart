import 'package:controlzukis/features/bootstrap/presentation/controllers/bootstrap_controller.dart';
import 'package:controlzukis/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReadOnlyBlocker extends ConsumerWidget {
  const ReadOnlyBlocker({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref
        .watch(bootstrapControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final readOnly = snapshot?.isReadOnly ?? false;
    if (!readOnly) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: Colors.black.withValues(alpha: 0.09),
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.lock_outline, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Modo solo lectura: escrituras bloqueadas por licencia.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
