import 'dart:async';

import 'package:controlzukis/core/theme/app_theme.dart';
import 'package:controlzukis/core/widgets/app_ui.dart';
import 'package:controlzukis/core/widgets/saas_scaffold.dart';
import 'package:controlzukis/features/categories/domain/models/category_input.dart';
import 'package:controlzukis/features/categories/presentation/controllers/categories_controller.dart';
import 'package:controlzukis/features/license/presentation/widgets/license_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  static const _pageSize = 10;
  int _page = 0;
  String _search = '';
  late final TextEditingController _searchCtrl;
  Timer? _searchDebounce;
  AsyncValue<CategoriesPageState> _state = const AsyncLoading();

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

  Future<void> _load() async {
    setState(() => _state = const AsyncLoading());
    _state = await AsyncValue.guard(
      () => ref
          .read(categoriesControllerProvider)
          .fetch(page: _page, pageSize: _pageSize, search: _search),
    );
    if (mounted) setState(() {});
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

  Future<void> _openForm({String? id, String? currentName}) async {
    final nameCtrl = TextEditingController(text: currentName ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(id == null ? 'Nueva categoría' : 'Editar categoría'),
          content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Nombre'),
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
    final input = CategoryInput(name: nameCtrl.text.trim());
    try {
      if (id == null) {
        await ref.read(categoriesControllerProvider).create(input);
      } else {
        await ref.read(categoriesControllerProvider).update(id, input);
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SaaSScaffold(
      currentRoute: '/categories',
      title: 'Categorías',
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
                    label: 'Buscar categoría',
                    hint: 'Nombre',
                    prefixIcon: Icons.search,
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppPrimaryButton(
                  onPressed: () => _openForm(),
                  icon: Icons.add,
                  label: 'Categoría',
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
                    title: 'Sin categorías',
                    message:
                        'Creá una categoría para comenzar a organizar productos.',
                    cta: AppPrimaryButton(
                      onPressed: () => _openForm(),
                      icon: Icons.add,
                      label: 'Nueva categoría',
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
                            title: Text(c.name),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      _openForm(id: c.id, currentName: c.name),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    try {
                                      await ref
                                          .read(categoriesControllerProvider)
                                          .delete(c.id);
                                      await _load();
                                    } catch (e) {
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
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
