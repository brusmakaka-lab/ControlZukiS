import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/features/dashboard/domain/models/dashboard_kpis.dart';
import 'package:controlzukis/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:drift/drift.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._db);

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

  Future<double> _sumSales(
    String tenantId,
    String branchId,
    DateTime from,
    DateTime to,
  ) async {
    final sumExp = _db.sales.total.sum();
    final q = _db.selectOnly(_db.sales)..addColumns([sumExp]);
    q.where(
      _db.sales.tenantId.equals(tenantId) &
          _db.sales.branchId.equals(branchId) &
          _db.sales.date.isBiggerOrEqualValue(from) &
          _db.sales.date.isSmallerThanValue(to),
    );
    final row = await q.getSingle();
    return row.read(sumExp) ?? 0;
  }

  Future<double> _sumExpenses(
    String tenantId,
    String branchId,
    DateTime from,
    DateTime to,
  ) async {
    final sumExp = _db.expenses.amount.sum();
    final q = _db.selectOnly(_db.expenses)..addColumns([sumExp]);
    q.where(
      _db.expenses.tenantId.equals(tenantId) &
          _db.expenses.branchId.equals(branchId) &
          _db.expenses.date.isBiggerOrEqualValue(from) &
          _db.expenses.date.isSmallerThanValue(to),
    );
    final row = await q.getSingle();
    return row.read(sumExp) ?? 0;
  }

  @override
  Future<DashboardKpis> getKpis() async {
    final (tenantId, branchId) = await _ctx();
    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    final startTomorrow = startToday.add(const Duration(days: 1));
    final startMonth = DateTime(now.year, now.month, 1);
    final startNextMonth = DateTime(now.year, now.month + 1, 1);

    final totalProductsExp = _db.products.id.count();
    final lowStockProductsExp = _db.products.id.count(
      filter:
          _db.products.isService.equals(false) &
          _db.products.isInventoriable.equals(true) &
          _db.products.stock.isSmallerOrEqual(_db.products.minStock),
    );
    final totalCustomersExp = _db.customers.id.count();

    final pQuery = _db.selectOnly(_db.products)
      ..addColumns([totalProductsExp, lowStockProductsExp]);
    pQuery.where(
      _db.products.tenantId.equals(tenantId) &
          _db.products.branchId.equals(branchId),
    );
    final pRow = await pQuery.getSingle();

    final cQuery = _db.selectOnly(_db.customers)
      ..addColumns([totalCustomersExp]);
    cQuery.where(_db.customers.tenantId.equals(tenantId));
    final cRow = await cQuery.getSingle();

    final salesToday = await _sumSales(
      tenantId,
      branchId,
      startToday,
      startTomorrow,
    );
    final salesMonth = await _sumSales(
      tenantId,
      branchId,
      startMonth,
      startNextMonth,
    );
    final expensesMonth = await _sumExpenses(
      tenantId,
      branchId,
      startMonth,
      startNextMonth,
    );

    final last7Sales = <double>[];
    final last7Expenses = <double>[];
    for (var i = 6; i >= 0; i--) {
      final dayStart = startToday.subtract(Duration(days: i));
      final dayEnd = dayStart.add(const Duration(days: 1));
      last7Sales.add(await _sumSales(tenantId, branchId, dayStart, dayEnd));
      last7Expenses.add(
        await _sumExpenses(tenantId, branchId, dayStart, dayEnd),
      );
    }

    return DashboardKpis(
      totalProducts: pRow.read(totalProductsExp) ?? 0,
      lowStockProducts: pRow.read(lowStockProductsExp) ?? 0,
      totalCustomers: cRow.read(totalCustomersExp) ?? 0,
      salesToday: salesToday,
      salesMonth: salesMonth,
      expensesMonth: expensesMonth,
      netMonth: salesMonth - expensesMonth,
      last7DaysSales: last7Sales,
      last7DaysExpenses: last7Expenses,
    );
  }
}
