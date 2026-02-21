import 'package:controlzukis/features/superadmin/domain/repositories/superadmin_repository.dart';

class ResetDemoUseCase {
  const ResetDemoUseCase(this._repository);

  final SuperAdminRepository _repository;

  Future<void> call() => _repository.resetDemo();
}
