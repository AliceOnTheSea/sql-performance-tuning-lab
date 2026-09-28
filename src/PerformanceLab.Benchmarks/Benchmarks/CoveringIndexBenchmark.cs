using BenchmarkDotNet.Attributes;
using Dapper;
using Microsoft.Data.SqlClient;

namespace PerformanceLab.Benchmarks.Benchmarks;

[MemoryDiagnoser]
public class CoveringIndexBenchmark
{
    private const string ConnectionString = "Server=localhost,1433;Database=PerformanceLabDb;User Id=sa;Password=YourStrong@Passw0rd!;TrustServerCertificate=True;";
    private SqlConnection _connection = null!;
    private DateTime _startDate;
    private DateTime _endDate;
    private int _targetStatus;

    [GlobalSetup]
    public void Setup()
    {
        _connection = new SqlConnection(ConnectionString);
        _connection.Open();
        _targetStatus = 3; // Completed status
        _endDate = DateTime.UtcNow;
        _startDate = _endDate.AddDays(-180);
    }

    [GlobalCleanup]
    public void Cleanup()
    {
        _connection?.Dispose();
    }

    /// <summary>
    /// Baseline: Forces non-covering index (IX_Orders_Unoptimized on Status).
    /// Requires expensive Bookmark (Key) Lookups back to the Clustered Index for TotalAmount, OrderDate, CustomerId, ShippingCity.
    /// </summary>
    [Benchmark(Baseline = true)]
    public async Task<int> Baseline_KeyLookup()
    {
        const string sql = @"
            SELECT o.Id, o.CustomerId, o.Status, o.TotalAmount, o.OrderDate, o.ShippingCity
            FROM dbo.Orders o WITH (INDEX(IX_Orders_Unoptimized))
            WHERE o.Status = @Status
              AND o.OrderDate >= @StartDate AND o.OrderDate <= @EndDate;";

        var results = await _connection.QueryAsync<CoveringOrderDto>(sql, new { Status = _targetStatus, StartDate = _startDate, EndDate = _endDate });
        return results.Count();
    }

    /// <summary>
    /// Optimized: Uses Covering Index (IX_Orders_Covering on (Status, OrderDate) INCLUDE (CustomerId, TotalAmount, ShippingCity)).
    /// Eliminates Key Lookups entirely; all required columns reside directly within the index leaf pages.
    /// </summary>
    [Benchmark]
    public async Task<int> Optimized_CoveringIndex()
    {
        const string sql = @"
            SELECT o.Id, o.CustomerId, o.Status, o.TotalAmount, o.OrderDate, o.ShippingCity
            FROM dbo.Orders o WITH (INDEX(IX_Orders_Covering))
            WHERE o.Status = @Status
              AND o.OrderDate >= @StartDate AND o.OrderDate <= @EndDate;";

        var results = await _connection.QueryAsync<CoveringOrderDto>(sql, new { Status = _targetStatus, StartDate = _startDate, EndDate = _endDate });
        return results.Count();
    }

    public record CoveringOrderDto(long Id, int CustomerId, int Status, decimal TotalAmount, DateTime OrderDate, string ShippingCity);
}
