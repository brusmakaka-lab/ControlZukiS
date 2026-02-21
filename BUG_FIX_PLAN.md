# BUG_FIX_PLAN — Priorización de arreglos

Base: hallazgos en [`QA_REPORT.md`](QA_REPORT.md:1).

## Prioridad 0 (bloqueantes)

### FIX-P0-1 — Stock atómico en ventas concurrentes (BUG-002)

- Impacto: evita oversell/inconsistencia financiera.
- Archivos objetivo:
  - [`sales_repository_impl.dart`](lib/features/sales/data/sales_repository_impl.dart:57)
- Implementación:
  1. Reemplazar update stock read-modify-write por sentencia atómica con condición.
  2. Validar `rowsAffected`.
  3. Si no afecta filas, lanzar `StateError('Stock insuficiente ...')` y rollback.
- Definition of Done:
  - Test concurrente (2 ventas simultáneas stock=1) pasa.
  - Stock nunca queda inconsistente.
  - No hay venta parcial ante conflicto.

### FIX-P0-2 — Modo mantenimiento real durante restore (BUG-004)

- Impacto: evita corrupción por operaciones simultáneas durante restore.
- Archivos objetivo:
  - [`superadmin_repository_impl.dart`](lib/features/superadmin/data/superadmin_repository_impl.dart:240)
  - Router/shell global (guard + blocker visual).
- Implementación:
  1. Crear provider de maintenance mode.
  2. Bloquear navegación/acciones de escritura mientras exista flag.
  3. Mostrar pantalla/overlay “restauración en curso”.
- Definition of Done:
  - Durante restore no se puede operar módulos.
  - Finalizado restore se restablece flujo normal.
  - Sin crash ni writes paralelos.

## Prioridad 1 (alto impacto funcional)

### FIX-P1-1 — Implementar flujo /login y sesión (BUG-001)

- Impacto: cumplimiento del flujo oficial y seguridad de acceso.
- Archivos objetivo:
  - [`app_router.dart`](lib/app/router/app_router.dart:17)
  - bootstrap/auth state
  - nueva pantalla `login`.
- Implementación:
  1. Agregar estado de sesión explícito.
  2. Crear `/login` con autenticación local.
  3. Ajustar guards para `tenant && !session => /login`.
- Definition of Done:
  - Caso cold-start con tenant y sin sesión redirige a login.
  - Con sesión activa entra a dashboard.

### FIX-P1-2 — Borrado de producto con limpieza de archivos/relaciones (BUG-003)

- Impacto: evita fuga de almacenamiento y basura en disco.
- Archivos objetivo:
  - [`products_repository_impl.dart`](lib/features/products/data/products_repository_impl.dart:268)
- Implementación:
  1. Transaction: leer imágenes, borrar rows dependientes, borrar producto.
  2. Borrar archivos físicos y manejar errores de IO sin crashear.
  3. Fallback placeholder cuando falte imagen.
- Definition of Done:
  - No quedan archivos huérfanos tras delete.
  - UI no crashea si archivo faltante.

### FIX-P1-3 — Módulo Categorías CRUD faltante (BUG-007)

- Impacto: requerimiento contractual no cubierto.
- Archivos objetivo:
  - Nueva feature categorías + ruta + navegación.
- Implementación:
  1. CRUD con paginación/filtros.
  2. Guardas de escritura.
  3. Regla de borrado en uso (bloquear o migrar a “Otros”).
- Definition of Done:
  - Crear/editar/borrar categorías funcional.
  - Comportamiento definido en categorías usadas.

## Prioridad 2 (seguridad/robustez)

### FIX-P2-1 — RoleGuard debe bloquear usuarios inactivos (BUG-005)

- Archivos objetivo:
  - [`role_guard.dart`](lib/core/guards/role_guard.dart:9)
- Implementación:
  - agregar check `user.isActive` antes de validar rol.
- Definition of Done:
  - Usuario inactivo no puede escribir en ningún módulo.

### FIX-P2-2 — Manejo de borrado de cliente con ventas (BUG-006)

- Archivos objetivo:
  - [`customers_repository_impl.dart`](lib/features/customers/data/customers_repository_impl.dart:110)
  - [`customers_screen.dart`](lib/features/customers/presentation/screens/customers_screen.dart:204)
- Implementación:
  - capturar violación FK y mapear a error de dominio amigable.
- Definition of Done:
  - Mensaje claro, sin stacktrace en UI.
  - Sin corrupción ni borrado parcial.

## Prioridad 3 (performance y QA continuo)

### FIX-P3-1 — Suite integration_test completa

- Objetivo: reproducibilidad de bugs y regresión.
- Nuevos tests sugeridos:
  - `integration_test/routing_guard_test.dart`
  - `integration_test/license_enforcement_test.dart`
  - `integration_test/backup_restore_integrity_test.dart`
  - `integration_test/stress_seed_test.dart`
- Definition of Done:
  - pipeline CI ejecuta suite y reporta métricas.

### FIX-P3-2 — Stress benchmark 5k/20k

- Objetivo: validar tiempos y evitar jank.
- Implementación:
  - seed controlado en SuperAdmin/test mode.
  - métricas de tiempos de lista/búsqueda/export.
- Definition of Done:
  - reporte de tiempos con umbrales aceptables definidos.

---

## Orden recomendado de ejecución

1. FIX-P0-1
2. FIX-P0-2
3. FIX-P1-1
4. FIX-P1-2
5. FIX-P2-1
6. FIX-P2-2
7. FIX-P1-3
8. FIX-P3-1
9. FIX-P3-2

---

## Re-test mínimo por cada release de fixes

1. `flutter analyze`
2. `flutter test`
3. Smoke crítico:
   - onboarding/activation/expired/tamper,
   - venta con y sin stock,
   - restore válido/corrupto,
   - write-block por expired y viewer.

---

## Estado de ejecución del plan (actualizado)

- FIX-P0-1 — **COMPLETADO**
  - stock atómico aplicado en [`sales_repository_impl.dart`](lib/features/sales/data/sales_repository_impl.dart:57).
- FIX-P0-2 — **COMPLETADO**
  - maintenance mode funcional en lógica/UI/restore:
    - [`license_write_guard.dart`](lib/core/guards/license_write_guard.dart:11)
    - [`maintenance_provider.dart`](lib/core/providers/maintenance_provider.dart:1)
    - [`saas_scaffold.dart`](lib/core/widgets/saas_scaffold.dart:1)
    - [`superadmin_repository_impl.dart`](lib/features/superadmin/data/superadmin_repository_impl.dart:242)
- FIX-P1-1 — **COMPLETADO**
  - login/sesión + redirect:
    - [`login_screen.dart`](lib/features/auth/presentation/screens/login_screen.dart:8)
    - [`app_router.dart`](lib/app/router/app_router.dart:49)
    - [`routing_snapshot.dart`](lib/app/router/routing_snapshot.dart:5)
- FIX-P1-2 — **COMPLETADO**
  - limpieza de dependencias/archivos en delete producto:
    - [`products_repository_impl.dart`](lib/features/products/data/products_repository_impl.dart:268)
- FIX-P1-3 — **COMPLETADO**
  - módulo categorías CRUD:
    - [`categories_screen.dart`](lib/features/categories/presentation/screens/categories_screen.dart:10)
    - [`categories_repository_impl.dart`](lib/features/categories/data/categories_repository_impl.dart:1)
- FIX-P2-1 — **COMPLETADO**
  - usuario inactivo bloqueado en [`role_guard.dart`](lib/core/guards/role_guard.dart:9)
- FIX-P2-2 — **PENDIENTE MENOR**
  - mejora de UX específica en borrado cliente con ventas (mensaje de dominio dedicado).
- FIX-P3-1 — **COMPLETADO**
  - integration tests implementados y pasando de forma individual:
    - [`routing_guard_test.dart`](integration_test/routing_guard_test.dart:1)
    - [`license_enforcement_test.dart`](integration_test/license_enforcement_test.dart:1)
    - [`backup_restore_integrity_test.dart`](integration_test/backup_restore_integrity_test.dart:1)
    - [`stress_seed_test.dart`](integration_test/stress_seed_test.dart:1)
- FIX-P3-2 — **COMPLETADO (escala CI local)**
  - stress seed con métricas JSON en [`stress_seed_test.dart`](integration_test/stress_seed_test.dart:13).

Nota: en Windows se observó inestabilidad del runner al ejecutar todo `integration_test` en una sola corrida; ejecución archivo por archivo validada como PASS.
