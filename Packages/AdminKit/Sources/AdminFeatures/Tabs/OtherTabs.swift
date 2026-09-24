import AdminDomain
import DesignSystem
import SwiftUI

// MARK: - Inbox

/// Everything waiting for an admin decision across all modules, grouped by kind.
struct InboxScreen: View {
    @Environment(AppModel.self) private var model
    @State private var kind: QueueItem.Kind?

    var body: some View {
        NavigationStack {
            ScrollView {
                let service = model.service
                AsyncContent(id: "inbox-\(model.revision)") {
                    try await service.inbox()
                } content: { items in
                    VStack(alignment: .leading, spacing: Theme.Space.gap) {
                        if items.isEmpty {
                            ContentUnavailableView(tr("Nothing waiting"), systemImage: "checkmark.seal.fill",
                                                   description: Text(tr("Every request has been handled.")))
                        } else {
                            summary(items)
                            let shown = kind.map { k in items.filter { $0.kind == k } } ?? items
                            VStack(spacing: 0) {
                                ForEach(shown) { item in
                                    NavigationLink(value: Route.record(item.recordID)) { QueueRow(item: item) }
                                        .buttonStyle(.plain)
                                    if item.id != shown.last?.id {
                                        Divider().overlay(Theme.hairline).padding(.leading, 62)
                                    }
                                }
                            }
                            .bentoSurface()
                        }
                    }
                    .padding(.horizontal, Theme.Space.screen)
                    .padding(.bottom, Theme.Space.tabBarClearance)
                }
            }
            .screenBackground()
            .navigationTitle(tr("Inbox"))
            .toolbar { ToolbarItem(placement: .topBarTrailing) { ActionsLockButton() } }
            .adminDestinations()
            .refreshable { await model.refreshInbox() }
        }
    }

    /// One tile per kind with its count; tap to filter.
    private func summary(_ items: [QueueItem]) -> some View {
        let counts = Dictionary(grouping: items, by: \.kind).mapValues(\.count)
        let kinds = QueueItem.Kind.allCases.filter { counts[$0] != nil }
        return LazyVGrid(columns: bentoColumns, spacing: Theme.Space.gap) {
            ForEach(kinds, id: \.self) { k in
                Button {
                    Haptic.click.fire()
                    withAnimation(Theme.snappy) { kind = kind == k ? nil : k }
                } label: {
                    PageTile(tr(k.titleKey), symbol: k.symbol, badge: counts[k])
                        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.tile)
                            .stroke(kind == k ? Theme.brandSolid : .clear, lineWidth: 2))
                }
                .buttonStyle(PressScale())
                .accessibilityAddTraits(kind == k ? .isSelected : [])
            }
        }
    }
}

// MARK: - Platform

/// Pages that belong to no single module: documents, listings, support, companies,
/// news, admins and roles, security groups, localization, car data. Plus app settings.
struct PlatformScreen: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.gap) {
                    SectionHeader(tr("Across all modules"))
                    LazyVGrid(columns: bentoColumns, spacing: Theme.Space.gap) {
                        ForEach(AdminPage.platform) { page in
                            NavigationLink(value: Route.page(page, nil)) {
                                PageTile(tr(page.titleKey), symbol: page.symbol)
                            }
                            .buttonStyle(PressScale())
                        }
                    }

                    SectionHeader(tr("This app"))
                    VStack(spacing: 0) {
                        Picker(selection: $model.language) {
                            ForEach(AppLanguage.allCases) { Text($0.nativeName).tag($0) }
                        } label: {
                            Label(tr("Language"), systemImage: "globe")
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        Divider().overlay(Theme.hairline)
                        Picker(selection: $model.appearance) {
                            ForEach(AppModel.Appearance.allCases) { Text(tr($0.titleKey)).tag($0) }
                        } label: {
                            Label(tr("Appearance"), systemImage: "circle.lefthalf.filled")
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        Divider().overlay(Theme.hairline)
                        Button(role: .destructive) {
                            model.signOut()
                        } label: {
                            Label(tr("Sign out"), systemImage: "rectangle.portrait.and.arrow.right")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                    }
                    .tint(Theme.goldText)
                    .bentoSurface()

                    Text(tr("Rentbutik Admin · version %@", Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"))
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.inkSoft)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, Theme.Space.screen)
                .padding(.bottom, Theme.Space.tabBarClearance)
            }
            .screenBackground()
            .navigationTitle(tr("Platform"))
            .adminDestinations()
        }
    }
}

// MARK: - Search

/// Global search: users, vehicles, trips and every other record, by name, phone,
/// plate or ID. Same as the search field in the old panel header.
struct SearchScreen: View {
    @Environment(AppModel.self) private var model
    @State private var text = ""
    @State private var hits: [SearchHit] = []
    @State private var searching = false

    var body: some View {
        NavigationStack {
            List {
                if text.count < 2 {
                    ContentUnavailableView(tr("Search everything"), systemImage: "magnifyingglass",
                                           description: Text(tr("Name, phone, plate, promo code or ID.")))
                        .listRowBackground(Color.clear)
                } else if hits.isEmpty, !searching {
                    ContentUnavailableView.search(text: text)
                        .listRowBackground(Color.clear)
                } else {
                    let grouped = Dictionary(grouping: hits, by: \.record.page)
                    ForEach(grouped.keys.sorted { $0.rawValue < $1.rawValue }, id: \.self) { page in
                        Section(tr(page.titleKey)) {
                            ForEach(grouped[page] ?? []) { hit in
                                NavigationLink(value: Route.record(hit.record.id)) { RecordRow(record: hit.record) }
                                    .listRowBackground(Theme.card)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle(tr("Search"))
            .searchable(text: $text, prompt: tr("Search name, phone or ID"))
            .task(id: text) {
                searching = true
                defer { searching = false }
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }
                hits = (try? await model.service.search(text)) ?? []
            }
            .adminDestinations()
        }
    }
}
