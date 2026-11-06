import UIKit
import GoogleMobileAds
import UserMessagingPlatform

// Official test inventory only; never grant from load/present/dismiss callbacks.
// Persist native observations until the game acknowledges its own transaction.
final class GardenAds: NSObject, FullScreenContentDelegate {
    private weak var controller: UIViewController?
    private let deliver: ([String: Any]) -> Void
    private let file: URL
    private var queue: [[String: Any]] = []
    private var unreadable = false
    private var storageFailed = false
    private var initialized = false
    private var initializing = false
    private var loadingId: String?
    private var cancelled = false
    private var loadedId: String?
    private var ad: RewardedAd?
    private var presenting = false
    private var presentationIds: [ObjectIdentifier: String] = [:]
    private var observations: [String: [String: Any]] = [:]
    private var presentingId: String?
    var active = false

    init(controller: UIViewController, deliver: @escaping ([String: Any]) -> Void) {
        self.controller = controller; self.deliver = deliver
        file = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("GlassGardenAdCallbacks-v1.json")
        super.init()
        do {
            if FileManager.default.fileExists(atPath: file.path) {
                guard let stored = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [[String: Any]] else { throw CocoaError(.fileReadCorruptFile) }
                queue = stored
                for event in stored { if let id = event["attemptId"] as? String, !id.isEmpty, let type = event["type"] as? String { observations[id + ":" + type] = event } }
            }
        } catch { unreadable = true; storageFailed = true; NSLog("GardenAds unreadable native receipt store; ads disabled") }
    }
    func command(_ message: [String: Any]) {
        let command = message["command"] as? String ?? ""
        if command == "drain" { queue.forEach(deliver); return }
        if command == "state" { emit("state", "", fields: ["busyAttemptIds": [loadingId, loadedId, presentingId].compactMap { $0 }]); return }
        if command == "ack", let id = message["eventId"] as? String { queue.removeAll { $0["id"] as? String == id }; persist(); return }
        if command == "initialize" {
            ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters()) { [weak self] error in
                if let error { self?.diagnostic(error) }; self?.status()
            }; return
        }
        if command == "privacy" {
            guard active, ConsentInformation.shared.privacyOptionsRequirementStatus == .required else { return }
            ConsentForm.presentPrivacyOptionsForm(from: controller) { [weak self] error in if let error { self?.diagnostic(error) }; self?.status() }; return
        }
        guard let id = message["attemptId"] as? String, UUID(uuidString: id) != nil else { return }
        if command == "cancel" {
            if !presenting { if loadingId == id { cancelled = true }; if loadedId == id { loadedId = nil; ad = nil }; emit("cancelled", id) }
            return
        }
        guard active else { emit(command == "show" ? "show_failed" : "load_failed", id, reason: "in_background"); return }
        guard !storageFailed else { emit("load_failed", id, reason: "sdk_error"); return }
        if command == "load" { load(id) }
        if command == "show" { show(id) }
    }
    private func status() { emit("consent", "", fields: ["canRequestAds": ConsentInformation.shared.canRequestAds, "privacyRequired": ConsentInformation.shared.privacyOptionsRequirementStatus == .required]) }
    private func load(_ id: String) {
        if loadingId == id { return }; if loadedId == id { emit("loaded", id); return }
        guard loadingId == nil, loadedId == nil, !presenting else { emit("load_failed", id, reason: "busy"); return }
        loadingId = id; cancelled = false
        ConsentForm.loadAndPresentIfRequired(from: controller) { [weak self] error in
            guard let self else { return }; if let error { self.diagnostic(error) }; self.status()
            guard self.loadingId == id else { return }
            guard !self.cancelled else { self.loadingId = nil; return }
            guard self.active, ConsentInformation.shared.canRequestAds else { self.loadingId = nil; self.emit("load_failed", id, reason: self.active ? "privacy" : "in_background"); return }
            if self.initialized { self.request(id); return }
            guard !self.initializing else { self.loadingId = nil; self.emit("load_failed", id, reason: "busy"); return }
            self.initializing = true; MobileAds.shared.requestConfiguration.maxAdContentRating = .parentalGuidance
            MobileAds.shared.start { [weak self] status in
                guard let self else { return }; self.initialized = true; self.initializing = false
                for (name, adapter) in status.adapterStatusesByClassName { NSLog("GardenAds adapter=%@ status=%ld latency=%f description=%@", name, adapter.state.rawValue, adapter.latency, adapter.description) }
                guard self.loadingId == id else { return }
                if self.cancelled { self.loadingId = nil; return }
                if self.active && ConsentInformation.shared.canRequestAds { self.request(id) }
                else { self.loadingId = nil; self.emit("load_failed", id, reason: self.active ? "privacy" : "in_background") }
            }
        }
    }
    private func request(_ id: String) {
        let request = Request(), extras = Extras(); extras.additionalParameters = ["npa": "1"]; request.register(extras)
        RewardedAd.load(with: "ca-app-pub-3940256099942544/1712485313", request: request) { [weak self] value, error in
            guard let self else { return }
            if let error { self.diagnostic(error); if self.loadingId == id { self.loadingId = nil }; let e = error as NSError; self.emit("load_failed", id, reason: e.code == 1 ? "no_fill" : e.code == 2 ? "network" : "sdk_error", fields: ["error": ["domain": e.domain, "code": e.code]]); return }
            guard self.loadingId == id else { return }; self.loadingId = nil
            guard !self.cancelled else { return }
            self.ad = value; self.loadedId = id; value?.fullScreenContentDelegate = self; self.emit("loaded", id)
        }
    }
    private func show(_ id: String) {
        if presenting && presentingId == id { return }
        guard let ad, loadedId == id, !presenting, ConsentInformation.shared.canRequestAds else { if loadedId == id { self.ad = nil; loadedId = nil }; emit("show_failed", id, reason: ConsentInformation.shared.canRequestAds ? "not_ready" : "privacy"); return }
        do { try ad.canPresent(from: controller) } catch { diagnostic(error); self.ad = nil; loadedId = nil; emit("show_failed", id, reason: "sdk_error"); return }
        self.ad = nil; loadedId = nil; presenting = true; presentingId = id; presentationIds[ObjectIdentifier(ad)] = id
        ad.present(from: controller) { [self] in emit("reward", id) }
    }
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) { if let id = presentationIds[ObjectIdentifier(ad)] { emit("shown", id) } }
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) { if let id = presentationIds[ObjectIdentifier(ad)] { emit("impression", id) } }
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) { presenting = false; presentingId = nil; if let id = presentationIds[ObjectIdentifier(ad)] { emit("closed", id) } }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) { presenting = false; presentingId = nil; diagnostic(error); if let id = presentationIds[ObjectIdentifier(ad)] { let e = error as NSError; emit("show_failed", id, reason: "sdk_error", fields: ["error": ["domain": e.domain, "code": e.code]]) } }
    private func diagnostic(_ error: Error) { let e = error as NSError; NSLog("GardenAds domain=%@ code=%ld message=%@", e.domain, e.code, e.localizedDescription) }
    private func persist() {
        guard !unreadable else { return }
        do {
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONSerialization.data(withJSONObject: queue).write(to: file, options: .atomic)
            let handle = try FileHandle(forWritingTo: file); try handle.synchronize(); try handle.close()
        } catch { storageFailed = true; diagnostic(error) }
    }
    private func emit(_ type: String, _ attemptId: String, reason: String? = nil, fields: [String: Any] = [:]) {
        let key = attemptId + ":" + type
        if !attemptId.isEmpty, let original = observations[key] { deliver(original); return }
        var event = fields; event["id"] = UUID().uuidString; event["type"] = type; event["attemptId"] = attemptId; event["occurredAt"] = ISO8601DateFormatter().string(from: Date()); if let reason { event["reason"] = reason }
        if !attemptId.isEmpty { observations[key] = event }
        queue.append(event); persist(); deliver(event)
    }
}
