import AdminDomain
import DesignSystem
import SwiftUI

// MARK: - Routes

/// Everything a NavigationStack can push.
enum Route: Hashable {
    case page(AdminPage, AdminModule?)
    case record(String)
}

extension View {
    /// Registers every destination once per stack.
    func adminDestinations() -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case let .page(page, module): PageScreen(page: page, module: module)
            case let .record(id): RecordDetailView(recordID: id)
            }
        }
    }
}

/// Picks the right screen for a page.
struct PageScreen: View {
    let page: AdminPage
    let module: AdminModule?

    var body: some View {
        switch page {
        case .overview: OverviewScreen(module: module ?? .p2p)
        case .map: MapScreen(module: module ?? .ev)
        case .statistics: StatisticsScreen(module: module ?? .ev)
        default: RecordListView(page: page, module: module)
        }
    }
}

// MARK: - Severity → tone

extension Severity {
    var tone: Tone {
        switch self {
        case .neutral: .neutral
        case .good: .good
        case .attention: .warn
        case .critical: .bad
        case .info: .info
        }
    }
}

extension StatusChip {
    init(_ status: StatusLabel) {
        self.init(tr(status.key), tone: status.severity.tone)
    }
}

// MARK: - Loading

enum Phase<Value> {
    case loading
    case loaded(Value)
    case failed(String)
}

/// Loads a value with `.task(id:)`, shows a skeleton while loading and a retry on error.
struct AsyncContent<Value: Sendable, Content: View>: View {
    let id: AnyHashable
    let load: @Sendable () async throws -> Value
    @ViewBuilder let content: (Value) -> Content

    @State private var phase: Phase<Value> = .loading
    @State private var attempt = 0

    init(id: AnyHashable, load: @escaping @Sendable () async throws -> Value, @ViewBuilder content: @escaping (Value) -> Content) {
        self.id = id
        self.load = load
        self.content = content
    }

    var body: some View {
        Group {
            switch phase {
            case .loading:
                LoadingTiles()
            case let .loaded(value):
                content(value)
            case let .failed(message):
                ContentUnavailableView {
                    Label(tr("Could not load"), systemImage: "wifi.exclamationmark")
                } description: {
                    Text(message)
                } actions: {
                    Button(tr("Try again")) { attempt += 1 }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.brandSolid)
                }
            }
        }
        .task(id: TaskKey(id: id, attempt: attempt)) {
            if case .loaded = phase {} else { phase = .loading }
            do {
                let value = try await load()
                withAnimation(Theme.snappy) { phase = .loaded(value) }
            } catch is CancellationError {
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    private struct TaskKey: Hashable {
        let id: AnyHashable
        let attempt: Int
    }
}

/// Skeleton of a bento grid while data loads.
struct LoadingTiles: View {
    var body: some View {
        VStack(spacing: Theme.Space.gap) {
            RoundedRectangle(cornerRadius: Theme.Radius.tile).fill(Theme.card).frame(height: 180)
            HStack(spacing: Theme.Space.gap) {
                RoundedRectangle(cornerRadius: Theme.Radius.tile).fill(Theme.card).frame(height: 128)
                RoundedRectangle(cornerRadius: Theme.Radius.tile).fill(Theme.card).frame(height: 128)
            }
            RoundedRectangle(cornerRadius: Theme.Radius.tile).fill(Theme.card).frame(height: 128)
        }
        .padding(Theme.Space.screen)
        .redacted(reason: .placeholder)
        .accessibilityLabel(tr("Loading"))
    }
}

// MARK: - Sample data banner

/// Shown wherever sample data is on screen, so nobody mistakes it for real numbers.
struct SampleDataBadge: View {
    var body: some View {
        Label(tr("Sample data"), systemImage: "flask.fill")
            .font(Theme.Font.caption2)
            .foregroundStyle(Theme.goldText)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Theme.brandTint, in: .capsule)
            .accessibilityLabel(tr("Sample data, not real numbers"))
    }
}

// MARK: - Screen scaffold

extension View {
    /// Standard screen background and horizontal padding.
    func screenBackground() -> some View {
        background(Theme.background.ignoresSafeArea())
    }
}

/// Two equal columns, the bento default on iPhone.
let bentoColumns = [GridItem(.flexible(), spacing: Theme.Space.gap), GridItem(.flexible(), spacing: Theme.Space.gap)]

extension Date {
    /// "5 min ago" in the active language.
    var relative: String {
        formatted(.relative(presentation: .named).locale(L10n.locale))
    }
}
