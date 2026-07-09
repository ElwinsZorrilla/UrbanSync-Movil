/* ============================================================
   Proyecto: UrbanSync
   Epica 1: Configuracion / Gestion de Usuarios y Accesos
   Ejecutar en el contexto de: UrbanSync
   ============================================================ */

USE UrbanSync;
GO

/* ---------------------------------------------------------
   Tabla: Roles
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.Roles', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Roles
    (
        Id              INT IDENTITY(1,1) PRIMARY KEY,
        Nombre          NVARCHAR(50)  NOT NULL,
        Descripcion     NVARCHAR(200) NULL,
        Activo          BIT           NOT NULL DEFAULT (1),
        FechaCreacion   DATETIME2     NOT NULL DEFAULT (SYSDATETIME()),
        CONSTRAINT UQ_Roles_Nombre UNIQUE (Nombre)
    );
END
GO

/* ---------------------------------------------------------
   Tabla: Permisos  (Modulo + Accion, ej: Incidencias / Crear)
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.Permisos', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Permisos
    (
        Id              INT IDENTITY(1,1) PRIMARY KEY,
        Modulo          NVARCHAR(50)  NOT NULL,   -- Ej: Usuarios, Incidencias, Reportes
        Accion          NVARCHAR(30)  NOT NULL,   -- Ej: Crear, Leer, Actualizar, Eliminar, Aprobar
        Descripcion     NVARCHAR(200) NULL,
        CONSTRAINT UQ_Permisos_Modulo_Accion UNIQUE (Modulo, Accion)
    );
END
GO

/* ---------------------------------------------------------
   Tabla: RolPermisos (N:M entre Roles y Permisos)
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.RolPermisos', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.RolPermisos
    (
        RolId       INT NOT NULL,
        PermisoId   INT NOT NULL,
        CONSTRAINT PK_RolPermisos PRIMARY KEY (RolId, PermisoId),
        CONSTRAINT FK_RolPermisos_Roles FOREIGN KEY (RolId)
            REFERENCES dbo.Roles(Id) ON DELETE CASCADE,
        CONSTRAINT FK_RolPermisos_Permisos FOREIGN KEY (PermisoId)
            REFERENCES dbo.Permisos(Id) ON DELETE CASCADE
    );
END
GO

/* ---------------------------------------------------------
   Tabla: Usuarios
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.Usuarios', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Usuarios
    (
        Id              INT IDENTITY(1,1) PRIMARY KEY,
        NombreUsuario   NVARCHAR(50)   NOT NULL,
        NombreCompleto  NVARCHAR(150)  NOT NULL,
        Email           NVARCHAR(150)  NOT NULL,
        PasswordHash    VARBINARY(256) NOT NULL,
        PasswordSalt    VARBINARY(128) NOT NULL,
        RolId           INT            NOT NULL,
        Activo          BIT            NOT NULL DEFAULT (1),
        FechaCreacion   DATETIME2      NOT NULL DEFAULT (SYSDATETIME()),
        FechaModificacion DATETIME2    NULL,
        UltimoAcceso    DATETIME2      NULL,
        CONSTRAINT UQ_Usuarios_NombreUsuario UNIQUE (NombreUsuario),
        CONSTRAINT UQ_Usuarios_Email UNIQUE (Email),
        CONSTRAINT FK_Usuarios_Roles FOREIGN KEY (RolId)
            REFERENCES dbo.Roles(Id)
    );
END
GO

/* ---------------------------------------------------------
   Tabla: AuditoriaAccesos (trazabilidad de operaciones)
   --------------------------------------------------------- */
IF OBJECT_ID('dbo.AuditoriaAccesos', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.AuditoriaAccesos
    (
        Id          BIGINT IDENTITY(1,1) PRIMARY KEY,
        UsuarioId   INT           NULL,
        Accion      NVARCHAR(50)  NOT NULL,   -- Ej: Login, Logout, Crear, Actualizar, Eliminar
        Entidad     NVARCHAR(80)  NULL,       -- Ej: Incidencias, Usuarios
        EntidadId   INT           NULL,
        Detalle     NVARCHAR(400) NULL,
        IpOrigen    NVARCHAR(45)  NULL,
        FechaHora   DATETIME2     NOT NULL DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_AuditoriaAccesos_Usuarios FOREIGN KEY (UsuarioId)
            REFERENCES dbo.Usuarios(Id)
    );
END
GO

/* ---------------------------------------------------------
   Indices de apoyo
   --------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Usuarios_RolId')
    CREATE INDEX IX_Usuarios_RolId ON dbo.Usuarios(RolId);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AuditoriaAccesos_UsuarioId')
    CREATE INDEX IX_AuditoriaAccesos_UsuarioId ON dbo.AuditoriaAccesos(UsuarioId);
GO

PRINT 'Tablas de la Epica 1 (Usuarios, Roles, Permisos, RolPermisos, AuditoriaAccesos) creadas correctamente.';
GO