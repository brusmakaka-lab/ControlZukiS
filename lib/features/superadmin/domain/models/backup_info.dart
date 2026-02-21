class BackupInfo {
  const BackupInfo({
    required this.filePath,
    required this.sha256,
    required this.createdAt,
  });

  final String filePath;
  final String sha256;
  final DateTime createdAt;
}
