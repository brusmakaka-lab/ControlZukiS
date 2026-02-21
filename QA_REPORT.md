# QA / Security / Performance Report — ControlZukiS

Fecha: 2026-02-21  
Scope: Offline Flutter + Drift(SQLite), routing/guards, CRUD, licencias, backup/restore, performance.

## 1) Evidencia ejecutada

- `flutter analyze` => **PASS** (sin issues)
- `flutter test` => **PASS** (suite actual mínima)
- Auditoría estática de flujo/guards/repositorios en:
  - [`app_router.dart`](lib/app/router/app_router.dart:17)
  - [`bootstrap_repository_impl.dart`](lib/features/bootstrap/data/bootstrap_repository_impl.dart:23)
  - [`license_write_guard.dart`](lib/core/guards/license_write_guard.dart:10)
  - [`role_guard.dart`](lib/core/guards/role_guard.dart:9)
  - [`sales_repository_impl.dart`](lib/features/sales/data/sales_repository_impl.dart:57)
  - [`products_repository_impl.dart`](lib/features/products/data/products_repository_impl.dart:118)
  - [`superadmin_repository_impl.dart`](lib/features/superadmin/data/superadmin_repository_impl.dart:163)

> Nota: varios casos pedidos (deep links reales, back button sistema, stress 5k/20k, permisos OS) requieren `integration_test` + harness de datos/entorno. Se marcan como **NO EJECUTADO** con plan de automatización al final.

---

## 2) Matriz de pruebas (resultado)

| ID   | Área         | Caso                                              | Resultado    | Evidencia                                                                                                                                |
| ---- | ------------ | ------------------------------------------------- | ------------ | ---------------------------------------------------------------------------------------------------------------------------------------- |
| F-01 | Routing      | Cold start DB vacía => onboarding                 | PASS         | [`bootstrap_repository_impl.initialize()`](lib/features/bootstrap/data/bootstrap_repository_impl.dart:27)                                |
| F-02 | Routing      | Tamper => redirect activation                     | PASS         | [`AppRoutePhase.activation`](lib/app/router/app_router.dart:34)                                                                          |
| F-03 | Routing      | Expired => shell read-only                        | PASS parcial | Overlay/banner en [`saas_scaffold.dart`](lib/core/widgets/saas_scaffold.dart:85), bloqueo lógico en guards                               |
| F-04 | Routing      | Estado tenant + sin sesión => /login              | FAIL         | No existe ruta/login screen (0 matches)                                                                                                  |
| F-05 | Routing      | Deep links inválidos bloqueados por redirect      | PASS parcial | Redirección global activa, pero no hay subrutas `/app/*`                                                                                 |
| E-01 | Enforcement  | Write guard en productos                          | PASS         | [`products_repository_impl.create()`](lib/features/products/data/products_repository_impl.dart:118)                                      |
| E-02 | Enforcement  | Write guard en ventas                             | PASS         | [`sales_repository_impl.createSaleWithStock()`](lib/features/sales/data/sales_repository_impl.dart:57)                                   |
| E-03 | Enforcement  | Write guard en gastos                             | PASS         | [`expenses_repository_impl.createExpenseOrPurchase()`](lib/features/expenses/data/expenses_repository_impl.dart:79)                      |
| E-04 | Enforcement  | Role check considera usuario inactivo             | FAIL         | [`role_guard.dart`](lib/core/guards/role_guard.dart:26) no valida `isActive`                                                             |
| C-01 | Consistencia | Venta sin stock suficiente no parcial             | PASS         | valida antes de insert + transacción en [`sales_repository_impl.dart`](lib/features/sales/data/sales_repository_impl.dart:69)            |
| C-02 | Consistencia | 2 ventas simultáneas mismo producto               | RIESGO ALTO  | patrón read-modify-write no atómico en [`sales_repository_impl.dart`](lib/features/sales/data/sales_repository_impl.dart:138)            |
| C-03 | Consistencia | Borrar producto limpia imágenes                   | FAIL         | delete producto no borra archivos en [`products_repository_impl.delete()`](lib/features/products/data/products_repository_impl.dart:268) |
| C-04 | Consistencia | Borrar cliente con ventas asociadas               | FAIL UX      | probable FK error, sin manejo específico                                                                                                 |
| B-01 | Backup       | ZIP contiene db/images/logs/metadata/checksum     | PASS         | [`createBackupZip()`](lib/features/superadmin/data/superadmin_repository_impl.dart:163)                                                  |
| B-02 | Backup       | Restore valida checksum y rollback                | PASS         | [`restoreBackupZip()`](lib/features/superadmin/data/superadmin_repository_impl.dart:240)                                                 |
| B-03 | Backup       | Modo mantenimiento bloquea UI                     | FAIL         | flag se escribe pero UI/router no lo consulta                                                                                            |
| P-01 | Performance  | Paginación LIMIT/OFFSET productos/clientes/gastos | PASS         | repositorios con `.limit(limit, offset: offset)`                                                                                         |
| P-02 | Performance  | Debounce búsqueda                                 | PASS parcial | productos/clientes sí; ventas no debounce                                                                                                |
| P-03 | Performance  | Stress 5k/20k medido                              | NO EJECUTADO | Falta harness de seed + benchmark                                                                                                        |

---

## 3) Bugs reproducibles (accionables)

## BUG-001 — Falta flujo de `/login` (desvío funcional del flujo oficial)

- Severidad: **ALTO**
- Reproducción:
  1. Arrancar app con tenant creado y sin sesión válida.
  2. Esperar resolución de bootstrap/router.
  3. Observar destino.
- Esperado: ir a `/login`.
- Actual: no existe módulo/ruta login; router solo usa `/dashboard` en ready.
- Archivos probables:
  - [`app_router.dart`](lib/app/router/app_router.dart:17)
  - [`routing_snapshot.dart`](lib/app/router/routing_snapshot.dart:3)
  - bootstrap/session model inexistente.
- Fix recomendado:
  - Introducir sesión explícita (`currentUserId` + `sessionActive`) en meta/auth state.
  - Crear `LoginScreen` y ruta `/login`.
  - Ajustar redirect: `ready && !session => /login`.

## BUG-002 — Riesgo de carrera en stock (oversell) con ventas concurrentes

- Severidad: **CRÍTICO**
- Reproducción (automatizable):
  1. Crear producto inventariable con stock=1.
  2. Disparar 2 `createSaleWithStock()` casi simultáneos (mismo producto, qty=1).
  3. Verificar stock y cantidad de ventas.
- Esperado: solo 1 venta efectiva (o stock nunca negativo si no permitido).
- Actual: patrón read-modify-write con valor leído previo puede perder actualización.
- Archivos probables:
  - [`sales_repository_impl.dart`](lib/features/sales/data/sales_repository_impl.dart:73)
  - update stock actual en [`sales_repository_impl.dart`](lib/features/sales/data/sales_repository_impl.dart:138)
- Fix recomendado:
  - Reemplazar update por SQL atómico: `stock = stock - ?` con cláusula `stock >= ?` cuando no permite negativo.
  - Validar filas afectadas; si 0 => abortar transacción.
  - Agregar test de concurrencia en `integration_test`.

## BUG-003 — Borrado de producto deja huérfanos de archivos (images/thumbs)

- Severidad: **ALTO**
- Reproducción:
  1. Crear producto con imágenes.
  2. Borrarlo desde lista.
  3. Verificar directorios `images/` y `thumbnails/`.
- Esperado: limpiar DB + archivos físicos asociados (o GC programado).
- Actual: [`delete()`](lib/features/products/data/products_repository_impl.dart:268) solo borra fila de producto.
- Archivos probables:
  - [`products_repository_impl.dart`](lib/features/products/data/products_repository_impl.dart:268)
- Fix recomendado:
  - Antes de borrar producto, listar imágenes y eliminar archivos físicos.
  - Borrar rows `product_images`/`product_custom_field_values` asociados en transacción.

## BUG-004 — `maintenance.flag` no bloquea UI durante restore

- Severidad: **ALTO**
- Reproducción:
  1. Iniciar restore backup.
  2. Interactuar con módulos durante restore.
- Esperado: app en modo mantenimiento (sin operaciones concurrentes de usuario).
- Actual: flag solo se crea/elimina en repo, pero no se consume en router/shell.
- Archivos probables:
  - [`superadmin_repository_impl.dart`](lib/features/superadmin/data/superadmin_repository_impl.dart:243)
  - falta lectura en router/shell.
- Fix recomendado:
  - Provider `maintenanceModeProvider` que lea `maintenance.flag`.
  - Guard global en router + overlay blocker global con CTA “restauración en curso”.

## BUG-005 — RoleGuard permite escritura de usuario inactivo

- Severidad: **MEDIO (Security/Authorization)**
- Reproducción:
  1. Marcar usuario `isActive=false`.
  2. Mantener `currentUserId` apuntando a ese usuario.
  3. Ejecutar acción de escritura.
- Esperado: bloqueo por usuario inactivo.
- Actual: [`RoleGuard`](lib/core/guards/role_guard.dart:26) valida rol pero no `isActive`.
- Fix recomendado:
  - Agregar check `if (!user.isActive) deny('Usuario inactivo')`.

## BUG-006 — UX defectuosa al borrar cliente con ventas asociadas

- Severidad: **MEDIO**
- Reproducción:
  1. Crear cliente.
  2. Asociarlo a venta.
  3. Intentar borrarlo.
- Esperado: regla explícita (bloquear con mensaje o desasociar).
- Actual: potencial fallo FK/StateError propagado (sin mensaje de negocio claro).
- Archivos probables:
  - [`customers_repository_impl.dart`](lib/features/customers/data/customers_repository_impl.dart:110)
  - UI [`customers_screen.dart`](lib/features/customers/presentation/screens/customers_screen.dart:204)
- Fix recomendado:
  - Capturar error FK y mostrar mensaje amigable.
  - Regla de dominio explícita (`deny if has sales`).

## BUG-007 — Falta módulo funcional de categorías CRUD

- Severidad: **ALTO (gap funcional vs requerimiento)**
- Reproducción:
  1. Revisar navegación y pantallas disponibles.
  2. Buscar pantalla de categorías.
- Esperado: módulo categorías CRUD operativo.
- Actual: no existe `CategoriesScreen`/feature.
- Archivos probables:
  - [`app_router.dart`](lib/app/router/app_router.dart:50)
- Fix recomendado:
  - Implementar feature categorías completa con guardas de escritura y regla de borrado en uso.

---

## 4) Seguridad/Bypass (estado)

- Tamper => redirect activation: **OK** por [`redirect`](lib/app/router/app_router.dart:34) + refuerzo en [`SaaSScaffold`](lib/core/widgets/saas_scaffold.dart:115).
- Read-only por licencia: **OK** en lógica vía [`LicenseWriteGuard`](lib/core/guards/license_write_guard.dart:17).
- Bypass por shortcut/deep link: **parcial**; faltan integration tests que simulen `router.go()` a rutas internas bajo estados inválidos.

---

## 5) Performance

- Paginación real: presente en productos/clientes/gastos (LIMIT/OFFSET).
- Índices críticos: presentes en DB create indexes.
- Debounce: productos/clientes implementado; ventas no.
- Stress 5k/20k: **NO EJECUTADO** por ausencia de seed benchmark y métricas instrumentadas.

Plan de automatización recomendado:

- Crear `integration_test/stress_seed_test.dart` para poblar 5k productos + 5k clientes + 20k ventas.
- Medir tiempos (stopwatch) de:
  - fetch primera página,
  - búsqueda por término,
  - render scroll.
- Guardar reporte CSV/JSON en carpeta `build/qa`.

---

## 6) Cobertura faltante para cumplir pedido al 100%

No ejecutado directamente en esta corrida (requiere integración/entorno):

- Permisos de carpeta denegados en Windows.
- Deep link/back button del SO en activation.
- Restore con corrupción de 1 byte vía test automatizado.
- Stress completo 5k/20k con métricas de jank.

Automatización propuesta:

- `integration_test/routing_guard_test.dart`
- `integration_test/license_enforcement_test.dart`
- `integration_test/backup_restore_integrity_test.dart`
- `integration_test/stress_seed_test.dart`

---

## 7) Fixes críticos aplicados en esta ronda + re-test

### Fix aplicado A — RoleGuard bloquea usuario inactivo

- Cambio en [`RoleGuard.canWrite()`](lib/core/guards/role_guard.dart:9): ahora deniega si `user.isActive == false`.
- Riesgo mitigado: bypass de autorización con usuario deshabilitado.

### Fix aplicado B — Borrado de producto limpia dependencias y archivos

- Cambio en [`ProductsRepositoryImpl.delete()`](lib/features/products/data/products_repository_impl.dart:268):
  - elimina `product_custom_field_values` y `product_images` en transacción,
  - elimina archivos `imagePath` + `thumbnailPath` en disco.
- Riesgo mitigado: huérfanos de DB y basura en filesystem.

### Fix aplicado C — Update de stock atómico en ventas

- Cambio en [`SalesRepositoryImpl.createSaleWithStock()`](lib/features/sales/data/sales_repository_impl.dart:57):
  - reemplazo de read-modify-write por `customUpdate` atómico,
  - con `AND stock >= ?` cuando no se permite negativo,
  - valida filas afectadas y aborta si no actualiza.
- Riesgo mitigado: condición de carrera/oversell en concurrencia.

### Re-test ejecutado tras fixes

- `flutter analyze` => PASS
- `flutter test` => PASS

---

## 8) Segunda ronda de cierre (ALTO) — estado final

### Cobertura funcional cerrada

- Login local y sesión persistente operativa:
  - [`LoginScreen`](lib/features/auth/presentation/screens/login_screen.dart:8)
  - Redirect en router con `hasSession` en [`app_router.dart`](lib/app/router/app_router.dart:49)
  - Persistencia de sesión en [`auth_repository_impl.dart`](lib/features/auth/data/auth_repository_impl.dart:13)
- Maintenance mode global:
  - Lectura de estado en [`maintenance_provider.dart`](lib/core/providers/maintenance_provider.dart:1)
  - Bloqueo lógico en [`license_write_guard.dart`](lib/core/guards/license_write_guard.dart:11)
  - Overlay global en [`saas_scaffold.dart`](lib/core/widgets/saas_scaffold.dart:1)
  - Activación/desactivación durante restore en [`superadmin_repository_impl.dart`](lib/features/superadmin/data/superadmin_repository_impl.dart:242)
- Categorías CRUD operativo:
  - pantalla [`categories_screen.dart`](lib/features/categories/presentation/screens/categories_screen.dart:10)
  - repo [`categories_repository_impl.dart`](lib/features/categories/data/categories_repository_impl.dart:1)
  - navegación y ruta en [`app_router.dart`](lib/app/router/app_router.dart:86)
- Debounce en ventas implementado en [`sales_screen.dart`](lib/features/sales/presentation/screens/sales_screen.dart:1)

### Migración DB aplicada

- `schemaVersion` subido a `2` y migración de columnas `session_active` / `maintenance_mode` en [`app_database.dart`](lib/core/database/app_database.dart:273).

### Integration tests agregados y validados

- [`license_enforcement_test.dart`](integration_test/license_enforcement_test.dart:1) => PASS
- [`routing_guard_test.dart`](integration_test/routing_guard_test.dart:1) => PASS
- [`backup_restore_integrity_test.dart`](integration_test/backup_restore_integrity_test.dart:1) => PASS
- [`stress_seed_test.dart`](integration_test/stress_seed_test.dart:1) => PASS

### Observación de entorno (Windows runner)

- `flutter test integration_test` (toda la carpeta en una corrida) puede fallar intermitentemente por inicialización del runner: `log reader stopped unexpectedly`.
- Ejecución archivo por archivo: PASS completa.

### Resultado consolidado final

- `flutter analyze` => PASS
- `flutter test` => PASS
- Integration tests (4/4) => PASS (ejecución individual)
