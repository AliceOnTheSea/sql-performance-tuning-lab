using BenchmarkDotNet.Columns;
using BenchmarkDotNet.Configs;
using BenchmarkDotNet.Diagnosers;
using BenchmarkDotNet.Exporters;
using BenchmarkDotNet.Exporters.Csv;
using BenchmarkDotNet.Loggers;
using BenchmarkDotNet.Order;

namespace PerformanceLab.Benchmarks.Config;

public class BenchmarkConfig : ManualConfig
{
    public BenchmarkConfig()
    {
        // Add Memory Diagnoser for GC allocation tracking
        AddDiagnoser(MemoryDiagnoser.Default);

        // Exporters for Github Markdown, CSV, and HTML
        AddExporter(MarkdownExporter.GitHub);
        AddExporter(HtmlExporter.Default);
        AddExporter(CsvExporter.Default);

        // Standard Loggers
        AddLogger(ConsoleLogger.Default);

        // Custom Orderer
        Orderer = new DefaultOrderer(SummaryOrderPolicy.FastestToSlowest);

        // Custom Columns
        AddColumn(TargetMethodColumn.Method);
        AddColumn(StatisticColumn.Mean);
        AddColumn(StatisticColumn.Error);
        AddColumn(StatisticColumn.StdDev);
        AddColumn(StatisticColumn.Median);
        AddColumn(BaselineRatioColumn.RatioMean);
        AddColumn(AllocationColumn.Default);
    }
}
