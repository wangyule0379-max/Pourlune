#if DEBUG && GARDEN_QA_SERVICES
import UIKit
import WebKit

// Explicitly enabled, local QA only. No timer, arbitrary code, IDs or save logs.
final class GardenQADiagnostics: NSObject {
    private weak var controller: UIViewController?
    private weak var web: WKWebView?
    private let button = UIButton(type: .system)
    private let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    init(controller: UIViewController, web: WKWebView) {
        super.init()
        self.controller = controller; self.web = web
        guard Bundle.main.bundleIdentifier == "dev.pourlune.glassgarden.localqa",
              ProcessInfo.processInfo.arguments.contains("--garden-qa-tools") else { return }
        button.setTitle("QA", for: .normal); button.backgroundColor = .systemYellow
        button.accessibilityLabel = "QA diagnostics"
        button.addTarget(self, action: #selector(menu), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        controller.view.addSubview(button)
        NSLayoutConstraint.activate([button.trailingAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.trailingAnchor), button.bottomAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.bottomAnchor), button.widthAnchor.constraint(equalToConstant: 44), button.heightAnchor.constraint(equalToConstant: 44)])
    }
    @objc private func menu() {
        guard let controller else { return }
        let panel = UIAlertController(title: "Independent QA only", message: "Synthetic checkpoints preserve the first original save. Restore before finishing.", preferredStyle: .actionSheet)
        panel.addAction(UIAlertAction(title: "Record render state", style: .default) { [weak self] _ in self?.record() })
        panel.addAction(UIAlertAction(title: "Import QA checkpoint", style: .default) { [weak self] _ in self?.checkpoint(restore: false) })
        panel.addAction(UIAlertAction(title: "Restore original QA save", style: .default) { [weak self] _ in self?.checkpoint(restore: true) })
        panel.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        panel.popoverPresentationController?.sourceView = button
        panel.popoverPresentationController?.sourceRect = button.bounds
        controller.present(panel, animated: true)
    }
    private func record() {
        web?.evaluateJavaScript(GardenQAScripts.render) { [weak self] value, error in
            guard let self, error == nil, let value, JSONSerialization.isValidJSONObject(value),
                  let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]) else { NSLog("GardenQA render diagnostic failed"); return }
            do { try data.write(to: self.documents.appendingPathComponent("garden-qa-render-last.json"), options: .atomic); NSLog("GardenQA render diagnostic saved") }
            catch { NSLog("GardenQA render diagnostic write failed") }
        }
    }
    private func checkpoint(restore: Bool) {
        var argument = "null"
        if !restore {
            let file = documents.appendingPathComponent("garden-qa-checkpoint.json")
            guard let data = try? Data(contentsOf: file), data.count < 2_000_000,
                  let value = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let level = value["currentLevel"] as? Int, [16,39,100].contains(level), value["analyticsChoice"] as? String == "declined",
                  let safe = try? JSONSerialization.data(withJSONObject: value), let json = String(data: safe, encoding: .utf8) else { NSLog("GardenQA checkpoint missing or invalid"); return }
            argument = json
        }
        // Async completion is a finite transaction; errors leave originals intact.
        let script = GardenQAScripts.checkpoint + "(" + argument + ").then(()=>location.reload()).catch(()=>{document.title='QA checkpoint operation failed';})"
        web?.evaluateJavaScript(script, completionHandler: nil)
    }
}
#endif
