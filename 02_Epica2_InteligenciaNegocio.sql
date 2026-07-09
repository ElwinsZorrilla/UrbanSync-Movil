/* ============================================================
   Proyecto: UrbanSync
   Epica 2: Inteligencia de negocio
   Ejecutar en el contexto de: UrbanSync
   Requiere haber ejecutado antes: 01_Epica1_UsuariosRolesPermisos.sql
   ============================================================ */

USE UrbanSync;
GO

/* ---------------------------------------------------------
   Tabla: Jurisdicciones (division territorial, jerarquica)
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.Jurisdicciones', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Jurisdicciones
    (
        Id              INT IDENTITY(1,1) PRIMARY KEY,
        Nombre          NVARCHAR(100) NOT NULL,
        Nivel           NVARCHAR(30)  NOT NULL,  -- Ej: Provincia, Municipio, Distrito Municipal, Sector
        JurisdiccionPadreId INT NULL,
        Activo          BIT NOT NULL DEFAULT (1),
        CONSTRAINT FK_Jurisdicciones_Padre FOREIGN KEY (JurisdiccionPadreId)
            REFERENCES dbo.Jurisdicciones(Id)
    );
END
GO

/* ---------------------------------------------------------
   Tabla: Departamentos (para panel de operaciones entre departamentos)
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.Departamentos', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Departamentos
    (
        Id              INT IDENTITY(1,1) PRIMARY KEY,
        Nombre          NVARCHAR(100) NOT NULL,
        JurisdiccionId  INT NULL,
        Activo          BIT NOT NULL DEFAULT (1),
        CONSTRAINT FK_Departamentos_Jurisdicciones FOREIGN KEY (JurisdiccionId)
            REFERENCES dbo.Jurisdicciones(Id)
    );
END
GO

/* ---------------------------------------------------------
   Tabla: Instituciones (entidad externa a la que se enruta,
   Ej: Empresa Electrica, MOPC, etc.)
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.Instituciones', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Instituciones
    (
        Id              INT IDENTITY(1,1) PRIMARY KEY,
        Nombre          NVARCHAR(150) NOT NULL,
        TipoInstitucion NVARCHAR(50)  NOT NULL, -- Ej: Electricidad, Infraestructura, Otro
        ContactoEmail   NVARCHAR(150) NULL,
        ContactoTelefono NVARCHAR(30) NULL,
        Activo          BIT NOT NULL DEFAULT (1)
    );
END
GO

/* ---------------------------------------------------------
   Tabla: TiposIncidencia (define a que institucion se enruta
   automaticamente cada tipo)
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.TiposIncidencia', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.TiposIncidencia
    (
        Id              INT IDENTITY(1,1) PRIMARY KEY,
        Nombre          NVARCHAR(100) NOT NULL,   -- Ej: Electrico, Infraestructura Fisica
        Descripcion     NVARCHAR(300) NULL,
        InstitucionId   INT NOT NULL,             -- institucion por defecto para este tipo
        Activo          BIT NOT NULL DEFAULT (1),
        CONSTRAINT UQ_TiposIncidencia_Nombre UNIQUE (Nombre),
        CONSTRAINT FK_TiposIncidencia_Instituciones FOREIGN KEY (InstitucionId)
            REFERENCES dbo.Instituciones(Id)
    );
END
GO

/* ---------------------------------------------------------
   Tabla: Ubicaciones (gestor de "donde ocurre la incidencia")
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.Ubicaciones', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Ubicaciones
    (
        Id              INT IDENTITY(1,1) PRIMARY KEY,
        Direccion       NVARCHAR(250) NOT NULL,
        Referencia      NVARCHAR(250) NULL,
        Latitud         DECIMAL(10,7) NULL,
        Longitud        DECIMAL(10,7) NULL,
        JurisdiccionId  INT NOT NULL,
        FechaCreacion   DATETIME2 NOT NULL DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_Ubicaciones_Jurisdicciones FOREIGN KEY (JurisdiccionId)
            REFERENCES dbo.Jurisdicciones(Id)
    );
END
GO

/* ---------------------------------------------------------
   Tabla: Incidencias (nucleo del sistema)
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.Incidencias', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Incidencias
    (
        Id                  INT IDENTITY(1,1) PRIMARY KEY,
        CodigoCaso          NVARCHAR(30) NOT NULL,
        UsuarioReportaId    INT NOT NULL,
        TipoIncidenciaId    INT NOT NULL,
        UbicacionId         INT NOT NULL,
        InstitucionAsignadaId INT NULL,
        Estado              NVARCHAR(30) NOT NULL DEFAULT ('Registrada'), -- Registrada, EnAnalisis, Asignada, EnProceso, Cerrada, Rechazada
        Prioridad           NVARCHAR(20) NOT NULL DEFAULT ('Media'),      -- Baja, Media, Alta, Critica
        Descripcion         NVARCHAR(1000) NOT NULL,
        FechaReporte        DATETIME2 NOT NULL DEFAULT (SYSDATETIME()),
        FechaAsignacion     DATETIME2 NULL,
        FechaCierre         DATETIME2 NULL,
        CONSTRAINT UQ_Incidencias_CodigoCaso UNIQUE (CodigoCaso),
        CONSTRAINT FK_Incidencias_Usuarios FOREIGN KEY (UsuarioReportaId)
            REFERENCES dbo.Usuarios(Id),
        CONSTRAINT FK_Incidencias_TiposIncidencia FOREIGN KEY (TipoIncidenciaId)
            REFERENCES dbo.TiposIncidencia(Id),
        CONSTRAINT FK_Incidencias_Ubicaciones FOREIGN KEY (UbicacionId)
            REFERENCES dbo.Ubicaciones(Id),
        CONSTRAINT FK_Incidencias_Instituciones FOREIGN KEY (InstitucionAsignadaId)
            REFERENCES dbo.Instituciones(Id)
    );
END
GO

/* ---------------------------------------------------------
   Tabla: Evidencias (gestor de evidencias: fotos, videos, docs)
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.Evidencias', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Evidencias
    (
        Id              INT IDENTITY(1,1) PRIMARY KEY,
        IncidenciaId    INT NOT NULL,
        TipoEvidencia   NVARCHAR(20) NOT NULL,  -- Foto, Video, Documento
        RutaArchivo     NVARCHAR(400) NOT NULL,
        Descripcion     NVARCHAR(300) NULL,
        UsuarioSubeId   INT NOT NULL,
        FechaSubida     DATETIME2 NOT NULL DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_Evidencias_Incidencias FOREIGN KEY (IncidenciaId)
            REFERENCES dbo.Incidencias(Id) ON DELETE CASCADE,
        CONSTRAINT FK_Evidencias_Usuarios FOREIGN KEY (UsuarioSubeId)
            REFERENCES dbo.Usuarios(Id)
    );
END
GO

/* ---------------------------------------------------------
   Tabla: AnalisisTecnico (gestor tecnico: que se debe hacer)
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.AnalisisTecnico', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.AnalisisTecnico
    (
        Id                  INT IDENTITY(1,1) PRIMARY KEY,
        IncidenciaId        INT NOT NULL,
        UsuarioTecnicoId    INT NOT NULL,
        Diagnostico         NVARCHAR(1000) NOT NULL,
        AccionesRecomendadas NVARCHAR(1000) NULL,
        FechaAnalisis       DATETIME2 NOT NULL DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_AnalisisTecnico_Incidencias FOREIGN KEY (IncidenciaId)
            REFERENCES dbo.Incidencias(Id) ON DELETE CASCADE,
        CONSTRAINT FK_AnalisisTecnico_Usuarios FOREIGN KEY (UsuarioTecnicoId)
            REFERENCES dbo.Usuarios(Id)
    );
END
GO

/* ---------------------------------------------------------
   Tabla: Trabajos (captura info de trabajos realizados,
   para estadisticas y reportes)
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.Trabajos', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Trabajos
    (
        Id                  INT IDENTITY(1,1) PRIMARY KEY,
        IncidenciaId        INT NOT NULL,
        UsuarioAsignadoId   INT NOT NULL,
        DescripcionTrabajo  NVARCHAR(1000) NOT NULL,
        Estado              NVARCHAR(30) NOT NULL DEFAULT ('Pendiente'), -- Pendiente, EnProgreso, Finalizado, Cancelado
        FechaInicio         DATETIME2 NULL,
        FechaFin            DATETIME2 NULL,
        Resultado           NVARCHAR(1000) NULL,
        CONSTRAINT FK_Trabajos_Incidencias FOREIGN KEY (IncidenciaId)
            REFERENCES dbo.Incidencias(Id) ON DELETE CASCADE,
        CONSTRAINT FK_Trabajos_Usuarios FOREIGN KEY (UsuarioAsignadoId)
            REFERENCES dbo.Usuarios(Id)
    );
END
GO

/* ---------------------------------------------------------
   Tabla: SolicitudesReclamaciones (panel entre departamentos)
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.SolicitudesReclamaciones', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SolicitudesReclamaciones
    (
        Id                      INT IDENTITY(1,1) PRIMARY KEY,
        IncidenciaId            INT NULL,
        TipoSolicitud           NVARCHAR(30) NOT NULL,  -- Solicitud, Reclamacion, Operacion
        DepartamentoOrigenId    INT NOT NULL,
        DepartamentoDestinoId   INT NOT NULL,
        Descripcion             NVARCHAR(1000) NOT NULL,
        Estado                  NVARCHAR(30) NOT NULL DEFAULT ('Abierta'), -- Abierta, EnProceso, Cerrada, Rechazada
        FechaCreacion           DATETIME2 NOT NULL DEFAULT (SYSDATETIME()),
        FechaCierre             DATETIME2 NULL,
        CONSTRAINT FK_SolicitudesReclamaciones_Incidencias FOREIGN KEY (IncidenciaId)
            REFERENCES dbo.Incidencias(Id),
        CONSTRAINT FK_SolicitudesReclamaciones_DeptoOrigen FOREIGN KEY (DepartamentoOrigenId)
            REFERENCES dbo.Departamentos(Id),
        CONSTRAINT FK_SolicitudesReclamaciones_DeptoDestino FOREIGN KEY (DepartamentoDestinoId)
            REFERENCES dbo.Departamentos(Id)
    );
END
GO

/* ---------------------------------------------------------
   Tabla: Reportes (informe final del caso)
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.Reportes', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Reportes
    (
        Id              INT IDENTITY(1,1) PRIMARY KEY,
        IncidenciaId    INT NOT NULL,
        TrabajoId       INT NULL,
        GeneradoPorId   INT NOT NULL,
        Contenido       NVARCHAR(MAX) NULL,
        RutaArchivo     NVARCHAR(400) NULL,
        FechaGeneracion DATETIME2 NOT NULL DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_Reportes_Incidencias FOREIGN KEY (IncidenciaId)
            REFERENCES dbo.Incidencias(Id),
        CONSTRAINT FK_Reportes_Trabajos FOREIGN KEY (TrabajoId)
            REFERENCES dbo.Trabajos(Id),
        CONSTRAINT FK_Reportes_Usuarios FOREIGN KEY (GeneradoPorId)
            REFERENCES dbo.Usuarios(Id)
    );
END
GO

/* ---------------------------------------------------------
   Indices de apoyo para consultas y estadisticas frecuentes
   --------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Incidencias_Estado')
    CREATE INDEX IX_Incidencias_Estado ON dbo.Incidencias(Estado);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Incidencias_TipoIncidenciaId')
    CREATE INDEX IX_Incidencias_TipoIncidenciaId ON dbo.Incidencias(TipoIncidenciaId);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Incidencias_UbicacionId')
    CREATE INDEX IX_Incidencias_UbicacionId ON dbo.Incidencias(UbicacionId);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Evidencias_IncidenciaId')
    CREATE INDEX IX_Evidencias_IncidenciaId ON dbo.Evidencias(IncidenciaId);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Trabajos_IncidenciaId')
    CREATE INDEX IX_Trabajos_IncidenciaId ON dbo.Trabajos(IncidenciaId);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Ubicaciones_JurisdiccionId')
    CREATE INDEX IX_Ubicaciones_JurisdiccionId ON dbo.Ubicaciones(JurisdiccionId);
GO

PRINT 'Tablas de la Epica 2 (Jurisdicciones, Departamentos, Instituciones, TiposIncidencia, Ubicaciones, Incidencias, Evidencias, AnalisisTecnico, Trabajos, SolicitudesReclamaciones, Reportes) creadas correctamente.';
GO