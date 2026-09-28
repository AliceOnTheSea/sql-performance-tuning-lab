using BenchmarkDotNet.Attributes;
using Dapper;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using PerformanceLab.Benchmarks.Data;
using PerformanceLab.Benchmarks.Data.Models;
using PerformanceLab.Benchmarks.Models;

namespace PerformanceLab.Benchmarks.Benchmarks;

[MemoryDiagnoser]
public class OrmOverheadBenchmark
{
    private const string ConnectionString = "Server=localhost,1433;Database=PerformanceLabDb;User Id=sa;Password=YourStrong@Passw0rd!;TrustServerCertificate=True;";
    private ApplicationDbContext _dbContext = null!;
    private SqlConnection _dapperConnection = null!;
    private const int BatchSize = 500;
    private const int TargetStatus = 3;

    [GlobalSetup]
    public void Setup()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseSqlServer(ConnectionString)
            .Options;

        _dbContext = new ApplicationDbContext(options);
        _dapperConnection = new SqlConnection(ConnectionString);
        _dapperConnection.Open();
    }

    [GlobalCleanup]
    public void Cleanup()
    {
        _dbContext?.Dispose();
        _dapperConnection?.Dispose();
    }

    /// <summary>
    /// Baseline: EF Core default change-tracked query loading full entity hierarchy.
    /// Allocates memory for Change Tracker identity resolution, entity state snapshots, and full model metadata.
    /// </summary>
    [Benchmark(Baseline = true)]
    public async Task<List<Order>> EFCore_Tracked()
    {
        return await _dbContext.Orders
            .Include(o => o.Customer)
            .Where(o => o.Status == TargetStatus)
            .OrderByDescending(o => o.Id)
            .Take(BatchSize)
            .ToListAsync();
    }

    /// <summary>
    /// Optimized EF Core: AsNoTracking with DTO projection.
    /// Bypass Change Tracker and materialize directly into immutable OrderSummaryDto record instances.
    /// </summary>
    [Benchmark]
    public async Task<List<OrderSummaryDto>> EFCore_AsNoTracking()
    {
        return await _dbContext.Orders
            .AsNoTracking()
            .Where(o => o.Status == TargetStatus)
            .OrderByDescending(o => o.Id)
            .Take(BatchSize)
            .Select(o => new OrderSummaryDto
            {
                Id = o.Id,
                CustomerId = o.CustomerId,
                CustomerName = o.Customer.FullName,
                Status = o.Status,
                TotalAmount = o.TotalAmount,
                OrderDate = o.OrderDate,
                ShippingCity = o.ShippingCity
            })
            .ToListAsync();
    }

    /// <summary>
    /// Micro-ORM Direct Projection: Dapper parameterized raw T-SQL projection.
    /// Achieves lowest memory footprint and maximum throughput by bypassing ORM abstraction layers.
    /// </summary>
    [Benchmark]
    public async Task<List<OrderSummaryDto>> Dapper_DirectProjection()
    {
        const string sql = @"
            SELECT TOP (@BatchSize) 
                o.Id, 
                o.CustomerId, 
                c.FullName AS CustomerName, 
                o.Status, 
                o.TotalAmount, 
                o.OrderDate, 
                o.ShippingCity
            FROM dbo.Orders o WITH (NOLOCK)
            INNER JOIN dbo.Customers c WITH (NOLOCK) ON o.CustomerId = c.Id
            WHERE o.Status = @Status
            ORDER BY o.Id DESC;";

        var results = await _dapperConnection.QueryAsync<OrderSummaryDto>(sql, new { Status = TargetStatus, BatchSize = BatchSize });
        return results.ToList();
    }
}
