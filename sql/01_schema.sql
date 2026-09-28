USE master;
GO

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'PerformanceLabDb')
BEGIN
    CREATE DATABASE PerformanceLabDb;
END;
GO

USE PerformanceLabDb;
GO

-- Drop tables if they already exist (for clean runs)
IF OBJECT_ID('dbo.OrderItems', 'U') IS NOT NULL DROP TABLE dbo.OrderItems;
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;
GO

-- Customers Table
CREATE TABLE dbo.Customers (
    Id INT IDENTITY(1,1) NOT NULL,
    Email NVARCHAR(255) NOT NULL,
    FullName NVARCHAR(150) NOT NULL,
    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_Customers_CreatedAt DEFAULT SYSDATETIME(),
    CONSTRAINT PK_Customers PRIMARY KEY CLUSTERED (Id)
);
GO

-- Orders Table
CREATE TABLE dbo.Orders (
    Id BIGINT IDENTITY(1,1) NOT NULL,
    CustomerId INT NOT NULL,
    Status INT NOT NULL, -- 1: Pending, 2: Processing, 3: Completed, 4: Cancelled
    TotalAmount DECIMAL(18,2) NOT NULL,
    OrderDate DATETIME2 NOT NULL,
    ShippingCity NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_Orders PRIMARY KEY CLUSTERED (Id),
    CONSTRAINT FK_Orders_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers(Id)
);
GO

-- OrderItems Table
CREATE TABLE dbo.OrderItems (
    Id BIGINT IDENTITY(1,1) NOT NULL,
    OrderId BIGINT NOT NULL,
    Sku NVARCHAR(50) NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    CONSTRAINT PK_OrderItems PRIMARY KEY CLUSTERED (Id),
    CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (OrderId) REFERENCES dbo.Orders(Id) ON DELETE CASCADE
);
GO

PRINT 'Schema creation completed successfully.';
GO
