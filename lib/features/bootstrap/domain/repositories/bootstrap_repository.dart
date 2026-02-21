import 'package:controlzukis/app/router/routing_snapshot.dart';

abstract class BootstrapRepository {
  Future<RoutingSnapshot> initialize();
}
