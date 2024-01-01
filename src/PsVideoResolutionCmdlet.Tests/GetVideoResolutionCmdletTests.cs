using System.Collections.Generic;
using System.IO;
using System.Linq;
using Newtonsoft.Json;
using VideoResolution;
using NUnit.Framework;
using PsVideoResolution.Core.Models;
using PsVideoResolutionCmdlet.Tests.Helpers;

namespace PsVideoResolutionCmdlet.Tests;

[TestFixture]
public partial class Tests
{
    private const string Assets = nameof(Assets);
    private static readonly string Nested = Path.Combine("Assets", "Nested");
    private const string File = "sample.mp4";
    private const string OutputDirectory = "VideoResolutionCmdletTests_Output";

    private const string Resolution = "320x240";
    private const double Size = 0.543879d;
    private static readonly string SizeAsMb = $"{Size}Mb";

    [SetUp] public void Setup() => DeleteOutputDirectory();
    [TearDown] public void TearDown() => DeleteOutputDirectory();

    [TestCase(false, false)]
    [TestCase(true, false)]
    [TestCase(false, true)]
    [TestCase(true, true)]
    public void FileReturnsInfo_Test(bool withInputDirectory, bool withOutputDirectory)
    {
        var outputDirectory = withOutputDirectory ? OutputDirectory : null;
        var expected = Path.Combine(Assets, File);

        // withInputDirectory determines if we call the cmdlet with -File or -File and -InputDirectory
        var results = (withInputDirectory
                ? ExecuteCmdlet(File, Assets, outputDirectory)
                : ExecuteCmdlet(expected, null, outputDirectory))
            .Select(r => r as List<string>)
            .ToList();

        Assert.That(results, Is.Not.Null);
        Assert.That(results, Has.Count.GreaterThanOrEqualTo(1));

        var response = results.FirstOrDefault(r => r.Count > 0);

        Assert.That(response, Is.Not.Null);

        Assert.That(response[5], Contains.Substring(Resolution));
        Assert.That(response[5], Contains.Substring(SizeAsMb));
        Assert.That(response[5], Contains.Substring(expected));

        if (!withOutputDirectory) 
            return;

        Assert.That(Directory.Exists(OutputDirectory), Is.True);

        var outputFiles = Directory.GetFiles(OutputDirectory);

        Assert.That(outputFiles, Has.Length.EqualTo(2));
        Assert.That(outputFiles, Has.Some.Contains("VideoResolution_"));
        Assert.That(outputFiles, Has.Some.Contains(".log"));
        Assert.That(outputFiles, Has.Some.Contains(".json"));
    }

    [TestCase(false, false)]
    [TestCase(true, false)]
    [TestCase(false, true)]
    [TestCase(true, true)]
    public void FileReturnsInfo_WithInputDirectory_Recursive_Test(bool withInputDirectoryRecursive, bool withOutputDirectory)
    {
        var outputDirectory = withOutputDirectory ? OutputDirectory : null;
        var file1 = Path.Combine(Assets, File);
        var file2 = Path.Combine(Nested, File);

        // withInputDirectoryRecursive determines if we call the cmdlet with -InputDirectory -Recursive or -Files
        var results = (withInputDirectoryRecursive
                ? ExecuteCmdlet(null, Assets, outputDirectory, true)
                : ExecuteCmdlet([file1, file2], outputDirectory))
            .Select(r => r as List<string>)
            .ToList();

        Assert.That(results, Is.Not.Null);
        Assert.That(results, Has.Count.GreaterThanOrEqualTo(1));

        var response = results.FirstOrDefault(r => r is not null && r.Count > 0);

        Assert.That(response, Is.Not.Null);

        // sorted by size
        Assert.That(response[8], Contains.Substring(Resolution));
        Assert.That(response[8], Contains.Substring(SizeAsMb));
        Assert.That(response[8], Contains.Substring(file1));

        Assert.That(response[9], Contains.Substring(Resolution));
        Assert.That(response[9], Contains.Substring(SizeAsMb));
        Assert.That(response[9], Contains.Substring(file2)); 
        
        // sorted by name
        Assert.That(response[16], Contains.Substring(Resolution));
        Assert.That(response[16], Contains.Substring(SizeAsMb));
        Assert.That(response[16], Contains.Substring(file2));

        Assert.That(response[17], Contains.Substring(Resolution));
        Assert.That(response[17], Contains.Substring(SizeAsMb));
        Assert.That(response[17], Contains.Substring(file1));

        if (!withOutputDirectory)
            return;

        Assert.That(Directory.Exists(OutputDirectory), Is.True);

        var outputFiles = Directory.GetFiles(OutputDirectory);

        Assert.That(outputFiles, Has.Length.EqualTo(2));
        Assert.That(outputFiles, Has.Some.Contains("VideoResolution_"));
        Assert.That(outputFiles, Has.Some.Contains(".log"));
        Assert.That(outputFiles, Has.Some.Contains(".json"));
    }

    [Test]
    public void FileReturnsJson_Test()
    {
        var expected = Path.Combine(Assets, File);

        var results = ExecuteCmdlet(new GetVideoResolutionCmdlet
            {
                File = expected,
                Json = true
            })
            .Select(r => r as string)
            .ToList();

        Assert.That(results, Is.Not.Null);
        Assert.That(results, Has.Count.EqualTo(1));

        var actual = JsonConvert.DeserializeObject<JsonOutput>(results.First());

        Assert.That(actual, Is.Not.Null);
        Assert.That(actual.Files, Is.Not.Null);
        Assert.That(actual.Files, Has.Count.EqualTo(1));

        var file = actual.Files.First();

        Assert.That(file, Is.Not.Null);
        Assert.That(file.File, Is.EqualTo(expected));
        Assert.That(file.Resolution, Is.EqualTo(Resolution));
        Assert.That(file.SizeInMb, Is.EqualTo(Size));
    }

    [Test]
    public void FileReturnsObject_Test()
    {
        var expected = Path.Combine(Assets, File);

        var results = ExecuteCmdlet(new GetVideoResolutionCmdlet
            {
                File = expected,
                PSObject = true
            })
            .Select(r => r as List<VideoInfo>)
            .ToList();

        Assert.That(results, Is.Not.Null);
        Assert.That(results, Has.Count.EqualTo(1));

        var infos = results[0];

        Assert.That(infos, Is.Not.Null);
        Assert.That(infos, Has.Count.EqualTo(1));

        var actual = infos[0];

        Assert.That(actual, Is.Not.Null);
        Assert.That(actual.File, Is.EqualTo(expected));
        Assert.That(actual.Resolution, Is.EqualTo(Resolution));
        Assert.That(actual.SizeInMb, Is.EqualTo(Size));
    }

    /// <summary>
    /// Executes InvokeVideoResolutionCmdlet.
    /// </summary>
    /// <param name="file"></param>
    /// <param name="inputDirectory"></param>
    /// <param name="outputDirectory"></param>
    /// <param name="recursive"></param>
    /// <returns></returns>
    private static List<object> ExecuteCmdlet(string file, string inputDirectory = null, string outputDirectory = null, bool recursive = false) =>
        ExecuteCmdlet(new GetVideoResolutionCmdlet
        {
            InputDirectory = inputDirectory,
            OutputDirectory = outputDirectory,
            File = file,
            Files = null,
            Recursive = recursive
        });

    /// <summary>
    /// Executes InvokeVideoResolutionCmdlet.
    /// </summary>
    /// <param name="files"></param>
    /// <param name="outputDirectory"></param>
    /// <returns></returns>
    private static List<object> ExecuteCmdlet(List<string> files, string outputDirectory = null) =>
        ExecuteCmdlet(new GetVideoResolutionCmdlet
        {
            InputDirectory = null,
            OutputDirectory = outputDirectory,
            File = null,
            Files = files,
            Recursive = default
        });

    /// <summary>
    /// Executes InvokeVideoResolutionCmdlet.
    /// </summary>
    /// <param name="cmdlet"></param>
    /// <returns></returns>
    private static List<object> ExecuteCmdlet(GetVideoResolutionCmdlet cmdlet)
    {
        var psEmulator = new PowershellEmulator();

        cmdlet.CommandRuntime = psEmulator;
        cmdlet.ProcessInternal();

        return psEmulator.OutputObjects;
    }

    /// <summary>
    /// Deletes test directories.
    /// </summary>
    private static void DeleteOutputDirectory()
    {
        if (Directory.Exists(OutputDirectory))
            Directory.Delete(OutputDirectory, true);
    }
}