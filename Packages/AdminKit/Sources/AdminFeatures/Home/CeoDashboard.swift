import AdminDomain
import DesignSystem
import SwiftUI

/// CEO view: what is happening now, what needs a decision, and every page of
/// the module as a tile with its live count.
struct CeoDashboard: View {
    @Environment(AppModel.self) private var model
    let module: AdminModule

    var body: some View {
        let service = model.service
        let module = module
        AsyncContent(id: [module.rawValue, "\(model.revision)"]) {
            try await service.overview(of: module)
        } content: { overview in
            VStack(alignment: .leading, spacing: Theme.Space.gap) {
                LiveHeroTile(overview: overview)

                LazyVGrid(columns: bentoColumns, spacing: Theme.Space.gap) {
                    ForEach(overview.kpis) { kpi in
                        tile(for: kpi, module: module)
                    }
                }

                if !overview.needsAttention.isEmpty {
                    SectionHeader(tr("Needs you"))
                    VStack(spacing: 0) {
                        ForEach(overview.needsAttention) { item in
                            NavigationLink(value: Route.record(item.recordID)) {
                                QueueRow(item: item)
                            }
                            .buttonStyle(.plain)
                            if item.id != overview.needsAttention.last?.id {
                                Divider().overlay(Theme.hairline).padding(.leading, 62)
                            }
                        }
                    }
                    .bentoSurface()
                }

                SectionHeader(tr("Pages"))
                LazyVGrid(columns: bentoColumns, spacing: Theme.Space.gap) {
                    ForEach(module.pages.filter { $0 != .overview }) { page in
                        NavigationLink(value: Route.page(page, module)) {
                            PageTile(tr(page.titleKey), symbol: page.symbol,
                                     detail: overview.pageBadges[page].map { tr("%lld waiting", $0) },
                                     badge: overview.pageBadges[page])
                        }
                        .buttonStyle(PressScale())
                    }
                }

                if !overview.recent.isEmpty {
                    SectionHeader(tr("Recent trips"))
                    VStack(spacing: 0) {
                        ForEach(overview.recent) { record in
                            NavigationLink(value: Route.record(record.id)) {
                                RecordRow(record: record)
                                    .padding(.horizontal, 14)
                            }
                            .buttonStyle(.plain)
                            Divider().overlay(Theme.hairline).padding(.leading, 62)
                        }
                        NavigationLink(value: Route.page(module == .transfer ? .transferBookings : .trips, module)) {
                            HStack {
                                Text(tr("All trips"))
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .font(Theme.Font.subheadline)
                            .foregroundStyle(Theme.goldText)
                            .padding(14)
                        }
                    }
                    .bentoSurface()
                }
            }
        }
    }

    @ViewBuilder
    private func tile(for kpi: Kpi, module: AdminModule) -> some View {
        let tile = StatTile(tr(kpi.titleKey), value: kpi.value, caption: kpi.captionKey.map { tr($0) },
                            symbol: kpi.symbol, tone: kpi.severity.tone, trend: kpi.trend)
        if let page = kpi.opens {
            NavigationLink(value: Route.page(page, module)) { tile }
                .buttonStyle(PressScale())
        } else {
            tile
        }
    }
}

/// The big tile: live trips, today's revenue and the 14-day trend.
struct LiveHeroTile: View {
    let overview: ModuleOverview

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(Theme.success).frame(width: 8, height: 8)
                    Text(tr("Live"))
                        .font(Theme.Font.caption2)
                        .foregroundStyle(Theme.success)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Theme.success.opacity(0.12), in: .capsule)
                Spacer()
                SampleDataBadge()
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(overview.liveNow, format: .number)
                    .font(Theme.Font.heroNumber)
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                Text(tr(overview.liveCaptionKey))
                    .font(Theme.Font.subheadline)
                    .foregroundStyle(Theme.inkSoft)
            }
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tr("Revenue today"))
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.inkSoft)
                    Text(overview.revenueToday.formatted(locale: L10n.locale))
                        .font(Theme.Font.title3)
                        .foregroundStyle(Theme.goldText)
                }
                Spacer(minLength: 16)
                Sparkline(values: overview.revenueTrend)
                    .frame(width: 150, height: 44)
            }
            Text(tr("Updated %@", overview.updatedAt.formatted(date: .omitted, time: .shortened)))
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .bentoSurface(radius: Theme.Radius.card)
        .accessibilityElement(children: .combine)
    }
}

struct QueueRow: View {
    let item: QueueItem

    var body: some View {
        HStack(spacing: 12) {
            SymbolBadge(item.kind.symbol, tone: item.isUrgent ? .bad : .brand)
            VStack(alignment: .leading, spacing: 2) {
                Text(tr(item.kind.titleKey))
                    .font(Theme.Font.caption2)
                    .foregroundStyle(item.isUrgent ? Theme.danger : Theme.goldText)
                Text(item.title)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(item.subtitle)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(item.createdAt.relative)
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.inkSoft)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(14)
        .contentShape(.rect)
    }
}
