import Foundation

/// In-memory implementation of `AdminService` with generated sample data.
///
/// It exists so every screen can be designed, tested and demoed before the new
/// backend is built. The data is deterministic (seeded), writes change it, and the
/// app labels it "Sample data" everywhere. It is never real business data.
public actor SampleAdminService: AdminService {
    private var records: [String: AdminRecord] = [:]
    private var lists: [ListKey: [String]] = [:]
    private let now: Date
    private let latency: Duration

    struct ListKey: Hashable {
        let page: AdminPage
        let module: AdminModule?
    }

    public init(seed: UInt64 = 2026, now: Date = .now, latency: Duration = .milliseconds(250)) {
        self.now = now
        self.latency = latency
        var rng = SeededRNG(seed: seed)
        var generator = SampleGenerator(now: now)
        for module in AdminModule.allCases {
            for page in module.pages where !page.hasCustomScreen {
                let made = generator.make(page: page, module: module, rng: &rng)
                lists[ListKey(page: page, module: module)] = made.map(\.id)
                for record in made { records[record.id] = record }
            }
        }
        for page in AdminPage.platform {
            let made = generator.make(page: page, module: nil, rng: &rng)
            lists[ListKey(page: page, module: nil)] = made.map(\.id)
            for record in made { records[record.id] = record }
        }
    }

    // MARK: - AdminService

    public func signIn(email: String, password: String) async throws -> AdminSession {
        try await pause()
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard trimmed.contains("@"), password.count >= 4 else { throw AdminError.invalidCredentials }
        let name = trimmed.split(separator: "@").first.map { $0.replacingOccurrences(of: ".", with: " ").capitalized } ?? "Admin"
        return AdminSession(name: name, email: trimmed, isSample: true)
    }

    public func overview(of module: AdminModule) async throws -> ModuleOverview {
        try await pause()
        let trips = list(.trips, module) + list(.transferBookings, module)
        let live = trips.filter { $0.status?.key == "Ongoing" }.count
        var badges: [AdminPage: Int] = [:]
        for page in module.pages {
            let count = list(page, module).filter { $0.status?.severity == .attention }.count
            if count > 0 { badges[page] = count }
        }
        var rng = SeededRNG(seed: UInt64((AdminModule.allCases.firstIndex(of: module) ?? 0) + 11))
        let trend = (0..<14).map { i in 900 + Double(i) * 38 + Double(rng.next(in: 0...260)) }
        let items = try await inbox().filter { $0.module == module }
        return ModuleOverview(
            module: module,
            liveNow: live,
            liveCaptionKey: module == .golf ? "carts out now" : module == .transfer ? "rides on the road" : "trips on the road",
            revenueToday: Money(manat: trend.last ?? 0),
            revenueTrend: trend,
            kpis: kpis(for: module),
            needsAttention: Array(items.prefix(4)),
            recent: Array(trips.prefix(5)),
            pageBadges: badges,
            updatedAt: now)
    }

    public func investor(of module: AdminModule) async throws -> InvestorSnapshot {
        try await pause()
        let scale: Double = switch module {
        case .ev: 1.0
        case .p2p: 1.6
        case .golf: 0.45
        case .transfer: 0.3
        }
        let months = ["Apr", "May", "Jun", "Jul", "Aug", "Sep"]
        let gmv = months.enumerated().map { i, m in (label: m, value: (18_000 + Double(i * i) * 2_100) * scale) }
        let last = gmv.last?.value ?? 0
        let previous = gmv.dropLast().last?.value ?? 1
        return InvestorSnapshot(
            module: module,
            gmvThisMonth: Money(manat: last),
            gmvGrowth: (last - previous) / previous,
            gmvByMonth: gmv,
            activeUsers30d: Int(1_240 * scale),
            activeTrend: (0..<12).map { 400 + Double($0 * $0) * 6 * scale },
            retention30d: 0.41 + 0.04 * scale / 1.6,
            utilization: module == .golf ? 0.62 : 0.34 * scale,
            takeRate: module == .p2p || module == .transfer ? 0.10 : 1.0,
            revenuePerTrip: Money(manat: module == .golf ? 38 : 14.6 * scale),
            funnel: [
                FunnelStep("Registered", Int(3_900 * scale)),
                FunnelStep("Documents verified", Int(2_300 * scale)),
                FunnelStep("First trip", Int(1_450 * scale)),
                FunnelStep("Second trip", Int(880 * scale)),
                FunnelStep("Active in 30 days", Int(1_240 * scale)),
            ],
            mix: module == .golf
                ? [Share("Hourly", 0.58), Share("Daily", 0.27), Share("With driver", 0.15)]
                : module == .ev
                ? [Share("Per minute", 0.46), Share("Hourly", 0.22), Share("Daily", 0.12), Share("EV plans", 0.12), Share("With driver", 0.08)]
                : [Share("Personal hosts", 0.63), Share("Commercial hosts", 0.37)],
            tripsByHour: (0..<24).map { hour in
                let peak = exp(-pow(Double(hour) - 18, 2) / 18) + 0.6 * exp(-pow(Double(hour) - 9, 2) / 8)
                return (peak * 40 * scale).rounded()
            })
    }

    public func records(_ page: AdminPage, module: AdminModule?, query: ListQuery) async throws -> PageResult<AdminRecord> {
        try await pause()
        let all = list(page, module)
        let text = query.text.trimmingCharacters(in: .whitespaces).lowercased()
        let searched = text.isEmpty ? all : all.filter { $0.matches(text) }
        var counts: [String: Int] = [:]
        for record in searched { if let key = record.status?.key { counts[key, default: 0] += 1 } }
        let filtered = query.statusKey.map { key in searched.filter { $0.status?.key == key } } ?? searched
        let end = min(filtered.count, query.page * query.pageSize)
        return PageResult(items: Array(filtered.prefix(end)), total: filtered.count, statusCounts: counts)
    }

    public func record(id: String) async throws -> AdminRecord {
        try await pause()
        guard let record = records[id] else { throw AdminError.notFound }
        return record
    }

    public func inbox() async throws -> [QueueItem] {
        let sources: [(AdminPage, AdminModule?, QueueItem.Kind)] = [
            (.documentChecks, nil, .documentCheck),
            (.listingReviews, nil, .listingReview),
            (.supportInbox, nil, .supportChat),
            (.reserves, .golf, .golfBooking),
            (.driverRequests, .golf, .golfDriverRequest),
            (.parkingWarnings, .ev, .parkingAppeal),
            (.damageReports, .ev, .damageReport),
            (.opsQueues, .p2p, .cancellationRequest),
            (.carChecks, .transfer, .transferCarCheck),
        ]
        var items: [QueueItem] = []
        for (page, module, kind) in sources {
            for record in list(page, module) where record.status?.severity == .attention {
                items.append(QueueItem(
                    id: "q-" + record.id, kind: kind, module: module ?? record.module,
                    title: record.title, subtitle: record.subtitle, createdAt: record.createdAt,
                    isUrgent: now.timeIntervalSince(record.createdAt) > 3 * 3600, recordID: record.id))
            }
        }
        return items.sorted { $0.createdAt > $1.createdAt }
    }

    public func mapPins(of module: AdminModule) async throws -> [MapPin] {
        try await pause()
        let page: AdminPage = module == .golf ? .fleet : .vehicles
        var rng = SeededRNG(seed: 77)
        // Baku centre; Sea Breeze resort for golf carts.
        let centre = module == .golf ? (40.5890, 50.0030) : (40.3953, 49.8822)
        let spread = module == .golf ? 0.006 : 0.05
        return list(page, module).map { record in
            MapPin(
                id: record.id,
                title: record.title,
                latitude: centre.0 + rng.nextDouble(-spread, spread),
                longitude: centre.1 + rng.nextDouble(-spread * 1.4, spread * 1.4),
                status: record.status ?? StatusLabel("Available", .good),
                batteryPercent: module == .ev ? Int(rng.next(in: 8...100)) : nil)
        }
    }

    public func search(_ text: String) async throws -> [SearchHit] {
        try await pause()
        let needle = text.trimmingCharacters(in: .whitespaces).lowercased()
        guard needle.count >= 2 else { return [] }
        return records.values
            .filter { $0.matches(needle) }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(40)
            .map(SearchHit.init)
    }

    @discardableResult
    public func perform(_ action: AdminAction) async throws -> AdminRecord {
        try await pause()
        guard var record = records[action.targetID] else { throw AdminError.notFound }
        let (status, next) = Self.outcome(of: action)
        record.status = status
        record.actions = next
        record.sections = record.sections.map { section in
            var section = section
            section.fields = section.fields.map { field in
                field.labelKey == "Status" ? RecordField("Status", status.key, status.severity) : field
            }
            return section
        }
        records[record.id] = record
        return record
    }

    // MARK: - Helpers

    private func pause() async throws {
        if latency > .zero { try await Task.sleep(for: latency) }
    }

    private func list(_ page: AdminPage, _ module: AdminModule?) -> [AdminRecord] {
        let key = ListKey(page: page, module: AdminPage.platform.contains(page) ? nil : module)
        return (lists[key] ?? []).compactMap { records[$0] }
    }

    static func outcome(of action: AdminAction) -> (StatusLabel, [AdminAction]) {
        let id = action.targetID
        return switch action {
        case .blockUser: (StatusLabel("Blocked", .critical), [.unblockUser(id)])
        case .unblockUser: (StatusLabel("Active", .good), [.blockUser(id)])
        case .verifyDocuments: (StatusLabel("Verified", .good), [.blockUser(id)])
        case .rejectDocuments: (StatusLabel("Rejected", .critical), [.verifyDocuments(id)])
        case .approveListing: (StatusLabel("Live", .good), [.blockVehicle(id)])
        case .requestListingChanges: (StatusLabel("Needs changes", .neutral), [.approveListing(id)])
        case .blockVehicle: (StatusLabel("Blocked", .critical), [.unblockVehicle(id)])
        case .unblockVehicle: (StatusLabel("Available", .good), [.blockVehicle(id)])
        case .approveBooking: (StatusLabel("Approved", .good), [.cancelTrip(id)])
        case .declineBooking: (StatusLabel("Declined", .critical), [])
        case .cancelTrip: (StatusLabel("Cancelled", .neutral), [])
        case .endTrip: (StatusLabel("Finished", .good), [])
        case .assignDriver: (StatusLabel("Driver assigned", .info), [])
        case .declineDriverRequest: (StatusLabel("Declined", .critical), [])
        case .approveCarCheck: (StatusLabel("Approved", .good), [])
        case .rejectCarCheck: (StatusLabel("Rejected", .critical), [.approveCarCheck(id)])
        case .resolve: (StatusLabel("Resolved", .good), [])
        case .hideReview: (StatusLabel("Hidden", .neutral), [])
        case .deactivatePromo: (StatusLabel("Inactive", .neutral), [])
        }
    }

    private func kpis(for module: AdminModule) -> [Kpi] {
        func count(_ page: AdminPage) -> Int { list(page, module).count }
        func count(_ page: AdminPage, _ severity: Severity) -> Int {
            list(page, module).filter { $0.status?.severity == severity }.count
        }
        switch module {
        case .p2p:
            return [
                Kpi("Users", value: "\(count(.users))", caption: "\(count(.users, .attention)) waiting for documents", symbol: "person.2.fill", severity: count(.users, .attention) > 0 ? .attention : .neutral, opens: .users),
                Kpi("Listed cars", value: "\(count(.vehicles))", caption: "\(count(.vehicles, .attention)) in review", symbol: "car.fill", opens: .vehicles),
                Kpi("Trips", value: "\(count(.trips))", caption: "\(count(.trips, .attention)) waiting for host", symbol: "road.lanes", trend: [4, 6, 5, 8, 7, 9, 11], opens: .trips),
                Kpi("Reviews to check", value: "\(count(.hostReviews, .attention) + count(.renterReviews, .attention))", symbol: "star.bubble.fill", severity: .attention, opens: .hostReviews),
            ]
        case .ev:
            return [
                Kpi("Fleet", value: "\(count(.vehicles))", caption: "\(count(.vehicles, .attention)) low battery", symbol: "bolt.car.fill", severity: count(.vehicles, .attention) > 0 ? .attention : .neutral, opens: .map),
                Kpi("Trips", value: "\(count(.trips))", symbol: "road.lanes", trend: [22, 25, 21, 30, 34, 31, 38], opens: .trips),
                Kpi("Reserves", value: "\(count(.reserves))", caption: "active holds", symbol: "clock.badge.checkmark.fill", opens: .reserves),
                Kpi("Outstanding debt", value: "\(count(.outstanding))", caption: "users owe money", symbol: "exclamationmark.bubble.fill", severity: .critical, opens: .outstanding),
                Kpi("Damage reports", value: "\(count(.damageReports, .attention))", caption: "open", symbol: "wrench.and.screwdriver.fill", severity: count(.damageReports, .attention) > 0 ? .attention : .good, opens: .damageReports),
                Kpi("Parking warnings", value: "\(count(.parkingWarnings, .attention))", caption: "appeals to review", symbol: "parkingsign.circle.fill", opens: .parkingWarnings),
            ]
        case .golf:
            return [
                Kpi("Carts", value: "\(count(.fleet))", caption: "\(count(.fleet, .critical)) blocked", symbol: "cart.fill", opens: .fleet),
                Kpi("Bookings to approve", value: "\(count(.reserves, .attention))", symbol: "clock.badge.checkmark.fill", severity: count(.reserves, .attention) > 0 ? .attention : .good, opens: .reserves),
                Kpi("Driver requests", value: "\(count(.driverRequests, .attention))", caption: "waiting for the Sea Breeze team", symbol: "person.badge.clock.fill", severity: .attention, opens: .driverRequests),
                Kpi("Trips", value: "\(count(.trips))", symbol: "figure.golf", trend: [9, 12, 10, 14, 18, 22, 19], opens: .trips),
            ]
        case .transfer:
            return [
                Kpi("Live routes", value: "\(count(.transferRoutes, .good))", symbol: "point.topleft.down.to.point.bottomright.curvepath.fill", opens: .transferRoutes),
                Kpi("Bookings", value: "\(count(.transferBookings))", symbol: "ticket", trend: [2, 3, 3, 5, 4, 6, 8], opens: .transferBookings),
                Kpi("Car checks", value: "\(count(.carChecks, .attention))", caption: "waiting for approval", symbol: "checkmark.seal.fill", severity: .attention, opens: .carChecks),
                Kpi("Drivers", value: "\(count(.transferDrivers))", symbol: "steeringwheel", opens: .transferDrivers),
            ]
        }
    }
}

extension AdminRecord {
    func matches(_ needle: String) -> Bool {
        title.lowercased().contains(needle)
            || subtitle.lowercased().contains(needle)
            || id.lowercased().contains(needle)
            || sections.contains { $0.fields.contains { $0.value.lowercased().contains(needle) } }
    }
}

// MARK: - Seeded randomness

/// SplitMix64. Same seed, same sample data, so screenshots and tests are stable.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func next(in range: ClosedRange<Int>) -> Int { Int.random(in: range, using: &self) }
    mutating func nextDouble(_ lo: Double, _ hi: Double) -> Double { Double.random(in: lo...hi, using: &self) }
    mutating func pick<T>(_ items: [T]) -> T { items[Int.random(in: 0..<items.count, using: &self)] }
    mutating func chance(_ p: Double) -> Bool { Double.random(in: 0..<1, using: &self) < p }
}
