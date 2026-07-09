# Cómo correr UrbanSync (teléfono, emulador Windows y Mac) + E2E

Requisito común: **la API dockerizada debe estar arriba** en la PC.

```bash
# En la raíz del proyecto (una vez):
cp .env.example .env        # coloca SA_PASSWORD y JWT_KEY (JWT_KEY >= 32 caracteres)
docker compose up -d --build
# Verifica: http://localhost:8080/swagger  → 200
```

Usuarios de prueba (seed): `admin@urbansync.com/Admin123*`, `supervisor@urbansync.com/Supervisor123*`, `tecnico@urbansync.com/Tecnico123*`, `ciudadano@urbansync.com/Ciudadano123*`.

Regla de red según destino:
- **Emulador Android** → la API es `http://10.0.2.2:8080` (alias del `localhost` del host). Es el valor por defecto en `dev`.
- **Teléfono físico / simulador iOS** → la API es `http://<IP_LAN_DE_LA_PC>:8080` (pásalo con `--dart-define=API_BASE_URL=...`).

---

## A) Teléfono Android físico (paso a paso)

1. **API arriba** (arriba) y **Docker corriendo**.
2. **IP LAN de la PC**: `ipconfig` → "Dirección IPv4" del adaptador Wi-Fi (ej. `192.168.100.246`).
3. **Firewall de Windows** (PowerShell como administrador, una vez):
   ```powershell
   New-NetFirewallRule -DisplayName "UrbanSync 8080" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow
   ```
4. **Teléfono y PC en el mismo Wi-Fi.** En el teléfono: Ajustes → Opciones de desarrollador → **Depuración USB** ON. Conéctalo por USB y acepta "Permitir depuración".
5. Desde `mobile/`:
   ```bash
   flutter devices           # confirma que aparece tu teléfono
   flutter run --dart-define=ENV=dev --dart-define=API_BASE_URL=http://192.168.100.246:8080 -d <deviceId>
   ```
   (sustituye `192.168.100.246` por tu IP y `<deviceId>` por el id que muestre `flutter devices`.)
6. **Instalar el APK directamente** (alternativa sin `flutter run`):
   ```bash
   flutter build apk --debug --dart-define=ENV=dev --dart-define=API_BASE_URL=http://192.168.100.246:8080
   adb install -r build/app/outputs/flutter-apk/app-debug.apk
   ```

---

## B) Emulador Android en esta PC (Windows)

Ya quedó creado un AVD llamado **`urbansync`** (Pixel 6, Android 34). El emulador usa `10.0.2.2:8080` para la API, así que no necesitas `API_BASE_URL`.

```bash
# Variables (git-bash):
export ANDROID_HOME=/c/Android
export PATH="/c/src/flutter/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"

# 1) Arrancar el emulador
emulator -avd urbansync -no-snapshot -gpu auto &

# 2) Esperar a que arranque
adb wait-for-device
adb shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done'

# 3) Correr la app (desde mobile/)
cd mobile
flutter run --dart-define=ENV=dev -d emulator-5554
```

> Si tu terminal es PowerShell, usa `& "C:\Android\emulator\emulator.exe" -avd urbansync` para arrancarlo.

---

## C) Mac (para tu compañero/entrega)

Requisitos en Mac: Flutter, Xcode (iOS) y/o Android Studio (Android), y Docker Desktop.

**iOS Simulator:**
```bash
open -a Simulator                      # abre el simulador de iOS
cd mobile && flutter pub get
# El simulador iOS comparte la red del Mac: usa la IP LAN del Mac (o localhost si la API corre en el mismo Mac):
flutter run --dart-define=ENV=dev --dart-define=API_BASE_URL=http://localhost:8080
```
> iOS bloquea HTTP en claro por ATS. Para desarrollo, `mobile/ios/Runner/Info.plist` debe permitir Arbitrary Loads (ver nota abajo).

**Emulador Android en Mac:** igual que la sección B, con `10.0.2.2:8080`.

**iPhone físico:** requiere Mac + Xcode, el dispositivo confiado y firma (Signing) con tu Apple ID; luego `flutter run --dart-define=API_BASE_URL=http://<IP_LAN_DEL_MAC>:8080`.

Nota ATS (iOS dev): en `ios/Runner/Info.plist` añade
```xml
<key>NSAppTransportSecurity</key>
<dict><key>NSAllowsArbitraryLoads</key><true/></dict>
```
Solo para desarrollo (HTTP a la LAN). En producción usa HTTPS y quítalo.

---

## D) Prueba E2E de la app (flujo completo para la demo)

1. **Ciudadano**: registro (o login `ciudadano@urbansync.com`) → **Reportar** → tomar/elegir foto, ajustar pin (jurisdicción se autodetecta) → enviar. Aparece en "Mis reportes".
2. **Gestor** (`supervisor@urbansync.com`): pestaña **Triage** → abrir la incidencia → **Analizar** (tipo, prioridad, acción "Asignar") → guardar. La incidencia pasa a **Asignada**.
3. **Técnico** (`tecnico@urbansync.com`): pestaña **Trabajos** → abrir → **Iniciar** → **Evidencia** (antes/después) → **Completar**. La incidencia queda **Cerrada**.
4. **Gestor**: pestaña **Indicadores** → dashboard con conteos por estado/tipo/prioridad.

### E2E automatizado (integration test)
Con la API arriba y un emulador/dispositivo conectado:
```bash
cd mobile
flutter test integration_test/app_test.dart -d emulator-5554
```
Valida el flujo login del gestor → home. (Usa `10.0.2.2:8080` en emulador.)
