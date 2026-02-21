import 'package:controlzukis/core/database/app_database.dart';
import 'package:controlzukis/core/guards/guard_result.dart';

class RoleGuard {
  const RoleGuard(this._db);

  final AppDatabase _db;

  Future<GuardResult> canWrite({required List<String> allowedRoles}) async {
    final meta = await _db.getAppMeta();
    final currentUserId = meta?.currentUserId;
    if (currentUserId == null) {
      return const GuardResult.deny('No hay usuario activo');
    }

    final user =
        await (_db.select(_db.users)
              ..where((u) => u.id.equals(currentUserId))
              ..limit(1))
            .getSingleOrNull();

    if (user == null) {
      return const GuardResult.deny('Usuario no encontrado');
    }

    if (!user.isActive) {
      return const GuardResult.deny('Usuario inactivo');
    }

    if (!allowedRoles.contains(user.role)) {
      return GuardResult.deny('Rol ${user.role} no autorizado para escritura');
    }

    return const GuardResult.allow();
  }
}
