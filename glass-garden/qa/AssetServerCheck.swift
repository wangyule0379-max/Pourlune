import Foundation
import Network

@main struct AssetServerCheck {
    static func main() async throws {
        let fm = FileManager.default, base = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString), root = base.appendingPathComponent("Web")
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: base) }
        try Data("garden".utf8).write(to: root.appendingPathComponent("index.html"))
        try Data("export default 1".utf8).write(to: root.appendingPathComponent("module.mjs"))
        try Data("outside".utf8).write(to: base.appendingPathComponent("outside.txt"))
        try fm.createSymbolicLink(at: root.appendingPathComponent("escape.txt"), withDestinationURL: base.appendingPathComponent("outside.txt"))
        let server = AssetServer(root: root, port: .any)
        defer { server.stop() }
        let entry: URL = try await withCheckedThrowingContinuation { continuation in server.start { continuation.resume(with: $0) } }
        func request(_ path: String, method: String = "GET") async throws -> (Data, HTTPURLResponse) {
            let origin = entry.deletingLastPathComponent().absoluteString
            var request = URLRequest(url: URL(string: origin + path)!);request.httpMethod = method
            let (data, response) = try await URLSession.shared.data(for: request)
            return (data, response as! HTTPURLResponse)
        }
        let (page, html) = try await request("index.html");precondition(html.statusCode == 200 && String(data: page, encoding: .utf8) == "garden")
        let (_, module) = try await request("module.mjs");precondition(module.mimeType == "text/javascript")
        let (empty, head) = try await request("index.html", method: "HEAD");precondition(empty.isEmpty && head.value(forHTTPHeaderField: "Content-Length") == "6")
        let (_, missing) = try await request("missing");precondition(missing.statusCode == 404)
        let (_, escape) = try await request("escape.txt");precondition(escape.statusCode == 403)
        let (_, traversal) = try await request("%2e%2e/outside.txt");precondition(traversal.statusCode != 200)
        let (_, post) = try await request("index.html", method: "POST");precondition(post.statusCode == 405)
        print("PASS: real loopback GET, JS module MIME, HEAD,404, symlink/traversal deny, POST deny; server/temp cleanup owned only")
    }
}
