import 'package:controlzukis/features/dashboard/domain/models/dashboard_kpis.dart';

abstract class DashboardRepository {
  Future<DashboardKpis> getKpis();
}
