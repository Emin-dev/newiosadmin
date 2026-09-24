import AdminDomain
import Charts
import DesignSystem
import MapKit
import SwiftUI

/// Overview opened as a page (from search or a deep link).
struct OverviewScreen: View {
    @Environment(AppModel.self) private var model
    let module: AdminModule

    var body: some View {
        ScrollView {
            Group {
                switch model.viewMode {
                case .ceo: CeoDashboard(module: module)
                case .investor: InvestorDashboard(module: module)
                }
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.bottom, Theme.Space.tabBarClearance)
        }
        .screenBackground()
        .navigationTitle(tr(module.longTitleKey))
    }
}

/// Live fleet map. Apple Maps, pins coloured by status, battery on EV pins.
struct MapScreen: View {
    @Environment(AppModel.self) private var model
    let module: AdminModule

    @State private var pins: [MapPin] = []
    @State private var selected: String?
    @State private var filter: Severity?

    private var visible: [MapPin] {
        guard let filter else { return pins }
        return pins.filter { $0.status.severity == filter }
    }

    var body: some View {
        Map(selection: $selected) {
            ForEach(visible) { pin in
                Annotation(pin.title, coordinate: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)) {
                    pinView(pin)
                }
                .tag(pin.id)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControls {
            MapScaleView()
            MapCompass()
        }
        .safeAreaInset(edge: .top) { legend.padding(.horizontal, Theme.Space.screen) }
        .safeAreaInset(edge: .bottom) {
            if let pin = pins.first(where: { $0.id == selected }) {
                NavigationLink(value: Route.record(pin.id)) {
                    HStack(spacing: 12) {
                        SymbolBadge(module.symbol, tone: pin.status.severity.tone)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pin.title).font(Theme.Font.headline).foregroundStyle(Theme.ink)
                            HStack(spacing: 8) {
                                StatusChip(pin.status)
                                if let battery = pin.batteryPercent {
                                    Label("\(battery) %", systemImage: "battery.75percent")
                                        .font(Theme.Font.caption)
                                        .foregroundStyle(battery < 20 ? Theme.danger : Theme.inkSoft)
                                }
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
                    }
                    .padding(14)
                    .bentoSurface()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Theme.Space.screen)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(Theme.snappy, value: selected)
        .navigationTitle(tr("Map"))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: model.revision) {
            pins = (try? await model.service.mapPins(of: module)) ?? []
        }
        .sensoryFeedback(.selection, trigger: selected)
    }

    private func pinView(_ pin: MapPin) -> some View {
        let isSelected = pin.id == selected
        return Image(systemName: module == .golf ? "cart.fill" : "car.fill")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(pin.status.severity.tone.color, in: .circle)
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .scaleEffect(isSelected ? 1.35 : 1)
            .shadow(color: .black.opacity(isSelected ? 0.3 : 0), radius: 6, y: 3)
            .animation(Theme.bouncy, value: isSelected)
    }

    private var legend: some View {
        let counts = Dictionary(grouping: pins, by: \.status.severity).mapValues(\.count)
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                legendChip(nil, title: tr("All"), count: pins.count)
                ForEach([Severity.good, .info, .attention, .critical, .neutral], id: \.self) { severity in
                    if let count = counts[severity], count > 0 {
                        legendChip(severity, title: tr(Self.legendKey(severity)), count: count)
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }

    static func legendKey(_ severity: Severity) -> String {
        switch severity {
        case .good: "Available"
        case .info: "Busy"
        case .attention: "Needs attention"
        case .critical: "Blocked"
        case .neutral: "Other"
        }
    }

    private func legendChip(_ severity: Severity?, title: String, count: Int) -> some View {
        let isOn = filter == severity
        return Button {
            Haptic.click.fire()
            filter = isOn ? nil : severity
        } label: {
            HStack(spacing: 6) {
                if let severity { Circle().fill(severity.tone.color).frame(width: 8, height: 8) }
                Text(title)
                Text(count, format: .number).foregroundStyle(Theme.inkSoft)
            }
            .font(Theme.Font.footnote)
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(.regularMaterial, in: .capsule)
            .overlay(Capsule().stroke(isOn ? Theme.brandSolid : .clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

/// Statistics: trips by hour, time-of-day mix and the 6-month trend.
/// Mirrors the old EV Statistics page on top of the investor data.
struct StatisticsScreen: View {
    @Environment(AppModel.self) private var model
    let module: AdminModule

    var body: some View {
        let service = model.service
        let module = module
        ScrollView {
            AsyncContent(id: "stats-" + module.rawValue) {
                try await service.investor(of: module)
            } content: { snapshot in
                VStack(alignment: .leading, spacing: Theme.Space.gap) {
                    let hours = snapshot.tripsByHour
                    let parts: [(String, ClosedRange<Int>)] = [
                        ("Morning · 6–11", 6...11), ("Afternoon · 12–16", 12...16),
                        ("Evening · 17–22", 17...22), ("Off-hours · 23–05", 0...5),
                    ]
                    LazyVGrid(columns: bentoColumns, spacing: Theme.Space.gap) {
                        ForEach(parts, id: \.0) { part in
                            let total = part.1.reduce(0.0) { $0 + hours[$1] } + (part.0.hasPrefix("Off") ? hours[23] : 0)
                            StatTile(tr(part.0), value: Int(total).formatted(), caption: tr("trips per day"), symbol: "clock.fill")
                        }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text(tr("Trips by hour")).font(Theme.Font.headline)
                        Chart(Array(hours.enumerated()), id: \.offset) { item in
                            BarMark(x: .value(tr("Hour"), item.offset), y: .value(tr("Trips"), item.element))
                                .foregroundStyle(Theme.goldGradient)
                                .cornerRadius(3)
                        }
                        .frame(height: 180)
                    }
                    .padding(18)
                    .bentoSurface()
                    VStack(alignment: .leading, spacing: 12) {
                        Text(tr("Unique riders")).font(Theme.Font.headline)
                        Sparkline(values: snapshot.activeTrend, tone: .good).frame(height: 90)
                    }
                    .padding(18)
                    .bentoSurface()
                }
            }
            .padding(.horizontal, Theme.Space.screen)
            .padding(.bottom, Theme.Space.tabBarClearance)
        }
        .screenBackground()
        .navigationTitle(tr("Statistics"))
    }
}
