import Foundation
import Network

// Bundled assets only. Product always uses one fixed loopback origin; no port fallback.
final class AssetServer {
    private let root: URL
    private let port: NWEndpoint.Port
    private let queue = DispatchQueue(label: "pourlune.assets")
    private var listener: NWListener?

    init(root: URL, port: NWEndpoint.Port = 43177) {
        self.root = root.resolvingSymlinksInPath().standardizedFileURL
        self.port = port
    }

    func start(completion: @escaping (Result<URL, Error>) -> Void) {
        // Page/renderer Retry reuses its healthy listener and exact origin.
        // Closing TCP flows can keep a just-stopped port occupied even after
        // the listener's cancellation callback, so do not rebind it needlessly.
        if let previous = listener {
            if case .ready = previous.state, let bound = previous.port,
               let url = URL(string: "http://127.0.0.1:\(bound.rawValue)/index.html") {
                completion(.success(url)); return
            }
            stop { [weak self] in self?.start(completion: completion) }
            return
        }
        do {
            let parameters = NWParameters.tcp
            parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: port)
            let next = try NWListener(using: parameters)
            listener = next
            var reported = false
            next.stateUpdateHandler = { [weak next] state in
                guard let next, !reported else { return }
                switch state {
                case .ready:
                    reported = true
                    guard let bound = next.port, let url = URL(string: "http://127.0.0.1:\(bound.rawValue)/index.html") else { return }
                    completion(.success(url))
                case .failed(let error): reported = true; completion(.failure(error))
                default: break
                }
            }
            next.newConnectionHandler = { [weak self] connection in self?.accept(connection) }
            next.start(queue: queue)
        } catch { completion(.failure(error)) }
    }

    func stop(completion: (() -> Void)? = nil) {
        guard let previous = listener else { completion?(); return }
        listener = nil
        if let completion {
            if case .cancelled = previous.state { completion(); return }
            previous.stateUpdateHandler = { state in
                if case .cancelled = state { completion() }
            }
        }
        previous.cancel()
    }
    deinit { stop() }

    private func accept(_ connection: NWConnection) {
        connection.start(queue: queue)
        queue.asyncAfter(deadline: .now() + 5) { connection.cancel() }
        receive(connection, bytes: Data())
    }

    private func receive(_ connection: NWConnection, bytes: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16384) { [weak self] data, _, complete, error in
            guard let self else { connection.cancel(); return }
            var collected = bytes
            if let data { collected.append(data) }
            if collected.count > 16384 { self.send(connection, status: 431); return }
            if collected.range(of: Data("\r\n\r\n".utf8)) != nil {
                self.respond(connection, request: collected)
            } else if complete || error != nil { connection.cancel() }
            else { self.receive(connection, bytes: collected) }
        }
    }

    private func respond(_ connection: NWConnection, request: Data) {
        guard let text = String(data: request, encoding: .utf8), let line = text.components(separatedBy: "\r\n").first else { send(connection, status: 400); return }
        let fields = line.split(separator: " ")
        guard fields.count == 3 else { send(connection, status: 400); return }
        let method = String(fields[0])
        guard method == "GET" || method == "HEAD" else { send(connection, status: 405); return }
        let rawPath = fields[1].split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)[0]
        guard rawPath.hasPrefix("/"), let decoded = String(rawPath).removingPercentEncoding, !decoded.contains("\0"), !decoded.contains("\\") else { send(connection, status: 400); return }
        let components = decoded.split(separator: "/")
        guard !components.contains("..") else { send(connection, status: 403); return }
        let relative = components.isEmpty ? "index.html" : components.joined(separator: "/")
        let file = root.appendingPathComponent(relative).resolvingSymlinksInPath().standardizedFileURL
        guard file.path.hasPrefix(root.path + "/") else { send(connection, status: 403); return }
        guard (try? file.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true, let body = try? Data(contentsOf: file) else { send(connection, status: 404); return }
        let types = ["html":"text/html; charset=utf-8", "mjs":"text/javascript; charset=utf-8", "js":"text/javascript; charset=utf-8", "css":"text/css; charset=utf-8", "json":"application/json", "png":"image/png", "jpg":"image/jpeg", "jpeg":"image/jpeg", "webp":"image/webp", "svg":"image/svg+xml", "ttf":"font/ttf", "woff2":"font/woff2", "wav":"audio/wav", "mp3":"audio/mpeg", "txt":"text/plain; charset=utf-8", "md":"text/plain; charset=utf-8"]
        send(connection, status: 200, contentType: types[file.pathExtension.lowercased()] ?? "application/octet-stream", body: body, head: method == "HEAD")
    }

    private func send(_ connection: NWConnection, status: Int, contentType: String = "text/plain", body: Data = Data(), head: Bool = false) {
        let reason = [200:"OK",400:"Bad Request",403:"Forbidden",404:"Not Found",405:"Method Not Allowed",431:"Request Header Fields Too Large"][status] ?? "Error"
        var response = Data("HTTP/1.1 \(status) \(reason)\r\nContent-Type: \(contentType)\r\nContent-Length: \(body.count)\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n".utf8)
        if !head { response.append(body) }
        connection.send(content: response, completion: .contentProcessed { _ in connection.cancel() })
    }
}
