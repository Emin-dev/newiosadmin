import Foundation

/// A business line. Same order as the module switch in the old panel, plus Transfer.
public enum AdminModule: String, CaseIterable, Identifiable, Sendable, Codable, Hashable {
    case p2p, ev, golf, transfer

    public var id: String { rawValue }

    /// English key; the UI translates it.
    public var titleKey: String {
        switch self {
        case .p2p: "P2P"
        case .ev: "EV"
        case .golf: "Golf"
        case .transfer: "Transfer"
        }
    }

    public var longTitleKey: String {
        switch self {
        case .p2p: "Car rental (P2P)"
        case .ev: "Electric carsharing"
        case .golf: "Golf · Sea Breeze"
        case .transfer: "Transfer marketplace"
        }
    }

    public var symbol: String {
        switch self {
        case .p2p: "car.2.fill"
        case .ev: "bolt.car.fill"
        case .golf: "figure.golf"
        case .transfer: "arrow.triangle.swap"
        }
    }

    /// Pages in the order the live panel shows them. Overview is always first.
    public var pages: [AdminPage] {
        switch self {
        case .p2p:
            [.overview, .users, .vehicles, .trips, .hostReviews, .renterReviews,
             .opsQueues, .notifications, .promoCodes, .settings]
        case .ev:
            [.overview, .users, .vehicles, .trips, .map, .reserves, .outstanding,
             .damageReports, .statistics, .evPlans, .parkingWarnings, .staff, .settings]
        case .golf:
            [.overview, .trips, .reserves, .driverRequests, .fleet, .transactions,
             .tariffs, .promoCodes, .zones, .staff, .settings]
        case .transfer:
            [.overview, .transferRoutes, .transferBookings, .transferDrivers,
             .carChecks, .payouts, .settings]
        }
    }
}

/// CEO = operations. Investor = the growth story.
public enum ViewMode: String, CaseIterable, Identifiable, Sendable, Codable {
    case ceo, investor
    public var id: String { rawValue }
    public var titleKey: String { self == .ceo ? "CEO" : "Investor" }
}

/// Every page the admin app can open. Module pages and platform pages share one list
/// so deep links, search results and the parity checklist can name any of them.
public enum AdminPage: String, CaseIterable, Identifiable, Sendable, Codable, Hashable {
    // Module pages
    case overview, users, vehicles, trips, map, reserves, outstanding, damageReports, statistics
    case hostReviews, renterReviews, opsQueues, notifications, promoCodes, settings
    case evPlans, parkingWarnings
    case driverRequests, fleet, transactions, tariffs, zones, staff
    case transferRoutes, transferBookings, transferDrivers, carChecks, payouts
    // Platform pages (not tied to one module)
    case documentChecks, listingReviews, supportInbox, companies, news
    case adminAccounts, securityGroups, localization, carData

    public var id: String { rawValue }

    public var titleKey: String {
        switch self {
        case .overview: "Overview"
        case .users: "Users"
        case .vehicles: "Vehicles"
        case .trips: "Trips"
        case .map: "Map"
        case .reserves: "Reserves"
        case .outstanding: "Outstanding debt"
        case .damageReports: "Damage reports"
        case .statistics: "Statistics"
        case .hostReviews: "Host reviews"
        case .renterReviews: "Renter reviews"
        case .opsQueues: "Ops queues"
        case .notifications: "Notifications"
        case .promoCodes: "Promo codes"
        case .settings: "Settings"
        case .evPlans: "EV plans"
        case .parkingWarnings: "Parking warnings"
        case .driverRequests: "Driver requests"
        case .fleet: "Fleet"
        case .transactions: "Transactions"
        case .tariffs: "Tariffs"
        case .zones: "Zones"
        case .staff: "Staff & drivers"
        case .transferRoutes: "Routes"
        case .transferBookings: "Bookings"
        case .transferDrivers: "Drivers"
        case .carChecks: "Car checks"
        case .payouts: "Payouts & fees"
        case .documentChecks: "Document checks"
        case .listingReviews: "Listing reviews"
        case .supportInbox: "Support inbox"
        case .companies: "Company accounts"
        case .news: "News & push"
        case .adminAccounts: "Admins & roles"
        case .securityGroups: "Security groups"
        case .localization: "Localization"
        case .carData: "Car data"
        }
    }

    public var symbol: String {
        switch self {
        case .overview: "square.grid.2x2.fill"
        case .users: "person.2.fill"
        case .vehicles: "car.fill"
        case .trips: "road.lanes"
        case .map: "map.fill"
        case .reserves: "clock.badge.checkmark.fill"
        case .outstanding: "exclamationmark.bubble.fill"
        case .damageReports: "wrench.and.screwdriver.fill"
        case .statistics: "chart.xyaxis.line"
        case .hostReviews: "star.bubble.fill"
        case .renterReviews: "star.leadinghalf.filled"
        case .opsQueues: "tray.full.fill"
        case .notifications: "bell.badge.fill"
        case .promoCodes: "ticket.fill"
        case .settings: "gearshape.fill"
        case .evPlans: "calendar.badge.clock"
        case .parkingWarnings: "parkingsign.circle.fill"
        case .driverRequests: "person.badge.clock.fill"
        case .fleet: "cart.fill"
        case .transactions: "creditcard.fill"
        case .tariffs: "tag.fill"
        case .zones: "mappin.and.ellipse"
        case .staff: "person.crop.rectangle.stack.fill"
        case .transferRoutes: "point.topleft.down.to.point.bottomright.curvepath.fill"
        case .transferBookings: "ticket"
        case .transferDrivers: "steeringwheel"
        case .carChecks: "checkmark.seal.fill"
        case .payouts: "banknote.fill"
        case .documentChecks: "person.text.rectangle.fill"
        case .listingReviews: "doc.text.magnifyingglass"
        case .supportInbox: "bubble.left.and.bubble.right.fill"
        case .companies: "building.2.fill"
        case .news: "megaphone.fill"
        case .adminAccounts: "person.badge.key.fill"
        case .securityGroups: "lock.shield.fill"
        case .localization: "globe"
        case .carData: "list.bullet.rectangle.fill"
        }
    }

    /// Platform pages live in the Platform tab, not under a module.
    public static let platform: [AdminPage] = [
        .documentChecks, .listingReviews, .supportInbox, .companies, .news,
        .adminAccounts, .securityGroups, .localization, .carData,
    ]

    /// Pages with their own screen. Everything else renders as a record list.
    public var hasCustomScreen: Bool {
        switch self {
        case .overview, .map, .statistics: true
        default: false
        }
    }
}
