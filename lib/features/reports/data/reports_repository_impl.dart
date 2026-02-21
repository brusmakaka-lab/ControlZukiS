import 'dart:io';

import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/storage/app_paths.dart';
import 'package:controlzukis/features/reports/domain/models/report_filters.dart';
import 'package:controlzukis/features/reports/domain/models/report_summary.dart';
import 'package:controlzukis/features/reports/domain/repositories/reports_repository.dart';
import 'package:drift/drift.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/widgets.dart' as pw;

class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl(this._db);

  final AppDatabase _db;

  Future<(String tenantId, String branchId)> _ctx() async {
    final meta = await _db.getAppMeta();
    final tenantId = meta?.currentTenantId;
    final branchId = meta?.currentBranchId;
    if (tenantId == null || branchId == null) {
      throw StateError('Contexto no configurado');
    }
    return (tenantId, branchId);
  }

  Future<ReportSummary> _buildSummary(ReportFilters filters) async {
    final (tenantId, branchId) = await _ctx();

    final salesTotalExp = _db.sales.total.sum();
    final salesCountExp = _db.sales.id.count();
    final sq = _db.selectOnly(_db.sales)
      ..addColumns([salesTotalExp, salesCountExp]);
    sq.where(
      _db.sales.tenantId.equals(tenantId) &
          _db.sales.branchId.equals(branchId) &
          _db.sales.date.isBiggerOrEqualValue(filters.from) &
          _db.sales.date.isSmallerOrEqualValue(filters.to),
    );
    final srow = await sq.getSingle();

    final expensesTotalExp = _db.expenses.amount.sum();
    final expensesCountExp = _db.expenses.id.count();
    final eq = _db.selectOnly(_db.expenses)
      ..addColumns([expensesTotalExp, expensesCountExp]);
    eq.where(
      _db.expenses.tenantId.equals(tenantId) &
          _db.expenses.branchId.equals(branchId) &
          _db.expenses.date.isBiggerOrEqualValue(filters.from) &
          _db.expenses.date.isSmallerOrEqualValue(filters.to),
    );
    final erow = await eq.getSingle();

    final sales = srow.read(salesTotalExp) ?? 0;
    final expenses = erow.read(expensesTotalExp) ?? 0;

    return ReportSummary(
      salesTotal: sales,
      expensesTotal: expenses,
      net: sales - expenses,
      salesCount: srow.read(salesCountExp) ?? 0,
      expensesCount: erow.read(expensesCountExp) ?? 0,
    );
  }

  @override
  Future<ReportSummary> summary(ReportFilters filters) {
    return _buildSummary(filters);
  }

  @override
  Future<String> exportPdf(ReportFilters filters) async {
    final data = await _buildSummary(filters);
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('ControlZukiS - Reporte'),
              pw.SizedBox(height: 8),
              pw.Text('Desde: ${filters.from.toIso8601String()}'),
              pw.Text('Hasta: ${filters.to.toIso8601String()}'),
              pw.SizedBox(height: 16),
              pw.Text('Ventas: ${data.salesTotal.toStringAsFixed(2)}'),
              pw.Text('Gastos: ${data.expensesTotal.toStringAsFixed(2)}'),
              pw.Text('Neto: ${data.net.toStringAsFixed(2)}'),
              pw.Text('Cant. ventas: ${data.salesCount}'),
              pw.Text('Cant. gastos: ${data.expensesCount}'),
            ],
          );
        },
      ),
    );

    final dir = await AppPaths.appDir();
    final file = File(
      p.join(dir.path, 'report_${DateTime.now().millisecondsSinceEpoch}.pdf'),
    );
    await file.writeAsBytes(await doc.save());
    return file.path;
  }

  @override
  Future<String> exportExcel(ReportFilters filters) async {
    final data = await _buildSummary(filters);
    final excel = Excel.createExcel();
    final sheet = excel['Reporte'];
    sheet.appendRow([
      TextCellValue('Desde'),
      TextCellValue(filters.from.toIso8601String()),
    ]);
    sheet.appendRow([
      TextCellValue('Hasta'),
      TextCellValue(filters.to.toIso8601String()),
    ]);
    sheet.appendRow([
      TextCellValue('Ventas'),
      DoubleCellValue(data.salesTotal),
    ]);
    sheet.appendRow([
      TextCellValue('Gastos'),
      DoubleCellValue(data.expensesTotal),
    ]);
    sheet.appendRow([TextCellValue('Neto'), DoubleCellValue(data.net)]);
    sheet.appendRow([
      TextCellValue('Cant. ventas'),
      IntCellValue(data.salesCount),
    ]);
    sheet.appendRow([
      TextCellValue('Cant. gastos'),
      IntCellValue(data.expensesCount),
    ]);

    final bytes = excel.save();
    if (bytes == null) throw StateError('No se pudo generar Excel');
    final dir = await AppPaths.appDir();
    final file = File(
      p.join(dir.path, 'report_${DateTime.now().millisecondsSinceEpoch}.xlsx'),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
