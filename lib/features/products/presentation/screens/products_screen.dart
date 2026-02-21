import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/widgets/saas_scaffold.dart';
import 'package:controlzukis/features/license/presentation/widgets/license_banner.dart';
import 'package:controlzukis/features/products/domain/models/product_input.dart';
import 'package:controlzukis/features/products/presentation/controllers/products_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  static const _pageSize = 10;
  int _page = 0;
  String _search = '';
  late final TextEditingController _searchCtrl;
  Timer? _searchDebounce;
  AsyncValue<ProductsPageState> _state = const AsyncLoading();

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
          .read(productsControllerProvider)
          .fetch(page: _page, pageSize: _pageSize, search: _search),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openForm({Product? product}) async {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final skuCtrl = TextEditingController(text: product?.sku ?? '');
    final buyCtrl = TextEditingController(
      text: (product?.buyPrice ?? 0).toString(),
    );
    final sellCtrl = TextEditingController(
      text: (product?.sellPrice ?? 0).toString(),
    );
    final stockCtrl = TextEditingController(
      text: (product?.stock ?? 0).toString(),
    );
    bool isService = product?.isService ?? false;

    final definitions = await ref
        .read(productsControllerProvider)
        .listCustomFieldDefinitions();
    final existingValues = product == null
        ? const <ProductCustomFieldValue>[]
        : await ref
              .read(productsControllerProvider)
              .listCustomFieldValues(product.id);

    final valuesByDefId = <String, ProductCustomFieldValue>{
      for (final value in existingValues) value.fieldDefinitionId: value,
    };

    final textValues = <String, TextEditingController>{};
    final boolValues = <String, bool>{};
    final dateValues = <String, DateTime?>{};
    final selectValues = <String, String?>{};
    final multiValues = <String, Set<String>>{};

    for (final def in definitions) {
      final current = valuesByDefId[def.id];
      switch (def.type) {
        case 'NUMBER':
        case 'DECIMAL':
          textValues[def.id] = TextEditingController(
            text: current?.valueNumber?.toString() ?? '',
          );
          break;
        case 'BOOLEAN':
          boolValues[def.id] = current?.valueBool ?? false;
          break;
        case 'DATE':
          dateValues[def.id] = current?.valueDate;
          break;
        case 'SELECT':
          selectValues[def.id] = current?.valueText;
          break;
        case 'MULTISELECT':
          final raw = current?.valueJson;
          final decoded = raw == null
              ? const <dynamic>[]
              : (jsonDecode(raw) as List<dynamic>);
          multiValues[def.id] = decoded.map((e) => e.toString()).toSet();
          break;
        case 'TEXT':
        default:
          textValues[def.id] = TextEditingController(
            text: current?.valueText ?? '',
          );
          break;
      }
    }

    if (!mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(
                product == null ? 'Nuevo producto' : 'Editar producto',
              ),
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
                        controller: skuCtrl,
                        decoration: const InputDecoration(labelText: 'SKU'),
                      ),
                      TextField(
                        controller: buyCtrl,
                        decoration: const InputDecoration(labelText: 'Costo'),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: sellCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Precio venta',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: stockCtrl,
                        decoration: const InputDecoration(labelText: 'Stock'),
                        keyboardType: TextInputType.number,
                      ),
                      SwitchListTile(
                        value: isService,
                        onChanged: (v) => setLocal(() => isService = v),
                        title: const Text('Es servicio'),
                      ),
                      if (definitions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Campos dinámicos'),
                        ),
                        const SizedBox(height: 8),
                        for (final def in definitions)
                          _buildCustomFieldInput(
                            context: context,
                            setLocal: setLocal,
                            def: def,
                            textValues: textValues,
                            boolValues: boolValues,
                            dateValues: dateValues,
                            selectValues: selectValues,
                            multiValues: multiValues,
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

    final customFields = <CustomFieldInput>[];
    for (final def in definitions) {
      switch (def.type) {
        case 'BOOLEAN':
          final value = boolValues[def.id] ?? false;
          customFields.add(
            CustomFieldInput(
              fieldDefinitionId: def.id,
              type: def.type,
              valueBool: value,
            ),
          );
          break;
        case 'NUMBER':
        case 'DECIMAL':
          final raw = textValues[def.id]?.text.trim() ?? '';
          final parsed = raw.isEmpty ? null : double.tryParse(raw);
          customFields.add(
            CustomFieldInput(
              fieldDefinitionId: def.id,
              type: def.type,
              valueNumber: parsed,
            ),
          );
          break;
        case 'DATE':
          customFields.add(
            CustomFieldInput(
              fieldDefinitionId: def.id,
              type: def.type,
              valueDate: dateValues[def.id],
            ),
          );
          break;
        case 'SELECT':
          customFields.add(
            CustomFieldInput(
              fieldDefinitionId: def.id,
              type: def.type,
              valueText: selectValues[def.id],
            ),
          );
          break;
        case 'MULTISELECT':
          final selected = multiValues[def.id] ?? <String>{};
          customFields.add(
            CustomFieldInput(
              fieldDefinitionId: def.id,
              type: def.type,
              valueJson: jsonEncode(selected.toList()),
            ),
          );
          break;
        case 'TEXT':
        default:
          final value = textValues[def.id]?.text.trim();
          customFields.add(
            CustomFieldInput(
              fieldDefinitionId: def.id,
              type: def.type,
              valueText: value,
            ),
          );
          break;
      }
    }

    for (final def in definitions.where((d) => d.required)) {
      final field = customFields.firstWhere(
        (f) => f.fieldDefinitionId == def.id,
        orElse: () =>
            CustomFieldInput(fieldDefinitionId: def.id, type: def.type),
      );
      if (!field.hasAnyValue) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Completá el campo requerido: ${def.label}')),
        );
        return;
      }
    }

    final input = ProductInput(
      name: nameCtrl.text.trim(),
      sku: skuCtrl.text.trim().isEmpty ? null : skuCtrl.text.trim(),
      isService: isService,
      stock: double.tryParse(stockCtrl.text) ?? 0,
      buyPrice: double.tryParse(buyCtrl.text) ?? 0,
      sellPrice: double.tryParse(sellCtrl.text) ?? 0,
      customFields: customFields,
    );

    if (product == null) {
      await ref.read(productsControllerProvider).create(input);
    } else {
      await ref.read(productsControllerProvider).update(product.id, input);
    }
    await _load();
  }

  Future<void> _openCreateCustomFieldDialog() async {
    final keyCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    final optionsCtrl = TextEditingController();
    String type = 'TEXT';
    bool required = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Nuevo campo dinámico'),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: keyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Key técnico (sin espacios)',
                        ),
                      ),
                      TextField(
                        controller: labelCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Etiqueta',
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items:
                            const [
                                  'TEXT',
                                  'NUMBER',
                                  'DECIMAL',
                                  'BOOLEAN',
                                  'DATE',
                                  'SELECT',
                                  'MULTISELECT',
                                ]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setLocal(() => type = v ?? 'TEXT'),
                      ),
                      SwitchListTile(
                        value: required,
                        onChanged: (v) => setLocal(() => required = v),
                        title: const Text('Requerido'),
                      ),
                      if (type == 'SELECT' || type == 'MULTISELECT')
                        TextField(
                          controller: optionsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Opciones (separadas por coma)',
                          ),
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
                  child: const Text('Crear campo'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;
    final key = keyCtrl.text.trim();
    final label = labelCtrl.text.trim();
    if (key.isEmpty || label.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Key y etiqueta son obligatorios.')),
      );
      return;
    }

    String? optionsJson;
    if (type == 'SELECT' || type == 'MULTISELECT') {
      final options = optionsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      optionsJson = jsonEncode(options);
    }

    await ref
        .read(productsControllerProvider)
        .createCustomFieldDefinition(
          key: key,
          label: label,
          type: type,
          required: required,
          optionsJson: optionsJson,
        );
  }

  Future<void> _openImages(Product product) async {
    Future<List<ProductImage>> loadImages() {
      return ref.read(productsControllerProvider).listImages(product.id);
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text('Imágenes · ${product.name}'),
              content: SizedBox(
                width: 680,
                height: 420,
                child: FutureBuilder<List<ProductImage>>(
                  future: loadImages(),
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) return Text('Error: ${snap.error}');
                    final items = snap.data ?? const <ProductImage>[];
                    if (items.isEmpty) {
                      return const Center(
                        child: Text('Sin imágenes para este producto.'),
                      );
                    }

                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final img = items[index];
                        return ListTile(
                          leading: img.thumbnailPath == null
                              ? const Icon(Icons.image_outlined)
                              : Image.file(
                                  File(img.thumbnailPath!),
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image_outlined),
                                ),
                          title: Text(img.imagePath),
                          subtitle: Text(
                            img.isPrimary ? 'Principal' : 'Galería',
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                onPressed: img.isPrimary
                                    ? null
                                    : () async {
                                        await ref
                                            .read(productsControllerProvider)
                                            .setPrimaryImage(
                                              productId: product.id,
                                              imageId: img.id,
                                            );
                                        setLocal(() {});
                                      },
                                icon: const Icon(Icons.star_outline),
                                tooltip: 'Marcar principal',
                              ),
                              IconButton(
                                onPressed: () async {
                                  await ref
                                      .read(productsControllerProvider)
                                      .deleteImage(imageId: img.id);
                                  setLocal(() {});
                                },
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Eliminar',
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    final pick = await FilePicker.platform.pickFiles(
                      allowMultiple: false,
                      type: FileType.image,
                    );
                    final path = pick?.files.single.path;
                    if (path == null) return;
                    await ref
                        .read(productsControllerProvider)
                        .addImage(productId: product.id, sourcePath: path);
                    setLocal(() {});
                  },
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Agregar imagen'),
                ),
              ],
            );
          },
        );
      },
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return SaaSScaffold(
      currentRoute: '/products',
      title: 'Productos',
      child: Column(
        children: [
          const LicenseBanner(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar por nombre o SKU',
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: (v) {
                      _searchDebounce?.cancel();
                      _search = v.trim();
                      _page = 0;
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Producto'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _openCreateCustomFieldDialog,
                  icon: const Icon(Icons.tune),
                  label: const Text('Definir campos'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (data) {
                final items = data.items;
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Sin productos. Creá el primero.'),
                  );
                }
                final totalPages = (data.total / _pageSize).ceil();
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final p = items[index];
                          return ListTile(
                            title: Text(p.name),
                            subtitle: Text(
                              'SKU: ${p.sku ?? '-'} · Stock: ${p.stock} · Venta: ${p.sellPrice.toStringAsFixed(2)}',
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  onPressed: () => _openForm(product: p),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  onPressed: () => _openImages(p),
                                  icon: const Icon(
                                    Icons.photo_library_outlined,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    await ref
                                        .read(productsControllerProvider)
                                        .delete(p.id);
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
                            'Página ${_page + 1} de ${totalPages == 0 ? 1 : totalPages}',
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
                            onPressed: (_page + 1) < totalPages
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

  Widget _buildCustomFieldInput({
    required BuildContext context,
    required void Function(void Function()) setLocal,
    required ProductCustomFieldDefinition def,
    required Map<String, TextEditingController> textValues,
    required Map<String, bool> boolValues,
    required Map<String, DateTime?> dateValues,
    required Map<String, String?> selectValues,
    required Map<String, Set<String>> multiValues,
  }) {
    final label = def.required ? '${def.label} *' : def.label;
    final options = _decodeOptions(def.optionsJson);

    switch (def.type) {
      case 'NUMBER':
      case 'DECIMAL':
      case 'TEXT':
        return TextField(
          controller: textValues[def.id],
          decoration: InputDecoration(labelText: label),
          keyboardType: def.type == 'TEXT'
              ? TextInputType.text
              : TextInputType.number,
        );
      case 'BOOLEAN':
        return SwitchListTile(
          value: boolValues[def.id] ?? false,
          onChanged: (v) => setLocal(() => boolValues[def.id] = v),
          title: Text(label),
        );
      case 'DATE':
        final date = dateValues[def.id];
        final text = date == null
            ? 'Seleccionar fecha'
            : '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          subtitle: Text(text),
          trailing: const Icon(Icons.event_outlined),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setLocal(() => dateValues[def.id] = picked);
            }
          },
        );
      case 'SELECT':
        return DropdownButtonFormField<String>(
          initialValue: selectValues[def.id],
          decoration: InputDecoration(labelText: label),
          items: options
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setLocal(() => selectValues[def.id] = v),
        );
      case 'MULTISELECT':
        final selected = multiValues[def.id] ?? <String>{};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(label),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final option in options)
                  FilterChip(
                    selected: selected.contains(option),
                    label: Text(option),
                    onSelected: (isSelected) {
                      setLocal(() {
                        final base = multiValues[def.id] ?? <String>{};
                        if (isSelected) {
                          base.add(option);
                        } else {
                          base.remove(option);
                        }
                        multiValues[def.id] = base;
                      });
                    },
                  ),
              ],
            ),
          ],
        );
      default:
        return TextField(
          controller: textValues[def.id],
          decoration: InputDecoration(labelText: label),
        );
    }
  }

  List<String> _decodeOptions(String? json) {
    if (json == null || json.trim().isEmpty) return const [];
    try {
      final parsed = jsonDecode(json) as List<dynamic>;
      return parsed.map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }
}
