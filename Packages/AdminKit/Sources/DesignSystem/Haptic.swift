import UIKit

/// The Rentbutik haptic vocabulary (design/RULES.md section E).
/// One-shot only: nothing loops, nothing fires on scroll.
public enum Haptic {
    case tick, click, open, grab, gain, warn, error, success

    @MainActor
    public func fire() {
        switch self {
        case .tick:
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
        case .click:
            UISelectionFeedbackGenerator().selectionChanged()
        case .open:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.8)
        case .grab:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        case .gain:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.6)
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(110))
                UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 1.0)
            }
        case .warn:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
