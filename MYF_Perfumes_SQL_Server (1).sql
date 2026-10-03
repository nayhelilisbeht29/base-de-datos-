
/* ============================================================
   MYF PERFUMES
   Base de datos para Microsoft SQL Server / SSMS
   Arquitectura SOA / Microservicios

   Servicios:
   - Autenticación
   - Productos
   - Inventario
   - Ventas
   - Alertas de stock
   - Reportes

   NOTA:
   Cada microservicio administra su propia base de datos.
   No se crean claves foráneas entre bases de datos diferentes.
   ============================================================ */

USE master;
GO

/* ============================================================
   1. BASE DE DATOS DE AUTENTICACIÓN
   ============================================================ */

IF DB_ID(N'MYF_Auth_DB') IS NULL
BEGIN
    CREATE DATABASE MYF_Auth_DB;
END
GO

USE MYF_Auth_DB;
GO

IF OBJECT_ID(N'dbo.UsuarioRol', N'U') IS NOT NULL DROP TABLE dbo.UsuarioRol;
IF OBJECT_ID(N'dbo.Usuario', N'U') IS NOT NULL DROP TABLE dbo.Usuario;
IF OBJECT_ID(N'dbo.Rol', N'U') IS NOT NULL DROP TABLE dbo.Rol;
GO

CREATE TABLE dbo.Rol (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(50) NOT NULL UNIQUE,
    Descripcion NVARCHAR(150) NULL
);
GO

CREATE TABLE dbo.Usuario (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    Nombres NVARCHAR(100) NOT NULL,
    Apellidos NVARCHAR(100) NOT NULL,
    Email NVARCHAR(150) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    Estado NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Usuario_Estado DEFAULT N'ACTIVO',
    FechaCreacion DATETIME2 NOT NULL
        CONSTRAINT DF_Usuario_FechaCreacion DEFAULT SYSDATETIME(),
    UltimoAcceso DATETIME2 NULL,

    CONSTRAINT CK_Usuario_Estado
        CHECK (Estado IN (N'ACTIVO', N'INACTIVO', N'BLOQUEADO'))
);
GO

CREATE TABLE dbo.UsuarioRol (
    UsuarioId BIGINT NOT NULL,
    RolId BIGINT NOT NULL,

    CONSTRAINT PK_UsuarioRol PRIMARY KEY (UsuarioId, RolId),

    CONSTRAINT FK_UsuarioRol_Usuario
        FOREIGN KEY (UsuarioId) REFERENCES dbo.Usuario(Id),

    CONSTRAINT FK_UsuarioRol_Rol
        FOREIGN KEY (RolId) REFERENCES dbo.Rol(Id)
);
GO

INSERT INTO dbo.Rol (Nombre, Descripcion)
SELECT N'ADMIN', N'Administrador del sistema'
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Rol WHERE Nombre = N'ADMIN'
);

INSERT INTO dbo.Rol (Nombre, Descripcion)
SELECT N'VENDEDOR', N'Usuario encargado de registrar ventas'
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Rol WHERE Nombre = N'VENDEDOR'
);
GO


/* ============================================================
   2. BASE DE DATOS DE PRODUCTOS
   ============================================================ */

USE master;
GO

IF DB_ID(N'MYF_Producto_DB') IS NULL
BEGIN
    CREATE DATABASE MYF_Producto_DB;
END
GO

USE MYF_Producto_DB;
GO

IF OBJECT_ID(N'dbo.Producto', N'U') IS NOT NULL DROP TABLE dbo.Producto;
IF OBJECT_ID(N'dbo.Marca', N'U') IS NOT NULL DROP TABLE dbo.Marca;
IF OBJECT_ID(N'dbo.Categoria', N'U') IS NOT NULL DROP TABLE dbo.Categoria;
GO

CREATE TABLE dbo.Categoria (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(80) NOT NULL UNIQUE,
    Descripcion NVARCHAR(200) NULL,
    Estado NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Categoria_Estado DEFAULT N'ACTIVO',

    CONSTRAINT CK_Categoria_Estado
        CHECK (Estado IN (N'ACTIVO', N'INACTIVO'))
);
GO

CREATE TABLE dbo.Marca (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL UNIQUE,
    PaisOrigen NVARCHAR(80) NULL,
    Estado NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Marca_Estado DEFAULT N'ACTIVO',

    CONSTRAINT CK_Marca_Estado
        CHECK (Estado IN (N'ACTIVO', N'INACTIVO'))
);
GO

CREATE TABLE dbo.Producto (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    CategoriaId BIGINT NULL,
    MarcaId BIGINT NULL,
    Codigo NVARCHAR(50) NOT NULL UNIQUE,
    Nombre NVARCHAR(150) NOT NULL,
    Descripcion NVARCHAR(MAX) NULL,

    Tipo NVARCHAR(20) NOT NULL,
    VolumenMl DECIMAL(8,2) NOT NULL,
    Genero NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Producto_Genero DEFAULT N'UNISEX',

    Precio DECIMAL(10,2) NOT NULL,
    Costo DECIMAL(10,2) NULL,
    ImagenUrl NVARCHAR(500) NULL,

    Estado NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Producto_Estado DEFAULT N'ACTIVO',

    FechaCreacion DATETIME2 NOT NULL
        CONSTRAINT DF_Producto_FechaCreacion DEFAULT SYSDATETIME(),

    FechaActualizacion DATETIME2 NOT NULL
        CONSTRAINT DF_Producto_FechaActualizacion DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Producto_Categoria
        FOREIGN KEY (CategoriaId) REFERENCES dbo.Categoria(Id),

    CONSTRAINT FK_Producto_Marca
        FOREIGN KEY (MarcaId) REFERENCES dbo.Marca(Id),

    CONSTRAINT CK_Producto_Tipo
        CHECK (Tipo IN (N'PERFUME', N'DECANT')),

    CONSTRAINT CK_Producto_Genero
        CHECK (Genero IN (N'HOMBRE', N'MUJER', N'UNISEX')),

    CONSTRAINT CK_Producto_Estado
        CHECK (Estado IN (N'ACTIVO', N'INACTIVO')),

    CONSTRAINT CK_Producto_Precio
        CHECK (Precio >= 0),

    CONSTRAINT CK_Producto_Volumen
        CHECK (VolumenMl > 0)
);
GO

CREATE INDEX IX_Producto_Nombre
ON dbo.Producto(Nombre);
GO

CREATE INDEX IX_Producto_Tipo
ON dbo.Producto(Tipo);
GO

INSERT INTO dbo.Categoria (Nombre, Descripcion)
SELECT N'Perfumes', N'Perfumes en presentación completa'
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Categoria WHERE Nombre = N'Perfumes'
);

INSERT INTO dbo.Categoria (Nombre, Descripcion)
SELECT N'Decants', N'Decants de 5 ml'
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Categoria WHERE Nombre = N'Decants'
);
GO

INSERT INTO dbo.Marca (Nombre, PaisOrigen)
SELECT N'Lattafa', N'Emiratos Árabes Unidos'
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Marca WHERE Nombre = N'Lattafa'
);

INSERT INTO dbo.Marca (Nombre, PaisOrigen)
SELECT N'Afnan', N'Emiratos Árabes Unidos'
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Marca WHERE Nombre = N'Afnan'
);

INSERT INTO dbo.Marca (Nombre, PaisOrigen)
SELECT N'Armaf', N'Emiratos Árabes Unidos'
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Marca WHERE Nombre = N'Armaf'
);
GO

DECLARE @CatPerfume BIGINT =
    (SELECT TOP 1 Id FROM dbo.Categoria WHERE Nombre = N'Perfumes');

DECLARE @CatDecant BIGINT =
    (SELECT TOP 1 Id FROM dbo.Categoria WHERE Nombre = N'Decants');

DECLARE @Lattafa BIGINT =
    (SELECT TOP 1 Id FROM dbo.Marca WHERE Nombre = N'Lattafa');

DECLARE @Afnan BIGINT =
    (SELECT TOP 1 Id FROM dbo.Marca WHERE Nombre = N'Afnan');

DECLARE @Armaf BIGINT =
    (SELECT TOP 1 Id FROM dbo.Marca WHERE Nombre = N'Armaf');


IF NOT EXISTS (
    SELECT 1 FROM dbo.Producto
    WHERE Codigo = N'PERF-KHAMRAH-DUKHAN'
)
BEGIN
    INSERT INTO dbo.Producto
    (
        CategoriaId, MarcaId, Codigo, Nombre, Descripcion,
        Tipo, VolumenMl, Genero, Precio, Costo
    )
    VALUES
    (
        @CatPerfume, @Lattafa,
        N'PERF-KHAMRAH-DUKHAN',
        N'Khamrah Dukhan',
        N'Perfume árabe en presentación completa',
        N'PERFUME',
        100.00,
        N'UNISEX',
        170.00,
        110.00
    );
END;


IF NOT EXISTS (
    SELECT 1 FROM dbo.Producto
    WHERE Codigo = N'PERF-9PM'
)
BEGIN
    INSERT INTO dbo.Producto
    (
        CategoriaId, MarcaId, Codigo, Nombre, Descripcion,
        Tipo, VolumenMl, Genero, Precio, Costo
    )
    VALUES
    (
        @CatPerfume, @Afnan,
        N'PERF-9PM',
        N'9 PM',
        N'Perfume árabe en presentación completa',
        N'PERFUME',
        100.00,
        N'HOMBRE',
        160.00,
        110.00
    );
END;


IF NOT EXISTS (
    SELECT 1 FROM dbo.Producto
    WHERE Codigo = N'PERF-ICONIC'
)
BEGIN
    INSERT INTO dbo.Producto
    (
        CategoriaId, MarcaId, Codigo, Nombre, Descripcion,
        Tipo, VolumenMl, Genero, Precio, Costo
    )
    VALUES
    (
        @CatPerfume, @Armaf,
        N'PERF-ICONIC',
        N'Club de Nuit Iconic',
        N'Perfume árabe en presentación completa',
        N'PERFUME',
        105.00,
        N'HOMBRE',
        190.00,
        170.00
    );
END;


IF NOT EXISTS (
    SELECT 1 FROM dbo.Producto
    WHERE Codigo = N'DEC-KHAMRAH-DUKHAN-5'
)
BEGIN
    INSERT INTO dbo.Producto
    (
        CategoriaId, MarcaId, Codigo, Nombre, Descripcion,
        Tipo, VolumenMl, Genero, Precio, Costo
    )
    VALUES
    (
        @CatDecant, @Lattafa,
        N'DEC-KHAMRAH-DUKHAN-5',
        N'Khamrah Dukhan Decant 5 ml',
        N'Decant de 5 ml',
        N'DECANT',
        5.00,
        N'UNISEX',
        15.00,
        0.00
    );
END;
GO


/* ============================================================
   3. BASE DE DATOS DE INVENTARIO
   ============================================================ */

USE master;
GO

IF DB_ID(N'MYF_Inventario_DB') IS NULL
BEGIN
    CREATE DATABASE MYF_Inventario_DB;
END
GO

USE MYF_Inventario_DB;
GO

IF OBJECT_ID(N'dbo.MovimientoInventario', N'U') IS NOT NULL
    DROP TABLE dbo.MovimientoInventario;

IF OBJECT_ID(N'dbo.Inventario', N'U') IS NOT NULL
    DROP TABLE dbo.Inventario;
GO

CREATE TABLE dbo.Inventario (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,

    ProductoId BIGINT NOT NULL,

    StockActual INT NOT NULL
        CONSTRAINT DF_Inventario_StockActual DEFAULT 0,

    StockMinimo INT NOT NULL
        CONSTRAINT DF_Inventario_StockMinimo DEFAULT 2,

    FechaActualizacion DATETIME2 NOT NULL
        CONSTRAINT DF_Inventario_FechaActualizacion DEFAULT SYSDATETIME(),

    CONSTRAINT UQ_Inventario_Producto
        UNIQUE (ProductoId),

    CONSTRAINT CK_Inventario_StockActual
        CHECK (StockActual >= 0),

    CONSTRAINT CK_Inventario_StockMinimo
        CHECK (StockMinimo >= 0)
);
GO

CREATE TABLE dbo.MovimientoInventario (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,

    ProductoId BIGINT NOT NULL,

    TipoMovimiento NVARCHAR(30) NOT NULL,

    Cantidad INT NOT NULL,

    Motivo NVARCHAR(200) NULL,

    ReferenciaVentaId BIGINT NULL,

    UsuarioId BIGINT NULL,

    FechaMovimiento DATETIME2 NOT NULL
        CONSTRAINT DF_MovimientoInventario_Fecha
        DEFAULT SYSDATETIME(),

    CONSTRAINT CK_MovimientoInventario_Tipo
        CHECK (
            TipoMovimiento IN (
                N'ENTRADA',
                N'SALIDA',
                N'AJUSTE_POSITIVO',
                N'AJUSTE_NEGATIVO'
            )
        ),

    CONSTRAINT CK_MovimientoInventario_Cantidad
        CHECK (Cantidad > 0)
);
GO

CREATE INDEX IX_MovimientoInventario_Producto
ON dbo.MovimientoInventario(ProductoId);
GO

CREATE INDEX IX_MovimientoInventario_Fecha
ON dbo.MovimientoInventario(FechaMovimiento);
GO


/* ============================================================
   4. BASE DE DATOS DE VENTAS
   ============================================================ */

USE master;
GO

IF DB_ID(N'MYF_Venta_DB') IS NULL
BEGIN
    CREATE DATABASE MYF_Venta_DB;
END
GO

USE MYF_Venta_DB;
GO

IF OBJECT_ID(N'dbo.DetalleVenta', N'U') IS NOT NULL
    DROP TABLE dbo.DetalleVenta;

IF OBJECT_ID(N'dbo.Venta', N'U') IS NOT NULL
    DROP TABLE dbo.Venta;
GO

CREATE TABLE dbo.Venta (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,

    NumeroVenta NVARCHAR(30) NOT NULL UNIQUE,

    UsuarioId BIGINT NOT NULL,

    FechaVenta DATETIME2 NOT NULL
        CONSTRAINT DF_Venta_Fecha DEFAULT SYSDATETIME(),

    Subtotal DECIMAL(10,2) NOT NULL
        CONSTRAINT DF_Venta_Subtotal DEFAULT 0,

    Descuento DECIMAL(10,2) NOT NULL
        CONSTRAINT DF_Venta_Descuento DEFAULT 0,

    Total DECIMAL(10,2) NOT NULL
        CONSTRAINT DF_Venta_Total DEFAULT 0,

    MetodoPago NVARCHAR(30) NOT NULL
        CONSTRAINT DF_Venta_MetodoPago DEFAULT N'EFECTIVO',

    Estado NVARCHAR(20) NOT NULL
        CONSTRAINT DF_Venta_Estado DEFAULT N'REGISTRADA',

    Observacion NVARCHAR(300) NULL,

    FechaCreacion DATETIME2 NOT NULL
        CONSTRAINT DF_Venta_FechaCreacion DEFAULT SYSDATETIME(),

    CONSTRAINT CK_Venta_MetodoPago
        CHECK (
            MetodoPago IN (
                N'EFECTIVO',
                N'YAPE',
                N'PLIN',
                N'TRANSFERENCIA',
                N'TARJETA',
                N'OTRO'
            )
        ),

    CONSTRAINT CK_Venta_Estado
        CHECK (Estado IN (N'REGISTRADA', N'ANULADA')),

    CONSTRAINT CK_Venta_Total
        CHECK (Total >= 0)
);
GO

CREATE TABLE dbo.DetalleVenta (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,

    VentaId BIGINT NOT NULL,

    ProductoId BIGINT NOT NULL,

    NombreProducto NVARCHAR(150) NOT NULL,

    TipoProducto NVARCHAR(20) NOT NULL,

    Cantidad INT NOT NULL,

    PrecioUnitario DECIMAL(10,2) NOT NULL,

    Subtotal DECIMAL(10,2) NOT NULL,

    CONSTRAINT FK_DetalleVenta_Venta
        FOREIGN KEY (VentaId)
        REFERENCES dbo.Venta(Id)
        ON DELETE CASCADE,

    CONSTRAINT CK_DetalleVenta_TipoProducto
        CHECK (TipoProducto IN (N'PERFUME', N'DECANT')),

    CONSTRAINT CK_DetalleVenta_Cantidad
        CHECK (Cantidad > 0),

    CONSTRAINT CK_DetalleVenta_Precio
        CHECK (PrecioUnitario >= 0),

    CONSTRAINT CK_DetalleVenta_Subtotal
        CHECK (Subtotal >= 0)
);
GO

CREATE INDEX IX_Venta_Fecha
ON dbo.Venta(FechaVenta);
GO

CREATE INDEX IX_Venta_Usuario
ON dbo.Venta(UsuarioId);
GO

CREATE INDEX IX_DetalleVenta_Producto
ON dbo.DetalleVenta(ProductoId);
GO


/* ============================================================
   5. BASE DE DATOS DE ALERTAS
   ============================================================ */

USE master;
GO

IF DB_ID(N'MYF_Alerta_DB') IS NULL
BEGIN
    CREATE DATABASE MYF_Alerta_DB;
END
GO

USE MYF_Alerta_DB;
GO

IF OBJECT_ID(N'dbo.AlertaStock', N'U') IS NOT NULL
    DROP TABLE dbo.AlertaStock;
GO

CREATE TABLE dbo.AlertaStock (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,

    ProductoId BIGINT NOT NULL,

    Tipo NVARCHAR(20) NOT NULL,

    StockActual INT NOT NULL,

    StockMinimo INT NOT NULL,

    Mensaje NVARCHAR(250) NOT NULL,

    Estado NVARCHAR(20) NOT NULL
        CONSTRAINT DF_AlertaStock_Estado DEFAULT N'PENDIENTE',

    FechaAlerta DATETIME2 NOT NULL
        CONSTRAINT DF_AlertaStock_Fecha DEFAULT SYSDATETIME(),

    FechaAtendida DATETIME2 NULL,

    CONSTRAINT CK_AlertaStock_Tipo
        CHECK (Tipo IN (N'STOCK_BAJO', N'SIN_STOCK')),

    CONSTRAINT CK_AlertaStock_Estado
        CHECK (Estado IN (N'PENDIENTE', N'ATENDIDA'))
);
GO

CREATE INDEX IX_AlertaStock_Producto
ON dbo.AlertaStock(ProductoId);
GO

CREATE INDEX IX_AlertaStock_Estado
ON dbo.AlertaStock(Estado);
GO


/* ============================================================
   6. BASE DE DATOS DE REPORTES
   ============================================================ */

USE master;
GO

IF DB_ID(N'MYF_Reporte_DB') IS NULL
BEGIN
    CREATE DATABASE MYF_Reporte_DB;
END
GO

USE MYF_Reporte_DB;
GO

IF OBJECT_ID(N'dbo.ReporteProductoVendido', N'U') IS NOT NULL
    DROP TABLE dbo.ReporteProductoVendido;

IF OBJECT_ID(N'dbo.ReporteVentaDiaria', N'U') IS NOT NULL
    DROP TABLE dbo.ReporteVentaDiaria;
GO

CREATE TABLE dbo.ReporteVentaDiaria (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,

    Fecha DATE NOT NULL UNIQUE,

    CantidadVentas INT NOT NULL
        CONSTRAINT DF_ReporteVentaDiaria_CantidadVentas DEFAULT 0,

    UnidadesVendidas INT NOT NULL
        CONSTRAINT DF_ReporteVentaDiaria_Unidades DEFAULT 0,

    TotalVentas DECIMAL(12,2) NOT NULL
        CONSTRAINT DF_ReporteVentaDiaria_Total DEFAULT 0,

    FechaActualizacion DATETIME2 NOT NULL
        CONSTRAINT DF_ReporteVentaDiaria_FechaAct DEFAULT SYSDATETIME()
);
GO

CREATE TABLE dbo.ReporteProductoVendido (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,

    Fecha DATE NOT NULL,

    ProductoId BIGINT NOT NULL,

    NombreProducto NVARCHAR(150) NOT NULL,

    CantidadVendida INT NOT NULL
        CONSTRAINT DF_ReporteProducto_Cantidad DEFAULT 0,

    TotalVendido DECIMAL(12,2) NOT NULL
        CONSTRAINT DF_ReporteProducto_Total DEFAULT 0,

    CONSTRAINT UQ_ReporteProducto_FechaProducto
        UNIQUE (Fecha, ProductoId)
);
GO


/* ============================================================
   CONSULTAS DE VERIFICACIÓN
   ============================================================ */

SELECT name AS BaseDeDatos
FROM sys.databases
WHERE name IN (
    N'MYF_Auth_DB',
    N'MYF_Producto_DB',
    N'MYF_Inventario_DB',
    N'MYF_Venta_DB',
    N'MYF_Alerta_DB',
    N'MYF_Reporte_DB'
)
ORDER BY name;
GO

USE MYF_Producto_DB;
GO

SELECT * FROM dbo.Categoria;
SELECT * FROM dbo.Marca;
SELECT * FROM dbo.Producto;
GO


/* ============================================================
   FLUJO DEL SISTEMA

   1. VentaService registra la venta.
   2. ProductoService devuelve información del producto.
   3. InventarioService valida el stock.
   4. VentaService registra Venta y DetalleVenta.
   5. InventarioService descuenta el stock.
   6. Si StockActual <= StockMinimo:
      se genera un evento de stock bajo.
   7. AlertaStockService registra la alerta.
   8. ReporteService procesa las ventas para generar reportes.

   Los IDs entre microservicios son referencias lógicas,
   no FOREIGN KEY entre bases diferentes.
   ============================================================ */
