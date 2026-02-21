import 'package:controlzukis/app/router/routing_snapshot.dart';

class BootstrapResult {
  const BootstrapResult({
    required this.snapshot,
    required this.currentTenantId,
  });

  final RoutingSnapshot snapshot;
  final String? currentTenantId;
}
