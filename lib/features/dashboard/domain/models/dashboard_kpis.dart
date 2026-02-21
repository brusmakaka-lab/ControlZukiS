class DashboardKpis {
  const DashboardKpis({
    required this.totalProducts,
    required this.lowStockProducts,
    required this.totalCustomers,
    required this.salesToday,
    required this.salesMonth,
    required this.expensesMonth,
    required this.netMonth,
    required this.last7DaysSales,
    required this.last7DaysExpenses,
  });

  final int totalProducts;
  final int lowStockProducts;
  final int totalCustomers;
  final double salesToday;
  final double salesMonth;
  final double expensesMonth;
  final double netMonth;
  final List<double> last7DaysSales;
  final List<double> last7DaysExpenses;
}
