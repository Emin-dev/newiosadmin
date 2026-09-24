import AdminDomain
import CoreTransferable
import DesignSystem
import SwiftUI
import UniformTypeIdentifiers

/// Every list page (users, vehicles, trips, reviews, promo codes, zones…):
/// search, status filter chips, paging, swipe for the main action, CSV export.
struct RecordListView: View {
    @Environment(AppModel.self) private var model
    let page: AdminPage
    let module: AdminModule?

    @State private var search = ""
    @State private var status: String?
    @State private var pageNumber = 1
    @State private var result: PageResult<AdminRecord>?
    @State private var error: String?
    @State private var pending: AdminAction?

    private var query: ListQuery {
        ListQuery(text: search, statusKey: status, page: pageNumber, pageSize: 30)
    }

    var body: some View {
        List {
            if let result {
                if !result.statusCounts.isEmpty {
                    filterChips(result.statusCounts)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                Section {
                    ForEach(result.items) { record in
                        NavigationLink(value: Route.record(record.id)) {
                            RecordRow(record: record)
                        }
                        .swipeActions(edge: .trailing) {
                            if let action = record.actions.first {
                                Button(tr(action.kindKey), systemImage: action.symbol) { pending = action }
                                    .tint(action.isDestructive ? Theme.danger : Theme.brandSolid)
                            }
                        }
                        .listRowBackground(Theme.card)
                    }
                    if result.hasMore {
                        Button(tr("Show more")) { pageNumber += 1 }
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(Theme.goldText)
                            .listRowBackground(Theme.card)
                    }
                } header: {
                    HStack {
                        Text(tr("%lld items", result.total))
                        Spacer()
                        SampleDataBadge()
                    }
                    .textCase(nil)
                }
                if result.items.isEmpty {
                    ContentUnavailableView.search(text: search)
                        .listRowBackground(Color.clear)
                }
            } else if let error {
                ContentUnavailableView(tr("Could not load"), systemImage: "wifi.exclamationmark", description: Text(error))
                    .listRowBackground(Color.clear)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .screenBackground()
        .navigationTitle(tr(page.titleKey))
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $search, prompt: tr("Search name, phone or ID"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let items = result?.items, !items.isEmpty {
                    ShareLink(item: CSVExport(name: tr(page.titleKey), records: items),
                              preview: SharePreview(tr("%@ · CSV", tr(page.titleKey)), image: Image(systemName: "tablecells"))) {
                        Label(tr("Export CSV"), systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .task(id: TaskKey(query: query, revision: model.revision)) { await load() }
        .onChange(of: search) { pageNumber = 1 }
        .onChange(of: status) { pageNumber = 1 }
        .refreshable { await load() }
        .actionConfirmation($pending)
    }

    private struct TaskKey: Hashable {
        let query: ListQuery
        let revision: Int
    }

    private func load() async {
        // Debounce typing.
        if !search.isEmpty { try? await Task.sleep(for: .milliseconds(250)) }
        guard !Task.isCancelled else { return }
        do {
            let loaded = try await model.service.records(page, module: module, query: query)
            withAnimation(Theme.snappy) {
                result = loaded
                error = nil
            }
        } catch is CancellationError {
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func filterChips(_ counts: [String: Int]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(tr("All"), count: counts.values.reduce(0, +), selected: status == nil) { status = nil }
                ForEach(counts.keys.sorted(), id: \.self) { key in
                    chip(tr(key), count: counts[key] ?? 0, selected: status == key) {
                        status = status == key ? nil : key
                    }
                }
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.vertical, 4)
        }
    }

    private func chip(_ title: String, count: Int, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptic.click.fire()
            withAnimation(Theme.snappy, action)
        } label: {
            HStack(spacing: 6) {
                Text(title)
                Text(count, format: .number).foregroundStyle(selected ? Theme.onGold.opacity(0.7) : Theme.inkSoft)
            }
            .font(Theme.Font.footnote)
            .foregroundStyle(selected ? Theme.onGold : Theme.ink)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(selected ? AnyShapeStyle(Theme.goldGradient) : AnyShapeStyle(Theme.card), in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// One row: symbol, title, subtitle, status chip, trailing value.
struct RecordRow: View {
    let record: AdminRecord

    var body: some View {
        HStack(spacing: 12) {
            SymbolBadge(record.symbol, tone: record.status?.severity.tone ?? .brand)
            VStack(alignment: .leading, spacing: 3) {
                Text(record.title)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(record.subtitle)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                if let status = record.status { StatusChip(status) }
                Text(record.trailing ?? record.createdAt.relative)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.inkSoft)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

/// The rows on screen as a CSV file for the share sheet.
struct CSVExport: Transferable, Sendable {
    let name: String
    let records: [AdminRecord]

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { export in
            let safeName = export.name.replacingOccurrences(of: "/", with: "-")
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("Rentbutik \(safeName) \(Date.now.formatted(.iso8601.year().month().day())).csv")
            try CSV.make(export.records, translate: { tr($0) }).write(to: url, atomically: true, encoding: .utf8)
            return SentTransferredFile(url)
        }
    }
}
