using BenchmarkDotNet.Attributes;
using Dapper;
using Microsoft.Data.SqlClient;

namespace PerformanceLab.Benchmarks.Benchmarks;

[MemoryDiagnoser]
public class KeysetPaginationBenchmark
{
    private const string ConnectionString = "Server=localhost,1433;Database=PerformanceLabDb;User Id=sa;Password=YourStrong@Passw0rd!;TrustServerCertificate=True;";
    private SqlConnection _connection = null!;

    private DateTime _lastOrderDate;
    private long _lastId;
    private const int TargetOffset = 100000;
    private const int PageSize = 50;

    [GlobalSetup]
    public async Task Setup()
    {
        _connection = new SqlConnection(ConnectionString);
        await _connection.OpenAsync();

        // Obtain reference benchmark anchor row at 100,000 offset
        const string referenceSql = @"
            SELECT OrderDate, Id 
            FROM dbo.Orders WITH (NOLOCK)
            ORDER BY OrderDate DESC, Id DESC 
            OFFSET @Offset ROWS FETCH NEXT 1 ROWS ONLY;";

        var reference = await _connection.QueryFirstOrDefaultAsync<ReferenceRow>(referenceSql, new { Offset = TargetOffset });
        if (reference != null)
        {
            _lastOrderDate = reference.OrderDate;
            _lastId = reference.Id;
        }
        else
        {
            _lastOrderDate = DateTime.UtcNow;
            _lastId = 100000;
        }
    }

    [GlobalCleanup]
    public void Cleanup()
    {
        _connection?.Dispose();
    }

    /// <summary>
    /// Baseline: Standard OFFSET...FETCH NEXT deep pagination (Page 2000, 100k rows deep).
    /// Incurs O(N) performance penalty as SQL Server scans and discards 100,000 records.
    /// </summary>
    [Benchmark(Baseline = true)]
    public async Task<List<PagedOrderDto>> Baseline_OffsetFetch()
    {
        const string sql = @"
            SELECT Id, CustomerId, Status, TotalAmount, OrderDate, ShippingCity
            FROM dbo.Orders WITH (INDEX(IX_Orders_Pagination))
            ORDER BY OrderDate DESC, Id DESC
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;";

        var results = await _connection.QueryAsync<PagedOrderDto>(sql, new { Offset = TargetOffset, PageSize = PageSize });
        return results.ToList();
    }

    /// <summary>
    /// Optimized: Keyset Pagination using B-Tree index seek predicate.
    /// Achieves O(1) constant-time seek performance directly to key page without reading discarded records.
    /// </summary>
    [Benchmark]
    public async Task<List<PagedOrderDto>> Optimized_KeysetSeek()
    {
        const string sql = @"
            SELECT TOP (@PageSize) Id, CustomerId, Status, TotalAmount, OrderDate, ShippingCity
            FROM dbo.Orders WITH (INDEX(IX_Orders_Pagination))
            WHERE (OrderDate < @LastDate) OR (OrderDate = @LastDate AND Id < @LastId)
            ORDER BY OrderDate DESC, Id DESC;";

        var results = await _connection.QueryAsync<PagedOrderDto>(sql, new { LastDate = _lastOrderDate, LastId = _lastId, PageSize = PageSize });
        return results.ToList();
    }

    public record ReferenceRow(DateTime OrderDate, long Id);
    public record PagedOrderDto(long Id, int CustomerId, int Status, decimal TotalAmount, DateTime OrderDate, string ShippingCity);
}
