using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Runtime.CompilerServices;
using Newtonsoft.Json;
using PsVideoResolution.Core.Formatters;
using PsVideoResolution.Core.Models;
using Xabe.FFmpeg;
using Xabe.FFmpeg.Exceptions;

[assembly: InternalsVisibleTo("PsVideoResolutionCmdlet.Tests")]
namespace VideoResolution;

/// <summary>
/// <para type="synopsis">Probe video files for their resolution and output results to host and optionally to log files</para>
/// </summary>
/// <para type="description">
/// Uses ffmpeg (ffprobe) to interrogate video files and retrieve the resolution and file size. ffmpeg must be installed.
/// </para>
/// <para type="description">
/// Can be run against:
/// </para>
/// <para type="description">
/// > all files in an input directory supplied as an InputDirectory parameter.
/// > a file using the File parameter. This can be a file name in the current directory, a relative path,
///   a full path, or a file name used in conjunction with the InputDirectory parameter.
/// > a collection of files piped into the module (note: this expects correct paths and won't use the InputDirectory
///   parameter).
/// </para>
/// <para type="description">
/// Outputs the results to the host in 2 ordered lists, firstly by resolution and secondly by file name.
/// </para>
/// <para type="description">
/// Results can also be output to log and json files if an OutputDirectory is supplied as a parameter.
/// A text log file is created that is a duplicate of the standard results written to the host.
/// A json file is created with an array representation of the VideoInfo class.
/// </para>
/// <example>
///     <para type="example">Process the supplied file using the current directory</para>
///     <code>PS C:\Videos\> Get-VideoResolution -File "ExampleFile.mkv"</code>
/// </example>
/// <example>
///     <para type="example">All files in the supplied input directory, writing json and log files to the supplied output directory.</para>
///     <code>PS C:\> Get-VideoResolution -InputDirectory "C:\Videos" -OutputDirectory "C:\Videos\Logs"</code>
/// </example>
/// <example>
///     <para type="example">Process the supplied file using the supplied input directory</para>
///     <code>PS C:\Videos\> Get-VideoResolution -File "ExampleFile.mkv" -InputDirectory "C:\Videos"</code>
/// </example>
/// <example>
///     <para type="example">Process the supplied file with path</para>
///     <code>PS C:\Videos\> Get-VideoResolution -File "C:\Videos\ExampleFile.mkv"</code>
/// </example>
/// <example>
///     <para type="example">Process the supplied file and return json</para>
///     <code>PS C:\Videos\> Get-VideoResolution -File "C:\Videos\ExampleFile.mkv" -Json</code>
/// </example>
/// <example>
///     <para type="example">Process the supplied file and return a PSObject</para>
///     <code>PS C:\Videos\> Get-VideoResolution -File "C:\Videos\ExampleFile.mkv" -PSObject</code>
/// </example>
/// <example>
///     <para type="example">Process the piped files array, writing json and log files to the supplied output directory.</para>
///     <code>PS C:\> "C:\Videos\ExampleFile1.mkv","C:\Videos\ExampleFile2.mkv" | Get-VideoResolution -OutputDirectory "C:\Videos\Logs"</code>
/// </example>
/// <para type="link" uri="(https://github.com/trossr32/ps-video-resolution)">[Github]</para>
[Cmdlet(VerbsCommon.Get, "VideoResolution", HelpUri = "https://github.com/trossr32/ps-video-resolution")]
public class GetVideoResolutionCmdlet : PSCmdlet
{
    #region Parameters

    /// <summary>
    /// <para type="description">
    /// Optional. If supplied this is the path used to find video files to process. If used in conjunction with the File
    /// parameter then this path will be joined to the file provided.
    /// </para>
    /// </summary>
    [Parameter(Mandatory = false)]
    public string InputDirectory { get; set; }

    /// <summary>
    /// <para type="description">
    /// Optional. If supplied this is the path used to write text and json data files.
    /// </para>
    /// </summary>
    [Parameter(Mandatory = false)]
    public string OutputDirectory { get; set; }

    /// <summary>
    /// <para type="description">
    /// Optional. If supplied this file will be processed. Must be a file in the current directory, a relative path, a full
    /// path, or a filename used in conjunction with the InputDirectory parameter.
    /// </para>
    /// </summary>
    [Parameter(Mandatory = false)]
    public string File { get; set; }

    /// <summary>
    /// <para type="description">
    /// Optional. Accepted as piped input. If supplied all files in this string array will be processed. Each file must be
    /// in the current directory, a relative path or a full path. Will be ignored if used in conjunction with the
    /// InputDirectory parameter.
    /// </para>
    /// </summary>
    [Parameter(Mandatory = false, ValueFromPipeline = true)]
    public List<string> Files { get; set; }

    /// <summary>
    /// <para type="description">
    /// Optional. If supplied along with an input directory, all sub-directories will also be searched for video files.
    /// </para>
    /// </summary>
    [Parameter(Mandatory = false)]
    public SwitchParameter Recursive { get; set; }

    /// <summary>
    /// <para type="description">
    /// Optional. If supplied json will be returned instead of the standard output.
    /// </para>
    /// </summary>
    [Parameter(Mandatory = false)]
    public SwitchParameter Json { get; set; }

    /// <summary>
    /// <para type="description">
    /// Optional. If supplied a PsObject will be returned instead of the standard output.
    /// </para>
    /// </summary>
    [Parameter(Mandatory = false)]
    public SwitchParameter PSObject { get; set; }

    #endregion

    private bool _isValid;
    private List<string> _filesToProcess;

    internal void ProcessInternal()
    {
        BeginProcessing();
        ProcessRecord();
        EndProcessing();
    }

    /// <summary>
    /// Implements the <see cref="BeginProcessing"/> method for <see cref="GetVideoResolutionCmdlet"/>.
    /// Initialise temporary containers
    /// </summary>
    protected override void BeginProcessing()
    {
        _filesToProcess = [];
        _isValid = true;
    }

    /// <summary>
    /// Implements the <see cref="ProcessRecord"/> method for <see cref="GetVideoResolutionCmdlet"/>.
    /// Validates input directory/directories exist and builds a list of directories to process in the EndProcessing method.
    /// </summary>
    protected override void ProcessRecord()
    {
        // First check if a file list was supplied
        if (Files is not null && Files.Count > 0)
        {
            // Check if all files exist
            if (!Files.All(System.IO.File.Exists))
            {
                _isValid = false;

                ThrowTerminatingError(new ErrorRecord(new Exception("One or more files not found, terminating."), null, ErrorCategory.InvalidArgument, null));
            }

            // Add all files to the list of files to process and return
            _filesToProcess.AddRange(Files);

            return;
        }

        // Check if a file was supplied
        if (!string.IsNullOrWhiteSpace(File))
        {
            // Check if the file exists
            if (System.IO.File.Exists(File))
            {
                _filesToProcess.Add(File);

                return;
            }

            if (string.IsNullOrWhiteSpace(InputDirectory))
            {
                _isValid = false;

                ThrowTerminatingError(new ErrorRecord(new Exception($"File not found: {File}, terminating."), null, ErrorCategory.InvalidArgument, null));
            }

            // Check if the file with input directory exists
            var file = Path.Combine(InputDirectory!, File);

            if (System.IO.File.Exists(file))
            {
                _filesToProcess.Add(file);

                return;
            }

            _isValid = false;

            ThrowTerminatingError(new ErrorRecord(new Exception($"File not found: {File}, terminating."), null, ErrorCategory.InvalidArgument, null));
        }

        // At this point no files or file lists were supplied so check if an input directory was supplied
        if (!string.IsNullOrWhiteSpace(InputDirectory))
        {
            // Check if the directory exists
            if (Directory.Exists(InputDirectory))
            {
                var searchOption = Recursive.IsPresent ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly;

                string[] extensions = [".avi", ".divx", ".iso", ".m2ts", ".m4v", ".mkv", ".mp4", ".mpg", ".x265", ".wmv"];
                
                _filesToProcess
                    .AddRange(Directory.GetFiles(InputDirectory, "*.*", searchOption)
                        .Where(f => extensions.Any(e => e.Equals(Path.GetExtension(f), StringComparison.OrdinalIgnoreCase)))
                        .ToArray());

                return;
            }

            _isValid = false;

            ThrowTerminatingError(new ErrorRecord(new Exception($"Directory not found: {InputDirectory}, terminating."), null, ErrorCategory.InvalidArgument, null));
        }

        _isValid = false;

        ThrowTerminatingError(new ErrorRecord(new Exception("No valid input parameters found. You must supply either Files, File, Input Directory, or File and InputDirectory. Terminating."), null, ErrorCategory.InvalidArgument, null));
    }

    /// <summary>
    /// Implements the <see cref="EndProcessing"/> method for <see cref="GetVideoResolutionCmdlet"/>.
    /// Perform the folder flattening on the configured directories.
    /// </summary>
    protected override void EndProcessing()
    {
        if (!_isValid)
            return;

        List<VideoInfo> results = [];

        var writeProgress = _filesToProcess.Count > 1;

        try
        {
            for (var i = 0; i < _filesToProcess.Count; i++)
            {
                // Show video processing progress
                if (writeProgress)
                    WriteProgress(new ProgressRecord(1, "Processing video files...", $"Processing file {i + 1} of {_filesToProcess.Count}")
                    {
                        PercentComplete = (int)(((i + 1) / (double)_filesToProcess.Count) * 100)
                    });

                // Get video info
                var info = FFmpeg.GetMediaInfo(_filesToProcess[i]).Result;
                    
                results.Add(new VideoInfo(info, _filesToProcess[i]));
            }

            WriteOutput(results);
        }
        catch (FFmpegNotFoundException ffe)
        {
            ThrowTerminatingError(new ErrorRecord(ffe, null, ErrorCategory.ResourceUnavailable, null));
        }
        catch (Exception e)
        {
            WriteError(new ErrorRecord(e, null, ErrorCategory.InvalidOperation, null));
        }
    }

    private void WriteOutput(List<VideoInfo> results)
    {
        if (!string.IsNullOrWhiteSpace(OutputDirectory))
        {
            if (!Directory.Exists(OutputDirectory))
            {
                try
                {
                    Directory.CreateDirectory(OutputDirectory);
                }
                catch (Exception e)
                {
                    WriteWarning($"Output directory: {OutputDirectory} does not exist and unable to create. Exception: {e.Message}");

                    return;
                }
            }

            results.WriteOutputFiles(OutputDirectory);
        }

        if (PSObject.IsPresent)
        {
            WriteObject(results);

            return;
        }

        if (Json.IsPresent)
        {
            WriteObject(JsonConvert.SerializeObject(new JsonOutput { Files = results }, Formatting.Indented));

            return;
        }

        var lines = results.GetHostOutput();

        WriteObject(lines);
    }
}