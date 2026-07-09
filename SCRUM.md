# SCRUM — UrbanSync Mobile

Gestión ágil de la app móvil de UrbanSync (ISO615 — 2do parcial). Backlog organizado por épicas e historias de usuario en formato **"Como [rol] quiero [capacidad] para [beneficio]"**, con estado y criterios de aceptación.

Estados: ✅ Hecho · 🔄 En progreso · ⬜ Pendiente (backlog para siguiente sprint).

## Roles

- **Ciudadano** — reporta incidencias y da seguimiento.
- **Técnico** — ejecuta trabajos y sube evidencias.
- **Gestor / Supervisor** — analiza (triage), asigna y monitorea indicadores.
- **Administrador** — todo lo anterior + catálogos y usuarios.

---

## Épica 1 — Gestores (Productores)

### E1.1 Gestor de ubicación de la incidencia

| ID | Historia | Estado |
|----|----------|--------|
| H-01 | Como **ciudadano** quiero **capturar mi ubicación por GPS** para reportar dónde ocurre el problema sin escribir coordenadas. | ✅ |
| H-02 | Como **ciudadano** quiero **ajustar el pin en un mapa** para corregir la ubicación exacta. | ✅ |
| H-03 | Como **ciudadano** quiero que **la jurisdicción se detecte automáticamente** para no tener que conocerla. | ✅ |
| H-04 | Como **ciudadano** quiero **agregar una referencia textual** (calle, sector) para dar más contexto. | ✅ |

*Aceptación:* al abrir "Reportar", la app pide permiso de ubicación, centra el mapa en mi posición, permite mover el pin y muestra "Jurisdicción: …".

### E1.2 Gestor de evidencias

| ID | Historia | Estado |
|----|----------|--------|
| H-05 | Como **ciudadano** quiero **adjuntar una foto** (cámara o galería) a mi reporte para evidenciar el problema. | ✅ |
| H-06 | Como **técnico** quiero **subir evidencias tipadas (antes/después)** con GPS para documentar el trabajo. | ✅ |
| H-07 | Como **usuario** quiero **ver la galería de evidencias** en el detalle de la incidencia. | ✅ |
| H-08 | Como **usuario** quiero **indicador de progreso y reintento** al subir evidencias. | 🔄 (progreso soportado por el cliente; reintento manual) |

*Aceptación:* la evidencia se sube por multipart, se guarda en el servidor y su URL se construye contra el host del request (no `localhost`).

### E1.3 Gestor de análisis técnico (triage)

| ID | Historia | Estado |
|----|----------|--------|
| H-09 | Como **gestor** quiero **una cola de incidencias nuevas** para priorizar mi trabajo. | ✅ |
| H-10 | Como **gestor** quiero **clasificar el tipo y la prioridad** de una incidencia. | ✅ |
| H-11 | Como **gestor** quiero **definir la acción** (asignar / derivar / solicitar info / rechazar). | ✅ |
| H-12 | Como **gestor** quiero **corregir la jurisdicción** si la autodetección falló. | ✅ |

*Aceptación:* al guardar el análisis, la incidencia cambia de estado (p. ej. Asignada) y se registra la fecha de asignación.

---

## Épica 2 — Inteligencia de negocio

### E2.1 Captura de trabajos

| ID | Historia | Estado |
|----|----------|--------|
| H-13 | Como **técnico** quiero **iniciar y completar** un trabajo desde la incidencia asignada. | ✅ (vía estado EnProceso → Cerrada + evidencias) |
| H-14 | Como **técnico** quiero **registrar el resultado** del trabajo para alimentar el historial. | ⬜ (endpoint `work-orders/complete` listo; pantalla dedicada pendiente) |

### E2.2 Routing automático por tipo

| ID | Historia | Estado |
|----|----------|--------|
| H-15 | Como **sistema** quiero **derivar la incidencia a la institución** según su tipo (eléctrico→distribuidora, infraestructura→MOPC). | ✅ |
| H-16 | Como **ciudadano** quiero **ver a qué institución** fue derivado mi caso. | ✅ |

### E2.3 Panel de administración de solicitudes

| ID | Historia | Estado |
|----|----------|--------|
| H-17 | Como **gestor** quiero **un panel filtrable** de incidencias por estado/tipo/prioridad. | ✅ (lista general; filtros de API disponibles) |
| H-18 | Como **gestor** quiero **transferir casos entre departamentos** con trazabilidad. | ⬜ (modelo de dominio previsto; UI en backlog) |

### E2.4 Reportes e indicadores

| ID | Historia | Estado |
|----|----------|--------|
| H-19 | Como **gestor** quiero **un dashboard con indicadores** (por estado, tipo, prioridad, jurisdicción). | ✅ (fl_chart) |
| H-20 | Como **gestor** quiero **el reporte de un caso** con el trabajo realizado. | ⬜ (datos disponibles; vista de reporte en backlog) |
| H-21 | Como **gestor** quiero **el historial del activo** intervenido. | ⬜ (requiere entidad Activo; backlog) |

---

## Transversales (Auth, Perfil, Navegación)

| ID | Historia | Estado |
|----|----------|--------|
| H-22 | Como **usuario** quiero **registrarme** para crear mi cuenta de ciudadano. | ✅ |
| H-23 | Como **usuario** quiero **iniciar sesión y mantener la sesión** de forma segura. | ✅ (JWT + secure storage) |
| H-24 | Como **usuario** quiero **una interfaz según mi rol** (ciudadano/técnico/gestor). | ✅ |
| H-25 | Como **usuario** quiero **ver mi perfil y cerrar sesión**. | ✅ |

---

## Sprint actual (MVP entregable) — Resumen

- **Completadas:** 20 historias (auth, reporte con GPS/mapa/foto, triage, evidencias, routing, dashboard, perfil, navegación por rol).
- **Backlog siguiente sprint:** H-14, H-18, H-20, H-21 (reporte de caso, transferencias entre departamentos, historial de activo, pantalla dedicada de cierre de trabajo).

> Las historias de este backlog se importan como *issues* al tablero **GitHub Projects** del repositorio (columnas: Backlog / En progreso / Hecho).
