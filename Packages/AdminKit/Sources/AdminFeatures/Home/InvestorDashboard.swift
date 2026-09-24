import AdminDomain
import Charts
import DesignSystem
import SwiftUI

/// Investor view: fewer, bigger tiles that tell the growth story.
/// No personal data, no actions.
struct InvestorDashboard: View {
    @Environment(AppModel.self) private var model
    let module: AdminModule

    var body: some View {
        let service = model.service
        let module = module
        AsyncContent(id: "investor-" + module.rawValue) {
            try await service.investor(of: module)
        } content: { snapshot in
            VStack(alignment: .leading, spacing: Theme.Space.gap) {
                gmvHero(snapshot)

                LazyVGrid(columns: bentoColumns, spacing: Theme.Space.gap) {
                    StatTile(tr("Active riders · 30 days"), value: snapshot.activeUsers30d.formatted(.number.locale(L10n.locale)),
                             symbol: "person.2.fill", tone: .good, trend: snapshot.activeTrend)
                    StatTile(tr("Retention · 30 days"), value: percent(snapshot.retention30d),
                             caption: tr("came back for a second trip"), symbol: "arrow.triangle.2.circlepath")
                    StatTile(tr("Fleet utilisation"), value: percent(snapshot.utilization),
                             caption: tr("of fleet hours earning"), symbol: "gauge.with.dots.needle.50percent")
                    StatTile(tr("Revenue per trip"), value: snapshot.revenuePerTrip.formatted(locale: L10n.locale),
                             caption: snapshot.takeRate < 1 ? tr("%@ take rate", percent(snapshot.takeRate)) : tr("own fleet, full fare"),
                             symbol: "banknote.fill")
                }

                funnel(snapshot)
                mix(snapshot)
                byHour(snapshot)
            }
        }
    }

    private func percent(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(0)).locale(L10n.locale))
    }

    private func gmvHero(_ snapshot: InvestorSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(tr("Gross bookings this month"))
                    .font(Theme.Font.caption2)
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                SampleDataBadge()
            }
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(snapshot.gmvThisMonth.formatted(locale: L10n.locale, fractionDigits: 0))
                    .font(Theme.Font.heroNumber)
                    .foregroundStyle(Theme.ink)
                Text((snapshot.gmvGrowth >= 0 ? "+" : "") + percent(snapshot.gmvGrowth))
                    .font(Theme.Font.headline)
                    .foregroundStyle(snapshot.gmvGrowth >= 0 ? Theme.success : Theme.danger)
            }
            Chart(snapshot.gmvByMonth, id: \.label) { month in
                BarMark(x: .value(tr("Month"), tr(month.label)), y: .value(tr("Bookings"), month.value))
                    .foregroundStyle(Theme.goldGradient)
                    .cornerRadius(6)
            }
            .chartYAxis(.hidden)
            .frame(height: 140)
        }
        .padding(18)
        .bentoSurface(radius: Theme.Radius.card)
    }

    private func funnel(_ snapshot: InvestorSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(tr("Activation funnel"))
                .font(Theme.Font.headline)
            let top = Double(snapshot.funnel.first?.count ?? 1)
            ForEach(snapshot.funnel) { step in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(tr(step.labelKey)).font(Theme.Font.subheadline)
                        Spacer()
                        Text(step.count, format: .number).font(Theme.Font.rowNumber)
                    }
                    GeometryReader { geo in
                        Capsule().fill(Theme.control)
                            .overlay(alignment: .leading) {
                                Capsule().fill(Theme.goldGradient)
                                    .frame(width: geo.size.width * Double(step.count) / max(top, 1))
                            }
                    }
                    .frame(height: 8)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(18)
        .bentoSurface()
    }

    private func mix(_ snapshot: InvestorSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(tr("Revenue mix"))
                .font(Theme.Font.headline)
            Chart(snapshot.mix) { share in
                SectorMark(angle: .value(tr("Share"), share.fraction), innerRadius: .ratio(0.62), angularInset: 2)
                    .foregroundStyle(by: .value(tr("Type"), tr(share.labelKey)))
                    .cornerRadius(4)
            }
            .chartForegroundStyleScale(range: [Theme.accentAmber, Theme.accentBronze, Theme.accentHoney, Theme.brandSolid, Theme.inkSoft])
            .frame(height: 180)
        }
        .padding(18)
        .bentoSurface()
    }

    private func byHour(_ snapshot: InvestorSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(tr("When people ride"))
                .font(Theme.Font.headline)
            Chart(Array(snapshot.tripsByHour.enumerated()), id: \.offset) { item in
                AreaMark(x: .value(tr("Hour"), item.offset), y: .value(tr("Trips"), item.element))
                    .foregroundStyle(LinearGradient(colors: [Theme.accentAmber.opacity(0.4), Theme.accentAmber.opacity(0)],
                                                    startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)
                LineMark(x: .value(tr("Hour"), item.offset), y: .value(tr("Trips"), item.element))
                    .foregroundStyle(Theme.brandSolid)
                    .interpolationMethod(.catmullRom)
            }
            .chartXAxis {
                AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                    AxisValueLabel { if let h = value.as(Int.self) { Text("\(h):00") } }
                }
            }
            .frame(height: 150)
        }
        .padding(18)
        .bentoSurface()
    }
}
