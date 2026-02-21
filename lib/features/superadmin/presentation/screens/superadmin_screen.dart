import 'package:controlzukis/features/license/presentation/widgets/license_banner.dart';
import 'package:controlzukis/features/superadmin/domain/models/superadmin_state_snapshot.dart';
import 'package:controlzukis/features/superadmin/presentation/controllers/superadmin_controller.dart';
import 'package:controlzukis/core/widgets/saas_scaffold.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SuperAdminScreen extends ConsumerStatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  ConsumerState<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends ConsumerState<SuperAdminScreen> {
  AsyncValue<SuperAdminStateSnapshot> _state = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const AsyncLoading());
    _state = await AsyncValue.guard(
      () => ref.read(superAdminControllerProvider).fetch(),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SaaSScaffold(
      currentRoute: '/superadmin',
      title: 'SuperAdmin',
      child: Column(
        children: [
          const LicenseBanner(),
          Expanded(
            child: _state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error SuperAdmin: $e')),
              data: (data) => ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Diagnóstico local',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text('App dir: ${data.diagnostics.appDirPath}'),
                          Text('DB: ${data.diagnostics.dbPath}'),
                          Text(
                            'DB size: ${data.diagnostics.dbSizeBytes} bytes',
                          ),
                          Text('Logs: ${data.diagnostics.logsPath}'),
                          Text(
                            'Logs size: ${data.diagnostics.logsSizeBytes} bytes',
                          ),
                          Text('Imágenes: ${data.diagnostics.imagesCount}'),
                          Text('Thumbnails: ${data.diagnostics.thumbsCount}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Acciones',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  try {
                                    final info = await ref
                                        .read(superAdminControllerProvider)
                                        .createBackupZip();
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Backup creado: ${info.filePath} · sha256=${info.sha256.substring(0, 12)}...',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Error backup: $e'),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.archive_outlined),
                                label: const Text('Crear backup ZIP'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final result = await FilePicker.platform
                                      .pickFiles(
                                        type: FileType.custom,
                                        allowedExtensions: const ['zip'],
                                      );
                                  final path = result?.files.single.path;
                                  if (path == null) return;

                                  try {
                                    await ref
                                        .read(superAdminControllerProvider)
                                        .restoreBackupZip(path);
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Restore completado'),
                                      ),
                                    );
                                    await _load();
                                  } catch (e) {
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Restore falló (rollback aplicado): $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.restore_outlined),
                                label: const Text('Restore backup ZIP'),
                              ),
                              FilledButton.icon(
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  try {
                                    final path = await ref
                                        .read(superAdminControllerProvider)
                                        .exportLogs();
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Logs exportados en: $path',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Error export logs: $e'),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.download_outlined),
                                label: const Text('Exportar logs'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Reset demo'),
                                      content: const Text(
                                        'Se limpiarán ventas, gastos, clientes, logs y se reiniciará TRIAL. ¿Continuar?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Confirmar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true) return;

                                  try {
                                    await ref
                                        .read(superAdminControllerProvider)
                                        .resetDemo();
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Demo reiniciado correctamente',
                                        ),
                                      ),
                                    );
                                    await _load();
                                  } catch (e) {
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Error reset demo: $e'),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.restart_alt_outlined),
                                label: const Text('Reset demo'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Activity logs recientes',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          if (data.logs.isEmpty)
                            const Text('Sin logs')
                          else
                            ...data.logs
                                .take(40)
                                .map(
                                  (l) => ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      '${l.action} · ${l.entityType}',
                                    ),
                                    subtitle: Text(
                                      '${l.createdAt.toIso8601String()} · user=${l.userId ?? '-'}',
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Licencia audit',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          if (data.licenseAudits.isEmpty)
                            const Text('Sin auditoría')
                          else
                            ...data.licenseAudits
                                .take(40)
                                .map(
                                  (a) => ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      '${a.action} · ${a.statusBefore ?? '-'} -> ${a.statusAfter ?? '-'}',
                                    ),
                                    subtitle: Text(
                                      '${a.createdAt.toIso8601String()} · device=${a.deviceId.substring(0, 12)}...',
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
