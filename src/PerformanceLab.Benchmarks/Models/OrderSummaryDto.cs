namespace PerformanceLab.Benchmarks.Models;

public record OrderSummaryDto
{
    public long Id { get; init; }
    public int CustomerId { get; init; }
    public string CustomerName { get; init; } = string.Empty;
    public int Status { get; init; }
    public decimal TotalAmount { get; init; }
    public DateTime OrderDate { get; init; }
    public string ShippingCity { get; init; } = string.Empty;
}
