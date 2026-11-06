import UIKit
import WebKit
private final class AdMessages: NSObject, WKScriptMessageHandler {
    weak var owner: GameViewController?
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) { owner?.adMessage(message) }
}

final class GameViewController: UIViewController, WKNavigationDelegate {
    private var server: AssetServer?
    private var web: WKWebView!
    private var retry: UIButton?
    private var ads: GardenAds?
    private var effects: NativeEffects?
    #if DEBUG && GARDEN_QA_SERVICES
    private var qaDiagnostics: GardenQADiagnostics?
    #endif
    private var openRevision = 0
    private let cream = UIColor(red: 1, green: 248/255, blue: 239/255, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = cream
        effects = NativeEffects { [weak self] script in self?.web?.evaluateJavaScript(script, completionHandler: nil) }
        effects?.active = UIApplication.shared.applicationState == .active
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        let bridge = AdMessages(); bridge.owner = self; config.userContentController.add(bridge, name: "gardenAds")
        #if GARDEN_PRODUCTION_SERVICES
        let serviceMode = Bundle.main.bundleIdentifier == "com.pourlune.app" ? "production" : "disabled"
        #elseif GARDEN_QA_SERVICES
        let serviceMode = Bundle.main.bundleIdentifier == "dev.pourlune.glassgarden.localqa" ? "test" : "disabled"
        #else
        let serviceMode = "disabled"
        #endif
        let adMode = serviceMode == "disabled" ? "disabled" : "test"
        let identityJSON = (try? JSONSerialization.data(withJSONObject: Bundle.main.bundleIdentifier ?? "", options: [.fragmentsAllowed])).flatMap { String(data: $0, encoding: .utf8) } ?? "null"
        let appVersion = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "") + "+" + (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "")
        let appVersionJSON = (try? JSONSerialization.data(withJSONObject: appVersion, options: [.fragmentsAllowed])).flatMap { String(data: $0, encoding: .utf8) } ?? "null"
        config.userContentController.addUserScript(WKUserScript(source: "window.GardenNativeActive=false;Object.defineProperty(window,'GardenNative',{value:Object.freeze({platform:'ios',services:'\(serviceMode)',ads:'\(adMode)',legacy:true,effects:true,identity:\(identityJSON),appVersion:\(appVersionJSON),send:message=>window.webkit.messageHandlers.gardenAds.postMessage(message)}),writable:false});", injectionTime: .atDocumentStart, forMainFrameOnly: true))
        #if GARDEN_QA_SERVICES || GARDEN_PRODUCTION_SERVICES
        if serviceMode != "disabled" { ads = GardenAds(controller: self) { [weak self] event in
            guard let data = try? JSONSerialization.data(withJSONObject: event), let json = String(data: data, encoding: .utf8) else { return }
            self?.web?.evaluateJavaScript("window.GardenAdEvents && window.GardenAdEvents.receive(\(json))", completionHandler: nil)
        }
        ads?.active = UIApplication.shared.applicationState == .active }
        #endif
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = .all
        web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = self
        web.isOpaque = false
        web.backgroundColor = cream
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.allowsBackForwardNavigationGestures = true
        if #available(iOS 16.4, *) {
            #if DEBUG
            web.isInspectable = true
            #endif
        }
        web.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(web)
        NSLayoutConstraint.activate([web.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),web.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),web.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),web.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)])
        NotificationCenter.default.addObserver(self, selector: #selector(inactive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(active), name: UIApplication.didBecomeActiveNotification, object: nil)
        openGame()
        #if DEBUG && GARDEN_QA_SERVICES
        qaDiagnostics = GardenQADiagnostics(controller: self, web: web)
        #endif
    }
    fileprivate func adMessage(_ message: WKScriptMessage) {
        let origin = message.frameInfo.securityOrigin
        guard message.frameInfo.isMainFrame, origin.protocol == "http", origin.host == "127.0.0.1", origin.port == 43177, message.frameInfo.request.url?.path == "/index.html", let value = message.body as? [String: Any] else { return }
        let command = value["command"] as? String
        if command == "music" { if let enabled = value["enabled"] as? Bool { effects?.music(enabled) }; return }
        if command == "haptic" { effects?.haptic(); return }
        if command == "audio-interaction" { effects?.interaction(); return }
        if command == "copy-email" { UIPasteboard.general.string = "wangyule0379@gmail.com"; web.evaluateJavaScript("window.GardenExternal && window.GardenExternal.result('copy',true)", completionHandler: nil); return }
        if command == "legacy-read" {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let source = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("pourlune_dev.sqlite")
                let payload: [String: Any]
                do { payload = try LegacyReader.read(from: source) }
                catch { NSLog("GardenQA previous save read failed; originals retained"); payload = ["protocolVersion": 1, "status": "error", "sourceFile": "pourlune_dev.sqlite", "originalRetained": true] }
                guard let data = try? JSONSerialization.data(withJSONObject: payload), let json = String(data: data, encoding: .utf8) else { return }
                DispatchQueue.main.async { self?.web?.evaluateJavaScript("window.GardenLegacy && window.GardenLegacy.receive(\(json))", completionHandler: nil) }
            }
            return
        }
        ads?.command(value)
    }

    @objc private func openGame() {
        effects?.music(false)
        retry?.removeFromSuperview(); retry = nil
        openRevision += 1
        let revision = openRevision
        guard let root = Bundle.main.url(forResource: "Web", withExtension: nil) else { failed(); return }
        let next = server ?? AssetServer(root: root)
        server = next
        next.start { [weak self, weak next] result in
            DispatchQueue.main.async {
                guard let self, self.server === next, self.openRevision == revision else { return }
                switch result {
                case .success(let url): self.web.load(URLRequest(url: url))
                case .failure: self.failed()
                }
            }
        }
    }

    private func failed() {
        guard retry == nil else { return }
        inactive()
        let button = UIButton(type: .system)
        button.setTitle("Could not open local game files. Retry", for: .normal)
        button.backgroundColor = cream
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self, action: #selector(openGame), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        NSLayoutConstraint.activate([button.centerXAnchor.constraint(equalTo: view.centerXAnchor),button.centerYAnchor.constraint(equalTo: view.centerYAnchor),button.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -32),button.heightAnchor.constraint(greaterThanOrEqualToConstant: 64)])
        retry = button
    }
    @objc private func inactive() { effects?.active = false; ads?.active = false; web?.evaluateJavaScript("window.GardenNativeActive=false;window.GardenLifecycle && window.GardenLifecycle.setActive(false)", completionHandler: nil) }
    @objc private func active() { effects?.active = true; ads?.active = true; web?.evaluateJavaScript("window.GardenNativeActive=true;window.GardenLifecycle && window.GardenLifecycle.setActive(true)", completionHandler: nil) }
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = action.request.url else { decisionHandler(.cancel); return }
        let external: Set<String> = ["https://policies.google.com/privacy", "mailto:wangyule0379@gmail.com?subject=Pourlune%20support", "https://wangyule0379-max.github.io/pourlune-support/", "https://creativecommons.org/licenses/by/4.0/", "https://incompetech.com/music/royalty-free/index.html?Search=Search&isrc=USUAN1300046"]
        if action.navigationType == .linkActivated, action.targetFrame?.isMainFrame == true, external.contains(url.absoluteString) { UIApplication.shared.open(url, options: [:]) { [weak self] success in if !success { self?.web?.evaluateJavaScript("window.GardenExternal && window.GardenExternal.result('open',false)", completionHandler: nil) } }; decisionHandler(.cancel); return }
        if url.absoluteString == "about:blank", action.targetFrame?.isMainFrame != true { decisionHandler(.allow); return }
        decisionHandler(url.scheme == "http" && url.host == "127.0.0.1" && url.port == 43177 ? .allow : .cancel)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let foreground = UIApplication.shared.applicationState == .active
        effects?.active = foreground; ads?.active = foreground
        let state = foreground ? "true" : "false"
        webView.evaluateJavaScript("window.GardenNativeActive=\(state);window.GardenLifecycle && window.GardenLifecycle.setActive(\(state))", completionHandler: nil)
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { if (error as NSError).code != NSURLErrorCancelled { failed() } }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { failed() }
    deinit { NotificationCenter.default.removeObserver(self); server?.stop() }
}
