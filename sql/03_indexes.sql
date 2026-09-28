USE PerformanceLabDb;
GO
SET NOCOUNT ON;

PRINT 'Configuring indexes for SQL Performance Tuning Lab...';

-- 1. Create essential Foreign Key indexes
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Orders_CustomerId' AND object_id = OBJECT_ID('dbo.Orders'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Orders_CustomerId ON dbo.Orders (CustomerId);
    PRINT 'Created IX_Orders_CustomerId';
END;

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_OrderItems_OrderId' AND object_id = OBJECT_ID('dbo.OrderItems'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_OrderItems_OrderId ON dbo.OrderItems (OrderId);
    PRINT 'Created IX_OrderItems_OrderId';
END;

-- 2. Keyset Pagination Index: (OrderDate DESC, Id DESC)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Orders_Pagination' AND object_id = OBJECT_ID('dbo.Orders'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Orders_Pagination ON dbo.Orders (OrderDate DESC, Id DESC);
    PRINT 'Created IX_Orders_Pagination';
END;

-- 3. Unoptimized Non-clustered Index: Status only
-- Forces Bookmark Key Lookups when queries request OrderDate, TotalAmount, CustomerId, ShippingCity
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Orders_Unoptimized' AND object_id = OBJECT_ID('dbo.Orders'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Orders_Unoptimized ON dbo.Orders (Status);
    PRINT 'Created IX_Orders_Unoptimized';
END;

-- 4. Optimized Covering Index: (Status, OrderDate) INCLUDE (CustomerId, TotalAmount, ShippingCity)
-- Satisfies query directly from index pages without Clustered Index Key Lookups
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Orders_Covering' AND object_id = OBJECT_ID('dbo.Orders'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Orders_Covering ON dbo.Orders (Status, OrderDate) INCLUDE (CustomerId, TotalAmount, ShippingCity);
    PRINT 'Created IX_Orders_Covering';
END;
GO

-- 5. Stored Procedures to Dynamically Toggle Indexes for Controlled Benchmarking

IF OBJECT_ID('dbo.sp_EnableUnoptimizedMode', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_EnableUnoptimizedMode;
GO
CREATE PROCEDURE dbo.sp_EnableUnoptimizedMode
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Orders_Covering' AND object_id = OBJECT_ID('dbo.Orders'))
    BEGIN
        DROP INDEX IX_Orders_Covering ON dbo.Orders;
        PRINT 'Dropped IX_Orders_Covering for baseline benchmarking.';
    END;
    
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Orders_Unoptimized' AND object_id = OBJECT_ID('dbo.Orders'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Orders_Unoptimized ON dbo.Orders (Status);
        PRINT 'Created IX_Orders_Unoptimized.';
    END;
END;
GO

IF OBJECT_ID('dbo.sp_EnableCoveringMode', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_EnableCoveringMode;
GO
CREATE PROCEDURE dbo.sp_EnableCoveringMode
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Orders_Unoptimized' AND object_id = OBJECT_ID('dbo.Orders'))
    BEGIN
        DROP INDEX IX_Orders_Unoptimized ON dbo.Orders;
        PRINT 'Dropped IX_Orders_Unoptimized.';
    END;

    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Orders_Covering' AND object_id = OBJECT_ID('dbo.Orders'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Orders_Covering ON dbo.Orders (Status, OrderDate) INCLUDE (CustomerId, TotalAmount, ShippingCity);
        PRINT 'Created IX_Orders_Covering.';
    END;
END;
GO

IF OBJECT_ID('dbo.sp_EnableAllIndexes', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_EnableAllIndexes;
GO
CREATE PROCEDURE dbo.sp_EnableAllIndexes
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Orders_Unoptimized' AND object_id = OBJECT_ID('dbo.Orders'))
        CREATE NONCLUSTERED INDEX IX_Orders_Unoptimized ON dbo.Orders (Status);
        
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Orders_Covering' AND object_id = OBJECT_ID('dbo.Orders'))
        CREATE NONCLUSTERED INDEX IX_Orders_Covering ON dbo.Orders (Status, OrderDate) INCLUDE (CustomerId, TotalAmount, ShippingCity);
        
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Orders_Pagination' AND object_id = OBJECT_ID('dbo.Orders'))
        CREATE NONCLUSTERED INDEX IX_Orders_Pagination ON dbo.Orders (OrderDate DESC, Id DESC);

    PRINT 'All benchmark indexes enabled.';
END;
GO

PRINT 'Index setup completed successfully.';
GO
