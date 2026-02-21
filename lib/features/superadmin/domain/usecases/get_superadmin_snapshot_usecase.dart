import 'package:controlzukis/features/superadmin/domain/models/superadmin_state_snapshot.dart';
import 'package:controlzukis/features/superadmin/domain/repositories/superadmin_repository.dart';

class GetSuperAdminSnapshotUseCase {
  const GetSuperAdminSnapshotUseCase(this._repository);

  final SuperAdminRepository _repository;

  Future<SuperAdminStateSnapshot> call() => _repository.getSnapshot();
}
