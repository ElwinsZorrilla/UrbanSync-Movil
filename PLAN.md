# PLAN.md — UrbanSync Mobile

Plataforma de gestión inteligente de infraestructura urbana. Cada activo público (postes, calles, semáforos, parques, aceras) tiene un historial digital de reparaciones e intervenciones. Los ciudadanos reportan problemas, los gestores los analizan y asignan según tipo y **jurisdicción**, los técnicos ejecutan y suben evidencias (antes/después, GPS, descripción), y el sistema genera indicadores y reportes para la toma de decisiones.

Entrega académica (ISO615 — 2do parcial): mínimo 5 pantallas funcionales, navegación entre pantallas, componentes de UI básicos, coherencia con el prototipo UX (Figma), proyecto ejecutable y presentable, repo en GitHub, pantallas en PDF, evidencia de gestión scrum y documentación breve.

---

## 1. Roles y qué puede hacer cada usuario

| Rol | Capacidades |
|---|---|
| **Ciudadano** | Registrarse, iniciar sesión, reportar incidencia con ubicación y fotos, ver el estado y el historial de sus reportes, recibir la resolución, ver el mapa de incidencias de su zona, editar su perfil. |
| **Técnico** | Ver trabajos asignados a su jurisdicción, aceptar/iniciar un trabajo, subir evidencias (fotos antes/después, video, documento, GPS, descripción), marcar trabajo como completado, ver historial del activo que interviene. |
| **Gestor / Analista** | Panel de solicitudes y reclamaciones, análisis técnico (triage) de incidencias, clasificar tipo de requerimiento, confirmar/ajustar jurisdicción, asignar a institución o técnico, gestionar operaciones entre departamentos, cerrar casos, generar reportes del caso. |
| **Admin** | Todo lo anterior + gestión de usuarios y roles, catálogo de instituciones, catálogo de jurisdicciones, tipos de incidencia, estadísticas globales. |

El rol viene del backend en el login; la app muestra u oculta según rol, pero la autorización real la valida el API en cada endpoint.

## 2. Épica 1 — Gestores (Productores)

Tres gestores, cada uno con su feature:

**E1.1 Gestor de ubicación de la incidencia** (`features/incidents`)
- Captura de ubicación por GPS (geolocator) con opción de ajustar el pin en un mapa y agregar referencia textual (calle, sector).
- Al capturar coordenadas, el sistema resuelve automáticamente la **jurisdicción** (llamada al endpoint de resolución por punto; ver §5) y la muestra al usuario.
- Vinculación opcional a un **activo** existente (poste, semáforo, etc.) cercano a la ubicación.

**E1.2 Gestor de evidencias** (`features/evidence`)
- Adjuntar fotos (cámara/galería), videos y documentos a una incidencia o a un trabajo.
- Para técnicos: evidencias tipadas `antes` / `después` / `documento`, con coordenadas GPS y timestamp automáticos.
- Subida con indicador de progreso, reintento en fallo, y compresión de imágenes antes de subir.
- Galería de evidencias en el detalle de la incidencia/trabajo.

**E1.3 Gestor de análisis técnico (triage)** (`features/triage`)
- Cola de incidencias nuevas para el gestor/analista.
- Pantalla de análisis: ver reporte + evidencias + ubicación, clasificar tipo de requerimiento, definir prioridad, determinar acción (asignar a técnico, derivar a institución, solicitar más información, rechazar con motivo).
- La clasificación de tipo dispara el **routing automático a la institución** (Épica 2), siempre condicionado por la jurisdicción.

## 3. Épica 2 — Inteligencia de negocio

**E2.1 Gestor de captura de trabajos** (`features/work_orders`)
- Toda intervención genera una orden de trabajo ligada a la incidencia, al activo, al técnico y a la jurisdicción.
- Al completar: descripción del trabajo, evidencias antes/después, materiales/observaciones, fecha de cierre. Esto alimenta el historial del activo y las estadísticas.

**E2.2 Routing automático por tipo de requerimiento**
- Regla mantenida en backend (tabla tipo_incidencia → institución, filtrada por jurisdicción):
  - Problema eléctrico → entidad responsable de electricidad de esa jurisdicción.
  - Infraestructura física → MOPC.
  - Otros → institución que corresponda según el catálogo.
- La app muestra a qué institución fue derivado el caso y su estado.

**E2.3 Panel de administración de solicitudes** (`features/management`)
- Lista filtrable por estado, tipo, prioridad, institución y **jurisdicción**.
- Solicitudes, reclamaciones y operaciones entre departamentos (transferencias de casos entre instituciones/departamentos con trazabilidad de quién transfirió, cuándo y por qué).
- Un gestor solo ve y opera los casos de las jurisdicciones que tiene asignadas (el backend filtra; la app respeta).

**E2.4 Reportes e indicadores** (`features/reports`)
- Dashboard con indicadores: incidencias por estado, por tipo, por jurisdicción, tiempos de resolución, activos con más intervenciones.
- Reporte de caso: al cerrar un trabajo, generar el reporte con la información del caso, el trabajo realizado y los resultados (vista en app + exportable en PDF si el API lo permite; si no, vista detallada compartible).
- Historial digital por activo: línea de tiempo de todas las intervenciones.

## 4. Modelo de jurisdicción (transversal)

- Entidad `Jurisdiction`: id, nombre, división territorial (provincia/municipio/distrito o polígono si el API lo soporta), instituciones asociadas.
- Toda `Incident` y toda `WorkOrder` tienen `jurisdictionId` obligatorio.
- Resolución: al crear una incidencia, las coordenadas se envían al endpoint de resolución y el backend devuelve la jurisdicción; el gestor puede corregirla en el triage.
- Asignación: técnicos e instituciones se filtran por jurisdicción; el routing automático elige la institución correcta **de esa jurisdicción**.
- Usuarios gestor/técnico tienen jurisdicciones asignadas que delimitan lo que ven y operan.

## 5. Endpoints

Primero inventariar lo que ya existe en el repo (auth con **registro ya implementado**, y lo que haya de incidencias/usuarios). Consumir lo existente tal cual. Crear SOLO lo que falte, con la misma arquitectura, convenciones y formato de respuesta del repo, sin comentarios.

Contrato objetivo (ajustar nombres a las convenciones reales del repo):

```txt
Auth
POST   /auth/register            (EXISTE — consumir)
POST   /auth/login
POST   /auth/refresh             (si el repo lo tiene)
GET    /users/me

Incidencias
POST   /incidents
GET    /incidents                (filtros: status, type, priority, jurisdictionId, mine)
GET    /incidents/{id}
PATCH  /incidents/{id}/triage    (tipo, prioridad, acción, jurisdicción corregida)
PATCH  /incidents/{id}/status
POST   /incidents/{id}/transfer  (operación entre departamentos/instituciones)

Evidencias
POST   /incidents/{id}/evidences        (multipart: archivo, tipo, lat, lng)
GET    /incidents/{id}/evidences
POST   /work-orders/{id}/evidences

Órdenes de trabajo
POST   /work-orders              (desde triage: incidentId, technicianId)
GET    /work-orders              (filtros: technicianId, status, jurisdictionId)
GET    /work-orders/{id}
PATCH  /work-orders/{id}/start
PATCH  /work-orders/{id}/complete       (descripción, resultados)

Catálogos y jurisdicción
GET    /jurisdictions
GET    /jurisdictions/resolve?lat=&lng=
GET    /institutions             (filtro: jurisdictionId, incidentTypeId)
GET    /incident-types
GET    /assets                   (filtro: near lat/lng, jurisdictionId)
GET    /assets/{id}/history

Reportes
GET    /reports/summary          (indicadores por estado/tipo/jurisdicción/tiempos)
GET    /reports/case/{incidentId}
```

Si el repo ya resuelve algo de esto con otra forma (p. ej. un solo endpoint de update), adaptarse al repo, no al plan.

## 6. Pantallas (≥ 12; la rúbrica exige 5)

1. **Splash / decisión de sesión**
2. **Login**
3. **Registro** (consume el endpoint existente; validaciones de nombre, email, contraseña, confirmación)
4. **Home por rol** — ciudadano: mis reportes + botón reportar; técnico: mis trabajos; gestor: cola de triage + panel
5. **Reportar incidencia** (E1.1: GPS + mapa + jurisdicción autodetectada + tipo + descripción + fotos)
6. **Detalle de incidencia** (estado, línea de tiempo, evidencias, institución derivada, jurisdicción)
7. **Captura de evidencias** (E1.2: cámara/galería, antes/después, progreso de subida)
8. **Triage / análisis técnico** (E1.3: clasificar, priorizar, asignar/derivar/rechazar)
9. **Panel de gestión** (E2.3: filtros, reclamaciones, transferencias entre departamentos)
10. **Mis trabajos + detalle de trabajo** (técnico: iniciar, evidenciar, completar)
11. **Dashboard de indicadores** (E2.4: fl_chart)
12. **Reporte de caso** (información, trabajo realizado, resultados)
13. **Historial del activo** (línea de tiempo de intervenciones)
14. **Perfil** (datos, jurisdicciones asignadas, cerrar sesión)

Navegación: go_router con `ShellRoute` + `BottomNavigationBar` por rol (ciudadano: Inicio/Reportar/Mis reportes/Perfil; técnico: Trabajos/Mapa/Perfil; gestor: Triage/Panel/Indicadores/Perfil).

## 7. Fases de ejecución

1. **Descubrimiento**: leer repo del API, extraer contratos reales, descomprimir ZIP de diseños, mapear Figma→pantallas, extraer theme (colores, tipografía) del UI Kit.
2. **Fundación Flutter**: proyecto, arquitectura de carpetas, theme desde Figma, env por `--dart-define`, cliente dio, secure storage, go_router con guard, widgets compartidos.
3. **Auth**: login + registro (endpoint existente) + sesión persistente + logout.
4. **Épica 1**: incidents (E1.1) → evidence (E1.2) → triage (E1.3). Endpoints faltantes del API en paralelo por feature.
5. **Épica 2**: work_orders (E2.1) → routing e instituciones (E2.2) → management (E2.3) → reports + historial de activo (E2.4).
6. **Calidad**: estados loading/empty/error en todas las pantallas, tests, `flutter analyze` limpio, `dart format`.
7. **Entrega**: Docker del API, verificación end-to-end, README, PDF de pantallas (capturas de cada pantalla en un solo PDF para la entrega), instrucciones de emulación en teléfono.

Al final de cada fase: commit(s) con mensaje convencional y verificación de que la app compila y corre.

## 8. Mapeo con la rúbrica del parcial

| Criterio | Cómo se cumple |
|---|---|
| Estructura de la interfaz | Theme centralizado desde Figma + widgets compartidos + arquitectura feature-first |
| Navegación entre pantallas | go_router, bottom nav por rol, rutas protegidas, deep-link a detalle |
| Componentes de interfaz | Formularios validados, botones, menús, listas (`ListView.builder`), tablas/paneles filtrables |
| Interacción básica | Formularios con validación, acciones de triage/asignación/completar, subida de evidencias |
| Organización del código front-end | Carpetas por feature con data/domain/presentation |
| Tecnologías de desarrollo | Flutter, Riverpod, go_router, dio, freezed, secure storage, fl_chart |
| Gestión scrum | Generar `SCRUM.md` con backlog por épica/historia y estado, e importar esas historias como issues/tareas al tablero (GitHub Projects/Trello/Jira) — historias en formato "Como [rol] quiero [capacidad] para [beneficio]" |
| Documentación breve | README con requisitos, cómo correr, ambientes, arquitectura y comandos |

## 9. Docker + emulación en teléfono (paso final obligatorio)

1. Si el repo del API no tiene Docker: crear `Dockerfile` y `docker-compose.yml` acordes a su stack (API + base de datos + volúmenes + variables de entorno; sin secretos en el repo, usar `.env` con `.env.example`).
2. `docker compose up -d --build` y verificar salud del API (endpoint de health o login de prueba).
3. Obtener la IP LAN de la máquina (`ipconfig` / `ifconfig`) y configurar `dev` con `API_BASE_URL=http://<IP_LAN>:<puerto>`.
4. Teléfono y PC en la misma red Wi-Fi. Android: activar depuración USB (o wireless debugging) → `flutter devices` → `flutter run --dart-define=ENV=dev -d <deviceId>`. iOS: requiere Mac + Xcode con el dispositivo confiado.
5. Probar flujo completo desde el teléfono: registro → login → reportar incidencia con GPS y foto → triage → asignación → evidencias antes/después → completar → ver reporte e indicadores.
6. Entregar al usuario, por escrito al final: los comandos exactos que ejecutó, la URL del API, y cómo relanzar todo desde cero.
