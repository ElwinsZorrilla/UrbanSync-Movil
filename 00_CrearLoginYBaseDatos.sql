/* ============================================================
   Descripcion: Crea el LOGIN a nivel de servidor, la BASE DE DATOS
                y el USUARIO mapeado dentro de la base de datos,
                con permisos para que la Web API (ADO.NET) opere.
   Ejecutar en el contexto de: master
   ============================================================ */

USE master;
GO

-- 1. Crear la base de datos si no existe
IF DB_ID('UrbanSync') IS NULL
BEGIN
    CREATE DATABASE UrbanSync;
END
GO

-- 2. Crear el LOGIN a nivel de servidor
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'UrbanSync_App')
BEGIN
    CREATE LOGIN UrbanSync_App
        WITH PASSWORD = 'Urb@nSyncP@ssw0rd',
             CHECK_POLICY = ON,
             CHECK_EXPIRATION = OFF,
             DEFAULT_DATABASE = UrbanSync;
END
GO

USE UrbanSync;
GO

-- 3. Crear el USUARIO dentro de la base de datos, mapeado al login
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'UrbanSync_App')
BEGIN
    CREATE USER UrbanSync_App FOR LOGIN UrbanSync_App;
END
GO

-- 4. Asignar permisos. Para desarrollo
ALTER ROLE db_owner ADD MEMBER UrbanSync_App;
GO

-- 5. Permiso explicito de EXECUTE para cuando
GRANT EXECUTE TO UrbanSync_App;
GO

PRINT 'Login, base de datos UrbanSync y usuario UrbanSync_App creados correctamente.';
GO