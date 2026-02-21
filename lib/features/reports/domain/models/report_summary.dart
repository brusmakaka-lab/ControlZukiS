class ReportSummary {
  const ReportSummary({
    required this.salesTotal,
    required this.expensesTotal,
    required this.net,
    required this.salesCount,
    required this.expensesCount,
  });

  final double salesTotal;
  final double expensesTotal;
  final double net;
  final int salesCount;
  final int expensesCount;
}
