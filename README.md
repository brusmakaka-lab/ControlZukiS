# ControlZukiS

Aplicación de gestión comercial **offline-first** en Flutter + SQLite (Drift), con licencia local (trial + activación offline), arquitectura por capas y módulos operativos.

## Stack

- Flutter (Windows + Android)
- Riverpod
- go_router
- Drift (SQLite)
- fl_chart
- image_picker + compresión/thumbnails
- Export PDF/Excel

## Arquitectura

Flujo obligatorio por capa:

`UI -> Controller -> UseCase -> Repository -> DB`

No se permite acceso directo UI->DB.

## Requisitos

- Flutter SDK estable
- Dart SDK (incluido con Flutter)
- Windows: Visual Studio Build Tools para target desktop
- Android: Android SDK/ADB para emulador o dispositivo

## Instalación

1. Obtener dependencias:

```bash
flutter pub get
```

2. (Opcional) Regenerar código Drift si hubo cambios de schema:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Ejecutar

### Windows

```bash
flutter run -d windows
```

### Android

```bash
flutter run -d android
```

## Build release

### Windows release

```bash
flutter build windows --release
```

### Android release con obfuscation y split-debug-info

```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

También podés generar appbundle:

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

## Licencia offline

Formato de key:

`ZKS-<payloadBase64>.<signatureBase64>`

Pantalla de activación: [`ActivationScreen`](lib/features/license/presentation/screens/activation_screen.dart:7).

### Generar key (CLI)

Generador: [`license_generator.dart`](lib/core/utils/license_generator.dart:1)

Ejemplo:

```bash
dart run lib/core/utils/license_generator.dart --tenantId=TENANT_001 --deviceId=DEVICE_ABC --plan=PRO --maxDevices=1
```

Con expiración opcional:

```bash
dart run lib/core/utils/license_generator.dart --tenantId=TENANT_001 --deviceId=DEVICE_ABC --plan=PRO --maxDevices=1 --expiresAt=2027-01-01T00:00:00Z --appVersionMin=1.0.0
```

## Simular expiración de trial

Para pruebas locales, modificar `trialEndsAt` en `app_meta` a una fecha pasada y reiniciar app.

Resultado esperado:

- estado `EXPIRED`
- modo solo lectura activo (bloqueo lógico de escrituras)

## Simular tamper (rollback de reloj)

Para pruebas locales, setear `lastSeenAt` a una fecha futura respecto de `now` y reiniciar app.

Resultado esperado:

- estado `TAMPER`
- redirección obligatoria a activación

## Validación rápida

```bash
flutter analyze
```

Debe finalizar en `No issues found`.

## Suite de pruebas

Unit/widget:

```bash
flutter test
```

Integration (Windows):

```bash
flutter test integration_test/license_enforcement_test.dart
flutter test integration_test/routing_guard_test.dart
flutter test integration_test/backup_restore_integrity_test.dart
flutter test integration_test/stress_seed_test.dart
```

Nota operativa: en algunos entornos Windows, ejecutar `flutter test integration_test` (todas juntas) puede fallar por reconexión del runner (`log reader stopped unexpectedly`). Ejecutar archivo por archivo mitiga ese problema.

Artefacto de stress:

- Se genera `qa/stress_metrics.json` en el directorio de datos de app (resuelto por `AppPaths.appDir()`).

## Documentación funcional

- Flujo operativo: [FLOW.md](FLOW.md)
- Pruebas de humo: [SMOKE_TEST.md](SMOKE_TEST.md)
