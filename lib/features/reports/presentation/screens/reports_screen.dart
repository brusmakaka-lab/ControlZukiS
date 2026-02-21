import 'package:controlzukis/features/license/presentation/widgets/license_banner.dart';
import 'package:controlzukis/core/widgets/saas_scaffold.dart';
import 'package:controlzukis/features/reports/domain/models/report_filters.dart';
import 'package:controlzukis/features/reports/domain/models/report_summary.dart';
import 'package:controlzukis/features/reports/presentation/controllers/reports_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime _from;
  late DateTime _to;
  AsyncValue<ReportSummary> _state = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = now;
    _load();
  }

  ReportFilters get _filters => ReportFilters(from: _from, to: _to);

  Future<void> _load() async {
    setState(() => _state = const AsyncLoading());
    _state = await AsyncValue.guard(
      () => ref.read(reportsControllerProvider).summary(_filters),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SaaSScaffold(
      currentRoute: '/reports',
      title: 'Reportes',
      child: Column(
        children: [
          const LicenseBanner(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _from,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _from = picked);
                      _load();
                    }
                  },
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    'Desde: ${_from.toIso8601String().split('T').first}',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _to,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _to = picked);
                      _load();
                    }
                  },
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    'Hasta: ${_to.toIso8601String().split('T').first}',
                  ),
                ),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final path = await ref
                        .read(reportsControllerProvider)
                        .exportPdf(_filters);
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('PDF exportado: $path')),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Exportar PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final path = await ref
                        .read(reportsControllerProvider)
                        .exportExcel(_filters);
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Excel exportado: $path')),
                    );
                  },
                  icon: const Icon(Icons.grid_on_outlined),
                  label: const Text('Exportar Excel'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (data) => Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ventas: ${data.salesTotal.toStringAsFixed(2)}'),
                        Text(
                          'Gastos: ${data.expensesTotal.toStringAsFixed(2)}',
                        ),
                        Text('Neto: ${data.net.toStringAsFixed(2)}'),
                        Text('Cantidad ventas: ${data.salesCount}'),
                        Text('Cantidad gastos: ${data.expensesCount}'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
