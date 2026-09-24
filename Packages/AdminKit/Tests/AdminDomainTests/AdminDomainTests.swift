import Foundation
import Testing
@testable import AdminDomain

@Suite("Money")
struct MoneyTests {
    @Test func azerbaijaniFormatPutsSymbolAfter() {
        let text = Money(minor: 1600).formatted(locale: Locale(identifier: "az_AZ"))
        #expect(text.hasSuffix(" ₼"))
        #expect(text.contains("16"))
    }

    @Test func englishFormatPutsSymbolFirst() {
        #expect(Money(minor: 1600).formatted(locale: Locale(identifier: "en_US")) == "₼16.00")
    }

    @Test func manatRoundTrip() {
        #expect(Money(manat: 12.345).minor == 1235)
        #expect((Money(minor: 50) + Money(minor: 75)).minor == 125)
    }
}

@Suite("CSV")
struct CSVTests {
    @Test func formulaCellsAreNeutralised() {
        #expect(CSV.escape("=SUM(A1)") == "\"'=SUM(A1)\"")
        #expect(CSV.escape("+994 50") == "\"'+994 50\"")
        #expect(CSV.escape("@cmd") == "\"'@cmd\"")
    }

    @Test func quotesAreDoubled() {
        #expect(CSV.escape("a \"b\"") == "\"a \"\"b\"\"\"")
    }
}

@Suite("Navigation")
struct NavigationTests {
    @Test func everyModuleStartsWithOverviewAndEndsWithSettings() {
        for module in AdminModule.allCases {
            #expect(module.pages.first == .overview)
            #expect(module.pages.last == .settings)
            #expect(Set(module.pages).count == module.pages.count)
        }
    }

    @Test func platformPagesAreNotModulePages() {
        let modulePages = Set(AdminModule.allCases.flatMap(\.pages))
        #expect(modulePages.isDisjoint(with: AdminPage.platform))
    }
}

@Suite("Sample service")
struct SampleServiceTests {
    let now = Date(timeIntervalSince1970: 1_790_000_000)

    func service() -> SampleAdminService { SampleAdminService(seed: 7, now: now, latency: .zero) }

    @Test func sameSeedSameData() async throws {
        let a = try await service().records(.users, module: .ev, query: ListQuery())
        let b = try await service().records(.users, module: .ev, query: ListQuery())
        #expect(a.items.map(\.title) == b.items.map(\.title))
        #expect(a.total == 60)
    }

    @Test func everyListPageHasRecords() async throws {
        let sample = service()
        for module in AdminModule.allCases {
            for page in module.pages where !page.hasCustomScreen {
                let result = try await sample.records(page, module: module, query: ListQuery())
                #expect(result.total > 0, "\(module) \(page) is empty")
            }
        }
        for page in AdminPage.platform {
            let result = try await sample.records(page, module: nil, query: ListQuery())
            #expect(result.total > 0, "\(page) is empty")
        }
    }

    @Test func statusFilterAndPaging() async throws {
        let sample = service()
        let all = try await sample.records(.trips, module: .ev, query: ListQuery(pageSize: 10))
        #expect(all.items.count == 10)
        #expect(all.hasMore)
        let key = try #require(all.statusCounts.keys.sorted().first)
        let filtered = try await sample.records(.trips, module: .ev, query: ListQuery(statusKey: key, pageSize: 100))
        #expect(filtered.items.allSatisfy { $0.status?.key == key })
        #expect(filtered.total == all.statusCounts[key])
    }

    @Test func performChangesStatusAndLeavesInbox() async throws {
        let sample = service()
        let inbox = try await sample.inbox()
        let item = try #require(inbox.first { $0.kind == .documentCheck })
        let before = try await sample.record(id: item.recordID)
        #expect(before.actions.contains(.verifyDocuments(item.recordID)))

        let after = try await sample.perform(.verifyDocuments(item.recordID))
        #expect(after.status == StatusLabel("Verified", .good))
        #expect(after.sections.first?.fields.first == RecordField("Status", "Verified", .good))

        let inboxAfter = try await sample.inbox()
        #expect(!inboxAfter.contains { $0.recordID == item.recordID })
    }

    @Test func overviewCountsMatchRecords() async throws {
        let sample = service()
        let overview = try await sample.overview(of: .ev)
        let trips = try await sample.records(.trips, module: .ev, query: ListQuery(statusKey: "Ongoing", pageSize: 500))
        #expect(overview.liveNow == trips.total)
        #expect(!overview.kpis.isEmpty)
    }

    @Test func signInRejectsBadEmail() async {
        await #expect(throws: AdminError.invalidCredentials) {
            try await service().signIn(email: "nope", password: "1234")
        }
    }

    @Test func searchFindsByTitle() async throws {
        let sample = service()
        let first = try #require(try await sample.records(.users, module: .p2p, query: ListQuery()).items.first)
        let hits = try await sample.search(first.title)
        #expect(hits.contains { $0.record.id == first.id })
    }
}
