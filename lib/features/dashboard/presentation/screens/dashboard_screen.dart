import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import 'package:controlzukis/core/theme/app_theme.dart';
import 'package:controlzukis/core/widgets/app_ui.dart';
import 'package:controlzukis/features/dashboard/domain/models/dashboard_kpis.dart';
import 'package:controlzukis/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:controlzukis/features/license/presentation/widgets/license_banner.dart';
import 'package:controlzukis/features/license/presentation/widgets/read_only_blocker.dart';
import 'package:controlzukis/core/widgets/saas_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncKpis = ref.watch(dashboardKpisProvider);
    return SaaSScaffold(
      currentRoute: '/dashboard',
      title: 'Dashboard',
      child: Column(
        children: [
          const LicenseBanner(),
          Expanded(
            child: ReadOnlyBlocker(
              child: asyncKpis.when(
                loading: () => const LoadingSkeleton(lines: 8),
                error: (e, st) => ErrorState(message: 'Error KPI: $e'),
                data: (kpis) => _DashboardBody(kpis: kpis),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.kpis});

  final DashboardKpis kpis;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Resumen financiero',
            subtitle: 'Indicadores clave en tiempo real desde SQLite local',
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: KPIStatCard(
                  title: 'Ventas hoy',
                  value: kpis.salesToday.toStringAsFixed(2),
                  icon: Icons.today_outlined,
                ),
              ),
              SizedBox(
                width: 220,
                child: KPIStatCard(
                  title: 'Ventas mes',
                  value: kpis.salesMonth.toStringAsFixed(2),
                  icon: Icons.trending_up_outlined,
                ),
              ),
              SizedBox(
                width: 220,
                child: KPIStatCard(
                  title: 'Gastos mes',
                  value: kpis.expensesMonth.toStringAsFixed(2),
                  icon: Icons.money_off_csred_outlined,
                ),
              ),
              SizedBox(
                width: 220,
                child: KPIStatCard(
                  title: 'Neto mes',
                  value: kpis.netMonth.toStringAsFixed(2),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              SizedBox(
                width: 220,
                child: KPIStatCard(
                  title: 'Productos',
                  value: '${kpis.totalProducts}',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              SizedBox(
                width: 220,
                child: KPIStatCard(
                  title: 'Stock bajo',
                  value: '${kpis.lowStockProducts}',
                  icon: Icons.warning_amber_outlined,
                ),
              ),
              SizedBox(
                width: 220,
                child: KPIStatCard(
                  title: 'Clientes',
                  value: '${kpis.totalCustomers}',
                  icon: Icons.groups_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: SizedBox(
                height: 260,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: 6,
                    minY: 0,
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < kpis.last7DaysSales.length; i++)
                            FlSpot(i.toDouble(), kpis.last7DaysSales[i]),
                        ],
                        isCurved: true,
                        dotData: const FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: [
                          for (
                            var i = 0;
                            i < kpis.last7DaysExpenses.length;
                            i++
                          )
                            FlSpot(i.toDouble(), kpis.last7DaysExpenses[i]),
                        ],
                        isCurved: true,
                        color: Colors.red,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const AppSectionHeader(
            title: 'Accesos rápidos',
            subtitle: 'Atajos de operación diaria',
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppPrimaryButton(
                onPressed: () => context.go('/products'),
                icon: Icons.inventory_2_outlined,
                label: 'Productos',
              ),
              AppSecondaryButton(
                onPressed: () => context.go('/categories'),
                icon: Icons.category_outlined,
                label: 'Categorías',
              ),
              AppSecondaryButton(
                onPressed: () => context.go('/sales'),
                icon: Icons.point_of_sale_outlined,
                label: 'Ventas',
              ),
              AppSecondaryButton(
                onPressed: () => context.go('/expenses'),
                icon: Icons.receipt_long_outlined,
                label: 'Gastos/Compras',
              ),
              AppSecondaryButton(
                onPressed: () => context.go('/customers'),
                icon: Icons.groups_outlined,
                label: 'Clientes',
              ),
              AppSecondaryButton(
                onPressed: () => context.go('/reports'),
                icon: Icons.assessment_outlined,
                label: 'Reportes',
              ),
              AppSecondaryButton(
                onPressed: () => context.go('/settings'),
                icon: Icons.settings_outlined,
                label: 'Settings',
              ),
              AppSecondaryButton(
                onPressed: () => context.go('/superadmin'),
                icon: Icons.admin_panel_settings_outlined,
                label: 'SuperAdmin',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
