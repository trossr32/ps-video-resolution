using ByteSizeLib;
using Newtonsoft.Json;
using Xabe.FFmpeg;

namespace PsVideoResolution.Core.Models;

public class VideoInfo
{
    public string File { get; set; }
    public int? Width { get; set; }
    public int? Height { get; set; }
    public long SizeInBytes { get; set; }

    public double SizeInMb => ByteSize.FromBytes(SizeInBytes).MegaBytes;
    public double SizeInGb => ByteSize.FromBytes(SizeInBytes).GigaBytes;

    public string Resolution() => $"{Width}x{Height}";

    public string ResultLine()
    {
        var res = Resolution().PadRight(10);
        var mb = $"{SizeInMb}Mb".PadRight(10);

        return $"{res}  {mb}  {File}";
    }

    public VideoInfo() { }

    public VideoInfo(string json, string file)
    {
        var info = JsonConvert.DeserializeObject<VideoInfoJson>(json);

        File = file;
        Width = info.Streams[0].Width;
        Height = info.Streams[0].Height;
        SizeInBytes = info.Format.Size;
    }

    public VideoInfo(IMediaInfo info, string file)
    {
        File = file;
        Width = info.VideoStreams.FirstOrDefault()?.Width;
        Height = info.VideoStreams.FirstOrDefault()?.Height;
        SizeInBytes = info.Size;
    }

    private class VideoInfoJson
    {
        [JsonProperty("format")]
        public Format Format { get; set; }

        [JsonProperty("streams")]
        public Stream[] Streams { get; set; }
    }

    private class Format
    {
        [JsonProperty("size")]
        public int Size { get; set; }
    }

    private class Stream
    {
        [JsonProperty("width")]
        public int Width { get; set; }

        [JsonProperty("height")]
        public int Height { get; set; }
    }
}
