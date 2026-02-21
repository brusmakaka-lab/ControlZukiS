import 'package:controlzukis/features/expenses/domain/models/expense_input.dart';
import 'package:controlzukis/features/expenses/presentation/controllers/expenses_controller.dart';
import 'package:controlzukis/features/license/presentation/widgets/license_banner.dart';
import 'package:controlzukis/core/widgets/saas_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  static const _pageSize = 10;
  int _page = 0;
  AsyncValue<ExpensesPageState> _state = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const AsyncLoading());
    _state = await AsyncValue.guard(
      () => ref
          .read(expensesControllerProvider)
          .fetch(page: _page, pageSize: _pageSize),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openForm() async {
    final categoryCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool affectsStock = false;
    String? productId;
    final quantityCtrl = TextEditingController();

    final products = await ref.read(expensesControllerProvider).listProducts();
    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Nuevo gasto / compra'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: categoryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                        ),
                      ),
                      TextField(
                        controller: amountCtrl,
                        decoration: const InputDecoration(labelText: 'Monto'),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(labelText: 'Notas'),
                      ),
                      SwitchListTile(
                        value: affectsStock,
                        onChanged: (v) => setLocal(() => affectsStock = v),
                        title: const Text('Es compra que aumenta stock'),
                      ),
                      if (affectsStock) ...[
                        DropdownButtonFormField<String>(
                          initialValue: productId,
                          decoration: const InputDecoration(
                            labelText: 'Producto',
                          ),
                          items: products
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setLocal(() => productId = v),
                        ),
                        TextField(
                          controller: quantityCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad a ingresar al stock',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
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
      },
    );

    if (ok != true) return;

    final input = ExpenseInput(
      category: categoryCtrl.text.trim(),
      amount: double.tryParse(amountCtrl.text.trim()) ?? 0,
      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      affectsStock: affectsStock,
      productId: productId,
      stockQuantity: affectsStock
          ? double.tryParse(quantityCtrl.text.trim())
          : null,
    );

    await ref.read(expensesControllerProvider).create(input);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return SaaSScaffold(
      currentRoute: '/expenses',
      title: 'Gastos / Compras',
      child: Column(
        children: [
          const LicenseBanner(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: _openForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Gasto/Compra'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (data) {
                if (data.items.isEmpty) {
                  return const Center(child: Text('Sin gastos registrados.'));
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
                          final e = data.items[index];
                          return ListTile(
                            title: Text(e.category),
                            subtitle: Text(
                              '${e.date.toIso8601String()} · ${e.affectsStock ? 'Compra con stock' : 'Gasto'}',
                            ),
                            trailing: Text(e.amount.toStringAsFixed(2)),
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
