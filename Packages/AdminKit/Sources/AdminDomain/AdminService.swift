import Foundation

/// The contract between the admin app and the backend.
///
/// The backend will be rebuilt to fit the new design, so this protocol is written
/// from the app's needs first. `SampleAdminService` implements it in memory today;
/// a network implementation replaces it once the API exists. Screens only ever see
/// this protocol.
public protocol AdminService: Sendable {
    func signIn(email: String, password: String) async throws -> AdminSession

    /// CEO dashboard for one module.
    func overview(of module: AdminModule) async throws -> ModuleOverview
    /// Investor dashboard for one module.
    func investor(of module: AdminModule) async throws -> InvestorSnapshot

    /// Any list page. `module` is nil for platform pages.
    func records(_ page: AdminPage, module: AdminModule?, query: ListQuery) async throws -> PageResult<AdminRecord>
    func record(id: String) async throws -> AdminRecord

    /// Everything waiting for an admin, across all modules, newest first.
    func inbox() async throws -> [QueueItem]

    /// Vehicles with a position, for the map.
    func mapPins(of module: AdminModule) async throws -> [MapPin]

    func search(_ text: String) async throws -> [SearchHit]

    /// Runs one write. Returns the updated record.
    @discardableResult
    func perform(_ action: AdminAction) async throws -> AdminRecord
}

public struct MapPin: Identifiable, Sendable, Hashable {
    public var id: String
    public var title: String
    public var latitude: Double
    public var longitude: Double
    public var status: StatusLabel
    public var batteryPercent: Int?

    public init(id: String, title: String, latitude: Double, longitude: Double,
                status: StatusLabel, batteryPercent: Int?) {
        self.id = id
        self.title = title
        self.latitude = latitude
        self.longitude = longitude
        self.status = status
        self.batteryPercent = batteryPercent
    }
}
