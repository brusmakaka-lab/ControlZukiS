import 'package:controlzukis/core/config/app_env.dart';
import 'package:controlzukis/core/widgets/saas_scaffold.dart';
import 'package:controlzukis/features/bootstrap/presentation/controllers/bootstrap_controller.dart';
import 'package:controlzukis/features/license/presentation/widgets/license_banner.dart';
import 'package:controlzukis/features/license/presentation/widgets/read_only_blocker.dart';
import 'package:controlzukis/features/settings/domain/models/company_profile_input.dart';
import 'package:controlzukis/features/settings/domain/models/settings_snapshot.dart';
import 'package:controlzukis/features/settings/domain/models/user_input.dart';
import 'package:controlzukis/features/settings/presentation/controllers/settings_controller.dart';
import 'package:controlzukis/features/settings/presentation/controllers/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  AsyncValue<SettingsSnapshot> _state = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const AsyncLoading());
    _state = await AsyncValue.guard(
      () => ref.read(settingsControllerProvider).fetch(),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref
        .watch(bootstrapControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final themeMode = ref.watch(themeModeProvider);

    return SaaSScaffold(
      currentRoute: '/settings',
      title: 'Settings',
      child: Column(
        children: [
          const LicenseBanner(),
          Expanded(
            child: ReadOnlyBlocker(
              child: _state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
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
                              'Empresa',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text('Nombre: ${data.tenant.name}'),
                            Text(
                              'Razón social: ${data.tenant.legalName ?? '-'}',
                            ),
                            Text('CUIT: ${data.tenant.taxId ?? '-'}'),
                            Text('Email: ${data.tenant.email ?? '-'}'),
                            Text('Teléfono: ${data.tenant.phone ?? '-'}'),
                            Text('Dirección: ${data.tenant.address ?? '-'}'),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: () => _editCompany(data),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Editar empresa'),
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
                              'Operación',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: data.meta.allowNegativeStock,
                              title: const Text('Permitir stock negativo'),
                              subtitle: const Text(
                                'Si está desactivado, las ventas validan stock disponible.',
                              ),
                              onChanged: (value) async {
                                await ref
                                    .read(settingsControllerProvider)
                                    .setAllowNegativeStock(value);
                                await _load();
                              },
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
                              'Usuarios y roles',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FilledButton.icon(
                                onPressed: _createUser,
                                icon: const Icon(Icons.person_add_alt_1),
                                label: const Text('Nuevo usuario'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...data.users.map(
                              (u) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('${u.name} · ${u.email}'),
                                subtitle: Text('Rol: ${u.role}'),
                                trailing: Wrap(
                                  spacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    DropdownButton<String>(
                                      value: u.role,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'SUPER_ADMIN',
                                          child: Text('SUPER_ADMIN'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'ADMIN',
                                          child: Text('ADMIN'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'SELLER',
                                          child: Text('SELLER'),
                                        ),
                                      ],
                                      onChanged: (value) async {
                                        if (value == null || value == u.role) {
                                          return;
                                        }
                                        await ref
                                            .read(settingsControllerProvider)
                                            .updateUserRole(
                                              userId: u.id,
                                              role: value,
                                            );
                                        await _load();
                                      },
                                    ),
                                    Switch(
                                      value: u.isActive,
                                      onChanged: (value) async {
                                        await ref
                                            .read(settingsControllerProvider)
                                            .setUserActive(
                                              userId: u.id,
                                              isActive: value,
                                            );
                                        await _load();
                                      },
                                    ),
                                  ],
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
                              'Tema',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            DropdownButton<ThemeMode>(
                              value: themeMode,
                              items: const [
                                DropdownMenuItem(
                                  value: ThemeMode.system,
                                  child: Text('Sistema'),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.light,
                                  child: Text('Claro'),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.dark,
                                  child: Text('Oscuro'),
                                ),
                              ],
                              onChanged: (value) async {
                                if (value == null) return;
                                await ref
                                    .read(themeModeProvider.notifier)
                                    .setThemeMode(value);
                              },
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
                              'Acerca de / Licencia',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text('App version: ${AppEnv.appVersion}'),
                            Text('Trial días: ${AppEnv.trialDays}'),
                            Text(
                              'Estado: ${snapshot?.licenseStatus.name.toUpperCase() ?? '-'}',
                            ),
                            Text(
                              'Días restantes: ${snapshot?.daysRemaining ?? 0}',
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await ref
                                    .read(settingsControllerProvider)
                                    .logout();
                                ref.invalidate(bootstrapControllerProvider);
                                if (!context.mounted) return;
                                context.go('/login');
                              },
                              icon: const Icon(Icons.logout),
                              label: const Text('Cerrar sesión'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editCompany(SettingsSnapshot data) async {
    final nameCtrl = TextEditingController(text: data.tenant.name);
    final legalCtrl = TextEditingController(text: data.tenant.legalName ?? '');
    final taxCtrl = TextEditingController(text: data.tenant.taxId ?? '');
    final emailCtrl = TextEditingController(text: data.tenant.email ?? '');
    final phoneCtrl = TextEditingController(text: data.tenant.phone ?? '');
    final addressCtrl = TextEditingController(text: data.tenant.address ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar empresa'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  TextField(
                    controller: legalCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Razón social',
                    ),
                  ),
                  TextField(
                    controller: taxCtrl,
                    decoration: const InputDecoration(labelText: 'CUIT'),
                  ),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                  ),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;
    await ref
        .read(settingsControllerProvider)
        .updateCompanyProfile(
          CompanyProfileInput(
            name: nameCtrl.text.trim(),
            legalName: legalCtrl.text.trim().isEmpty
                ? null
                : legalCtrl.text.trim(),
            taxId: taxCtrl.text.trim().isEmpty ? null : taxCtrl.text.trim(),
            email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
            phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
            address: addressCtrl.text.trim().isEmpty
                ? null
                : addressCtrl.text.trim(),
          ),
        );
    await _load();
  }

  Future<void> _createUser() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    var role = 'ADMIN';

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Nuevo usuario'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    TextField(
                      controller: passwordCtrl,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    DropdownButton<String>(
                      value: role,
                      items: const [
                        DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                        DropdownMenuItem(
                          value: 'SELLER',
                          child: Text('SELLER'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setLocal(() => role = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;
    await ref
        .read(settingsControllerProvider)
        .createUser(
          UserInput(
            name: nameCtrl.text.trim(),
            email: emailCtrl.text.trim(),
            role: role,
            password: passwordCtrl.text,
          ),
        );
    await _load();
  }
}
