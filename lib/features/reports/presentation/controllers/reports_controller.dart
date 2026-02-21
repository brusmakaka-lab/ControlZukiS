import 'package:controlzukis/core/providers/core_providers.dart';
import 'package:controlzukis/features/reports/data/reports_repository_impl.dart';
import 'package:controlzukis/features/reports/domain/models/report_filters.dart';
import 'package:controlzukis/features/reports/domain/models/report_summary.dart';
import 'package:controlzukis/features/reports/domain/repositories/reports_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepositoryImpl(ref.watch(appDatabaseProvider));
});

class ReportsController {
  const ReportsController(this._ref);

  final Ref _ref;

  Future<ReportSummary> summary(ReportFilters filters) {
    return _ref.read(reportsRepositoryProvider).summary(filters);
  }

  Future<String> exportPdf(ReportFilters filters) {
    return _ref.read(reportsRepositoryProvider).exportPdf(filters);
  }

  Future<String> exportExcel(ReportFilters filters) {
    return _ref.read(reportsRepositoryProvider).exportExcel(filters);
  }
}

final reportsControllerProvider = Provider<ReportsController>(
  ReportsController.new,
);
