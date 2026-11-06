import UIKit
import GoogleMobileAds
import UserMessagingPlatform

// Two independent test inventories; one fullscreen route. Native observations
// outlive the page and are acknowledged only after the game transaction.
final class GardenAds: NSObject, FullScreenContentDelegate {
    private final class Inventory {
        let id: String, kind: String
        var loading = true, cancelled = false
        var reward: RewardedAd?
        var interstitial: InterstitialAd?
        init(_ id: String, _ kind: String) { self.id = id; self.kind = kind }
    }
    private weak var controller: UIViewController?
    private let deliver: ([String: Any]) -> Void
    private let file: URL
    private var queue: [[String: Any]] = []
    private var unreadable = false, storageFailed = false, initialized = false, initializing = false
    private var inventories: [String: Inventory] = [:]
    private var presenting: Inventory?
    private var presentationIds: [ObjectIdentifier: Inventory] = [:]
    private var observations: [String: [String: Any]] = [:]
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
        if command == "state" { emit("state", "", fields: ["busyAttemptIds": Array(inventories.values.map { $0.id }) + [presenting?.id].compactMap { $0 }]); return }
        if command == "ack", let id = message["eventId"] as? String { queue.removeAll { $0["id"] as? String == id }; persist(); return }
        if command == "initialize" {
            // A new page cannot inherit cached, unshown inventory. A presented
            // ad retains its original object/delegate and callback identity.
            for slot in Array(inventories.values) { cancel(slot) }
            ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters()) { [weak self] error in
                if let error { self?.diagnostic(error) }; self?.status()
            }; return
        }
        if command == "privacy" {
            guard active, presenting == nil, ConsentInformation.shared.privacyOptionsRequirementStatus == .required else { return }
            ConsentForm.presentPrivacyOptionsForm(from: controller) { [weak self] error in if let error { self?.diagnostic(error) }; self?.status() }; return
        }
        guard let id = message["attemptId"] as? String, UUID(uuidString: id) != nil else { return }
        let kind = message["kind"] as? String ?? "rewarded"
        guard kind == "rewarded" || kind == "interstitial" else { return }
        if command == "cancel" { if presenting?.id != id, let slot = inventories[kind], slot.id == id { cancel(slot) }; return }
        guard active, !storageFailed else { emit("blocked", id, kind: kind, reason: active ? "sdk_error" : "in_background"); return }
        if command == "load" { load(id, kind) }
        if command == "show" { show(id, kind) }
    }
    private func cancel(_ slot: Inventory) {
        slot.cancelled = true
        if !slot.loading { inventories.removeValue(forKey: slot.kind) }
        emit("cancelled", slot.id, kind: slot.kind)
    }
    private func status() { emit("consent", "", fields: ["canRequestAds": ConsentInformation.shared.canRequestAds, "privacyRequired": ConsentInformation.shared.privacyOptionsRequirementStatus == .required]) }
    private func load(_ id: String, _ kind: String) {
        if let old = inventories[kind], old.id == id { if !old.loading { emit("loaded", id, kind: kind) }; return }
        guard inventories[kind] == nil, presenting == nil else { emit("blocked", id, kind: kind, reason: "busy"); return }
        let slot = Inventory(id, kind); inventories[kind] = slot
        let consentReady: (Error?) -> Void = { [weak self] error in
            guard let self else { return }; if let error { self.diagnostic(error) }; self.status()
            guard self.inventories[kind] === slot else { return }
            guard !slot.cancelled else { self.inventories.removeValue(forKey: kind); return }
            guard self.active, ConsentInformation.shared.canRequestAds else { self.inventories.removeValue(forKey: kind); self.emit("blocked", id, kind: kind, reason: self.active ? "privacy" : "in_background"); return }
            if self.initialized { self.request(slot); return }
            guard !self.initializing else { self.inventories.removeValue(forKey: kind); self.emit("blocked", id, kind: kind, reason: "busy"); return }
            self.initializing = true; MobileAds.shared.requestConfiguration.maxAdContentRating = .parentalGuidance
            MobileAds.shared.start { [weak self] status in
                guard let self else { return }; self.initialized = true; self.initializing = false
                for (name, adapter) in status.adapterStatusesByClassName { NSLog("GardenAds adapter=%@ status=%ld latency=%f description=%@", name, adapter.state.rawValue, adapter.latency, adapter.description) }
                guard self.inventories[kind] === slot else { return }
                if slot.cancelled { self.inventories.removeValue(forKey: kind); return }
                if self.active && ConsentInformation.shared.canRequestAds { self.request(slot) }
                else { self.inventories.removeValue(forKey: kind); self.emit("blocked", id, kind: kind, reason: self.active ? "privacy" : "in_background") }
            }
        }
        // Preloading an unsolicited interstitial never opens a consent form.
        if kind == "rewarded" { ConsentForm.loadAndPresentIfRequired(from: controller, completionHandler: consentReady) }
        else { consentReady(nil) }
    }
    private func request(_ slot: Inventory) {
        let request = Request(), extras = Extras(); extras.additionalParameters = ["npa": "1"]; request.register(extras)
        emit("load_requested", slot.id, kind: slot.kind)
        if slot.kind == "rewarded" {
            RewardedAd.load(with: "ca-app-pub-3940256099942544/1712485313", request: request) { [weak self] value, error in
                self?.loaded(slot, reward: value, interstitial: nil, error: error)
            }
        } else {
            InterstitialAd.load(with: "ca-app-pub-3940256099942544/4411468910", request: request) { [weak self] value, error in
                self?.loaded(slot, reward: nil, interstitial: value, error: error)
            }
        }
    }
    private func loaded(_ slot: Inventory, reward: RewardedAd?, interstitial: InterstitialAd?, error: Error?) {
        if let error { diagnostic(error); if inventories[slot.kind] === slot { inventories.removeValue(forKey: slot.kind) }; let e = error as NSError; emit("load_failed", slot.id, kind: slot.kind, reason: e.code == 1 ? "no_fill" : e.code == 2 ? "network" : "sdk_error", fields: ["error": ["domain": e.domain, "code": e.code]]); return }
        guard inventories[slot.kind] === slot else { return }
        guard !slot.cancelled else { inventories.removeValue(forKey: slot.kind); return }
        slot.loading = false; slot.reward = reward; slot.interstitial = interstitial
        reward?.fullScreenContentDelegate = self; interstitial?.fullScreenContentDelegate = self
        emit("loaded", slot.id, kind: slot.kind)
    }
    private func show(_ id: String, _ kind: String) {
        if presenting?.id == id { return }
        guard let slot = inventories[kind], slot.id == id, !slot.loading, !slot.cancelled, presenting == nil, ConsentInformation.shared.canRequestAds else { emit("show_failed", id, kind: kind, reason: ConsentInformation.shared.canRequestAds ? "not_ready" : "privacy"); return }
        do { if let ad = slot.reward { try ad.canPresent(from: controller) } else if let ad = slot.interstitial { try ad.canPresent(from: controller) } else { throw CocoaError(.coderInvalidValue) } }
        catch { diagnostic(error); inventories.removeValue(forKey: kind); emit("show_failed", id, kind: kind, reason: "sdk_error"); return }
        inventories.removeValue(forKey: kind); presenting = slot
        if let ad = slot.reward { presentationIds[ObjectIdentifier(ad)] = slot; ad.present(from: controller) { [self] in emit("reward", id, kind: kind) } }
        else if let ad = slot.interstitial { presentationIds[ObjectIdentifier(ad)] = slot; ad.present(from: controller) }
    }
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) { if let slot = presentationIds[ObjectIdentifier(ad)] { emit("shown", slot.id, kind: slot.kind) } }
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) { if let slot = presentationIds[ObjectIdentifier(ad)] { emit("impression", slot.id, kind: slot.kind) } }
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) { if let slot = presentationIds.removeValue(forKey: ObjectIdentifier(ad)) { if presenting === slot { presenting = nil }; emit("closed", slot.id, kind: slot.kind) } }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) { diagnostic(error); if let slot = presentationIds.removeValue(forKey: ObjectIdentifier(ad)) { if presenting === slot { presenting = nil }; let e = error as NSError; emit("show_failed", slot.id, kind: slot.kind, reason: "sdk_error", fields: ["error": ["domain": e.domain, "code": e.code]]) } }
    private func diagnostic(_ error: Error) { let e = error as NSError; NSLog("GardenAds domain=%@ code=%ld message=%@", e.domain, e.code, e.localizedDescription) }
    private func persist() {
        guard !unreadable else { return }
        do {
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONSerialization.data(withJSONObject: queue).write(to: file, options: .atomic)
            let handle = try FileHandle(forWritingTo: file); try handle.synchronize(); try handle.close()
        } catch { storageFailed = true; diagnostic(error) }
    }
    private func emit(_ type: String, _ attemptId: String, kind: String = "rewarded", reason: String? = nil, fields: [String: Any] = [:]) {
        let key = attemptId + ":" + type
        if !attemptId.isEmpty, let original = observations[key] { deliver(original); return }
        var event = fields; event["id"] = UUID().uuidString; event["type"] = type; event["kind"] = kind; event["attemptId"] = attemptId; event["occurredAt"] = ISO8601DateFormatter().string(from: Date()); if let reason { event["reason"] = reason }
        if !attemptId.isEmpty { observations[key] = event }
        queue.append(event); persist(); deliver(event)
    }
}
