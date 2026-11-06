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
    private let cream = UIColor(red: 1, green: 248/255, blue: 239/255, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = cream
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        #if GARDEN_QA_SERVICES
        let bridge = AdMessages(); bridge.owner = self; config.userContentController.add(bridge, name: "gardenAds")
        config.userContentController.addUserScript(WKUserScript(source: "Object.defineProperty(window,'GardenNative',{value:Object.freeze({platform:'ios',services:'test',ads:'test',appVersion:'0.1.0+3',send:message=>window.webkit.messageHandlers.gardenAds.postMessage(message)}),writable:false});", injectionTime: .atDocumentStart, forMainFrameOnly: true))
        ads = GardenAds(controller: self) { [weak self] event in
            guard let data = try? JSONSerialization.data(withJSONObject: event), let json = String(data: data, encoding: .utf8) else { return }
            self?.web?.evaluateJavaScript("window.GardenAdEvents && window.GardenAdEvents.receive(\(json))", completionHandler: nil)
        }
        ads?.active = UIApplication.shared.applicationState == .active
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
    }
    fileprivate func adMessage(_ message: WKScriptMessage) {
        let origin = message.frameInfo.securityOrigin
        guard message.frameInfo.isMainFrame, origin.protocol == "http", origin.host == "127.0.0.1", origin.port == 43177, message.frameInfo.request.url?.path == "/index.html", let value = message.body as? [String: Any] else { return }
        ads?.command(value)
    }

    @objc private func openGame() {
        retry?.removeFromSuperview(); retry = nil
        server?.stop()
        guard let root = Bundle.main.url(forResource: "Web", withExtension: nil) else { failed(); return }
        let next = AssetServer(root: root)
        server = next
        next.start { [weak self, weak next] result in
            DispatchQueue.main.async {
                guard let self, self.server === next else { return }
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
    @objc private func inactive() { ads?.active = false; web?.evaluateJavaScript("window.GardenLifecycle && window.GardenLifecycle.setActive(false)", completionHandler: nil) }
    @objc private func active() { ads?.active = true; web?.evaluateJavaScript("window.GardenLifecycle && window.GardenLifecycle.setActive(true)", completionHandler: nil) }
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = action.request.url else { decisionHandler(.cancel); return }
        if action.navigationType == .linkActivated, action.targetFrame?.isMainFrame == true, url.absoluteString == "https://policies.google.com/privacy" { UIApplication.shared.open(url); decisionHandler(.cancel); return }
        if url.absoluteString == "about:blank", action.targetFrame?.isMainFrame != true { decisionHandler(.allow); return }
        decisionHandler(url.scheme == "http" && url.host == "127.0.0.1" && url.port == 43177 ? .allow : .cancel)
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { if (error as NSError).code != NSURLErrorCancelled { failed() } }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { failed() }
    deinit { NotificationCenter.default.removeObserver(self); server?.stop() }
}
