import 'dart:async';

import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/theme/app_theme.dart';
import 'package:controlzukis/core/widgets/app_ui.dart';
import 'package:controlzukis/core/widgets/saas_scaffold.dart';
import 'package:controlzukis/features/customers/domain/models/customer_input.dart';
import 'package:controlzukis/features/customers/presentation/controllers/customers_controller.dart';
import 'package:controlzukis/features/license/presentation/widgets/license_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  static const _pageSize = 10;
  int _page = 0;
  String _search = '';
  late final TextEditingController _searchCtrl;
  Timer? _searchDebounce;
  AsyncValue<CustomersPageState> _state = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _search = value.trim();
      _page = 0;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _state = const AsyncLoading());
    _state = await AsyncValue.guard(
      () => ref
          .read(customersControllerProvider)
          .fetch(page: _page, pageSize: _pageSize, search: _search),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openForm({Customer? customer}) async {
    final fullNameCtrl = TextEditingController(text: customer?.fullName ?? '');
    final dniCtrl = TextEditingController(text: customer?.dniCuit ?? '');
    final emailCtrl = TextEditingController(text: customer?.email ?? '');
    final phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    final addressCtrl = TextEditingController(text: customer?.address ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(customer == null ? 'Nuevo cliente' : 'Editar cliente'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: fullNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                    ),
                  ),
                  TextField(
                    controller: dniCtrl,
                    decoration: const InputDecoration(labelText: 'DNI/CUIT'),
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

    final input = CustomerInput(
      fullName: fullNameCtrl.text.trim(),
      dniCuit: dniCtrl.text.trim().isEmpty ? null : dniCtrl.text.trim(),
      email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
      phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
      address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
    );

    if (customer == null) {
      await ref.read(customersControllerProvider).create(input);
    } else {
      await ref.read(customersControllerProvider).update(customer.id, input);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return SaaSScaffold(
      currentRoute: '/customers',
      title: 'Clientes',
      child: Column(
        children: [
          const LicenseBanner(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _searchCtrl,
                    label: 'Buscar cliente',
                    hint: 'Nombre o DNI/CUIT',
                    prefixIcon: Icons.search,
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppPrimaryButton(
                  onPressed: () => _openForm(),
                  icon: Icons.add,
                  label: 'Cliente',
                ),
              ],
            ),
          ),
          Expanded(
            child: _state.when(
              loading: () => const LoadingSkeleton(lines: 8),
              error: (e, st) =>
                  ErrorState(message: 'Error: $e', onRetry: _load),
              data: (data) {
                if (data.items.isEmpty) {
                  return EmptyState(
                    title: 'Sin clientes',
                    message: 'Creá tu primer cliente para asociarlo a ventas.',
                    cta: AppPrimaryButton(
                      onPressed: () => _openForm(),
                      icon: Icons.person_add_alt_1,
                      label: 'Nuevo cliente',
                    ),
                  );
                }
                final pages = (data.total / _pageSize).ceil();
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: data.items.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final c = data.items[index];
                          return ListTile(
                            title: Text(c.fullName),
                            subtitle: Text(
                              'DNI/CUIT: ${c.dniCuit ?? '-'} · ${c.email ?? '-'} · ${c.phone ?? '-'}',
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  onPressed: () => _openForm(customer: c),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    await ref
                                        .read(customersControllerProvider)
                                        .delete(c.id);
                                    await _load();
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Página ${_page + 1} de ${pages == 0 ? 1 : pages}',
                          ),
                          IconButton(
                            onPressed: _page > 0
                                ? () {
                                    _page--;
                                    _load();
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          IconButton(
                            onPressed: (_page + 1) < pages
                                ? () {
                                    _page++;
                                    _load();
                                  }
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
