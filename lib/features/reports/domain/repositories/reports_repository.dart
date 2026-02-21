import 'package:controlzukis/features/reports/domain/models/report_filters.dart';
import 'package:controlzukis/features/reports/domain/models/report_summary.dart';

abstract class ReportsRepository {
  Future<ReportSummary> summary(ReportFilters filters);
  Future<String> exportPdf(ReportFilters filters);
  Future<String> exportExcel(ReportFilters filters);
}
