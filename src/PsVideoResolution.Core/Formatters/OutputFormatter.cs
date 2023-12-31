using Newtonsoft.Json;
using PsVideoResolution.Core.Models;

namespace PsVideoResolution.Core.Formatters;

public static class OutputFormatter
{
    private static readonly string[] ResolutionHeader = ["", "Ordered by resolution:", "----------------------"];
    private static readonly string[] NameHeader = ["", "Ordered by name:", "----------------"];
    private static readonly string[] ResultsHeader = ["", "Resolution  Size (Mb)   File", "----------  ---------   ----"];
    
    /// <summary>
    /// Writes output files to the output directory
    /// </summary>
    /// <param name="results"></param>
    /// <param name="outputDirectory"></param>
    public static void WriteOutputFiles(this List<VideoInfo> results, string outputDirectory)
    {
        // build base file name
        var now = DateTime.Now;

        var baseFileName = $"VideoResolution_{now:yyyyMMdd_HHmmss}";

        // write output log file
        using var sw = new StreamWriter(Path.Combine(outputDirectory, $"{baseFileName}.log"));

        foreach (var header in ResolutionHeader)
        {
            sw.WriteLine(header);
        }

        foreach (var result in results.OrderBy(r => r.Width))
        {
            sw.Write(result.ResultLine());
        }

        foreach (var header in NameHeader)
        {
            sw.WriteLine(header);
        }

        foreach (var result in results.OrderBy(r => r.File))
        {
            sw.WriteLine(result.ResultLine());
        }

        // write output json file
        using var jsw = new StreamWriter(Path.Combine(outputDirectory, $"{baseFileName}.json"));
        using var jw = new JsonTextWriter(jsw);

        var serializer = new JsonSerializer
        {
            Formatting = Formatting.Indented
        };

        serializer.Serialize(jw, results);
    }

    /// <summary>
    /// Gets the output for the host
    /// </summary>
    /// <param name="results"></param>
    /// <returns></returns>
    public static List<string> GetHostOutput(this List<VideoInfo> results)
    {
        List<string> output = ["", "Finished! Here are the results:"];

        if (results.Count == 1)
        {
            output.AddRange(ResultsHeader);

            output.AddRange(results.Select(r => r.ResultLine()));

            output.Add("");

            return output;
        }

        output.AddRange(ResolutionHeader);

        output.AddRange(ResultsHeader);

        output.AddRange(results.OrderBy(r => r.Width).Select(r => r.ResultLine()));

        output.AddRange(NameHeader);

        output.AddRange(ResultsHeader);

        output.AddRange(results.OrderBy(r => r.File).Select(r => r.ResultLine()));

        output.Add("");

        return output;
    }
}