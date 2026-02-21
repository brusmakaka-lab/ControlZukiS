# ControlZukiS — Flujo Operativo Oficial

## A) AppStart

1. Inicio en [`main()`](lib/main.dart:6).
2. Inicialización de logger en [`AppLogger.init()`](lib/core/logging/app_logger.dart:14).
3. Render de app en [`ControlZukiSApp`](lib/app/app.dart:7).
4. Ruta inicial: [`/splash`](lib/app/router/app_router.dart:21).
5. Bootstrap en [`bootstrapControllerProvider`](lib/features/bootstrap/presentation/controllers/bootstrap_controller.dart:24):
   - inicializa DB y migraciones (Drift),
   - lee/crea `app_meta`,
   - evalúa trial/licencia,
   - ejecuta anti-tamper (`now < lastSeenAt` => `TAMPER`).
6. Resultado de bootstrap: [`RoutingSnapshot`](lib/app/router/routing_snapshot.dart:5).
7. Redirección global en [`GoRouter.redirect`](lib/app/router/app_router.dart:22):
   - `onboarding` -> `/onboarding`
   - `activation` -> `/activation`
   - `ready` -> `/dashboard`

## B) Onboarding (si no hay tenant)

1. Pantalla [`OnboardingScreen`](lib/features/onboarding/presentation/screens/onboarding_screen.dart:10).
2. Captura: empresa, rubro, admin y sucursal.
3. Persistencia por pipeline:
   - UI -> Controller -> UseCase -> Repository -> DB.
4. Seed inicial:
   - categorías por rubro,
   - definiciones de custom fields por rubro.
5. Actualiza `app_meta` con tenant/branch/user actuales.
6. Navega a dashboard.

## C) Licencia / Trial / Tamper

1. Primer arranque:
   - crea trial de 15 días (`installedAt`, `trialEndsAt`, `lastSeenAt`, `licenseStatus=TRIAL`).
2. Anti-tamper:
   - si reloj retrocede => `TAMPER`.
   - fuerza activación obligatoria (`/activation`).
3. Trial vencido:
   - estado `EXPIRED`.
   - app operativa en solo lectura (dashboard/listados/reportes/export habilitados).
4. Activación offline:
   - pantalla [`ActivationScreen`](lib/features/license/presentation/screens/activation_screen.dart:7),
   - valida key `ZKS-<payload>.<signature>`,
   - bind por `deviceId`,
   - guarda auditoría en `license_audit`.

## D) Enforcement de escritura (no solo UI)

Toda escritura pasa por guardas en lógica:

1. [`RoleGuard`](lib/core/guards/role_guard.dart:1)
2. [`LicenseWriteGuard`](lib/core/guards/license_write_guard.dart:1)
3. [`WriteAccessService`](lib/core/guards/write_access_service.dart:1)

Si licencia está `EXPIRED` o `TAMPER`, bloquea operaciones de creación/edición/eliminación en repositorios/casos de uso.

## E) Ventas transaccionales

1. UI de ventas en [`SalesScreen`](lib/features/sales/presentation/screens/sales_screen.dart:10).
2. Operación principal por caso de uso transaccional:
   - crea encabezado de venta,
   - inserta items,
   - actualiza stock,
   - registra actividad en `activity_log`.
3. Si falla una parte, rollback completo.

## F) Backup / Restore

1. Ejecución desde SuperAdmin.
2. Backup ZIP contiene:
   - DB,
   - imágenes y thumbnails,
   - `metadata.json`,
   - logs.
3. Incluye checksum SHA256.
4. Restore entra en modo mantenimiento (`maintenance.flag`) y aplica rollback si falla integridad/restauración.

## G) Shell SaaS / navegación

1. Estructura unificada en [`SaaSScaffold`](lib/core/widgets/saas_scaffold.dart:7).
2. Desktop: sidebar (`NavigationRail`) + topbar.
3. Mobile: bottom navigation (`NavigationBar`).
4. Indicador persistente de licencia + banner read-only/tamper.
