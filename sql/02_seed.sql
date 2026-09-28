USE PerformanceLabDb;
GO
SET NOCOUNT ON;

PRINT 'Starting high-throughput seed process...';

-- 1. Seed 10,000 Customers
IF NOT EXISTS (SELECT 1 FROM dbo.Customers)
BEGIN
    PRINT 'Seeding 10,000 Customers...';
    
    WITH 
    E1(N) AS (SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1), -- 10
    E2(N) AS (SELECT 1 FROM E1 a CROSS JOIN E1 b), -- 100
    E4(N) AS (SELECT 1 FROM E2 a CROSS JOIN E2 b), -- 10,000
    Numbers AS (
        SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Num
        FROM E4
    )
    INSERT INTO dbo.Customers WITH (TABLOCK) (Email, FullName, CreatedAt)
    SELECT 
        'user' + CAST(Num AS VARCHAR(10)) + '@example.com',
        'Customer ' + CAST(Num AS VARCHAR(10)),
        DATEADD(second, -ABS(CHECKSUM(HASHBYTES('MD5', CAST(Num AS VARCHAR(20))))) % (365 * 3 * 86400), SYSDATETIME())
    FROM Numbers;

    PRINT 'Customers seeded successfully.';
END;
GO

-- 2. Seed 500,000 Orders in Batches
IF NOT EXISTS (SELECT 1 FROM dbo.Orders)
BEGIN
    PRINT 'Seeding 500,000 Orders...';
    
    CREATE TABLE #Cities (CityId INT IDENTITY(1,1), CityName NVARCHAR(100));
    INSERT INTO #Cities (CityName) VALUES 
    ('New York'), ('Los Angeles'), ('Chicago'), ('Houston'), ('Phoenix'),
    ('Philadelphia'), ('San Antonio'), ('San Diego'), ('Dallas'), ('San Jose'),
    ('Austin'), ('Seattle'), ('Denver'), ('Boston'), ('Miami');

    DECLARE @BatchCount INT = 5;
    DECLARE @CurrentBatch INT = 1;

    WHILE @CurrentBatch <= @BatchCount
    BEGIN
        PRINT 'Inserting Order Batch ' + CAST(@CurrentBatch AS VARCHAR(10)) + ' of ' + CAST(@BatchCount AS VARCHAR(10)) + ' (100,000 rows)...';
        
        WITH 
        E1(N) AS (SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1), -- 10
        E2(N) AS (SELECT 1 FROM E1 a CROSS JOIN E1 b), -- 100
        E3(N) AS (SELECT 1 FROM E2 a CROSS JOIN E1 b), -- 1,000
        E5(N) AS (SELECT 1 FROM E3 a CROSS JOIN E2 b), -- 100,000
        Numbers AS (
            SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Num
            FROM E5
        )
        INSERT INTO dbo.Orders WITH (TABLOCK) (CustomerId, Status, TotalAmount, OrderDate, ShippingCity)
        SELECT 
            ((Num * 17 + @CurrentBatch * 10007) % 10000) + 1 AS CustomerId,
            ((Num + @CurrentBatch) % 4) + 1 AS Status, -- 1: Pending, 2: Processing, 3: Completed, 4: Cancelled
            ROUND(10.0 + (CAST((ABS(CHECKSUM(HASHBYTES('MD5', CAST((Num + @CurrentBatch * 100000) AS VARCHAR(20))))) % 99000) AS DECIMAL(18,2)) / 100.0), 2) AS TotalAmount,
            DATEADD(minute, -((Num * 13 + @CurrentBatch * 97) % (3 * 365 * 1440)), SYSDATETIME()) AS OrderDate,
            c.CityName
        FROM Numbers n
        JOIN #Cities c ON c.CityId = ((n.Num % 15) + 1);

        SET @CurrentBatch = @CurrentBatch + 1;
    END;

    DROP TABLE #Cities;
    PRINT '500,000 Orders seeded successfully.';
END;
GO

-- 3. Seed 2,000,000 OrderItems (4 items per order)
IF NOT EXISTS (SELECT 1 FROM dbo.OrderItems)
BEGIN
    PRINT 'Seeding 2,000,000 OrderItems...';
    
    DECLARE @ItemBatch INT = 1;
    DECLARE @ItemBatchSize INT = 125000; -- 125k orders * 4 items = 500k order items per batch

    WHILE @ItemBatch <= 4
    BEGIN
        PRINT 'Inserting OrderItem Pass ' + CAST(@ItemBatch AS VARCHAR(10)) + ' of 4...';
        
        -- Generate 4 items for each order in the current range
        INSERT INTO dbo.OrderItems WITH (TABLOCK) (OrderId, Sku, Quantity, UnitPrice)
        SELECT 
            o.Id AS OrderId,
            'SKU-PROD-' + CAST(((o.Id * ItemSeq.N * 31) % 500) + 1 AS VARCHAR(10)) AS Sku,
            ((o.Id + ItemSeq.N) % 5) + 1 AS Quantity,
            ROUND(5.0 + ((o.Id * ItemSeq.N * 17) % 15000) / 100.0, 2) AS UnitPrice
        FROM dbo.Orders o WITH (NOLOCK)
        CROSS JOIN (
            SELECT 1 AS N UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        ) ItemSeq
        WHERE o.Id > (@ItemBatch - 1) * @ItemBatchSize AND o.Id <= @ItemBatch * @ItemBatchSize;

        SET @ItemBatch = @ItemBatch + 1;
    END;

    PRINT '2,000,000 OrderItems seeded successfully.';
END;
GO

PRINT 'Data seeding complete!';
GO
