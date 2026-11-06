import Foundation
import CoreFoundation
import SQLite3

struct LegacyReadFailure: Error { let code: Int32 }
enum LegacyReader {
    private static let keys: Set<String> = ["music", "sound", "haptics", "reduced_motion", "color_symbols", "strong_contrast"]
    private static func exists(_ url: URL) throws -> Bool {
        do {
            let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
            guard values.isRegularFile == true, values.isSymbolicLink != true else { throw LegacyReadFailure(code: SQLITE_CANTOPEN) }
            return true
        } catch let error as NSError where error.domain == NSCocoaErrorDomain && [NSFileNoSuchFileError, NSFileReadNoSuchFileError].contains(error.code) { return false }
    }
    static func read(from source: URL) throws -> [String: Any] {
        let base: [String: Any] = ["protocolVersion": 1, "sourceFile": "pourlune_dev.sqlite", "originalRetained": true]
        if try !exists(source) {
            if try exists(URL(fileURLWithPath: source.path + "-wal")) || exists(URL(fileURLWithPath: source.path + "-shm")) { throw LegacyReadFailure(code: SQLITE_CANTOPEN) }
            return base.merging(["status": "missing"]) { _, next in next }
        }
        let fm = FileManager.default, scratch = fm.temporaryDirectory.appendingPathComponent("glass-garden-legacy-" + UUID().uuidString, isDirectory: true)
        try fm.createDirectory(at: scratch, withIntermediateDirectories: false)
        defer { try? fm.removeItem(at: scratch) }
        let copy = scratch.appendingPathComponent("pourlune_dev.sqlite")
        // Copy the complete SQLite family before opening anything. SQLite may
        // update its copied WAL index; the original main/WAL/SHM are never opened.
        for suffix in ["", "-wal", "-shm"] {
            let original = URL(fileURLWithPath: source.path + suffix)
            if try exists(original) { try fm.copyItem(at: original, to: URL(fileURLWithPath: copy.path + suffix)) }
        }
        var db: OpaquePointer?
        let opened = sqlite3_open_v2(copy.path, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX, nil)
        defer { if let db { sqlite3_close(db) } }
        guard opened == SQLITE_OK, let db else { throw LegacyReadFailure(code: opened) }
        func rows(_ sql: String, _ consume: (OpaquePointer) throws -> Void) throws {
            var statement: OpaquePointer?; let result = sqlite3_prepare_v2(db, sql, -1, &statement, nil)
            guard result == SQLITE_OK, let statement else { throw LegacyReadFailure(code: result) }
            defer { sqlite3_finalize(statement) }
            while true { let step = sqlite3_step(statement); if step == SQLITE_DONE { break }; guard step == SQLITE_ROW else { throw LegacyReadFailure(code: step) }; try consume(statement) }
        }
        var checked = 0
        try rows("PRAGMA quick_check(1)") { row in guard let text = sqlite3_column_text(row, 0), String(cString: text) == "ok" else { throw LegacyReadFailure(code: SQLITE_CORRUPT) }; checked += 1 }
        guard checked == 1 else { throw LegacyReadFailure(code: SQLITE_CORRUPT) }
        var version = 0
        try rows("PRAGMA user_version") { row in version = Int(sqlite3_column_int(row, 0)) }
        guard (1...5).contains(version) else { throw LegacyReadFailure(code: SQLITE_SCHEMA) }
        var preferences: [String: Bool] = [:]
        if version >= 3 {
            try rows("SELECT key,value FROM settings") { row in
                guard sqlite3_column_type(row, 0) == SQLITE_TEXT, let text = sqlite3_column_text(row, 0) else { throw LegacyReadFailure(code: SQLITE_CORRUPT) }
                let key = String(cString: text); guard keys.contains(key) else { return }
                let value = sqlite3_column_int(row, 1)
                guard sqlite3_column_type(row, 1) == SQLITE_INTEGER, value == 0 || value == 1 else { throw LegacyReadFailure(code: SQLITE_MISMATCH) }
                preferences[key] = value == 1
            }
        }
        var privacy: [String: Bool]?
        var lastFullscreen: Any = NSNull(), uncertain = false
        if version >= 4 {
            try rows("SELECT value FROM service_values WHERE key='privacy_choices'") { row in
                guard let text = sqlite3_column_text(row, 0), let data = String(cString: text).data(using: .utf8), let raw = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw LegacyReadFailure(code: SQLITE_MISMATCH) }
                var choice: [String: Bool] = [:]
                for key in ["analytics", "crash"] { guard let value = raw[key] as? NSNumber, CFGetTypeID(value) == CFBooleanGetTypeID() else { throw LegacyReadFailure(code: SQLITE_MISMATCH) }; choice[key] = value.boolValue }
                privacy = choice
            }
        }
        if version >= 4 {
            try rows("SELECT key,value FROM service_values WHERE key IN ('last_fullscreen_ms','fullscreen_intent')") { row in
                guard let keyText = sqlite3_column_text(row, 0), let valueText = sqlite3_column_text(row, 1), let data = String(cString: valueText).data(using: .utf8) else { throw LegacyReadFailure(code: SQLITE_MISMATCH) }
                let key = String(cString: keyText), raw = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
                if key == "last_fullscreen_ms" {
                    guard let value = raw as? NSNumber, CFGetTypeID(value) != CFBooleanGetTypeID(), value.doubleValue >= 0, value.doubleValue <= 9007199254740991, value.doubleValue.rounded() == value.doubleValue else { throw LegacyReadFailure(code: SQLITE_MISMATCH) }
                    lastFullscreen = value
                } else {
                    guard let intent = raw as? [String: Any], let id = intent["id"] as? String, !id.isEmpty, let kind = intent["kind"] as? String, ["rewarded", "interstitial"].contains(kind) else { throw LegacyReadFailure(code: SQLITE_MISMATCH) }
                    uncertain = true
                }
            }
        }
        return base.merging(["status": "present", "databaseVersion": version, "preferences": preferences, "privacy": privacy as Any? ?? NSNull(), "fullscreen": ["lastShownAt": lastFullscreen, "uncertain": uncertain]]) { _, next in next }
    }
}
