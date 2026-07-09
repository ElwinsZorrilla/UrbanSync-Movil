# Code Review Summary — `movil-app`

**Skill:** code-reviewer-pro · **Alcance:** app Flutter + capa API JSON/JWT nueva sobre el repo MVC (ASP.NET Core 8, EF Core, SQL Server) · **Modo:** 3 sub-agentes (Security, Architecture, Code Quality).

**Contexto detectado:** MODERN_DOTNET (.NET 8 + EF Core) + Flutter. Sin Npgsql/Angular/AWS/GitLab → mejores prácticas estándar.

**Veredicto inicial:** ⚠️ CHANGES REQUESTED (hallazgos HIGH). **Veredicto tras correcciones:** ✅ APPROVED (los HIGH/medios accionables se corrigieron y re-verificaron; los residuales son decisiones documentadas para una entrega académica).

---

## Corregido y re-verificado

| # | Sev. | Hallazgo | Fix | Verificación |
|---|------|----------|-----|--------------|
| CQ-HIGH-001 | 🔴 | DateTimes UTC leídos de SQL Server perdían la `Z` → timestamps desfasados por zona horaria | Value converter global en `ApplicationDbContext` que fuerza `DateTimeKind.Utc` en lectura | `GET /incidents/{id}` → `...Z` ✔ |
| SEC-HIGH-003 / CQ-LOW-003 | 🟠 | IDOR: cualquier ciudadano listaba/leía TODAS las incidencias (PII+GPS) | `IncidentsApiController`: ciudadanos forzados a sus propias incidencias en List; `GetById` 403 si no es dueño | otro ciudadano `GET /incidents/1` → **403**; dueño → 200; lista de otro → 0 ✔ |
| SEC-HIGH-002 | 🟠 | Subida de archivos sin validar (XSS almacenado / malware) | Allow-list de extensiones (`jpg/jpeg/png/webp/gif/mp4/pdf`), header `X-Content-Type-Options: nosniff`, y solo dueño/staff | `.txt` → **400**, `.png` → 201 ✔ |
| SEC-MED-004 | 🟡 | Técnicos podían operar work orders ajenas; upload a incidencia ajena | Checks de propiedad en WorkOrders Start/Complete y en upload | upload ajeno → **403** ✔ |
| ARCH-MED-001 | 🟡 | `Ubicacion` guardada en transacción separada → fila huérfana si falla | `Ubicacion` como navegación anidada en `Incidencia` → un solo `SaveChanges` atómico | crea incidencia OK ✔ |
| CQ-LOW-002 | 🟢 | `UpdateStatus` aceptaba cualquier `estado` | Allow-list de estados válidos | `Foo` → **400**, `EnAnalisis` → 200 ✔ |
| SEC-LOW-008 | 🟢 | `/api/reports/summary` legible por ciudadanos | `[Authorize(Roles="Administrador,Supervisor")]` | ciudadano → **403**, supervisor → 200 ✔ |
| ARCH-MED-002 / CQ-INFO-001 | 🟡 | Sin manejo global de 401 (sesión expirada dejaba al usuario atascado) | Interceptor `onError` en dio: 401 (no-auth) limpia token y marca sesión expirada → guard redirige a login | compila + tests ✔ |
| CQ-MED-003 | 🟡 | Validador de contraseña del cliente más débil que la política del servidor | `Validators.password` ahora exige mayús/minús/dígito/símbolo (mensaje en español) | 15/15 tests ✔ |
| CQ-MED-002 | 🟡 | `setState` tras `await` sin `mounted` (picker/GPS) | Guards `if (!mounted) return;` en report/detail | compila ✔ |
| SEC-MED-006 | 🟡 | `usesCleartextTraffic` en release | Movido a `src/debug/AndroidManifest.xml` (solo debug) | build APK ✔ |
| (fix propio) | 🟠 | `Forbid()` manual devolvía 302 (esquema cookie) en vez de 403 | `StatusCode(403)` explícito en los checks de propiedad | 403 confirmado ✔ |

## Aceptado / documentado (decisiones para la entrega académica)

| Sev. | Hallazgo | Razón |
|------|----------|-------|
| 🔴 SEC-CRITICAL-001 | Usuarios semilla con contraseñas conocidas | **Intencional**: el profesor necesita credenciales por rol para calificar. Documentado en README. |
| 🟢 SEC-LOW-007 | Swagger habilitado en Producción | **Intencional**: se usa para verificación/demostración. |
| 🟡 ARCH-MED-003 / CQ-MED-001 | Asignación por técnico y UI de work orders incompletas | **Backlog H-14** (SCRUM). El técnico ve la cola de asignadas como simplificación MVP. |
| 🟢 ARCH-LOW-004 | Modelos de dominio con `fromJson` (sin freezed) | **Desviación documentada**: `freezed` resolvía a prerelease; se priorizó build estable. |
| 🟢 ARCH-LOW-005/006 | 5 queries en reports; IndexedStack mantiene tabs vivos | Aceptable a escala académica. |
| 🟡 SEC-MED-005 | Llave JWT/`sa` como defaults | `.env` gitignored; llave ≥256 bits; para demo local. |

---

## Cómo se verificó
- **API (dockerizada):** `docker compose up -d --build` + flujo E2E con `curl` (login por rol, crear incidencia, triage, evidencias, reportes, y casos negativos 401/403/400).
- **App:** `flutter build bundle` (compila) + `flutter test` (**15/15 verdes**).
