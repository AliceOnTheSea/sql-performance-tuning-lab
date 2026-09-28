namespace PerformanceLab.Benchmarks.Data.Models;

public class OrderItem
{
    public long Id { get; set; }
    public long OrderId { get; set; }
    public string Sku { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }

    public Order Order { get; set; } = null!;
}
