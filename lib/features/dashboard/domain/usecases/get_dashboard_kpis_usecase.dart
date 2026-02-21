import 'package:controlzukis/features/dashboard/domain/models/dashboard_kpis.dart';
import 'package:controlzukis/features/dashboard/domain/repositories/dashboard_repository.dart';

class GetDashboardKpisUseCase {
  const GetDashboardKpisUseCase(this._repository);

  final DashboardRepository _repository;

  Future<DashboardKpis> call() {
    return _repository.getKpis();
  }
}
