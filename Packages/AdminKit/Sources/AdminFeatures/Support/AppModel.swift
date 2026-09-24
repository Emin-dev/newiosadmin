import AdminDomain
import Foundation
import LocalAuthentication
import Observation
import SwiftUI

/// App-wide state: session, the module and view the admin is looking at, the
/// Actions lock, language and appearance.
@MainActor
@Observable
public final class AppModel {
    public let service: any AdminService

    public private(set) var session: AdminSession?
    public var module: AdminModule {
        didSet { UserDefaults.standard.set(module.rawValue, forKey: Keys.module) }
    }
    public var viewMode: ViewMode {
        didSet { UserDefaults.standard.set(viewMode.rawValue, forKey: Keys.viewMode) }
    }
    public var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: L10n.storageKey) }
    }
    public var appearance: Appearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    /// Writes are off until the admin unlocks them with Face ID. They switch off
    /// again after 15 minutes, as in the old panel.
    public private(set) var actionsUnlockedUntil: Date?
    public var actionsEnabled: Bool { (actionsUnlockedUntil ?? .distantPast) > .now }
    public private(set) var inboxCount = 0
    /// Bumped after every write so open screens reload.
    public private(set) var revision = 0

    private var lockTask: Task<Void, Never>?
    static let unlockDuration: Duration = .seconds(15 * 60)

    enum Keys {
        static let session = "rb.admin.session"
        static let module = "rb.admin.module"
        static let viewMode = "rb.admin.viewMode"
        static let appearance = "rb.admin.appearance"
    }

    public enum Appearance: String, CaseIterable, Identifiable, Sendable {
        case system, light, dark
        public var id: String { rawValue }
        var titleKey: String {
            switch self {
            case .system: "System"
            case .light: "Light"
            case .dark: "Dark"
            }
        }
        var colorScheme: ColorScheme? {
            switch self {
            case .system: nil
            case .light: .light
            case .dark: .dark
            }
        }
    }

    public init(service: any AdminService) {
        self.service = service
        let defaults = UserDefaults.standard
        module = defaults.string(forKey: Keys.module).flatMap(AdminModule.init(rawValue:)) ?? .p2p
        viewMode = defaults.string(forKey: Keys.viewMode).flatMap(ViewMode.init(rawValue:)) ?? .ceo
        language = L10n.current
        appearance = defaults.string(forKey: Keys.appearance).flatMap(Appearance.init(rawValue:)) ?? .system
        if let data = defaults.data(forKey: Keys.session) {
            session = try? JSONDecoder().decode(AdminSession.self, from: data)
        }
    }

    // MARK: - Session

    public func signIn(email: String, password: String) async throws {
        let session = try await service.signIn(email: email, password: password)
        self.session = session
        UserDefaults.standard.set(try? JSONEncoder().encode(session), forKey: Keys.session)
        await refreshInbox()
    }

    public func signOut() {
        session = nil
        lockActions()
        UserDefaults.standard.removeObject(forKey: Keys.session)
    }

    // MARK: - Actions lock

    /// Asks for Face ID (or the passcode) before writes are allowed.
    public func unlockActions() async -> Bool {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            do {
                guard try await context.evaluatePolicy(.deviceOwnerAuthentication,
                                                       localizedReason: tr("Unlock admin actions for 15 minutes")) else { return false }
            } catch {
                return false
            }
        }
        actionsUnlockedUntil = Date.now.addingTimeInterval(15 * 60)
        lockTask?.cancel()
        lockTask = Task { [weak self] in
            try? await Task.sleep(for: Self.unlockDuration)
            guard !Task.isCancelled else { return }
            self?.lockActions()
        }
        return true
    }

    public func lockActions() {
        lockTask?.cancel()
        lockTask = nil
        actionsUnlockedUntil = nil
    }

    // MARK: - Writes

    public func perform(_ action: AdminAction) async throws -> AdminRecord {
        guard actionsEnabled else { throw AdminError.actionNotAllowed(tr("Actions are locked. Unlock them first.")) }
        let record = try await service.perform(action)
        revision += 1
        await refreshInbox()
        return record
    }

    public func refreshInbox() async {
        inboxCount = (try? await service.inbox().count) ?? inboxCount
    }
}
