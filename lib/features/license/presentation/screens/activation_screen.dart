import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:controlzukis/core/theme/app_theme.dart';
import 'package:controlzukis/core/widgets/app_ui.dart';
import 'package:controlzukis/features/bootstrap/presentation/controllers/bootstrap_controller.dart';
import 'package:controlzukis/features/license/presentation/controllers/license_controller.dart';

class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key});

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  final _keyCtrl = TextEditingController();
  bool _loading = false;
  String? _deviceId;
  String? _status;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    final id = await ref.read(licenseControllerProvider).getDeviceId();
    if (!mounted) return;
    setState(() {
      _deviceId = id;
    });
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activación offline')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionHeader(
                    title: 'Activación definitiva',
                    subtitle:
                        'Ingresá tu licencia offline para habilitar escritura y operación completa.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SelectableText(
                    'ID dispositivo: ${_deviceId ?? 'cargando...'}',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppSecondaryButton(
                    onPressed: _deviceId == null
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await Clipboard.setData(
                              ClipboardData(text: _deviceId!),
                            );
                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('ID de dispositivo copiado'),
                              ),
                            );
                          },
                    icon: Icons.copy,
                    label: 'Copiar ID del dispositivo',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _keyCtrl,
                    maxLines: 2,
                    label: 'Key de activación',
                    hint: 'ZKS-<payload>.<signature>',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppPrimaryButton(
                    onPressed: _loading
                        ? null
                        : () async {
                            setState(() {
                              _loading = true;
                              _status = null;
                            });
                            final ok = await ref
                                .read(licenseControllerProvider)
                                .activateOfflineKey(_keyCtrl.text);
                            if (!mounted) return;
                            setState(() {
                              _loading = false;
                              _status = ok
                                  ? 'Activación exitosa'
                                  : 'Key inválida o no compatible';
                            });
                            if (ok) {
                              ref.invalidate(bootstrapControllerProvider);
                              if (!context.mounted) return;
                              context.go('/dashboard');
                            }
                          },
                    icon: Icons.verified,
                    label: _loading ? 'Activando...' : 'Activar offline',
                  ),
                  if (_status != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(_status!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
