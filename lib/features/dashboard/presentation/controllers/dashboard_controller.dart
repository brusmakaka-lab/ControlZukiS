import 'package:controlzukis/core/providers/core_providers.dart';
import 'package:controlzukis/features/dashboard/data/dashboard_repository_impl.dart';
import 'package:controlzukis/features/dashboard/domain/models/dashboard_kpis.dart';
import 'package:controlzukis/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:controlzukis/features/dashboard/domain/usecases/get_dashboard_kpis_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(appDatabaseProvider));
});

final getDashboardKpisUseCaseProvider = Provider<GetDashboardKpisUseCase>(
  (ref) => GetDashboardKpisUseCase(ref.watch(dashboardRepositoryProvider)),
);

final dashboardKpisProvider = FutureProvider.autoDispose<DashboardKpis>((
  ref,
) async {
  final useCase = ref.watch(getDashboardKpisUseCaseProvider);
  return useCase();
});
