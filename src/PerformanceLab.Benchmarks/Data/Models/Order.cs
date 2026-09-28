namespace PerformanceLab.Benchmarks.Data.Models;

public class Order
{
    public long Id { get; set; }
    public int CustomerId { get; set; }
    public int Status { get; set; }
    public decimal TotalAmount { get; set; }
    public DateTime OrderDate { get; set; }
    public string ShippingCity { get; set; } = string.Empty;

    public Customer Customer { get; set; } = null!;
    public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
}
