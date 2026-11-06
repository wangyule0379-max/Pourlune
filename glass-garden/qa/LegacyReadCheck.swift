import Foundation
import SQLite3

@main enum LegacyReadCheck {
    static func main() throws {
        if CommandLine.arguments.count == 3 {
            let source = URL(fileURLWithPath: CommandLine.arguments[1]), output = URL(fileURLWithPath: CommandLine.arguments[2])
            var before: [String: Data] = [:]
            for suffix in ["", "-wal", "-shm"] { let file = URL(fileURLWithPath: source.path + suffix); if FileManager.default.fileExists(atPath: file.path) { before[suffix] = try Data(contentsOf: file) } }
            let record = try LegacyReader.read(from: source)
            for (suffix, data) in before { let after = try Data(contentsOf: URL(fileURLWithPath: source.path + suffix)); precondition(after == data, "Original fixture bytes changed") }
            try JSONSerialization.data(withJSONObject: record, options: [.prettyPrinted, .sortedKeys]).write(to: output, options: .atomic)
            print("PASS: unchanged native reader parsed actual old GameStore fixture; original family byte-identical")
            return
        }
        let fm = FileManager.default, root = fm.temporaryDirectory.appendingPathComponent("garden-legacy-check-" + UUID().uuidString)
        try fm.createDirectory(at: root, withIntermediateDirectories: false); defer { try? fm.removeItem(at: root) }
        let source = root.appendingPathComponent("pourlune_dev.sqlite")
        let missing = try LegacyReader.read(from: source); precondition(missing["status"] as? String == "missing")
        var db: OpaquePointer?; precondition(sqlite3_open(source.path, &db) == SQLITE_OK)
        defer { sqlite3_close(db) }
        func sql(_ text: String) { precondition(sqlite3_exec(db, text, nil, nil, nil) == SQLITE_OK, text) }
        sql("PRAGMA journal_mode=WAL"); sql("PRAGMA wal_autocheckpoint=0"); sql("PRAGMA user_version=5")
        sql("CREATE TABLE settings(key TEXT PRIMARY KEY,value INTEGER NOT NULL)")
        sql("CREATE TABLE service_values(key TEXT PRIMARY KEY,value TEXT NOT NULL)")
        sql("CREATE TABLE active_slots(slot TEXT PRIMARY KEY,payload TEXT NOT NULL)")
        sql("INSERT INTO active_slots VALUES('ordinary','nonempty old60 board and undo retained')")
        sql("INSERT INTO settings VALUES('sound',0),('music',1),('haptics',1),('reduced_motion',1),('strong_contrast',1)")
        sql("INSERT INTO service_values VALUES('privacy_choices','{\"analytics\":false,\"crash\":true}')")
        // Keep the writer open so the current settings exist in WAL, not just main.
        func originals() throws -> [String: Data] { var result: [String: Data] = [:]; for suffix in ["", "-wal", "-shm"] { let file = URL(fileURLWithPath: source.path + suffix); if fm.fileExists(atPath: file.path) { result[suffix] = try Data(contentsOf: file) } }; return result }
        sql("INSERT INTO service_values VALUES('last_fullscreen_ms','123456789'),('fullscreen_intent','{\"id\":\"old-show\",\"kind\":\"rewarded\"}')")
        let before = try originals(), record = try LegacyReader.read(from: source)
        precondition((record["preferences"] as? [String: Bool])?["sound"] == false)
        precondition((record["privacy"] as? [String: Bool])?["crash"] == true)
        precondition((record["fullscreen"] as? [String: Any])?["lastShownAt"] as? Int == 123456789)
        precondition((record["fullscreen"] as? [String: Any])?["uncertain"] as? Bool == true)
        precondition(JSONSerialization.isValidJSONObject(record))
        let after = try originals(); precondition(after == before, "Reader modified an original database family file")
        sql("UPDATE settings SET value=2 WHERE key='sound'")
        do { _ = try LegacyReader.read(from: source); preconditionFailure("Bad boolean accepted") } catch {}
        sql("UPDATE settings SET value=0 WHERE key='sound'"); sql("PRAGMA user_version=99")
        do { _ = try LegacyReader.read(from: source); preconditionFailure("Unknown schema accepted") } catch {}
        sql("PRAGMA user_version=5"); sql("UPDATE service_values SET value='{\"analytics\":1,\"crash\":false}'")
        do { _ = try LegacyReader.read(from: source); preconditionFailure("Numeric JSON consent coerced to true") } catch {}
        sql("PRAGMA user_version=1")
        let v1 = try LegacyReader.read(from: source); precondition(v1["privacy"] is NSNull); precondition(JSONSerialization.isValidJSONObject(v1))
        let corrupt = root.appendingPathComponent("corrupt.sqlite"); try Data("not a SQLite database".utf8).write(to: corrupt)
        do { _ = try LegacyReader.read(from: corrupt); preconditionFailure("Corruption treated as missing") } catch {}
        let orphan = root.appendingPathComponent("orphan.sqlite"); try Data("orphan".utf8).write(to: URL(fileURLWithPath: orphan.path + "-wal"))
        do { _ = try LegacyReader.read(from: orphan); preconditionFailure("Orphan journal treated as missing") } catch {}
        let link = root.appendingPathComponent("not-a-database.sqlite"); try fm.createSymbolicLink(at: link, withDestinationURL: source)
        do { _ = try LegacyReader.read(from: link); preconditionFailure("Symlink accepted") } catch {}
        print("PASS: missing vs corrupt, current WAL settings, nonempty old data preserved, strict privacy/schema, no original writes")
    }
}
