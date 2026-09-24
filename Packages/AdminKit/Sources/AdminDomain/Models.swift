import Foundation

// MARK: - Money

/// Money in minor units (qəpik). One unit everywhere, so the old panel's
/// minor/decimal split (P2P minor, EV/Golf decimal) never comes back.
public struct Money: Sendable, Hashable, Codable, Comparable {
    public var minor: Int
    public var currency: String

    public init(minor: Int, currency: String = "AZN") {
        self.minor = minor
        self.currency = currency
    }

    public init(manat: Double) {
        self.init(minor: Int((manat * 100).rounded()))
    }

    public static let zero = Money(minor: 0)

    public var manat: Double { Double(minor) / 100 }

    /// "16,00 ₼" in Azerbaijani and Russian, "₼16.00" in English.
    public func formatted(locale: Locale = .current, fractionDigits: Int = 2) -> String {
        let number = manat.formatted(
            .number
                .precision(.fractionLength(fractionDigits))
                .grouping(.automatic)
                .locale(locale))
        let symbol = currency == "AZN" ? "₼" : currency
        return locale.language.languageCode?.identifier == "en" ? symbol + number : number + " " + symbol
    }

    /// Compact form for tiles: "₼12.4K" / "12,4K ₼".
    public func compact(locale: Locale = .current) -> String {
        let number = manat.formatted(.number.notation(.compactName).precision(.fractionLength(0...1)).locale(locale))
        let symbol = currency == "AZN" ? "₼" : currency
        return locale.language.languageCode?.identifier == "en" ? symbol + number : number + " " + symbol
    }

    public static func < (lhs: Money, rhs: Money) -> Bool { lhs.minor < rhs.minor }
    public static func + (lhs: Money, rhs: Money) -> Money { Money(minor: lhs.minor + rhs.minor, currency: lhs.currency) }
}

// MARK: - State

/// Domain-level severity. The UI maps it to a colour tone.
public enum Severity: String, Sendable, Codable, Hashable {
    case neutral, good, attention, critical, info
}

/// A status as shown on a chip: an English key plus its severity.
public struct StatusLabel: Sendable, Hashable, Codable {
    public var key: String
    public var severity: Severity
    public init(_ key: String, _ severity: Severity) {
        self.key = key
        self.severity = severity
    }
}

// MARK: - Records (every list page)

/// One row of any list page, plus everything its detail sheet shows.
/// Users, vehicles, trips, reviews, promo codes, zones… all map to this, so every
/// page gets search, filters, detail, actions and CSV export from one screen.
public struct AdminRecord: Identifiable, Sendable, Hashable {
    public var id: String
    public var page: AdminPage
    public var module: AdminModule?
    public var title: String
    public var subtitle: String
    public var status: StatusLabel?
    /// Right-aligned value: a price, a count, a date.
    public var trailing: String?
    public var symbol: String
    public var sections: [RecordSection]
    public var actions: [AdminAction]
    public var createdAt: Date

    public init(id: String, page: AdminPage, module: AdminModule?, title: String, subtitle: String,
                status: StatusLabel?, trailing: String?, symbol: String,
                sections: [RecordSection], actions: [AdminAction], createdAt: Date) {
        self.id = id
        self.page = page
        self.module = module
        self.title = title
        self.subtitle = subtitle
        self.status = status
        self.trailing = trailing
        self.symbol = symbol
        self.sections = sections
        self.actions = actions
        self.createdAt = createdAt
    }
}

public struct RecordSection: Identifiable, Sendable, Hashable {
    public var id: String { titleKey }
    public var titleKey: String
    public var fields: [RecordField]
    public init(_ titleKey: String, _ fields: [RecordField]) {
        self.titleKey = titleKey
        self.fields = fields
    }
}

public struct RecordField: Identifiable, Sendable, Hashable {
    public var id: String { labelKey }
    public var labelKey: String
    public var value: String
    public var severity: Severity
    public init(_ labelKey: String, _ value: String, _ severity: Severity = .neutral) {
        self.labelKey = labelKey
        self.value = value
        self.severity = severity
    }
}

// MARK: - Queries

public struct ListQuery: Sendable, Hashable {
    public var text: String
    /// Status key filter; nil = all.
    public var statusKey: String?
    public var page: Int
    public var pageSize: Int

    public init(text: String = "", statusKey: String? = nil, page: Int = 1, pageSize: Int = 30) {
        self.text = text
        self.statusKey = statusKey
        self.page = page
        self.pageSize = pageSize
    }
}

public struct PageResult<Item: Sendable>: Sendable {
    public var items: [Item]
    public var total: Int
    /// Status keys present in the full list, with counts, for the filter chips.
    public var statusCounts: [String: Int]
    public var hasMore: Bool { items.count < total }

    public init(items: [Item], total: Int, statusCounts: [String: Int]) {
        self.items = items
        self.total = total
        self.statusCounts = statusCounts
    }
}

// MARK: - Dashboards

public struct Kpi: Identifiable, Sendable, Hashable {
    public var id: String { titleKey }
    public var titleKey: String
    public var value: String
    public var captionKey: String?
    public var symbol: String
    public var severity: Severity
    public var trend: [Double]
    /// Page this tile opens.
    public var opens: AdminPage?

    public init(_ titleKey: String, value: String, caption: String? = nil, symbol: String,
                severity: Severity = .neutral, trend: [Double] = [], opens: AdminPage? = nil) {
        self.titleKey = titleKey
        self.value = value
        self.captionKey = caption
        self.symbol = symbol
        self.severity = severity
        self.trend = trend
        self.opens = opens
    }
}

/// CEO view of one module: what is happening now and what needs a decision.
public struct ModuleOverview: Sendable {
    public var module: AdminModule
    public var liveNow: Int
    public var liveCaptionKey: String
    public var revenueToday: Money
    public var revenueTrend: [Double]
    public var kpis: [Kpi]
    public var needsAttention: [QueueItem]
    public var recent: [AdminRecord]
    /// Page counts shown on page tiles (e.g. "Host reviews · 4").
    public var pageBadges: [AdminPage: Int]
    public var updatedAt: Date

    public init(module: AdminModule, liveNow: Int, liveCaptionKey: String, revenueToday: Money,
                revenueTrend: [Double], kpis: [Kpi], needsAttention: [QueueItem], recent: [AdminRecord],
                pageBadges: [AdminPage: Int], updatedAt: Date) {
        self.module = module
        self.liveNow = liveNow
        self.liveCaptionKey = liveCaptionKey
        self.revenueToday = revenueToday
        self.revenueTrend = revenueTrend
        self.kpis = kpis
        self.needsAttention = needsAttention
        self.recent = recent
        self.pageBadges = pageBadges
        self.updatedAt = updatedAt
    }
}

public struct FunnelStep: Identifiable, Sendable, Hashable {
    public var id: String { labelKey }
    public var labelKey: String
    public var count: Int
    public init(_ labelKey: String, _ count: Int) {
        self.labelKey = labelKey
        self.count = count
    }
}

public struct Share: Identifiable, Sendable, Hashable {
    public var id: String { labelKey }
    public var labelKey: String
    public var fraction: Double
    public init(_ labelKey: String, _ fraction: Double) {
        self.labelKey = labelKey
        self.fraction = fraction
    }
}

/// Investor view of one module: growth, unit economics, retention.
public struct InvestorSnapshot: Sendable {
    public var module: AdminModule
    public var gmvThisMonth: Money
    public var gmvGrowth: Double
    public var gmvByMonth: [(label: String, value: Double)]
    public var activeUsers30d: Int
    public var activeTrend: [Double]
    public var retention30d: Double
    public var utilization: Double
    public var takeRate: Double
    public var revenuePerTrip: Money
    public var funnel: [FunnelStep]
    public var mix: [Share]
    public var tripsByHour: [Double]

    public init(module: AdminModule, gmvThisMonth: Money, gmvGrowth: Double,
                gmvByMonth: [(label: String, value: Double)], activeUsers30d: Int, activeTrend: [Double],
                retention30d: Double, utilization: Double, takeRate: Double, revenuePerTrip: Money,
                funnel: [FunnelStep], mix: [Share], tripsByHour: [Double]) {
        self.module = module
        self.gmvThisMonth = gmvThisMonth
        self.gmvGrowth = gmvGrowth
        self.gmvByMonth = gmvByMonth
        self.activeUsers30d = activeUsers30d
        self.activeTrend = activeTrend
        self.retention30d = retention30d
        self.utilization = utilization
        self.takeRate = takeRate
        self.revenuePerTrip = revenuePerTrip
        self.funnel = funnel
        self.mix = mix
        self.tripsByHour = tripsByHour
    }
}

// MARK: - Inbox

/// Something waiting for an admin decision.
public struct QueueItem: Identifiable, Sendable, Hashable {
    public enum Kind: String, CaseIterable, Sendable, Codable {
        case documentCheck, listingReview, golfBooking, golfDriverRequest, evDriverRequest
        case parkingAppeal, supportChat, transferCarCheck, cancellationRequest, damageReport

        public var titleKey: String {
            switch self {
            case .documentCheck: "Document check"
            case .listingReview: "Listing review"
            case .golfBooking: "Golf booking"
            case .golfDriverRequest: "Golf driver request"
            case .evDriverRequest: "EV driver request"
            case .parkingAppeal: "Parking appeal"
            case .supportChat: "Support chat"
            case .transferCarCheck: "Transfer car check"
            case .cancellationRequest: "Cancellation request"
            case .damageReport: "Damage report"
            }
        }

        public var symbol: String {
            switch self {
            case .documentCheck: "person.text.rectangle.fill"
            case .listingReview: "doc.text.magnifyingglass"
            case .golfBooking: "figure.golf"
            case .golfDriverRequest: "person.badge.clock.fill"
            case .evDriverRequest: "steeringwheel"
            case .parkingAppeal: "parkingsign.circle.fill"
            case .supportChat: "bubble.left.and.bubble.right.fill"
            case .transferCarCheck: "checkmark.seal.fill"
            case .cancellationRequest: "xmark.circle.fill"
            case .damageReport: "wrench.and.screwdriver.fill"
            }
        }

        /// The page that owns this kind of item.
        public var page: AdminPage {
            switch self {
            case .documentCheck: .documentChecks
            case .listingReview: .listingReviews
            case .golfBooking: .reserves
            case .golfDriverRequest, .evDriverRequest: .driverRequests
            case .parkingAppeal: .parkingWarnings
            case .supportChat: .supportInbox
            case .transferCarCheck: .carChecks
            case .cancellationRequest: .opsQueues
            case .damageReport: .damageReports
            }
        }
    }

    public var id: String
    public var kind: Kind
    public var module: AdminModule?
    public var title: String
    public var subtitle: String
    public var createdAt: Date
    public var isUrgent: Bool
    /// The record this item is about, opened on tap.
    public var recordID: String

    public init(id: String, kind: Kind, module: AdminModule?, title: String, subtitle: String,
                createdAt: Date, isUrgent: Bool, recordID: String) {
        self.id = id
        self.kind = kind
        self.module = module
        self.title = title
        self.subtitle = subtitle
        self.createdAt = createdAt
        self.isUrgent = isUrgent
        self.recordID = recordID
    }
}

// MARK: - Actions

/// Every write the admin app can make. All go through `AdminService.perform`,
/// behind the Actions lock and a confirmation.
public enum AdminAction: Sendable, Hashable, Identifiable {
    case blockUser(String), unblockUser(String)
    case verifyDocuments(String), rejectDocuments(String)
    case approveListing(String), requestListingChanges(String)
    case blockVehicle(String), unblockVehicle(String)
    case approveBooking(String), declineBooking(String), cancelTrip(String), endTrip(String)
    case assignDriver(String), declineDriverRequest(String)
    case approveCarCheck(String), rejectCarCheck(String)
    case resolve(String), hideReview(String)
    case deactivatePromo(String)

    public var id: String { kindKey + ":" + targetID }

    public var targetID: String {
        switch self {
        case let .blockUser(id), let .unblockUser(id), let .verifyDocuments(id), let .rejectDocuments(id),
             let .approveListing(id), let .requestListingChanges(id), let .blockVehicle(id),
             let .unblockVehicle(id), let .approveBooking(id), let .declineBooking(id),
             let .cancelTrip(id), let .endTrip(id), let .assignDriver(id), let .declineDriverRequest(id),
             let .approveCarCheck(id), let .rejectCarCheck(id), let .resolve(id), let .hideReview(id),
             let .deactivatePromo(id):
            id
        }
    }

    /// English key; also the button title.
    public var kindKey: String {
        switch self {
        case .blockUser: "Block user"
        case .unblockUser: "Unblock user"
        case .verifyDocuments: "Verify documents"
        case .rejectDocuments: "Reject documents"
        case .approveListing: "Approve listing"
        case .requestListingChanges: "Request changes"
        case .blockVehicle: "Block vehicle"
        case .unblockVehicle: "Unblock vehicle"
        case .approveBooking: "Approve and assign"
        case .declineBooking: "Decline booking"
        case .cancelTrip: "Cancel trip"
        case .endTrip: "End trip"
        case .assignDriver: "Assign driver"
        case .declineDriverRequest: "Decline request"
        case .approveCarCheck: "Approve car check"
        case .rejectCarCheck: "Reject car check"
        case .resolve: "Mark resolved"
        case .hideReview: "Hide review"
        case .deactivatePromo: "Deactivate promo"
        }
    }

    public var symbol: String {
        switch self {
        case .blockUser, .blockVehicle: "hand.raised.fill"
        case .unblockUser, .unblockVehicle: "hand.thumbsup.fill"
        case .verifyDocuments, .approveListing, .approveBooking, .approveCarCheck: "checkmark.circle.fill"
        case .rejectDocuments, .rejectCarCheck, .declineBooking, .declineDriverRequest: "xmark.circle.fill"
        case .requestListingChanges: "arrow.uturn.backward.circle.fill"
        case .cancelTrip: "xmark.octagon.fill"
        case .endTrip: "flag.checkered"
        case .assignDriver: "person.fill.checkmark"
        case .resolve: "checkmark.seal.fill"
        case .hideReview: "eye.slash.fill"
        case .deactivatePromo: "ticket"
        }
    }

    /// Destructive actions get a red button and a warning haptic.
    public var isDestructive: Bool {
        switch self {
        case .blockUser, .rejectDocuments, .blockVehicle, .declineBooking, .cancelTrip,
             .declineDriverRequest, .rejectCarCheck, .hideReview, .deactivatePromo:
            true
        default:
            false
        }
    }
}

// MARK: - Session and search

public struct AdminSession: Sendable, Hashable, Codable {
    public var name: String
    public var email: String
    public var isSample: Bool
    public init(name: String, email: String, isSample: Bool) {
        self.name = name
        self.email = email
        self.isSample = isSample
    }
}

public struct SearchHit: Identifiable, Sendable, Hashable {
    public var id: String { record.id }
    public var record: AdminRecord
    public init(record: AdminRecord) { self.record = record }
}

public enum AdminError: LocalizedError, Sendable, Equatable {
    case invalidCredentials
    case notFound
    case actionNotAllowed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials: "Email or password is wrong."
        case .notFound: "This item no longer exists."
        case let .actionNotAllowed(reason): reason
        }
    }
}
