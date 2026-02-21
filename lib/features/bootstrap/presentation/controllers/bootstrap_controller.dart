import 'package:controlzukis/app/router/routing_snapshot.dart';
import 'package:controlzukis/core/providers/core_providers.dart';
import 'package:controlzukis/core/services/device_service.dart';
import 'package:controlzukis/features/bootstrap/data/bootstrap_repository_impl.dart';
import 'package:controlzukis/features/bootstrap/domain/repositories/bootstrap_repository.dart';
import 'package:controlzukis/features/bootstrap/domain/usecases/bootstrap_app_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deviceServiceProvider = Provider<DeviceService>(
  (ref) => const DeviceService(),
);

final bootstrapRepositoryProvider = Provider<BootstrapRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final deviceService = ref.watch(deviceServiceProvider);
  return BootstrapRepositoryImpl(database: db, deviceService: deviceService);
});

final bootstrapUseCaseProvider = Provider<BootstrapAppUseCase>((ref) {
  final repository = ref.watch(bootstrapRepositoryProvider);
  return BootstrapAppUseCase(repository);
});

final bootstrapControllerProvider = FutureProvider.autoDispose<RoutingSnapshot>(
  (ref) async {
    final useCase = ref.watch(bootstrapUseCaseProvider);
    return useCase();
  },
);
