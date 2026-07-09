# UrbanSync — Plataforma de gestión de infraestructura urbana

App móvil (Flutter) + API (ASP.NET Core) para que ciudadanos reporten incidencias en la infraestructura pública, los gestores las analicen y asignen según **tipo** y **jurisdicción**, los técnicos las resuelvan con evidencias, y se generen indicadores.

- **`mobile/`** — App Flutter (Riverpod, go_router, dio, flutter_map, fl_chart).
- **`backend/`** — API + web MVC (ASP.NET Core 8, EF Core, Identity + JWT, SQL Server). Extiende el repo [rrivas-unapec/UrbanSync](https://github.com/rrivas-unapec/UrbanSync) añadiéndole una capa de API JSON bajo `/api`.
- **`docker-compose.yml`** — Levanta SQL Server + la API.
- **`*.sql`** — Scripts de referencia del dominio (traducidos a entidades EF; no se ejecutan directamente).

---

## Requisitos

| Herramienta | Uso |
|-------------|-----|
| Docker Desktop | Levantar API + SQL Server |
| Flutter SDK (stable) + Android SDK | Compilar/correr la app |
| Un teléfono Android con **depuración USB** | Ejecutar en dispositivo físico (§ "Correr en el teléfono") |

No necesitas instalar .NET localmente: el backend se compila **dentro de Docker** (imagen `sdk:8.0`).

---

## 1. Levantar la API (Docker)

```bash
# En la raíz del proyecto
cp .env.example .env        # y edita SA_PASSWORD y JWT_KEY (JWT_KEY >= 32 caracteres)
docker compose up -d --build
```

- Swagger: <http://localhost:8080/swagger>
- SQL Server escucha en el host en el puerto **14333** (mapeado a 1433 del contenedor, para evitar chocar con un SQL Server local).
- La base se **migra y siembra** automáticamente al arrancar (con reintentos mientras SQL Server termina de iniciar).

### Usuarios semilla

| Rol | Correo | Contraseña |
|-----|--------|-----------|
| Administrador | admin@urbansync.com | Admin123* |
| Supervisor (gestor) | supervisor@urbansync.com | Supervisor123* |
| Técnico | tecnico@urbansync.com | Tecnico123* |
| Ciudadano | ciudadano@urbansync.com | Ciudadano123* |

Verifica el login:

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"ciudadano@urbansync.com","password":"Ciudadano123*"}'
```

---

## 2. Correr la app en el teléfono (§9)

1. **API arriba** (`docker compose up -d`) y Docker corriendo.
2. **IP LAN de la PC:** `ipconfig` (Windows) → busca "Dirección IPv4" del adaptador Wi-Fi (ej. `192.168.1.20`).
3. **Firewall de Windows:** permite el puerto **8080 entrante** (o marca la red Wi-Fi como *Privada*). Sin esto el teléfono no verá la API.
   ```powershell
   New-NetFirewallRule -DisplayName "UrbanSync 8080" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow
   ```
4. **Teléfono y PC en la misma red Wi-Fi.** Activa *Depuración USB* en el teléfono y conéctalo.
5. Desde `mobile/`:
   ```bash
   flutter devices                     # confirma que aparece tu teléfono
   flutter run --dart-define=ENV=dev --dart-define=API_BASE_URL=http://<IP_LAN>:8080 -d <deviceId>
   ```
   > `API_BASE_URL` es obligatorio para dispositivo físico. En emulador Android puedes omitirlo (usa `http://10.0.2.2:8080`).

### Flujo end-to-end para la demo

Registro → login → **reportar incidencia** (GPS + foto) → (gestor) **triage/asignación** → (técnico) **iniciar/completar + evidencia** → (gestor) **dashboard de indicadores**.

---

## 3. Arquitectura

### Backend (`backend/UrbanSync.Web`)
- **Web MVC + Identity (cookies)** original del repo, intacto.
- **Capa API nueva** en `Controllers/Api/*` con `[ApiController]` + **JWT** (`[Authorize(AuthenticationSchemes = JwtBearer)]`). Esquema dual: cookies para la web, JWT para `/api`.
- **Dominio** (`Domain/*`): `Jurisdiccion, Institucion, TipoIncidencia, Ubicacion, Incidencia, Evidencia, AnalisisTecnico, Trabajo` — traducido de los scripts SQL a entidades EF Core (provider **SQL Server**).
- **Registro** reutiliza `UserManager` (misma lógica que el `AuthController` MVC): no se reimplementa.

### Mobile (`mobile/lib`) — feature-first / clean
```
app/        theme (tokens de Figma), router (go_router + guard)
core/       env, network (dio + interceptor JWT), storage (secure storage)
shared/     widgets (PrimaryButton, AppTextField, StatusChip, …), utils (validators)
features/   auth · incidents · triage · reports · home · profile  (data/domain/presentation)
```
- **Estado:** Riverpod (`Notifier` + `FutureProvider`), estados `loading/success/empty/error` en cada pantalla.
- **Navegación:** go_router con guard de autenticación y home por rol.
- **Diseño:** tokens del prototipo (primario `#0057B8`, secundario `#00A676`, acento `#FFB800`, tipografía Inter).

---

## 4. Endpoints principales (API JSON)

```
POST  /api/auth/register        POST /api/auth/login        GET /api/auth/me
GET   /api/incidents            POST /api/incidents         GET /api/incidents/{id}
PATCH /api/incidents/{id}/triage           PATCH /api/incidents/{id}/status
GET   /api/incidents/{id}/evidences        POST /api/incidents/{id}/evidences  (multipart)
GET   /api/incident-types   /api/jurisdictions   /api/jurisdictions/resolve   /api/institutions
GET   /api/work-orders  POST /api/work-orders  PATCH /api/work-orders/{id}/start|complete
GET   /api/reports/summary
```

---

## 5. Comandos útiles

```bash
# App
cd mobile
flutter pub get
flutter analyze         # ver nota de "ruta con acentos" abajo
flutter test            # 15 pruebas (validadores, repos con mocks, LoginPage, pantalla de reporte)
dart format .

# API
docker compose logs -f api
docker compose down            # detener (conserva datos)
docker compose down -v         # detener y borrar datos
```

---

## 6. Notas y decisiones de implementación

- **Modelos sin codegen:** se usan modelos inmutables con `fromJson`/`toJson` manuales en lugar de `freezed`, porque la resolución de dependencias (mediados de 2026) traía `freezed` en versión *prerelease*; se priorizó un build estable.
- **SQL Server en host:14333:** para no chocar con una instancia local de SQL Server que ya ocupa el 1433.
- **`android.overridePathCheck=true`** (en `mobile/android/gradle.properties`): la ruta del proyecto (OneDrive) contiene un carácter no-ASCII (`é`), que el Android Gradle Plugin rechaza por defecto.
- **`flutter analyze` puede fallar** en esta ruta con un error del *analysis server* por el mismo carácter no-ASCII. El **build** y `flutter test` no se ven afectados. Si necesitas analyze, corre el proyecto desde una ruta ASCII (ej. una junction `mklink /J C:\dev\urbansync "<ruta>"`).
- **`/api/jurisdictions/resolve`** es heurístico: la BD no tiene geometría, así que devuelve la jurisdicción raíz y el gestor la corrige en triage.

---

## 7. Créditos

Backend base: equipo UNAPEC (David Rivas, Romer Amparo, Elwins Zorrilla, Carlos Rodriguez, Renny Placencio). App móvil y capa API: este proyecto.
