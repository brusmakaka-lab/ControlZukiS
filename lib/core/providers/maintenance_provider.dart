import 'dart:async';

import 'package:controlzukis/core/providers/core_providers.dart';
import 'package:controlzukis/core/storage/app_paths.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final maintenanceModeProvider = StreamProvider<bool>((ref) async* {
  final db = ref.watch(appDatabaseProvider);

  Future<bool> readState() async {
    final meta = await db.getAppMeta();
    final flag = await AppPaths.maintenanceFlagFile();
    return (meta?.maintenanceMode ?? false) || flag.existsSync();
  }

  yield await readState();
  while (true) {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    yield await readState();
  }
});
