import 'package:controlzukis/app/router/routing_snapshot.dart';
import 'package:controlzukis/features/bootstrap/domain/repositories/bootstrap_repository.dart';

class BootstrapAppUseCase {
  const BootstrapAppUseCase(this._repository);

  final BootstrapRepository _repository;

  Future<RoutingSnapshot> call() {
    return _repository.initialize();
  }
}
