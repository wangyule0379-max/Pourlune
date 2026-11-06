import UIKit
import AVFoundation

final class NativeEffects: NSObject {
    private var player: AVAudioPlayer?
    private var enabled = false
    private var interrupted = false
    private var waitForInteraction = false
    private let notify: (String) -> Void
    var active = false { didSet { sync() } }
    init(notify: @escaping (String) -> Void) {
        self.notify = notify; super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(interruption), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(routeChange), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    func music(_ wanted: Bool) { enabled = wanted; sync() }
    func interaction() { if active && !interrupted { try? AVAudioSession.sharedInstance().setCategory(.ambient) }; waitForInteraction = false; sync() }
    func haptic() { guard active, !interrupted else { return }; UISelectionFeedbackGenerator().selectionChanged() }
    private func sync() {
        guard enabled, active, !interrupted, !waitForInteraction else { player?.pause(); return }
        guard player?.isPlaying != true else { return }
        do {
            // Match the old app: ambient mixes implicitly and respects Silent.
            try AVAudioSession.sharedInstance().setCategory(.ambient)
            if player == nil {
                guard let root = Bundle.main.url(forResource: "Web", withExtension: nil) else { return }
                let next = try AVAudioPlayer(contentsOf: root.appendingPathComponent("media/dream-culture.mp3"))
                next.volume = 0.12; next.numberOfLoops = -1; next.prepareToPlay(); player = next
            }
            if player?.play() != true { NSLog("GardenQA optional music could not start") }
        } catch { NSLog("GardenQA optional music unavailable") }
    }
    @objc private func interruption(_ note: Notification) {
        guard let value = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt, let type = AVAudioSession.InterruptionType(rawValue: value) else { return }
        if type == .began { interrupted = true; sync(); notify("window.GardenLifecycle && window.GardenLifecycle.audioInterrupted(true)") }
        else {
            interrupted = false
            let options = AVAudioSession.InterruptionOptions(rawValue: note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0)
            waitForInteraction = !options.contains(.shouldResume)
            notify("window.GardenLifecycle && window.GardenLifecycle.audioInterrupted(false)"); sync()
        }
    }
    @objc private func routeChange(_ note: Notification) {
        guard note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue else { return }
        waitForInteraction = true; sync(); notify("window.GardenLifecycle && window.GardenLifecycle.stopAudio()")
    }
    deinit { NotificationCenter.default.removeObserver(self); player?.stop() }
}
