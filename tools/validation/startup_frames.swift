import Foundation
import AVFoundation
import AppKit

// Sample actual recorded launch frames. No app hooks, interpolation or timing claims.
let input = URL(fileURLWithPath: CommandLine.arguments[1])
let out = URL(fileURLWithPath: CommandLine.arguments[2])
try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
let asset = AVURLAsset(url: input)
let duration = CMTimeGetSeconds(try await asset.load(.duration))
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.maximumSize = CGSize(width: 390, height: 860)
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero
var samples = [[String: Any]]()
let limit = CommandLine.arguments.count > 3 ? min(Double(CommandLine.arguments[3])!, duration) : duration
for index in 0..<Int(limit * 10) {
    let seconds = Double(index) / 10
    var actual = CMTime.zero
    let frame = try generator.copyCGImage(at: CMTime(seconds: seconds, preferredTimescale: 600), actualTime: &actual)
    let data = NSBitmapImageRep(cgImage: frame).representation(using: .png, properties: [:])!
    let filename = String(format: "%05.2f.png", seconds)
    try data.write(to: out.appendingPathComponent(filename))
    samples.append(["file": filename, "requested_seconds": seconds,
                    "actual_seconds": CMTimeGetSeconds(actual)])
}
let report: [String: Any] = ["source": input.path, "duration_seconds": duration,
                           "sample_interval_seconds": 0.1, "frames": samples]
try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
    .write(to: out.appendingPathComponent("samples.json"))
print("Sampled \(samples.count) launch frames; duration \(duration)")
