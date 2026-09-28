using BenchmarkDotNet.Running;
using PerformanceLab.Benchmarks.Config;

namespace PerformanceLab.Benchmarks;

public class Program
{
    public static void Main(string[] args)
    {
        var config = new BenchmarkConfig();

        Console.WriteLine("========================================================================");
        Console.WriteLine("     SQL Server & .NET 8 Performance Tuning Lab Benchmark Suite        ");
        Console.WriteLine("========================================================================");
        Console.WriteLine(" Executing with BenchmarkDotNet v0.13.12 (.NET 8.0 / SQL Server 2022)   ");
        Console.WriteLine("========================================================================");

        if (args.Length == 0)
        {
            Console.WriteLine();
            Console.WriteLine("No benchmark filter passed. Running interactive BenchmarkSwitcher...");
            Console.WriteLine("To run specific benchmarks via CLI:");
            Console.WriteLine("  dotnet run -c Release -- --filter *Covering*");
            Console.WriteLine("  dotnet run -c Release -- --filter *Keyset*");
            Console.WriteLine("  dotnet run -c Release -- --filter *Orm*");
            Console.WriteLine();

            BenchmarkSwitcher.FromAssembly(typeof(Program).Assembly).RunAll(config);
        }
        else
        {
            BenchmarkSwitcher.FromAssembly(typeof(Program).Assembly).Run(args, config);
        }
    }
}
