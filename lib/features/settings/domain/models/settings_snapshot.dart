import 'package:controlzukis/core/database/app_database.dart';

class SettingsSnapshot {
  const SettingsSnapshot({
    required this.tenant,
    required this.meta,
    required this.users,
  });

  final Tenant tenant;
  final AppMeta meta;
  final List<User> users;
}
