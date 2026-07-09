/* ============================================================
   03_DatosSemilla.sql
   Proyecto: UrbanSync
   Descripcion: Datos base para poder probar la API de inmediato
   Ejecutar en el contexto de: UrbanSync
   Requiere: 01_Epica1_UsuariosRolesPermisos.sql y
             02_Epica2_InteligenciaNegocio.sql ya ejecutados
   ============================================================ */

USE UrbanSync;
GO

/* ---------------------------------------------------------
   Roles
   --------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE Nombre = 'Administrador')
INSERT INTO dbo.Roles (Nombre, Descripcion) VALUES
    ('Administrador', 'Acceso total a la plataforma'),
    ('GestorUbicacion', 'Registra donde ocurre la incidencia'),
    ('GestorEvidencias', 'Registra fotos, videos y documentos de la incidencia'),
    ('AnalistaTecnico', 'Analiza la incidencia y determina que se debe hacer'),
    ('SupervisorOperaciones', 'Administra solicitudes, reclamaciones y operaciones entre departamentos'),
    ('Ciudadano', 'Usuario que reporta incidencias');
GO

/* ---------------------------------------------------------
   Permisos base (Modulo, Accion)
   --------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Modulo = 'Usuarios' AND Accion = 'Crear')
INSERT INTO dbo.Permisos (Modulo, Accion, Descripcion) VALUES
    ('Usuarios', 'Crear', 'Crear usuarios'),
    ('Usuarios', 'Leer', 'Consultar usuarios'),
    ('Usuarios', 'Actualizar', 'Editar usuarios'),
    ('Usuarios', 'Eliminar', 'Eliminar/desactivar usuarios'),
    ('Incidencias', 'Crear', 'Registrar incidencias'),
    ('Incidencias', 'Leer', 'Consultar incidencias'),
    ('Incidencias', 'Actualizar', 'Editar incidencias'),
    ('Evidencias', 'Crear', 'Subir evidencias'),
    ('Evidencias', 'Leer', 'Consultar evidencias'),
    ('AnalisisTecnico', 'Crear', 'Registrar analisis tecnico'),
    ('AnalisisTecnico', 'Leer', 'Consultar analisis tecnico'),
    ('Trabajos', 'Crear', 'Registrar trabajos realizados'),
    ('Trabajos', 'Leer', 'Consultar trabajos'),
    ('SolicitudesReclamaciones', 'Crear', 'Crear solicitudes/reclamaciones'),
    ('SolicitudesReclamaciones', 'Leer', 'Consultar panel de solicitudes'),
    ('SolicitudesReclamaciones', 'Actualizar', 'Gestionar/cerrar solicitudes'),
    ('Reportes', 'Crear', 'Generar reportes'),
    ('Reportes', 'Leer', 'Consultar reportes');
GO

/* ---------------------------------------------------------
   Asignar TODOS los permisos al rol Administrador
   --------------------------------------------------------- */
INSERT INTO dbo.RolPermisos (RolId, PermisoId)
SELECT r.Id, p.Id
FROM dbo.Roles r
CROSS JOIN dbo.Permisos p
WHERE r.Nombre = 'Administrador'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.RolPermisos rp
      WHERE rp.RolId = r.Id AND rp.PermisoId = p.Id
  );
GO

/* ---------------------------------------------------------
   Instituciones de ejemplo
   --------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM dbo.Instituciones WHERE Nombre = 'Empresa Distribuidora de Electricidad')
INSERT INTO dbo.Instituciones (Nombre, TipoInstitucion, ContactoEmail) VALUES
    ('Empresa Distribuidora de Electricidad', 'Electricidad', 'contacto@edeeste.example'),
    ('Ministerio de Obras Publicas y Comunicaciones (MOPC)', 'Infraestructura', 'contacto@mopc.example'),
    ('Institucion General de Servicios', 'Otro', 'contacto@general.example');
GO

/* ---------------------------------------------------------
   Tipos de incidencia de ejemplo (enrutamiento automatico)
   --------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM dbo.TiposIncidencia WHERE Nombre = 'Problema Electrico')
INSERT INTO dbo.TiposIncidencia (Nombre, Descripcion, InstitucionId)
SELECT 'Problema Electrico', 'Fallas o incidencias relacionadas al servicio electrico', Id
FROM dbo.Instituciones WHERE Nombre = 'Empresa Distribuidora de Electricidad';

IF NOT EXISTS (SELECT 1 FROM dbo.TiposIncidencia WHERE Nombre = 'Infraestructura Fisica')
INSERT INTO dbo.TiposIncidencia (Nombre, Descripcion, InstitucionId)
SELECT 'Infraestructura Fisica', 'Danos en vias, aceras, edificaciones publicas', Id
FROM dbo.Instituciones WHERE Nombre = 'Ministerio de Obras Publicas y Comunicaciones (MOPC)';

IF NOT EXISTS (SELECT 1 FROM dbo.TiposIncidencia WHERE Nombre = 'Otro')
INSERT INTO dbo.TiposIncidencia (Nombre, Descripcion, InstitucionId)
SELECT 'Otro', 'Incidencias que no encajan en una categoria especifica', Id
FROM dbo.Instituciones WHERE Nombre = 'Institucion General de Servicios';
GO

/* ---------------------------------------------------------
   Jurisdiccion raiz de ejemplo (ajusta segun tu division real)
   --------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM dbo.Jurisdicciones WHERE Nombre = 'Distrito Nacional')
INSERT INTO dbo.Jurisdicciones (Nombre, Nivel) VALUES ('Distrito Nacional', 'Provincia');
GO

PRINT 'Datos semilla insertados correctamente.';
GO