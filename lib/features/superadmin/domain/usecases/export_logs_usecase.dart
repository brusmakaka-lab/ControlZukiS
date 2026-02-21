import 'package:controlzukis/features/superadmin/domain/repositories/superadmin_repository.dart';

class ExportLogsUseCase {
  const ExportLogsUseCase(this._repository);

  final SuperAdminRepository _repository;

  Future<String> call() => _repository.exportLogs();
}
