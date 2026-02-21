class SuperAdminDiagnostics {
  const SuperAdminDiagnostics({
    required this.appDirPath,
    required this.dbPath,
    required this.dbSizeBytes,
    required this.logsPath,
    required this.logsSizeBytes,
    required this.imagesCount,
    required this.thumbsCount,
    required this.now,
  });

  final String appDirPath;
  final String dbPath;
  final int dbSizeBytes;
  final String logsPath;
  final int logsSizeBytes;
  final int imagesCount;
  final int thumbsCount;
  final DateTime now;
}
