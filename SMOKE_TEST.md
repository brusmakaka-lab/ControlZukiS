# ControlZukiS — Smoke Test Manual

## 0) Preparación

1. Ejecutar dependencias y generación Drift si aplica.
2. Iniciar app local en Windows o Android.
3. Verificar que abre en [`SplashScreen`](lib/features/bootstrap/presentation/screens/splash_screen.dart:8).

## 1) Primer arranque + onboarding

1. Confirmar redirección automática a onboarding.
2. Completar datos de empresa, rubro, admin y sucursal.
3. Finalizar onboarding.
4. Verificar:
   - dashboard visible,
   - categorías seed cargadas para rubro elegido,
   - custom fields seed cargados para rubro.

## 2) Trial / indicador licencia

1. En topbar o appbar verificar badge de licencia (`Trial (N días)`).
2. Confirmar banner/licencia visible en pantallas operativas.

## 3) Productos + inventario + custom fields + imágenes

1. Ir a productos y crear producto inventariable.
2. Completar campos base + custom fields requeridos.
3. Guardar y verificar aparición en listado.
4. Agregar imagen principal/galería y verificar thumbnail.
5. Probar búsqueda por nombre/SKU (debounce activo).

## 4) Clientes

1. Crear cliente.
2. Editar cliente.
3. Buscar por nombre o DNI/CUIT (debounce activo).
4. Eliminar cliente y verificar refresco listado.

## 5) Gastos / compras

1. Crear gasto normal y verificar registro.
2. Crear compra con “aumenta stock” seleccionando producto.
3. Verificar incremento de stock en producto afectado.

## 6) Ventas transaccionales

1. Abrir ventas y buscar productos.
2. Agregar items, cantidades y precios.
3. Confirmar venta.
4. Verificar:
   - venta creada,
   - items creados,
   - stock decrementado,
   - log de actividad generado.

## 7) Dashboard + reportes + export

1. Abrir dashboard y validar KPIs no vacíos tras operar.
2. Abrir reportes.
3. Exportar PDF y Excel (mínimo funcional).
4. Verificar archivos generados localmente.

## 8) Trial expirado (read-only)

1. Simular expiración (ajustar `trialEndsAt` en DB a fecha pasada).
2. Reiniciar app.
3. Verificar estado `EXPIRED` + banner de solo lectura.
4. Confirmar:
   - navegación/listados/reportes/export permitidos,
   - alta/edición/borrado bloqueados por lógica.

## 9) Tamper (clock rollback)

1. Simular `lastSeenAt` futuro respecto de `now`.
2. Reiniciar app.
3. Verificar redirección obligatoria a activación.
4. Confirmar estado `TAMPER` y bloqueo de escritura.

## 10) Activación offline

1. En activación copiar ID de dispositivo.
2. Generar key válida (`ZKS-...`) para ese `deviceId`.
3. Activar offline.
4. Verificar:
   - estado pasa a `ACTIVE`,
   - navegación a dashboard,
   - auditoría en `license_audit`.

## 11) SuperAdmin: logs + backup/restore

1. Abrir SuperAdmin.
2. Ver snapshot/diagnóstico.
3. Exportar logs.
4. Ejecutar backup ZIP.
5. Modificar datos (crear/eliminar algo).
6. Ejecutar restore desde backup.
7. Verificar rollback funcional si se fuerza fallo de integridad.

## 12) Validación final

1. Ejecutar [`flutter analyze`](pubspec.yaml).
2. Confirmar “No issues found”.
3. Probar navegación completa desktop/mobile.
