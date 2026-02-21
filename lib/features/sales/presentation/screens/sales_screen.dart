import 'dart:async';

import 'package:controlzukis/core/theme/app_theme.dart';
import 'package:controlzukis/core/widgets/app_ui.dart';
import 'package:controlzukis/features/license/presentation/widgets/license_banner.dart';
import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/widgets/saas_scaffold.dart';
import 'package:controlzukis/features/sales/domain/models/create_sale_input.dart';
import 'package:controlzukis/features/sales/domain/models/sale_item_input.dart';
import 'package:controlzukis/features/sales/presentation/controllers/sales_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _discountCtrl = TextEditingController(text: '0');
  final TextEditingController _taxCtrl = TextEditingController(text: '0');
  final TextEditingController _notesCtrl = TextEditingController();
  Timer? _searchDebounce;

  List<Product> _products = const [];
  bool _loadingProducts = false;
  bool _submitting = false;
  final Map<String, _CartLine> _cart = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _discountCtrl.dispose();
    _taxCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _loadProducts();
    });
  }

  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);
    final items = await ref
        .read(salesControllerProvider)
        .listProducts(search: _searchCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _products = items;
      _loadingProducts = false;
    });
  }

  Future<void> _confirmSale() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agregá al menos un producto al carrito.'),
        ),
      );
      return;
    }

    final input = CreateSaleInput(
      items: _cart.values
          .map(
            (line) => SaleItemInput(
              productId: line.product.id,
              quantity: line.quantity,
              unitPrice: line.unitPrice,
            ),
          )
          .toList(),
      discount: double.tryParse(_discountCtrl.text.trim()) ?? 0,
      tax: double.tryParse(_taxCtrl.text.trim()) ?? 0,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    setState(() => _submitting = true);
    try {
      await ref.read(salesControllerProvider).createSaleWithStock(input);
      if (!mounted) return;
      setState(() {
        _cart.clear();
        _discountCtrl.text = '0';
        _taxCtrl.text = '0';
        _notesCtrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venta registrada con actualización de stock.'),
        ),
      );
      await _loadProducts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar la venta: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  double get _subtotal {
    return _cart.values.fold(
      0,
      (acc, line) => acc + (line.quantity * line.unitPrice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discount = double.tryParse(_discountCtrl.text.trim()) ?? 0;
    final tax = double.tryParse(_taxCtrl.text.trim()) ?? 0;
    final total = _subtotal - discount + tax;

    return SaaSScaffold(
      currentRoute: '/sales',
      title: 'Ventas',
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
                    label: 'Buscar producto',
                    hint: 'Nombre o SKU',
                    prefixIcon: Icons.search,
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppSecondaryButton(
                  onPressed: _loadProducts,
                  icon: Icons.refresh,
                  label: 'Actualizar',
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 1100;
                if (desktop) {
                  return Row(
                    children: [
                      Expanded(flex: 3, child: _productsPane()),
                      const VerticalDivider(width: 1),
                      Expanded(flex: 2, child: _cartPane(total, discount, tax)),
                    ],
                  );
                }
                return Column(
                  children: [
                    Expanded(child: _productsPane()),
                    const Divider(height: 1),
                    SizedBox(
                      height: 320,
                      child: _cartPane(total, discount, tax),
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

  Widget _productsPane() {
    if (_loadingProducts) return const LoadingSkeleton(lines: 9);
    if (_products.isEmpty) {
      return const EmptyState(
        title: 'Sin productos',
        message: 'No hay coincidencias para la búsqueda actual.',
      );
    }
    return ListView.separated(
      itemCount: _products.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final p = _products[index];
        return ListTile(
          title: Text(p.name),
          subtitle: Text(
            'SKU: ${p.sku ?? '-'} · Stock: ${p.stock.toStringAsFixed(2)} · ${p.sellPrice.toStringAsFixed(2)}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.add_shopping_cart_outlined),
            onPressed: () {
              setState(() {
                final current = _cart[p.id];
                if (current == null) {
                  _cart[p.id] = _CartLine(product: p);
                } else {
                  current.quantity += 1;
                }
              });
            },
          ),
        );
      },
    );
  }

  Widget _cartPane(double total, double discount, double tax) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AppCard(
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Carrito (${_cart.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _cart.isEmpty ? null : () => setState(_cart.clear),
                  child: const Text('Vaciar'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: _cart.isEmpty
                  ? const EmptyState(
                      title: 'Carrito vacío',
                      message: 'Agregá productos para registrar la venta.',
                    )
                  : ListView.builder(
                      itemCount: _cart.length,
                      itemBuilder: (context, index) {
                        final line = _cart.values.elementAt(index);
                        return AppCard(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(line.product.name)),
                                  IconButton(
                                    onPressed: () => setState(
                                      () => _cart.remove(line.product.id),
                                    ),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: line.quantity
                                          .toStringAsFixed(2),
                                      decoration: const InputDecoration(
                                        labelText: 'Cantidad',
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => line.quantity =
                                          double.tryParse(v) ?? line.quantity,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: line.unitPrice
                                          .toStringAsFixed(2),
                                      decoration: const InputDecoration(
                                        labelText: 'Precio',
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => line.unitPrice =
                                          double.tryParse(v) ?? line.unitPrice,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppTextField(
              controller: _discountCtrl,
              label: 'Descuento',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppTextField(
              controller: _taxCtrl,
              label: 'Impuestos',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppTextField(controller: _notesCtrl, label: 'Notas'),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Subtotal: ${_subtotal.toStringAsFixed(2)}\nTotal: ${total.toStringAsFixed(2)}\nDesc: ${discount.toStringAsFixed(2)} · Imp: ${tax.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              width: double.infinity,
              child: AppPrimaryButton(
                onPressed: _submitting ? null : _confirmSale,
                icon: Icons.point_of_sale_outlined,
                label: _submitting ? 'Registrando...' : 'Confirmar venta',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLine {
  _CartLine({required this.product})
    : quantity = 1,
      unitPrice = product.sellPrice;

  final Product product;
  double quantity;
  double unitPrice;
}
