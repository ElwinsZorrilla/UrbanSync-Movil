# UrbanSync Mobile — Módulo **Auditoría e Incidencias**
### Especificación de Loop Engineering para agente de código

> **Para el agente:** este archivo es tu única fuente de verdad y también tu estado.
> Lo lees al inicio de cada iteración y lo **actualizas** (sección §12) al final de cada una.
> No escribes ni un `.dart` antes de completar la **Fase 0**.

---

## §0. Reglas del loop (no negociables)

```
┌─────────────────────────────────────────────────────────────┐
│  LEER (este .md + §12 estado)                               │
│        ↓                                                    │
│  PLANIFICAR (archivos exactos de la iteración actual)        │
│        ↓                                                    │
│  IMPLEMENTAR (solo los archivos planificados)                │
│        ↓                                                    │
│  VERIFICAR (§11 comandos — TODOS en verde)                   │
│        ↓                                                    │
│  ¿verde? ── NO ──> CORREGIR (máx. 3 intentos) ──> VERIFICAR │
│        │                                                    │
│       SÍ                                                    │
│        ↓                                                    │
│  COMMIT + ACTUALIZAR §12 ──> siguiente iteración             │
└─────────────────────────────────────────────────────────────┘
```

**Invariantes:**

1. **No inventas endpoints, campos ni enums.** Todo sale del backend real (Fase 0). Si algo falta → lo anotas en §13 *Bloqueos*, implementas el resto y **paras** ese sub-flujo. No haces mocks silenciosos.
2. **No tocas módulos existentes** (login, reportar, dashboard, perfil, triage) salvo: registrar rutas nuevas en `go_router`, y añadir enlaces de navegación. Cualquier otro cambio fuera del módulo va anotado en §12.
3. **No avanzas de iteración con `flutter analyze` en rojo** ni con tests fallando.
4. **Reutilizas** `AppCard`, `AppTextField`, `PrimaryButton`, `StatusChip` de `lib/shared/`. Si necesitas un widget nuevo y es genérico → va a `lib/shared/widgets/`. No duplicas componentes.
5. **Un commit por iteración**, mensaje: `feat(audit): <iteración N> — <resumen>`.
6. Nada de archivos de documentación extra, READMEs, ni carpetas `docs/`. Solo código, tests y este `.md`.

---

## §1. Alcance

**Qué se construye (solo mobile / Flutter):**

| Sub-módulo | Contenido |
|---|---|
| **Incidencias** | Bandeja con filtros y paginación, ciclo de vida (cambio de estado), asignación a técnico/cuadrilla, comentarios, evidencia fotográfica, verificación de cierre |
| **Auditoría** | Timeline de auditoría por incidencia, bitácora global filtrable (actor / entidad / acción / rango de fechas), detalle de evento con diff antes→después |

**Qué NO se construye:** backend (ya existe), panel web, pantallas ya funcionales del móvil.

**Advertencia de duplicación:** la app ya tiene *Reportar Incidencia*, *Detalle de Incidencia* y *Triage*. En Fase 0 determinas si el nuevo módulo **extiende** esas pantallas o crea unas nuevas. Regla por defecto: **extender** el detalle existente añadiéndole la pestaña de auditoría; crear pantallas nuevas solo para la bandeja y la bitácora global.

---

## §2. FASE 0 — Reconocimiento (obligatoria, sin escribir código)

### 2.1 Repositorio

Estado real relevado (2026-08-06):

- Repo **monorepo** (`mobile/` + `backend/`), rama única de trabajo: **`main`**. No existe rama `mobile` separada; el remoto `rrivas/movil-app` es del repo base upstream.
- `Flutter 3.44.5 • stable • Dart 3.12.2` (SDK en `C:\src\flutter`).
- `flutter pub get` → OK.
- **Nota de entorno crítica:** la ruta del proyecto contiene `é` (OneDrive / "Académico") y el *analysis server* falla ahí. `flutter analyze` y `flutter test` se corren por la **junction ASCII** ya existente: **`C:\dev\urbansync-mobile`** → `mobile/`. Es la vía obligatoria para el gate de §11.

### 2.2 Inventario del móvil

| Dato | Valor detectado |
|---|---|
| Ruta del router | `lib/app/router.dart` → `routerProvider = Provider<GoRouter>`. Guard **solo de autenticación** en `redirect` (`AuthStatus.unknown/unauthenticated`); **no hay guards por rol**. Rutas actuales: `/splash`, `/login`, `/register`, `/home`, `/report`, `/incidents/:id`, `/triage/:id` |
| Cliente HTTP (archivo + clase) | `lib/core/network/dio_client.dart` → `dioProvider = Provider<Dio>`. `BaseOptions(baseUrl: AppEnv.baseUrl, connect 15s / receive 20s / send 20s)`. **Instancia única compartida** |
| Interceptor JWT / refresh | `InterceptorsWrapper` en `dio_client.dart`: `onRequest` inyecta `Authorization: Bearer <token>` desde `TokenStorage`. `onError`: si 401 y la ruta no es `/api/auth/`, limpia el token y llama `authControllerProvider.notifier.markSessionExpired()`. **No hay refresh token** (el API no lo soporta; JWT de 480 min) |
| Modelo `Incident` existente (ruta) | `lib/features/incidents/domain/incident.dart` → clases `Incident` y `Evidence` (inmutables, `fromJson` manual). Campos en **español**, espejo 1:1 del `IncidentDto` del API |
| Widgets shared disponibles | `lib/shared/widgets/`: `AppCard({child, onTap, padding})`, `AppTextField({label, controller, hintText, validator, keyboardType, obscureText, prefixIcon, maxLines, onChanged})`, `PrimaryButton({label, onPressed, loading, icon})`, `SecondaryButton({label, onPressed, icon})`, `LoadingView({message})`, `ErrorView({message, onRetry})`, `EmptyState({title, message, icon})`, `StatusChip({label, kind})` con `enum ChipKind { estado, prioridad }`. Utils: `formatDateTime`/`formatDate` (`intl`, `dd/MM/yyyy HH:mm`, aplican `.toLocal()`), `Validators` |
| Estrategia de serialización | **Manual.** `factory X.fromJson(Map<String,dynamic>)` dentro de la propia entidad de dominio. **No hay DTOs separados, ni `freezed`, ni `json_serializable`, ni `build_runner`** (decisión documentada en README §6). → **No introducir codegen** |
| Convención de estado Riverpod | `NotifierProvider` + `Notifier<T>` para sesión (`authControllerProvider`); `FutureProvider`, `FutureProvider.autoDispose` y `FutureProvider.autoDispose.family` para datos (`incidents_providers.dart`, `reports_providers.dart`). **No existe `AsyncNotifier` ni `StateNotifier` en el proyecto.** riverpod ^3.3.2 |
| Manejo de errores existente | `lib/core/network/api_exception.dart` → `class ApiException implements Exception { message, statusCode, isUnauthorized }` + `ApiException.fromDio(DioException)`. Mapea timeouts, `connectionError`, y `badResponse` leyendo `detail`/`title`/`message` y `errors{}` de ProblemDetails. **No hay `Failure` ni `Either`**; los repos hacen `on DioException catch → throw ApiException.fromDio(e)` |
| Paquete de imágenes/cámara ya instalado | `image_picker: ^1.2.3` (usado con `ImageSource.camera`, `imageQuality: 70`, `maxWidth: 1600`). Además: `geolocator ^14.0.3`, `geocoding ^5.0.0`, `flutter_map ^8.3.1` + `latlong2`, `fl_chart ^1.2.0`, `intl ^0.20.3`, `google_fonts ^8.1.0`, `flutter_secure_storage ^10.3.1`, `dio ^5.10.0`, `go_router ^17.3.0`. Dev: `mocktail ^1.0.5`, `integration_test` |

**Hallazgos adicionales del inventario (afectan al diseño del módulo):**

- **No existe `Page<T>`** ni ningún tipo de paginación en el móvil. Habría que crearlo en `lib/core/` — pero ver §13-B5: el API no pagina.
- **No hay i18n** (`flutter_localizations` / `.arb` ausentes). Los textos van literales en español dentro de cada pantalla. → §8 "todo texto pasa por i18n si lo hay": **no lo hay**, se mantienen constantes en el propio feature.
- **No hay logger** (`debugPrint` no aparece en `lib/`, `print` tampoco). Los errores se muestran vía `SnackBar` / `ErrorView`.
- **La pantalla de detalle ya existe y ya tiene una "Línea de tiempo"**: `incident_detail_page.dart` renderiza `_timelineCard` con 3 hitos derivados de fechas del propio `IncidentDto` (`fechaReporte` / `fechaAsignacion` / `fechaCierre`) — **no es auditoría**, es una barra de progreso. El tab de Auditoría de §8.3 convive con esto, no lo sustituye.
- Entrada de navegación: `home_page.dart` arma tabs por `RoleGroup` (`manager` → Triage/Panel/Indicadores/Perfil; `technician` → Trabajos/Perfil; `citizen` → Reportes/Perfil). Las rutas nuevas `/incidents` y `/audit` deben engancharse aquí.
- Roles en el móvil: `AppUser.roleGroup` mapea `Tecnico → technician`, `Administrador|Supervisor → manager`, resto → `citizen`. El rol se toma de `GET /api/auth/me`, **no se decodifica el JWT**.

### 2.3 Contrato del backend

Fuente: **código real** de `backend/UrbanSync.Web/Controllers/Api/*` **+ Swagger y respuestas de la API viva** (`docker compose up -d`, `http://localhost:8080`). **No hay despliegue en Render**; el API corre local. `AppEnv`: dev → `http://10.0.2.2:8080`, override con `--dart-define=API_BASE_URL`.

**Swagger confirma 20 endpoints, y la lista es exactamente esta** (`/swagger/v1/swagger.json`):

```
POST   /api/auth/login          GET  /api/auth/me           POST /api/auth/register
GET    /api/incident-types      GET  /api/institutions      GET  /api/jurisdictions
GET    /api/jurisdictions/resolve
POST   /api/incidents           GET  /api/incidents         GET  /api/incidents/{id}
PATCH  /api/incidents/{id}/status                           PATCH /api/incidents/{id}/triage
GET    /api/incidents/{incidentId}/evidences                POST  /api/incidents/{incidentId}/evidences
GET    /api/reports/summary
GET    /api/work-orders         POST /api/work-orders       GET  /api/work-orders/{id}
PATCH  /api/work-orders/{id}/start                          PATCH /api/work-orders/{id}/complete
```

**No aparece ninguna ruta de auditoría, comentarios, asignación ni usuarios.** Verificado además contra la API viva: `GET /api/audit` → **404**, `GET /api/incidents/1/audit` → **404**.

| # | Método | Ruta | Query / Body | Respuesta | Rol requerido | ✔ |
|---|---|---|---|---|---|---|
| 1 | GET | `/api/incidents` | `status`, `type` (int), `priority`, `jurisdictionId` (int), `mine` (bool) — **sin `page`/`pageSize`/`from`/`to`/`q`/`assignedTo`** | **array plano** de `IncidentDto` (sin evidencias), orden `FechaReporte` desc | Autenticado. Si NO es staff, se fuerza `UsuarioReportaId == yo` | ⚠ parcial |
| 2 | GET | `/api/incidents/{id}` | — | `IncidentDto` **con** `evidencias[]` | Autenticado; no-staff solo las propias, si no **403** | ✔ |
| 3 | PATCH | `/api/incidents/{id}/status` | `{ "estado": "<literal>" }` — **sin campo `comment`** | `IncidentDto` | `Administrador,Supervisor,Tecnico` | ⚠ parcial |
| 4 | POST | `/api/incidents/{id}/assign` | — | — | — | ✗ **NO EXISTE** |
| 5 | POST | `/api/incidents/{id}/comments` | — | — | — | ✗ **NO EXISTE** |
| 6 | POST | `/api/incidents/{id}/attachments` | Existe como **`/api/incidents/{id}/evidences`**. multipart: `file` (≤50 MB; `.jpg .jpeg .png .webp .gif .mp4 .pdf`), `tipo`, `lat`, `lng`, `descripcion` | `EvidenceDto` (201) | Autenticado; no-staff solo sobre incidencia propia | ✔ (otra ruta) |
| 7 | GET | `/api/incidents/{id}/audit` | — | — | — | ✗ **NO EXISTE** |
| 8 | GET | `/api/audit` | — | — | — | ✗ **NO EXISTE** |
| 9 | GET | `/api/audit/{id}` | — | — | — | ✗ **NO EXISTE** |
| 10 | GET | *(catálogos)* | `/api/incident-types` ✔ · `/api/jurisdictions` ✔ · `/api/jurisdictions/resolve?lat&lng` ✔ · `/api/institutions?incidentTypeId` ✔ · **técnicos/usuarios ✗** | arrays planos | Autenticado | ⚠ parcial |

**Endpoints adicionales relevantes (existen y no estaban en la tabla de la spec):**

| Método | Ruta | Body | Respuesta | Rol |
|---|---|---|---|---|
| POST | `/api/incidents` | `{tipoIncidenciaId, descripcion, prioridad?, ubicacion{lat,lng,direccion,referencia?,jurisdiccionId?}}` | `IncidentDto` (201) | Autenticado |
| PATCH | `/api/incidents/{id}/triage` | `{tipoIncidenciaId?, prioridad?, accion?, jurisdiccionId?, institucionAsignadaId?}` | `IncidentDto` | `Administrador,Supervisor` |
| GET | `/api/incidents/{id}/evidences` | — | `EvidenceDto[]` | Autenticado |
| GET | `/api/work-orders` | `technicianId?`, `status?`, `incidentId?` | `WorkOrderDto[]` | Autenticado |
| POST | `/api/work-orders` | `{incidenciaId, usuarioAsignadoId, descripcionTrabajo}` → pone la incidencia en `Asignada` + `FechaAsignacion` | `WorkOrderDto` (201) | `Administrador,Supervisor` |
| PATCH | `/api/work-orders/{id}/start` | — → incidencia a `EnProceso` | `WorkOrderDto` | `Tecnico,Administrador,Supervisor` |
| PATCH | `/api/work-orders/{id}/complete` | `{resultado, descripcionTrabajo?}` → incidencia a `Cerrada` + `FechaCierre` | `WorkOrderDto` | `Tecnico,Administrador,Supervisor` |
| GET | `/api/reports/summary` | — | `{total, porEstado[], porPrioridad[], porTipo[], porJurisdiccion[]}` | `Administrador,Supervisor` |
| POST/GET | `/api/auth/register` · `/api/auth/login` · `/api/auth/me` | — | `UserDto` / `AuthResponse{token, expiresAt, user}` | anon / anon / autenticado |

**Anotaciones exactas (§2.3):**

- **Paginación: NO EXISTE.** Todos los listados devuelven un **array JSON plano**, sin envelope (`{items,total,…}`), sin `{data,meta}` y sin header `X-Total-Count`. `GET /api/incidents` trae **todo** el conjunto filtrado. Respuesta real verificada:
  ```json
  [{"id":2,"codigoCaso":"INC-20260709-D8F298CF","estado":"EnAnalisis","prioridad":"Media",
    "descripcion":"Fix verify","tipoIncidenciaId":2,"tipoIncidencia":"Infraestructura Fisica",
    "institucionAsignadaId":2,"institucionAsignada":"Ministerio de Obras Publicas…",
    "jurisdiccionId":1,"jurisdiccion":"Distrito Nacional","direccion":"Calle X","referencia":null,
    "latitud":18.48,"longitud":-69.93,"usuarioReporta":"Ciudadano de Prueba",
    "fechaReporte":"2026-07-09T17:48:45.1400648Z","fechaAsignacion":null,"fechaCierre":null,
    "evidencias":null}, …]
  ```
- **Enums: strings PascalCase concatenado** (no enteros, no `snake_case`). Literales copiados del código:
  - **Estado de incidencia** (lista blanca en `IncidentsApiController.cs:188`): `"Registrada"`, `"EnAnalisis"`, `"Asignada"`, `"EnProceso"`, `"Cerrada"`, `"Rechazada"`. *No existen* `Triaged`, `Resolved`, `Verified`, `Duplicated`.
  - **Prioridad**: **sin lista blanca en el backend** (acepta cualquier string; default `"Media"`). Valores en uso por el móvil y el `StatusChip`: `"Baja"`, `"Media"`, `"Alta"`, `"Critica"` (sin tilde).
  - **Estado de orden de trabajo**: `"Pendiente"`, `"EnProgreso"`, `"Finalizado"`.
  - **`accion` de triage** → estado: `"asignar"`/`"derivar"` → `Asignada`; `"rechazar"` → `Rechazada`; cualquier otro/vacío → `EnAnalisis` (`AccionToEstado`, case-insensitive).
  - **Tipo de evidencia**: string libre, default `"Foto"`; el móvil ofrece `Antes` / `Despues` / `Documento`.
- **Formato JSON**: System.Text.Json por defecto → **camelCase** (`codigoCaso`, `fechaReporte`, `tipoIncidenciaId`…).
- **Formato de fecha**: `DateTime` de .NET. El `ApplicationDbContext` aplica un `ValueConverter` global que fuerza `DateTimeKind.Utc` al materializar (`ApplicationDbContext.cs:120-137`), por lo que la serialización sale **ISO-8601 con sufijo `Z`** — verificado en vivo: `"fechaReporte":"2026-07-09T17:48:45.1400648Z"` (7 decimales). Sin offset local, sin `DateTimeOffset`. `DateTime.parse` de Dart lo interpreta correctamente como UTC y `formatDateTime` ya hace `.toLocal()`.
- **Forma del error** (verificado en vivo):
  - `ValidationProblem(ModelState)` → **400** `{"type":"…rfc9110#section-15.5.1","title":"One or more validation errors occurred.","status":400,"errors":{"Estado":["Estado inválido."]},"traceId":"…"}`.
  - `Problem(...)` / `BadRequest(new ProblemDetails{...})` / `Conflict(...)` / `Unauthorized(...)` → `ProblemDetails` con `title` **y** `detail` en español.
  - `NotFound()` → **404 con cuerpo** ProblemDetails autogenerado: `{"type":"…","title":"Not Found","status":404,"traceId":"…"}` — **sin `detail`**. ⚠️ `ApiException._messageFromResponse` lee `detail ?? title ?? message`, así que en un 404 muestra literalmente **"Not Found"** en inglés en vez de "Recurso no encontrado.". Nit de UX a corregir en la iteración 11 (§10 "404 en deep-link").
  - `StatusCode(403)` → **403 con cuerpo vacío** (`Content-Length: 0`) ⇒ `ApiException` cae al `switch` y devuelve "No tienes permisos para esta acción." ✓
- **Sin header `X-Total-Count`** en `GET /api/incidents` (verificado: solo `Content-Type`, `Date`, `Server`, `Transfer-Encoding`).
- **`evidencias` viene `null`** (no `[]`) en el listado; solo se puebla en `GET /api/incidents/{id}`. `Incident.fromJson` ya lo absorbe con `?? const []`.
- **Claim de rol en el JWT**: `ClaimTypes.Role` = `http://schemas.microsoft.com/ws/2008/06/identity/claims/role` (`JwtTokenService.cs:40`). Valores literales sembrados: **`Administrador`**, **`Supervisor`**, **`Tecnico`** (sin tilde), **`Ciudadano`**. También lleva `sub`, `jti`, `nameidentifier`, `name`, `email`. Emisor `UrbanSync`, audiencia `UrbanSyncMobile`, expiración 480 min. `Program.cs` valida issuer, audience, lifetime y firma. **El móvil no decodifica el JWT**: usa `role` de `GET /api/auth/me` (solo el **primer** rol, `roles.FirstOrDefault()`).
- **Diff de auditoría: NO APLICA.** Lo único que existe es la tabla `UserActivity` (`Models/UserActivity.cs`) con `{Id, UserId, User, Action, Description, IpAddress, CreatedAt}`. `Action` es una **frase libre en español** (`"Reporte de incidencia"`, `"Triage"`, `"Cambio de estado"`, `"Evidencia"`, `"Orden de trabajo"`, `"Creación de usuario"`, `"Cambio de estado de usuario"`) y `Description` es texto humano (`"Incidencia INC-… → Cerrada."`). **No hay** `entityType`, `entityId`, `actorRole`, `source`, `changes`, `oldValues`/`newValues`. La única superficie de lectura es la **vista MVC** `ActivityController.Index` (`[Authorize(Roles="Administrador,Supervisor")]`, cookies, `Take(100)`, sin API JSON y sin filtros).

### 2.4 Segundo relevamiento — el API de auditoría **SÍ existe**, pero en otro backend

`git pull` sobre `origin/main` → **"Already up to date"**. `origin` (github.com/ElwinsZorrilla/UrbanSync-Movil) solo tiene `main` en `39aee7c`. Los endpoints de auditoría están en el **upstream `rrivas`** (github.com/rrivas-unapec/UrbanSync), rama **`rrivas/main`** (`b8c8bf0`, 28 commits).

> ⚠️ **`git merge-base main rrivas/main` no devuelve nada: las historias NO están relacionadas.** Además el árbol upstream está reestructurado (`src/backend/`, `src/web/`, `src/mobile/`) y **ya no contiene `mobile/` ni `backend/`**. Un `git pull rrivas main` exigiría `--allow-unrelated-histories` y dejaría **dos copias** de la app (nuestra `mobile/` + `src/mobile/`). **No ejecutado**: es una decisión estructural del humano (§13-B10).

**Contrato REAL de auditoría** (`src/backend/UrbanSync.Api/Controllers/ActivityController.cs`) — **a consumir tal cual, sin modificar**:

| # | Método | Ruta | Query / Body | Respuesta | Rol |
|---|---|---|---|---|---|
| A1 | GET | `/api/activity` | `usuarioId` (int), `entidad` (string), `accion` (string), `fechaInicio` (DateTime), `fechaFin` (DateTime). **Sin `page`/`pageSize`, sin `entidadId`** | **array plano** de `AuditResponse`, orden `FechaHora DESC` | `Administrador,SupervisorOperaciones` |
| A2 | GET | `/api/activity/{id:long}` | — | `AuditResponse`, o **404** `ProblemDetails{title:"Recurso no encontrado", detail:"No se encontró ningún registro de auditoría con el ID {id}."}` | `Administrador,SupervisorOperaciones` |
| A3 | POST | `/api/activity` | `{accion, entidad, entidadId, detalle}` — `usuarioId` e `ipOrigen` los pone el servidor | `AuditResponse` (201) | **cualquier autenticado** |

```jsonc
// AuditResponse
{ "id": 12,                    // long
  "usuarioId": 3,              // int?  — ¡int, no GUID!
  "nombreUsuario": "jperez",
  "accion": "Actualizar",      // NVARCHAR(50), obligatorio
  "entidad": "Incidencias",    // NVARCHAR(80), nullable
  "entidadId": 7,              // int?   ← permite atar el evento a una incidencia
  "detalle": "…",              // NVARCHAR(400), nullable, TEXTO LIBRE
  "ipOrigen": "10.0.2.2",      // NVARCHAR(45), nullable
  "fechaHora": "2026-08-06T14:22:31.123" }  // ⚠️ SIN sufijo Z
```

Esquema (`database/scripts/01_Epica1_UsuariosRolesPermisos.sql`):
`AuditoriaAccesos(Id BIGINT IDENTITY, UsuarioId INT NULL, Accion NVARCHAR(50) NOT NULL, Entidad NVARCHAR(80) NULL, EntidadId INT NULL, Detalle NVARCHAR(400) NULL, IpOrigen NVARCHAR(45) NULL, FechaHora DATETIME2 NOT NULL DEFAULT SYSDATETIME())`.

**Validaciones del `AuditService`** (devuelven `ArgumentException`): `accion` obligatoria y ≤50; `entidad` ≤80; `detalle` ≤400; `ipOrigen` ≤45; `entidadId > 0`; `usuarioId > 0`; `fechaInicio ≤ fechaFin`.

**Tres consecuencias que cambian el diseño del módulo:**

1. ✅ **`entidad` + `entidadId` existen** ⇒ el **timeline por incidencia (§8.3) SÍ es viable**: `GET /api/activity?entidad=Incidencias` y filtrar `entidadId == id` **en cliente** (el API no expone filtro por `entidadId`).
2. ❌ **Sigue sin haber diff.** `Detalle` es un `NVARCHAR(400)` de texto libre; no hay `oldValues`/`newValues`. **`AuditDiffView` (§8.3, §8.5) sigue sin respaldo de datos** salvo que el propio móvil escriba el "antes → después" dentro de `detalle` con un formato convenido.
3. ⛔ **Nadie escribe auditoría.** `IAuditService` solo se inyecta en `ActivityController`; `IncidentService` y el login **no** insertan filas, y el `ActivityLogger` del web nuevo **solo escribe a `ILogger`**, no a la BD. ⇒ **`GET /api/activity` devuelve `[]`** hasta que un cliente haga `POST /api/activity`. Para que el módulo muestre algo, **la app debe registrar sus propios eventos con A3** tras cada mutación. Eso es *consumir* el endpoint existente, no modificarlo.

**⚠️ Fecha sin zona horaria:** `FechaHora` es `DATETIME2` con `DEFAULT SYSDATETIME()` (hora **local del servidor**) y el repositorio lo lee con `reader.GetDateTime()` → `Kind=Unspecified` → System.Text.Json lo emite **sin `Z`** → `DateTime.parse` de Dart lo interpreta como **hora local del teléfono**. Es el **comportamiento opuesto** al de `/api/incidents` del backend actual (que sí fuerza UTC). Hay que tratarlo explícitamente y **no** aplicarle `.toLocal()`.

**El resto del API nuevo (`src/backend/UrbanSync.Api`, puerto `5119`) — 17 endpoints en total:**

```
POST  /api/auth/login · /api/auth/register · /api/auth/change-password
GET   /api/incidents · /api/incidents/{id}      POST /api/incidents
PATCH /api/incidents/{id}/status · /api/incidents/{id}/triage   [Administrador,SupervisorOperaciones,AnalistaTecnico]
GET   /api/activity · /api/activity/{id}        POST /api/activity
GET   /api/roles · /api/roles/{id}              POST /api/roles          [Administrador]
GET   /api/usuarios · /api/usuarios/{id}        POST /api/usuarios
PATCH /api/usuarios/{id}/toggle-status                                   [Administrador]
```

**NO tiene**: `/api/incidents/{id}/evidences`, `/api/incident-types`, `/api/jurisdictions`, `/api/institutions`, `/api/work-orders`, `/api/reports/summary` — **todos en uso hoy por la app** (reportar incidencia, evidencias, triage, dashboard).

**Otras rupturas del API nuevo frente al actual:**

- **Roles distintos.** Sembrados: `Administrador`, `GestorUbicacion`, `GestorEvidencias`, `AnalistaTecnico`, `SupervisorOperaciones`, `Ciudadano`. **Ya no existen `Supervisor` ni `Tecnico`** ⇒ `AppUser.roleGroup` (que mapea esos dos literales) haría caer **a todos** en `citizen`, ocultando toda la UI de gestión.
- **`usuarioId` es `int`**, no el GUID de ASP.NET Identity.
- `IncidentResponse` **sí es wire-compatible** con nuestro `Incident.fromJson` (mismos nombres camelCase), salvo que **no trae `evidencias`**. Por eso `incidents_repository.dart` es **byte-idéntico** entre nuestro repo y `src/mobile/` del upstream.
- El `src/mobile/` upstream ya apunta a `http://10.0.2.2:5119/` y **no tiene `features/audit`** — el módulo de auditoría móvil está por construir (es justo este trabajo).

**Salida de Fase 0:** tablas completas arriba + bloqueos en §13. Commit `chore(audit): fase 0 — contrato de API relevado`.

---

## §3. Estructura de archivos objetivo

Ajustar a la convención real detectada. Estructura por defecto (feature-first, capas):

```
lib/features/incidents/
├── data/
│   ├── datasources/incidents_remote_datasource.dart
│   ├── dtos/incident_dto.dart
│   ├── dtos/comment_dto.dart
│   ├── dtos/attachment_dto.dart
│   ├── dtos/paged_response_dto.dart
│   └── repositories/incidents_repository_impl.dart
├── domain/
│   ├── entities/incident.dart
│   ├── entities/incident_status.dart
│   ├── entities/incident_filter.dart
│   ├── entities/comment.dart
│   └── repositories/incidents_repository.dart
└── presentation/
    ├── providers/incidents_list_provider.dart
    ├── providers/incident_detail_provider.dart
    ├── providers/incident_filter_provider.dart
    ├── pages/incidents_inbox_page.dart
    ├── pages/incident_detail_page.dart          # o extensión de la existente
    └── widgets/
        ├── incident_list_tile.dart
        ├── incident_filter_sheet.dart
        ├── status_transition_sheet.dart
        ├── assign_technician_sheet.dart
        ├── comment_composer.dart
        └── attachment_picker.dart

lib/features/audit/
├── data/
│   ├── datasources/audit_remote_datasource.dart
│   ├── dtos/audit_entry_dto.dart
│   └── repositories/audit_repository_impl.dart
├── domain/
│   ├── entities/audit_entry.dart
│   ├── entities/audit_action.dart
│   ├── entities/audit_filter.dart
│   └── repositories/audit_repository.dart
└── presentation/
    ├── providers/audit_log_provider.dart
    ├── providers/incident_audit_provider.dart
    ├── pages/audit_log_page.dart
    ├── pages/audit_entry_detail_page.dart
    └── widgets/
        ├── audit_timeline.dart
        ├── audit_entry_tile.dart
        ├── audit_diff_view.dart
        └── audit_filter_sheet.dart
```

> **Ajuste por Fase 0:** el proyecto real **no separa DTO de entidad** ni usa carpetas `datasources/` `repositories/`; usa `data/<feature>_repository.dart` + `domain/<entidad>.dart` + `presentation/<x>_providers.dart`. Por la regla "sigues la convención que ya exista" (§2.2), la estructura a usar es la del repo, no esta. Confirmar en la iteración 1.

---

## §4. Dominio

Entidades **inmutables**, sin dependencia de Flutter ni de `dio`. La conversión JSON vive en los DTOs.

```dart
// domain/entities/incident_status.dart
enum IncidentStatus {
  reported, underReview, triaged, assigned, inProgress,
  resolved, verified, closed, rejected, duplicated;

  // ⚠️ Reemplazar por los literales REALES del backend (Fase 0 §2.3)
  static IncidentStatus fromApi(String raw) => switch (raw) {
        'Reported' => IncidentStatus.reported,
        _ => throw ArgumentError('Estado desconocido: $raw'),
      };

  String get apiValue => /* mapeo inverso */;
}
```

> **Ajuste por Fase 0:** los estados reales son 6, no 10 → `registrada, enAnalisis, asignada, enProceso, cerrada, rechazada` (+ `unknown` para valores no reconocidos, §5). `fromApi` **no debe lanzar**: cae a `unknown`.

```dart
// domain/entities/incident.dart
class Incident {
  final String id;
  final String code;              // folio visible al usuario
  final String title;
  final String description;
  final IncidentCategory category;
  final IncidentPriority priority;
  final IncidentStatus status;
  final GeoPoint location;
  final String? address;
  final String reportedById;
  final String? reportedByName;
  final String? assignedToId;
  final String? assignedToName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final List<Attachment> attachments;
  final int commentsCount;
  const Incident({...});
  Incident copyWith({...});
}
```

> **Ajuste por Fase 0:** el API **no expone** `title`, `reportedById`, `assignedToId/Name`, `updatedAt`, `commentsCount`. El `id` es **`int`**, no `String`. Los campos reales están en `IncidentDto` (§2.3). La entidad `Incident` ya existe en `lib/features/incidents/domain/incident.dart` y refleja el contrato: **se extiende, no se reemplaza**.

```dart
// domain/entities/audit_entry.dart
class AuditEntry {
  final String id;
  final String entityType;        // "Incident", "WorkOrder", "User"...
  final String entityId;
  final AuditAction action;       // created, statusChanged, assigned, commented, deleted...
  final String actorId;
  final String actorName;
  final String actorRole;
  final DateTime timestamp;
  final String? comment;
  final Map<String, AuditChange> changes;   // campo -> (antes, después)
  final String? source;           // "mobile" | "web"
  const AuditEntry({...});
}

class AuditChange {
  final String? before;
  final String? after;
  const AuditChange(this.before, this.after);
}
```

> **Ajuste por Fase 0:** **BLOQUEADO**. No hay API ni esquema que soporte `entityType`, `entityId`, `actorRole`, `source` ni `changes`. Ver §13-B1 y §13-B2.

**Filtros** (`IncidentFilter`, `AuditFilter`): clases inmutables con `copyWith` y `toQueryParameters()`; omiten claves nulas.

**Repositorios (contratos):**

```dart
abstract interface class IncidentsRepository {
  Future<Page<Incident>> list(IncidentFilter filter, {int page, int pageSize});
  Future<Incident> getById(String id);
  Future<Incident> changeStatus(String id, IncidentStatus to, {String? comment});
  Future<Incident> assign(String id, {required String assigneeId});
  Future<Comment> addComment(String id, String text);
  Future<Attachment> uploadAttachment(String id, File file);
}

abstract interface class AuditRepository {
  Future<Page<AuditEntry>> forIncident(String incidentId, {int page, int pageSize});
  Future<Page<AuditEntry>> query(AuditFilter filter, {int page, int pageSize});
  Future<AuditEntry> getById(String id);
}
```

`Page<T>` va en `lib/core/` si no existe: `items`, `total`, `page`, `pageSize`, `hasMore`.

> **Ajuste por Fase 0:** `addComment` y `assign` no tienen endpoint (§13-B3, §13-B4). `Page<T>` no puede alimentarse del servidor (§13-B5). `AuditRepository` completo bloqueado (§13-B1).

---

## §5. Capa de datos

- Un `dio` **compartido** desde `lib/core` (con el interceptor JWT existente). **No crear una instancia nueva.** → `ref.read(dioProvider)`, tal como hace `IncidentsRepository`.
- DTO ↔ entidad: `IncidentDto.fromJson` + `toDomain()`. Nunca parsear JSON dentro de widgets ni providers. → **En este repo no hay capa DTO**: el `fromJson` vive en la entidad. Se mantiene esa convención (§2.2).
- Errores: capturar `DioException` en el datasource y traducirla al tipo de error propio del proyecto (`ApiException`). Distinguir: 401 (sesión), 403 (rol insuficiente), 404, 409 (transición de estado inválida), 422 (validación), 5xx, timeout, sin red.
  - Realidad del API: **no usa 409 para transiciones** (`PATCH /status` responde **400 ValidationProblem** con `errors.Estado = ["Estado inválido."]`). 409 solo aparece en registro duplicado y en "sin jurisdicción configurada". **No usa 422**; las validaciones son **400**.
- Enum desconocido llegando del API → no crashear: registrar warning y caer a un valor `unknown` visible en la UI.

---

## §6. Estado (Riverpod)

Seguir la convención detectada. Referencia:

```dart
// Lista paginada con filtros e infinite scroll
final incidentsListProvider =
    AsyncNotifierProvider.autoDispose<IncidentsListNotifier, IncidentsListState>(
        IncidentsListNotifier.new);

class IncidentsListState {
  final List<Incident> items;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final IncidentFilter filter;
}
```

Reglas:
- `build()` carga la página 1. `loadMore()` no reentra si `isLoadingMore`. `applyFilter()` resetea a página 1. `refresh()` invalida y recarga.
- Detalle: `incidentDetailProvider.family(id)`.
- Auditoría de una incidencia: `incidentAuditProvider.family(id)`.
- Tras `changeStatus` / `assign` / `addComment` → invalidar **detalle + auditoría + lista**, para que el timeline refleje el evento nuevo.
- Ninguna llamada HTTP dentro de `build()` de un widget ni en `initState` sin guard.

> **Ajuste por Fase 0:** el proyecto **no usa `AsyncNotifier`**; usa `Notifier` + `FutureProvider(.autoDispose)(.family)`. Y la paginación no existe server-side (§13-B5). Decidir en la iteración 3 si se introduce `Notifier<IncidentsListState>` (coherente con `AuthController`) con paginación **en cliente**.

---

## §7. Rutas (go_router)

Añadir al router existente, respetando su patrón de guards por rol:

| Ruta | Pantalla | Roles |
|---|---|---|
| `/incidents` | Bandeja | supervisor, técnico, admin |
| `/incidents/:id` | Detalle (tabs: Info · Comentarios · Auditoría) | según asignación / rol |
| `/audit` | Bitácora global | supervisor, admin |
| `/audit/:id` | Detalle de evento | supervisor, admin |

Deep-link `/incidents/:id` debe funcionar en frío (cargar por id sin depender de la lista).

> **Ajuste por Fase 0:** `/incidents/:id` **ya existe** y ya carga por id (`incidentDetailProvider.family`), deep-link en frío OK. El router **no tiene guards por rol**: hay que añadir el patrón (no existe uno que respetar). Roles literales: `Administrador`, `Supervisor`, `Tecnico`, `Ciudadano`.

---

## §8. Pantallas

### 8.1 Bandeja de incidencias (`/incidents`)
- `ListView` paginado con `IncidentListTile`: folio, título, `StatusChip`, badge de prioridad, categoría, tiempo relativo, avatar/nombre del asignado.
- AppBar: búsqueda de texto (debounce 400 ms) + botón de filtros.
- `IncidentFilterSheet`: estado (multi), prioridad, categoría, asignado a mí / sin asignar, rango de fechas. Botones *Aplicar* / *Limpiar*. Chips de filtros activos bajo el AppBar.
- Pull-to-refresh. Estados **Loading** (skeletons) / **Error** (mensaje + reintentar) / **Empty** (texto según haya o no filtros activos).

> **Ajuste por Fase 0:** no hay `title` ni asignado en `IncidentDto` (se usa `descripcion` truncada + `institucionAsignada`). El API filtra por `status`, `type`, `priority`, `jurisdictionId`, `mine`; **búsqueda de texto, rango de fechas, multi-estado y "sin asignar" no existen server-side** → o se filtran en cliente, o se amplía el backend (§13-B5).

### 8.2 Detalle de incidencia (`/incidents/:id`)
- Cabecera: folio, `StatusChip`, prioridad, categoría, fecha, reportante.
- Descripción, mini-mapa o coordenadas + dirección, galería de evidencia (tap → visor a pantalla completa).
- **Acciones según rol y estado** — solo transiciones válidas:
  - *Cambiar estado* → `StatusTransitionSheet` con las transiciones permitidas + comentario (obligatorio al rechazar / cerrar).
  - *Asignar* → `AssignTechnicianSheet` con buscador de técnicos.
  - *Adjuntar evidencia* → cámara o galería, con barra de progreso.
- Tabs: **Info** · **Comentarios** · **Auditoría** (§8.3).
- Confirmación antes de acciones irreversibles. Feedback con SnackBar de éxito/error.

> **Ajuste por Fase 0:** cabecera, mini-mapa y evidencia ya existen. El **comentario del cambio de estado no es persistible** (§13-B6); **Asignar no tiene endpoint ni lista de técnicos** (§13-B4, §13-B7); el tab **Comentarios no tiene backend** (§13-B3).

### 8.3 Timeline de auditoría (dentro del detalle)
- Lista vertical cronológica descendente: icono por acción, actor + rol, fecha absoluta y relativa, resumen legible.
- Resumen legible por acción, p. ej. *"Ana Pérez (Supervisor) cambió Estado: Asignada → En proceso"*.
- Tap en un evento con `changes` → expandir `AuditDiffView` (antes en rojo, después en verde, por campo).
- Paginado si supera 20 eventos. Estados Loading/Error/Empty.

> **BLOQUEADO** — §13-B1 y §13-B2.

### 8.4 Bitácora global (`/audit`)
- Lista paginada de todos los eventos, agrupados por día con encabezado pegajoso.
- `AuditFilterSheet`: tipo de entidad, acción, actor, rango de fechas.
- Tap → `/audit/:id`.

> **BLOQUEADO** — §13-B1.

### 8.5 Detalle de evento (`/audit/:id`)
- Ficha completa: id, entidad + id (con enlace a la incidencia si aplica), acción, actor, rol, origen, timestamp, comentario, diff completo.

> **BLOQUEADO** — §13-B1, §13-B2.

**Reglas de UI transversales:**
- Los tres estados (Loading/Error/Empty) son **obligatorios** en toda vista que consuma red.
- Fechas formateadas con `intl` según el locale de la app; nunca `toString()` de `DateTime`. → usar `formatDateTime` de `lib/shared/utils/formatters.dart`.
- Todo texto visible pasa por el sistema de i18n existente si lo hay; si no, constantes en un solo archivo del feature. → **no hay i18n**; constantes por feature.
- Sin `print`. Usar el logger del proyecto. → **no hay logger**; `debugPrint` si hiciera falta.

---

## §9. Permisos por rol

Roles literales del JWT (`ClaimTypes.Role`): **`Ciudadano`**, **`Tecnico`**, **`Supervisor`**, **`Administrador`**.

| Acción | Ciudadano | Técnico | Supervisor | Admin |
|---|---|---|---|---|
| Ver bandeja completa | ✗ (el API fuerza solo las suyas) | ✓ (es "staff": ve **todas**, no solo asignadas) | ✓ | ✓ |
| Cambiar estado | ✗ (403) | ✓ (`PATCH /status` lo permite: sin restricción por asignación) | ✓ | ✓ |
| Asignar (`/triage`, `POST /work-orders`) | ✗ | ✗ | ✓ | ✓ |
| Comentar | — sin endpoint — | — | — | — |
| Ver bitácora global | ✗ | ✗ | ✓ (solo vista web MVC) | ✓ (solo vista web MVC) |
| Subir evidencia | ✓ solo en incidencia propia | ✓ cualquiera | ✓ | ✓ |
| Ver `/api/reports/summary` | ✗ | ✗ | ✓ | ✓ |

> Diferencias reales frente a la tabla asumida por la spec: el **técnico ve todas** las incidencias (`IsStaff` incluye `Tecnico`, `IncidentsApiController.cs:29`), no solo las asignadas; y **puede cambiar estado de cualquiera**. Si la UI debe restringirlo a "solo asignadas", es una regla **de cliente** (cruzando con `GET /api/work-orders?technicianId=<yo>`), no del backend.

Regla: **la UI oculta lo que el rol no puede hacer**, y aun así se maneja el 403 del backend (la UI no es la autorización).

---

## §10. Casos borde a cubrir

- Token expirado a mitad de la acción → refresh o redirección a login sin perder el borrador del comentario. → **no hay refresh**; el interceptor limpia sesión y el router redirige a `/login`.
- Sin conexión → mensaje claro y botón de reintentar; no pantalla en blanco. → `ApiException` ya distingue `connectionError` y timeouts.
- Cambio de estado en conflicto (409, otro usuario ya lo movió) → refrescar detalle y avisar. → **el API no devuelve 409 aquí**; devuelve 400 solo si el literal es inválido. Sin control de concurrencia (sin ETag/rowversion): el último gana silenciosamente.
- Subida de imagen: comprimir antes de enviar, límite de tamaño, cancelable. → límite del servidor **50 MB**; extensiones `.jpg .jpeg .png .webp .gif .mp4 .pdf`. `image_picker` ya comprime (`imageQuality: 70`, `maxWidth: 1600`).
- Lista vacía vs error: nunca mostrar el mismo mensaje.
- Incidencia eliminada / 404 en deep-link. → el 404 **sí trae** ProblemDetails con `title:"Not Found"` y sin `detail`, así que hoy `ApiException` muestra **"Not Found"** en inglés. Corregir en la iteración 11.
- Diff con valores `null` (creación) → renderizar como "—". → bloqueado (§13-B2).
- Lista de auditoría muy larga → paginación, no cargar todo. → bloqueado (§13-B1/B5).

---

## §11. Verificación (gate de cada iteración)

```bash
# Correr SIEMPRE desde la junction ASCII (la ruta real tiene "é" y rompe el analysis server)
cd /c/dev/urbansync-mobile
export PATH="/c/src/flutter/bin:$PATH"

dart format --set-exit-if-changed lib test
flutter analyze                       # 0 issues nuevos vs baseline de Fase 0 (18)
flutter test
flutter build apk --debug             # solo en la iteración final de cada bloque
```

**Tests mínimos por iteración:**
- Unit: mapeo DTO→entidad (incluye enums desconocidos y nulls), `toQueryParameters()` de filtros, lógica de transiciones válidas.
- Unit: notifiers con repositorio falso (primera página, loadMore, aplicar filtro, error).
- Widget: bandeja en estados Loading / Error / Empty / con datos; timeline renderizando un diff.

Sin llamadas de red reales en tests. Nada de `Future.delayed` como sincronización — usar `pumpAndSettle` / fakes.

---

## §12. Estado del loop *(el agente edita esta sección)*

**Baseline `flutter analyze` (Fase 0): `18` issues** — 17 `info` (lints de estilo: `unnecessary_underscores` ×6, `use_null_aware_elements` ×4, `curly_braces_in_flow_control_structures` ×4, `deprecated_member_use` ×1, `prefer_final_fields` ×1) + **1 `error`**: `test/widget_test.dart:16:35 creation_with_non_type — The name 'MyApp' isn't a class`.

**Baseline `flutter test` (Fase 0): 15 pasan / 1 falla** — `test/widget_test.dart` (plantilla del contador de Flutter, referencia `MyApp` que no existe; la app se llama `UrbanSyncApp`). **El gate de §11 arranca en rojo**; ver §13-B8.

| It. | Objetivo | Archivos | Estado | Verificación | Commit |
|---|---|---|---|---|---|
| 0 | Reconocimiento: §2.2 y §2.3 completos | *(este .md)* | ☑ | n/a | *(pendiente)* |
| 1 | Dominio: entidades, enums, filtros, contratos de repositorio | `domain/**` | ☐ | analyze + unit | |
| 2 | Datos: DTOs, datasources, impl de repositorios, mapeo de errores | `data/**` | ☐ | analyze + unit mapeo | |
| 3 | Providers de incidencias (lista + detalle) con fakes probados | `presentation/providers/**` | ☐ | unit notifiers | |
| 4 | Bandeja `/incidents` + tile + estados L/E/E + ruta | `pages/incidents_inbox_page.dart` | ☐ | widget test | |
| 5 | Filtros + búsqueda + paginación infinita | `incident_filter_sheet.dart` | ☐ | unit + widget | |
| 6 | Detalle: cabecera, evidencia, tabs, deep-link | `incident_detail_page.dart` | ☐ | widget test | |
| 7 | Acciones: cambio de estado, asignación, comentarios, adjuntos + invalidaciones | `widgets/*_sheet.dart` | ☐ | unit transiciones | |
| 8 | Auditoría: dominio + datos + provider (contra `/api/activity`) | `features/audit/{domain,data}/**` | ☐ | unit mapeo | *desbloqueada; depende de §13-B10* |
| 9 | Timeline en el detalle (`entidad=Incidencias` + `entidadId`) | `widgets/audit_timeline.dart` | ☐ | widget test | *`AuditDiffView` pendiente de §13-B2* |
| 10 | Bitácora global `/audit` + filtros + detalle `/audit/:id` | `pages/audit_*.dart` | ☐ | widget test | *desbloqueada; depende de §13-B10* |
| 11 | Guards por rol + manejo de 401/403 + casos borde §10 | varios | ☐ | analyze + test | |
| 12 | Pulido: formato, i18n, sin `print`, build APK verde | — | ☐ | build apk | |

**Notas de la iteración actual (It. 0):**

- Se creó este archivo en la raíz del repo (no existía; el contenido venía en el prompt). Es el único artefacto de documentación permitido por §0.6.
- **El backend NO está desplegado en Render.** Corre local vía `docker compose up -d` (SQL Server 2022 + API en `:8080`; Swagger en `/swagger`). Se levantó el stack y el contrato de §2.3 quedó **relevado por código fuente Y validado contra la API viva**: rutas de Swagger, cuerpo real de `GET /api/incidents`, formato de fecha con `Z`, ausencia de `X-Total-Count`, y formas de error 400/403/404. No queda validación pendiente.
- **Gate de §11 obligatoriamente vía junction ASCII `C:\dev\urbansync-mobile`** (ya existía). Desde la ruta real con `é` el analysis server falla.
- La spec asume una arquitectura (DTOs separados, `AsyncNotifier`, `Page<T>`, `freezed`) que **no es la del repo**. Por la regla "sigues la convención que ya exista" (§2.2), en la iteración 1 se usará la convención real: `fromJson` en la entidad, `Notifier`/`FutureProvider`, `ApiException`. Los §3/§4/§6 quedan anotados con el ajuste.
- El detalle de incidencia ya tiene una "Línea de tiempo" basada en 3 fechas del propio DTO — **no es auditoría**. Convive con el tab de Auditoría; no se elimina.

---

## §13. Bloqueos / decisiones pendientes *(el agente edita)*

> **Actualizado tras §2.4.** El API de auditoría **existe** (`/api/activity` ×3) — B1 queda **resuelto**. Pero vive en **otro backend, en un repo con historia no relacionada**, lo que abre B10. Instrucción vigente del humano: *"los endpoints existen, haz git pull y trata de no modificarlos"* ⇒ **se consumen tal cual; no se toca el backend.**

| # | Bloqueo | Impacto | Necesita del humano |
|---|---|---|---|
| ~~B1~~ | ~~No existe API de auditoría~~ | **RESUELTO** — existen `GET /api/activity`, `GET /api/activity/{id}`, `POST /api/activity` en `rrivas/main` (§2.4). El timeline por incidencia es viable vía `entidad`+`entidadId` (filtrando `entidadId` en cliente) | — |
| **B2** | **Sigue sin haber diff.** `AuditoriaAccesos.Detalle` es `NVARCHAR(400)` de texto libre; no hay `oldValues`/`newValues` ni acción tipada | **`AuditDiffView` (§8.3, §8.5) no tiene datos que renderizar.** Sin tocar el backend, la única vía es que el móvil escriba el "antes → después" **dentro de `detalle`** con un formato convenido (ej. `Estado: Asignada → EnProceso`) y el cliente lo parsee | ¿Se acepta el diff derivado de `detalle` con formato convenido (funciona solo para eventos que escriba la app), o `AuditDiffView` se recorta del alcance? |
| **B2b** | **`GET /api/activity` devuelve `[]`.** Nadie escribe auditoría: `IAuditService` solo se usa en `ActivityController`, y el `ActivityLogger` del web nuevo escribe a `ILogger`, no a la BD | Bitácora y timeline **salen vacíos** hasta que un cliente haga `POST /api/activity` | ¿Autorizas que la app registre sus propios eventos con `POST /api/activity` tras cada mutación (crear incidencia, cambiar estado, triage)? Es consumir el endpoint existente, no modificarlo |
| **B3** | **No existe endpoint de comentarios** (`POST/GET /api/incidents/{id}/comments`) ni tabla de comentarios | Tab **Comentarios** de §8.2, `addComment` de §4, `CommentComposer` de §3, y "comentario obligatorio al rechazar/cerrar" de §8.2 | ¿Se crea el recurso en el backend (entidad + migración + controller) o se elimina del alcance? |
| **B4** | **No existe `POST /api/incidents/{id}/assign`.** La asignación real es a **institución** (vía `PATCH /triage`), y la asignación a **técnico** solo ocurre creando una **orden de trabajo** (`POST /api/work-orders {incidenciaId, usuarioAsignadoId, descripcionTrabajo}`), que además fuerza la incidencia a `Asignada` | `AssignTechnicianSheet` (§3, §8.2) y `IncidentsRepository.assign` (§4) | ¿Se acepta implementar "Asignar" como creación de orden de trabajo (endpoint real, semántica del dominio), o se exige un `/assign` nuevo? |
| **B5** | **El API no pagina.** `GET /api/incidents` devuelve un **array plano** completo, sin `page`/`pageSize`/`total`. Tampoco soporta `q` (texto), `from`/`to` (fechas), `assignedTo`, ni multi-valor de estado | **Scroll infinito y `Page<T>` (§4, §6, §8.1, iteración 5) no implementables server-side.** Búsqueda y rango de fechas tendrían que resolverse en cliente sobre todo el conjunto | ¿Paginación y búsqueda **en cliente** (simple, no escala), o se añaden `page`/`pageSize`/`q`/`from`/`to` al backend? |
| **B6** | **`PATCH /api/incidents/{id}/status` no acepta comentario.** Body = `{estado}` únicamente | El comentario obligatorio al rechazar/cerrar (§8.2) **no se persiste en ningún lado** | ¿Se amplía `UpdateStatusRequest` con `comentario` (y dónde se guarda: `UserActivity.Description`, comentarios de B3, o nueva columna)? ¿O se quita el requisito? |
| **B7** | **No hay endpoint para listar usuarios/técnicos.** Solo la vista MVC `UserManagementController.Index` (cookies + rol `Administrador`). No hay `GET /api/users?role=Tecnico` | El **buscador de técnicos** de `AssignTechnicianSheet` (§8.2) no tiene fuente de datos | ¿Se crea `GET /api/users?role=` en el backend, o se elimina la asignación desde el móvil? |
| **B8** | **El gate de §11 ya arranca en rojo.** `flutter test` falla en `test/widget_test.dart` (plantilla del contador de Flutter, referencia `MyApp`, clase inexistente — la app es `UrbanSyncApp`). También es el único `error` del `flutter analyze` baseline | §0.3 prohíbe avanzar con tests fallando ⇒ **ninguna iteración podría cerrarse.** Arreglarlo toca un archivo fuera del módulo (§0.2) | ¿Autorizas borrar/corregir `test/widget_test.dart` (1 línea, cambio trivial fuera del módulo, se anotaría en §12)? Es la vía más limpia para desbloquear el gate |
| **B9** | ~~Conflicto de alcance~~ → **RESUELTO por instrucción del humano**: no se toca el backend, se consumen los endpoints tal cual | B3, B4, B6, B7 quedan **fuera de alcance** (no hay endpoint y no se crea): sin comentarios, sin `/assign`, sin comentario en cambio de estado, sin buscador de técnicos | — (asignación de técnico solo sería posible si se apunta al backend actual vía `POST /api/work-orders`) |
| **B10** | **¿A qué backend apunta la app?** Son dos APIs **incompatibles y complementarias**: · **actual** `backend/UrbanSync.Web` `:8080` → incidents + **evidences + catálogos + work-orders + reports**, **sin auditoría** · **nuevo** `src/backend/UrbanSync.Api` `:5119` (upstream) → incidents + **auditoría + roles + usuarios**, **sin evidences/catálogos/work-orders/reports** | **Apuntar al nuevo API habilita Auditoría pero rompe Reportar Incidencia (`/api/incident-types`, `/api/jurisdictions`), Evidencias, Triage y Dashboard** — viola §0.2. Además los **roles cambian** (`Supervisor`/`Tecnico` ya no existen ⇒ `AppUser.roleGroup` manda a todos a `citizen`) y `usuarioId` pasa de GUID a `int` | **Decisión raíz nueva.** Tres caminos: **(a)** apuntar al API nuevo y aceptar que se rompen 4 pantallas; **(b)** mantener `:8080` y que el módulo de auditoría hable con `:5119` en paralelo (dos `baseUrl`, dos tokens — los JWT no son intercambiables); **(c)** integrar el upstream (`git merge rrivas/main --allow-unrelated-histories`, reestructuración mayor con `mobile/` + `src/mobile/` duplicados). **¿Cuál?** |

---

## §14. Prompt de arranque (pegar en Claude Code, dentro del repo)

```
Lee urbansync_auditoria_incidencias_loop.md completo y ejecútalo como loop.

Empieza por la FASE 0 (§2): haz pull, inventaría el móvil y releva el contrato
real del backend. Completa las tablas de §2.2 y §2.3 EDITANDO ese mismo archivo.
No escribas código Dart todavía.

Cuando termines la Fase 0: muéstrame las tablas completas y los bloqueos que
hayas detectado, y detente para que yo confirme antes de la iteración 1.

A partir de ahí, una iteración por turno: planificar → implementar → verificar
con §11 → marcar §12 → commit. No avances con analyze en rojo. Si el backend no
tiene un endpoint que la spec asume, anótalo en §13 y NO lo simules.
```

---

## §15. Definición de "terminado"

- [ ] `flutter analyze` sin issues nuevos respecto al baseline (18)
- [ ] `flutter test` en verde, con los tests mínimos de §11 por sub-módulo
- [ ] `flutter build apk --debug` exitoso
- [ ] Las 4 pantallas nuevas funcionan **contra el API real** desplegada, no contra mocks
- [ ] Loading / Error / Empty presentes en toda vista con red
- [ ] Permisos por rol aplicados en UI y 403 manejado
- [ ] Ningún endpoint inventado; §13 vacío o con bloqueos explicados
- [ ] Ramas y PR según el flujo del repo, sin archivos de documentación extra
