import AdminDomain
import DesignSystem
import SwiftUI

/// Entry point used by the app target.
public struct RootView: View {
    @State private var model: AppModel

    public init(service: any AdminService = SampleAdminService()) {
        _model = State(initialValue: AppModel(service: service))
    }

    public var body: some View {
        Group {
            if model.session == nil {
                LoginView()
            } else {
                MainTabView()
            }
        }
        .environment(model)
        .environment(\.locale, model.language.locale)
        .preferredColorScheme(model.appearance.colorScheme)
        .tint(Theme.goldText)
        // Rebuild every screen when the language changes so all strings re-resolve.
        .id(model.language)
    }
}

enum MainTab: Hashable {
    case home, inbox, platform, search
}

struct MainTabView: View {
    @Environment(AppModel.self) private var model
    @State private var tab: MainTab = .home

    var body: some View {
        TabView(selection: $tab) {
            Tab(tr("Home"), systemImage: "square.grid.2x2.fill", value: MainTab.home) {
                HomeScreen()
            }
            Tab(tr("Inbox"), systemImage: "tray.full.fill", value: MainTab.inbox) {
                InboxScreen()
            }
            .badge(model.inboxCount)
            Tab(tr("Platform"), systemImage: "building.columns.fill", value: MainTab.platform) {
                PlatformScreen()
            }
            Tab(value: MainTab.search, role: .search) {
                SearchScreen()
            }
        }
        .task { await model.refreshInbox() }
    }
}
