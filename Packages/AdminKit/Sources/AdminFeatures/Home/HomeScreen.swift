import AdminDomain
import DesignSystem
import SwiftUI

/// The Home tab: module switch, CEO / Investor switch, the dashboard and every
/// page of the module as bento tiles. Same structure as the old web panel.
struct HomeScreen: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.gap) {
                    Picker(tr("Module"), selection: $model.module.animation(Theme.snappy)) {
                        ForEach(AdminModule.allCases) { module in
                            Text(tr(module.titleKey)).tag(module)
                        }
                    }
                    .pickerStyle(.segmented)
                    .sensoryFeedback(.selection, trigger: model.module)

                    switch model.viewMode {
                    case .ceo:
                        CeoDashboard(module: model.module)
                    case .investor:
                        InvestorDashboard(module: model.module)
                    }
                }
                .padding(.horizontal, Theme.Space.screen)
                .padding(.bottom, Theme.Space.tabBarClearance)
            }
            .screenBackground()
            .navigationTitle(tr(model.module.longTitleKey))
            .toolbar { HomeToolbar() }
            .adminDestinations()
            .refreshable { await model.refreshInbox() }
        }
    }
}

/// Top bar: CEO / Investor, the Actions lock and the account menu.
struct HomeToolbar: ToolbarContent {
    @Environment(AppModel.self) private var model

    var body: some ToolbarContent {
        @Bindable var model = model
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Picker(tr("View"), selection: $model.viewMode.animation(Theme.snappy)) {
                    ForEach(ViewMode.allCases) { mode in
                        Label(tr(mode.titleKey), systemImage: mode == .ceo ? "gauge.with.dots.needle.67percent" : "chart.line.uptrend.xyaxis")
                            .tag(mode)
                    }
                }
            } label: {
                Label(tr(model.viewMode.titleKey), systemImage: model.viewMode == .ceo ? "gauge.with.dots.needle.67percent" : "chart.line.uptrend.xyaxis")
                    .labelStyle(.titleAndIcon)
            }
            .accessibilityLabel(tr("Switch between CEO and Investor view"))
        }
        ToolbarItem(placement: .topBarTrailing) {
            ActionsLockButton()
        }
        ToolbarItem(placement: .topBarTrailing) {
            AccountMenu()
        }
    }
}

/// Writes are locked by default. Tap to unlock with Face ID for 15 minutes.
struct ActionsLockButton: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Button {
            if model.actionsEnabled {
                model.lockActions()
                Haptic.tick.fire()
            } else {
                Task {
                    if await model.unlockActions() { Haptic.warn.fire() }
                }
            }
        } label: {
            Image(systemName: model.actionsEnabled ? "lock.open.fill" : "lock.fill")
                .foregroundStyle(model.actionsEnabled ? Theme.danger : Theme.inkSoft)
                .contentTransition(.symbolEffect(.replace))
        }
        .accessibilityLabel(model.actionsEnabled ? tr("Actions on. Tap to lock.") : tr("Actions off. Tap to unlock."))
    }
}

struct AccountMenu: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Menu {
            if let session = model.session {
                Section(session.name) {
                    Text(session.email)
                }
            }
            Picker(tr("Language"), selection: $model.language) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.nativeName).tag(language)
                }
            }
            .pickerStyle(.menu)
            Picker(tr("Appearance"), selection: $model.appearance) {
                ForEach(AppModel.Appearance.allCases) { appearance in
                    Text(tr(appearance.titleKey)).tag(appearance)
                }
            }
            .pickerStyle(.menu)
            Divider()
            Button(tr("Sign out"), systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                model.signOut()
            }
        } label: {
            Image(systemName: "person.crop.circle")
        }
        .accessibilityLabel(tr("Account"))
    }
}
