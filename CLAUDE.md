# CLAUDE.md — UrbanSync Mobile (Flutter)

Este folder contiene todo lo necesario para construir la app móvil de UrbanSync:
- `PLAN.md` — plan de implementación completo. Léelo ANTES de escribir código y síguelo.
- Repo del API (clonado o como submódulo): https://github.com/rrivas-unapec/UrbanSync.git
- ZIP con los diseños exportados de Figma (descomprímelo y úsalo como referencia visual obligatoria).
- Figma (referencia): https://www.figma.com/design/khOqg1McjJxAwnRYE9PIAN/UrbanSync_Desing?node-id=4-2

## Reglas de oro (NO negociables)

1. **Cero comentarios innecesarios.** No escribas comentarios en el código salvo que algo sea genuinamente no obvio (algoritmo raro, workaround documentado). Nada de `// constructor`, `// build method`, `// llamada a la API`.
2. **El código nuevo del backend sigue EXACTAMENTE la arquitectura existente del repo.** Antes de crear cualquier endpoint, lee el código del API, identifica sus capas (controllers/services/repositories/models o lo que use), sus convenciones de nombres, su manejo de errores y su formato de respuesta, y replica todo eso. No introduzcas patrones nuevos en el backend.
3. **El endpoint de registro ya existe.** Localízalo en el repo, entiende su contrato (ruta, body, respuesta) y consúmelo desde Flutter. No lo reimplementes.
4. **UI fiel al diseño de Figma** (colores, tipografía, espaciados, componentes del ZIP). Si un elemento no está diseñado, créalo consistente con el UI Kit.
5. **La jurisdicción es un concepto de primer nivel** en el dominio: toda incidencia pertenece a una jurisdicción y la asignación/routing depende de ella. Ver PLAN.md §4.
6. Textos de UI en **español**.

## Stack y convenciones Flutter

- Flutter estable + Dart con null safety estricto (evitar `!`, preferir `?`, `??` y validación).
- State management: **Riverpod** (flutter_riverpod). Estados sellados/enum: `initial | loading | success | empty | error`. Nunca múltiples booleanos sueltos.
- Navegación: **go_router**, rutas centralizadas en `lib/app/routes.dart`, con guard de autenticación (rutas públicas: login, registro; el resto protegidas).
- HTTP: **dio** con cliente centralizado (`baseUrl` desde configuración de ambiente, interceptor que inyecta el token, manejo de refresh si el API lo soporta, timeouts, mapeo de errores HTTP a excepciones de dominio).
- Token y credenciales: **flutter_secure_storage**. Nunca SharedPreferences para datos sensibles. Ningún secreto hardcodeado en el código.
- Modelos: **freezed + json_serializable**. Nada de `Map<String, dynamic>` circulando por la app ni `dynamic` innecesario. Separar modelos de API (DTO) de entidades de dominio.
- Ubicación: **geolocator** (+ **geocoding** si aplica). Fotos/videos: **image_picker**. Gráficos: **fl_chart**. Mapa: **flutter_map** (OpenStreetMap, sin API key) salvo que el proyecto ya use Google Maps.
- Fechas en UTC hacia el backend, mostradas en hora local. Montos monetarios (si aparecen) en enteros/centavos, nunca `double`.

## Arquitectura Flutter (feature-first, clean)

```txt
lib/
├── main.dart
├── app/            (app.dart, routes.dart, theme.dart)
├── core/           (constants, env, errors, network, storage, utils)
├── features/
│   ├── auth/            data / domain / presentation
│   ├── incidents/       data / domain / presentation
│   ├── evidence/        data / domain / presentation
│   ├── triage/          data / domain / presentation
│   ├── work_orders/     data / domain / presentation
│   ├── management/      data / domain / presentation
│   ├── reports/         data / domain / presentation
│   └── profile/         data / domain / presentation
└── shared/         (widgets, models, services)
```

- `presentation`: pantallas, widgets, providers/controllers. Las pantallas NO conocen dio, storage ni parseo de JSON.
- `domain`: entidades, casos de uso, contratos de repositorio.
- `data`: datasources remotos, DTOs, implementaciones de repositorio.
- Widgets compartidos obligatorios: `PrimaryButton`, `SecondaryButton`, `AppTextField`, `LoadingView`, `ErrorView`, `EmptyState`, `AppCard`, `StatusChip`.

## Calidad

- `const` donde aplique; listas con `ListView.builder`; ninguna llamada a API dentro de `build`; toda pantalla con datos maneja loading/success/empty/error.
- Try/catch nunca vacíos; errores diferenciados (red, 401, validación, servidor) con mensajes claros al usuario; `debugPrint`, nunca `print`.
- Antes de dar por terminado: `dart format .` y `flutter analyze` sin warnings; correr los tests con `flutter test`.
- Tests mínimos: validadores de formularios (unit), repositorio de auth e incidencias con mocks (unit), y widget test de LoginPage y de la pantalla de reporte de incidencia.
- Git: commits pequeños con convención `feat: | fix: | refactor: | test: | docs:`. Ramas `feature/...` si el flujo lo permite.

## Ambientes

`lib/core/env/` con `dev`, `staging`, `prod` seleccionables por `--dart-define=ENV=dev`. En dev, el `baseUrl` apunta al API en Docker mediante la IP LAN de la máquina (no `localhost`, porque el teléfono no la resuelve). Ver PLAN.md §9.

## Flujo de trabajo esperado

1. Leer `PLAN.md` completo.
2. Explorar el repo del API: rutas existentes, modelos, auth, formato de respuestas.
3. Descomprimir el ZIP de diseños y mapear pantallas de Figma → pantallas del plan.
4. Presentar el plan de ejecución (fases del PLAN.md ajustadas a lo que encontraste en el repo) y ejecutarlo fase por fase.
5. Crear los endpoints faltantes en el API respetando su arquitectura, sin comentarios.
6. Construir la app Flutter.
7. Levantar el API con Docker (docker-compose si no existe, créalo siguiendo el stack del repo).
8. Verificar la app corriendo contra el API dockerizado y dar las instrucciones exactas para correrla en el teléfono físico (PLAN.md §9).
