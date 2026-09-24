import Foundation

/// Builds the sample records for each page. Plausible Baku data, clearly fake.
struct SampleGenerator {
    let now: Date
    private var serial = 1000

    init(now: Date) { self.now = now }

    private static let firstNames = ["Aysel", "Rauf", "Nigar", "Elvin", "Leyla", "Tural", "Günel", "Kamran", "Səbinə", "Orxan",
                                     "Aynur", "Fərid", "Nərmin", "Rəşad", "Lalə", "Murad", "Zəhra", "Emil", "Könül", "Vüsal"]
    private static let lastNames = ["Məmmədov", "Əliyeva", "Həsənov", "Quliyeva", "Hüseynov", "Kərimova", "Nəbiyev",
                                    "İsmayılova", "Rzayev", "Abbasova", "Cəfərov", "Bağırova"]
    private static let places = ["Sahil", "28 May", "Nizami", "Gənclik", "İçərişəhər", "Heydər Əliyev Mərkəzi", "Ağ şəhər",
                                 "Port Baku", "Hava limanı GYD", "Elmlər Akademiyası", "Nərimanov", "Bayıl"]
    private static let evModels = ["BYD Seagull (2024)", "BYD Dolphin (2024)", "BYD Atto 3 (2025)", "Tesla Model 3 (2023)", "Zeekr X (2025)"]
    private static let p2pModels = ["Toyota Prius (2019)", "Hyundai Elantra (2021)", "Kia K5 (2022)", "Chevrolet Malibu (2020)",
                                    "Toyota Camry (2023)", "Hyundai Tucson (2022)", "Mercedes E 200 (2019)", "Kia Sportage (2024)"]
    private static let seaBreeze = ["Sea Breeze Golf desk", "Beach Club", "Marina", "Villa 12", "Hotel lobby", "Nobu", "Aqua park"]

    mutating func make(page: AdminPage, module: AdminModule?, rng: inout SeededRNG) -> [AdminRecord] {
        let count: Int = switch page {
        case .users, .trips, .transactions: 60
        case .vehicles, .fleet, .transferBookings, .hostReviews, .renterReviews: 36
        case .settings, .tariffs, .zones, .localization, .securityGroups, .adminAccounts, .carData, .evPlans: 8
        default: 18
        }
        return (0..<count).map { index in build(page: page, module: module, index: index, rng: &rng) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Per page

    private mutating func build(page: AdminPage, module: AdminModule?, index: Int, rng: inout SeededRNG) -> AdminRecord {
        serial += 1
        let id = "\(module?.rawValue ?? "pl")-\(page.rawValue)-\(serial)"
        let created = now.addingTimeInterval(-Double(rng.next(in: 60...(60 * 60 * 24 * 30))))
        let person = name(&rng)
        let phone = "+994 \(rng.pick(["50", "51", "55", "70", "77", "99"])) \(rng.next(in: 200...999)) \(rng.next(in: 10...99)) \(rng.next(in: 10...99))"

        func make(_ title: String, _ subtitle: String, _ status: StatusLabel?, trailing: String? = nil,
                  symbol: String? = nil, sections: [RecordSection], actions: [AdminAction] = []) -> AdminRecord {
            var sections = sections
            if let status, var first = sections.first {
                first.fields.insert(RecordField("Status", status.key, status.severity), at: 0)
                sections[0] = first
            }
            return AdminRecord(id: id, page: page, module: module, title: title, subtitle: subtitle, status: status,
                               trailing: trailing, symbol: symbol ?? page.symbol, sections: sections,
                               actions: actions, createdAt: created)
        }

        switch page {
        case .users, .documentChecks:
            let status: StatusLabel = page == .documentChecks
                ? rng.pick([StatusLabel("Waiting for check", .attention), StatusLabel("Waiting for check", .attention), StatusLabel("Verified", .good), StatusLabel("Rejected", .critical)])
                : rng.pick([StatusLabel("Active", .good), StatusLabel("Active", .good), StatusLabel("Active", .good),
                            StatusLabel("Waiting for check", .attention), StatusLabel("Unverified", .neutral), StatusLabel("Blocked", .critical)])
            let actions: [AdminAction] = switch status.key {
            case "Waiting for check": [.verifyDocuments(id), .rejectDocuments(id)]
            case "Blocked": [.unblockUser(id)]
            default: [.blockUser(id)]
            }
            let trips = rng.next(in: 0...64)
            let debt = rng.chance(0.15) ? Money(minor: rng.next(in: 500...18_000)) : .zero
            return make(person, phone, status, trailing: "\(trips) trips", symbol: "person.crop.circle.fill", sections: [
                RecordSection("Profile", [
                    RecordField("Phone", phone),
                    RecordField("Email", person.lowercased().replacingOccurrences(of: " ", with: ".").folding(options: .diacriticInsensitive, locale: nil) + "@mail.az"),
                    RecordField("Account type", rng.chance(0.12) ? "Company" : "Personal"),
                    RecordField("Language", rng.pick(["Azərbaycan", "Русский", "English"])),
                ]),
                RecordSection("Documents", [
                    RecordField("Verification", rng.chance(0.4) ? "MyGov" : "5 photos"),
                    RecordField("ID card", rng.chance(0.9) ? "Uploaded" : "Missing", rng.chance(0.9) ? .good : .critical),
                    RecordField("Driving licence", "Valid until \(rng.next(in: 2027...2034))"),
                    RecordField("Selfie with ID", "Uploaded"),
                ]),
                RecordSection("Activity", [
                    RecordField("Trips", "\(trips)"),
                    RecordField("Modules", rng.pick(["EV", "EV · P2P", "Golf", "P2P", "EV · Golf · Transfer"])),
                    RecordField("Wallet balance", Money(minor: rng.next(in: 0...9_000)).formatted(locale: .az)),
                    RecordField("Debt", debt.formatted(locale: .az), debt.minor > 0 ? .critical : .neutral),
                    RecordField("Registered", created.formatted(date: .abbreviated, time: .omitted)),
                ]),
            ], actions: actions)

        case .vehicles, .listingReviews, .fleet:
            let isEV = module == .ev
            let isGolf = page == .fleet
            let title = isGolf ? "Golf cart \(index + 1)" : rng.pick(isEV ? Self.evModels : Self.p2pModels)
            let plate = isGolf ? "SB-\(String(format: "%02d", index + 1))" : "\(rng.pick(["10", "77", "90", "99"]))-\(rng.pick(["AB", "BK", "RB", "EV", "ZZ"]))-\(rng.next(in: 100...999))"
            let status: StatusLabel = switch page {
            case .listingReviews: rng.pick([StatusLabel("In review", .attention), StatusLabel("In review", .attention), StatusLabel("Live", .good), StatusLabel("Needs changes", .neutral)])
            case .fleet: rng.pick([StatusLabel("Available", .good), StatusLabel("Available", .good), StatusLabel("On rental", .info), StatusLabel("Blocked", .critical)])
            default: isEV
                ? rng.pick([StatusLabel("Available", .good), StatusLabel("On trip", .info), StatusLabel("Charging", .info), StatusLabel("Low battery", .attention), StatusLabel("Blocked", .critical)])
                : rng.pick([StatusLabel("Live", .good), StatusLabel("Live", .good), StatusLabel("On trip", .info), StatusLabel("In review", .attention), StatusLabel("Paused", .neutral), StatusLabel("Blocked", .critical)])
            }
            let actions: [AdminAction] = switch status.key {
            case "In review": [.approveListing(id), .requestListingChanges(id)]
            case "Blocked": [.unblockVehicle(id)]
            default: [.blockVehicle(id)]
            }
            let battery = rng.next(in: 9...100)
            let price = isGolf ? Money(manat: 38) : isEV ? Money(minor: 25) : Money(minor: rng.next(in: 45...140) * 100)
            let priceText = isEV ? price.formatted(locale: .az) + " / dəq" : isGolf ? price.formatted(locale: .az) + " / saat" : price.formatted(locale: .az) + " / gün"
            var info = [RecordField("Plate", plate), RecordField("Price", priceText)]
            if isEV { info.append(RecordField("Battery", "\(battery) %", battery < 20 ? .attention : .neutral)) }
            if !isGolf && !isEV { info.append(RecordField("Host", name(&rng))) }
            return make(title, plate + " · " + (isGolf ? "Sea Breeze" : rng.pick(Self.places)), status,
                        trailing: isEV ? "\(battery) %" : priceText, symbol: isGolf ? "cart.fill" : isEV ? "bolt.car.fill" : "car.fill",
                        sections: [
                            RecordSection("Vehicle", info),
                            RecordSection("Performance", [
                                RecordField("Trips", "\(rng.next(in: 0...140))"),
                                RecordField("Earnings", Money(minor: rng.next(in: 0...900_000)).formatted(locale: .az)),
                                RecordField("Rating", String(format: "%.1f ★", rng.nextDouble(4.1, 5.0))),
                                RecordField("Damage reports", "\(rng.next(in: 0...3))"),
                            ]),
                            RecordSection("Papers", [
                                RecordField("Insurance", "Valid until \(rng.pick(["03.2027", "11.2026", "07.2027"]))"),
                                RecordField("Portal registration", rng.chance(0.85) ? "Registered" : "Missing", rng.chance(0.85) ? .good : .critical),
                            ]),
                        ], actions: actions)

        case .trips, .transferBookings, .reserves, .driverRequests:
            let from = module == .golf ? rng.pick(Self.seaBreeze) : rng.pick(Self.places)
            let to = module == .golf ? rng.pick(Self.seaBreeze) : rng.pick(Self.places)
            let vehicle = module == .golf ? "Golf cart \(rng.next(in: 1...24))" : module == .ev ? rng.pick(Self.evModels) : rng.pick(Self.p2pModels)
            let status: StatusLabel = switch page {
            case .reserves where module == .golf:
                rng.pick([StatusLabel("Pending approval", .attention), StatusLabel("Approved", .good), StatusLabel("Pending approval", .attention)])
            case .reserves:
                rng.pick([StatusLabel("Active hold", .info), StatusLabel("Expired", .neutral)])
            case .driverRequests:
                rng.pick([StatusLabel("Waiting", .attention), StatusLabel("Driver assigned", .info), StatusLabel("Finished", .good)])
            default:
                rng.pick([StatusLabel("Finished", .good), StatusLabel("Finished", .good), StatusLabel("Finished", .good),
                          StatusLabel("Ongoing", .info), StatusLabel("Cancelled", .neutral),
                          module == .p2p ? StatusLabel("Waiting for host", .attention) : StatusLabel("Upcoming", .info)])
            }
            let actions: [AdminAction] = switch status.key {
            case "Ongoing": [.endTrip(id), .cancelTrip(id)]
            case "Pending approval": [.approveBooking(id), .declineBooking(id)]
            case "Waiting": [.assignDriver(id), .declineDriverRequest(id)]
            case "Waiting for host", "Upcoming", "Active hold": [.cancelTrip(id)]
            default: []
            }
            let minutes = rng.next(in: 8...240)
            let price = module == .golf ? Money(manat: 38 * Double(max(1, minutes / 60))) : Money(minor: rng.next(in: 300...9_000))
            var trip = [
                RecordField("Renter", person), RecordField("Phone", phone), RecordField("Vehicle", vehicle),
                RecordField("From", from), RecordField("To", to), RecordField("Duration", "\(minutes) min"),
            ]
            if page == .driverRequests {
                trip.append(RecordField("Passengers", "\(rng.next(in: 1...4))"))
                trip.append(RecordField("Arrival", "about \(rng.pick([5, 10, 15, 20])) min"))
            }
            return make(person, "\(vehicle) · \(from) → \(to)", status, trailing: price.formatted(locale: .az),
                        symbol: module?.symbol, sections: [
                            RecordSection("Trip", trip),
                            RecordSection("Money", [
                                RecordField("Price", price.formatted(locale: .az)),
                                RecordField("Paid with", rng.pick(["Wallet", "Card ·· 4412", "Apple Pay", "Company invoice"])),
                                RecordField("Promo", rng.chance(0.2) ? "FIRST5 · −5,00 ₼" : "None"),
                                RecordField("Fee", page == .transferBookings ? Money(minor: price.minor / 10).formatted(locale: .az) : "—"),
                            ]),
                            RecordSection("Photos", [
                                RecordField("Before", rng.chance(0.9) ? "5 photos" : "Missing"),
                                RecordField("After", status.key == "Finished" ? "6 photos + signature" : "—"),
                            ]),
                        ], actions: actions)

        case .outstanding:
            let debt = Money(minor: rng.next(in: 300...40_000))
            let days = rng.next(in: 1...60)
            let status = days > 14 ? StatusLabel("Overdue", .critical) : StatusLabel("Owes", .attention)
            return make(person, phone, status, trailing: debt.formatted(locale: .az), symbol: "exclamationmark.bubble.fill", sections: [
                RecordSection("Debt", [RecordField("Amount", debt.formatted(locale: .az)), RecordField("Days open", "\(days)"),
                                       RecordField("Last trip", rng.pick(Self.evModels))]),
            ], actions: [.resolve(id)])

        case .damageReports, .parkingWarnings, .opsQueues, .supportInbox, .carChecks:
            let kind: (String, String) = switch page {
            case .damageReports: ("Damage report", rng.pick(["Scratch on rear bumper", "Cracked mirror", "Dirty interior", "Flat tyre"]))
            case .parkingWarnings: ("Parking warning", rng.pick(["Parked outside the zone", "Blocking a driveway", "Left on a pavement"]))
            case .opsQueues: ("Cancellation request", rng.pick(["Host cannot hand over", "Renter changed plans", "Car not as listed"]))
            case .supportInbox: ("Support chat", rng.pick(["Card was charged twice", "Car does not unlock", "How do I extend?", "Refund question"]))
            default: ("Car check", rng.pick(Self.p2pModels))
            }
            let status: StatusLabel = switch page {
            case .parkingWarnings: rng.pick([StatusLabel("Appealed", .attention), StatusLabel("Fee charged", .neutral), StatusLabel("Warning sent", .info)])
            case .carChecks: rng.pick([StatusLabel("Waiting for approval", .attention), StatusLabel("Approved", .good), StatusLabel("Rejected", .critical)])
            default: rng.pick([StatusLabel("Open", .attention), StatusLabel("Open", .attention), StatusLabel("Resolved", .good)])
            }
            let actions: [AdminAction] = switch (page, status.severity) {
            case (.carChecks, .attention): [.approveCarCheck(id), .rejectCarCheck(id)]
            case (_, .attention): [.resolve(id)]
            default: []
            }
            return make(kind.1, "\(person) · \(rng.pick(Self.places))", status, symbol: page.symbol, sections: [
                RecordSection(kind.0, [RecordField("User", person), RecordField("Phone", phone), RecordField("Details", kind.1),
                                       RecordField("Photos", "\(rng.next(in: 0...4))")]),
            ], actions: actions)

        case .hostReviews, .renterReviews:
            let rating = rng.next(in: 1...5)
            let status = rating <= 2 ? StatusLabel("Flagged", .attention) : StatusLabel("Published", .good)
            let text = rating <= 2 ? rng.pick(["Car was late and dirty", "Rude on handover", "Smelled of smoke"])
                : rng.pick(["Great car, easy handover", "Clean and on time", "Would rent again", "Helpful host"])
            return make(String(repeating: "★", count: rating) + String(repeating: "☆", count: 5 - rating), "\(person) · \(text)", status,
                        trailing: "\(rating).0", symbol: "star.fill", sections: [
                            RecordSection("Review", [RecordField("Author", person), RecordField("Rating", "\(rating) / 5"), RecordField("Text", text)]),
                        ], actions: status.severity == .attention ? [.hideReview(id), .resolve(id)] : [.hideReview(id)])

        case .transactions, .payouts:
            let amount = Money(minor: rng.next(in: 200...20_000))
            let status = rng.pick([StatusLabel("Paid", .good), StatusLabel("Paid", .good), StatusLabel("Paid", .good), StatusLabel("Refunded", .neutral), StatusLabel("Failed", .critical)])
            let method = rng.pick(["Wallet", "Card ·· 4412", "Apple Pay", "Company invoice"])
            return make(amount.formatted(locale: .az), "\(person) · \(method)", status, trailing: amount.formatted(locale: .az),
                        symbol: "creditcard.fill", sections: [
                            RecordSection("Payment", [RecordField("Payer", person), RecordField("Method", method),
                                                      RecordField("Gateway", rng.pick(["Kapital Bank", "Pasha Pay"])),
                                                      RecordField("Reference", "TX\(rng.next(in: 100_000...999_999))")]),
                        ])

        case .notifications, .news:
            let title = rng.pick(["Weekend −20 % on EV", "New cars near Sahil", "Golf season opens", "App update 3.2", "Parking rules changed"])
            let status = rng.pick([StatusLabel("Sent", .good), StatusLabel("Scheduled", .info), StatusLabel("Draft", .neutral)])
            return make(title, rng.pick(["All users", "EV riders", "Hosts", "Golf guests"]) + " · " + rng.pick(["Push", "Push + News card"]),
                        status, trailing: "\(rng.next(in: 200...9_000)) users", sections: [
                            RecordSection("Message", [RecordField("Audience", rng.pick(["All users", "EV riders", "Hosts"])),
                                                      RecordField("Opened", "\(rng.next(in: 12...61)) %")]),
                        ])

        case .promoCodes:
            let code = rng.pick(["FIRST5", "SAHIL20", "GOLF10", "WEEKEND", "HOST15", "BAKU25"]) + "\(index)"
            let status = rng.chance(0.7) ? StatusLabel("Active", .good) : StatusLabel("Expired", .neutral)
            return make(code, rng.pick(["−5,00 ₼ first ride", "−20 % weekend", "−10 % golf hourly"]), status,
                        trailing: "\(rng.next(in: 0...400)) used", symbol: "ticket.fill", sections: [
                            RecordSection("Promo", [RecordField("Code", code), RecordField("Limit", "\(rng.next(in: 100...1_000))"),
                                                    RecordField("Valid until", "\(rng.next(in: 1...28)).\(rng.next(in: 10...12)).2026")]),
                        ], actions: status.key == "Active" ? [.deactivatePromo(id)] : [])

        case .evPlans:
            let plan = ["Weekly · 300 min", "Weekly · 600 min", "Monthly · 1 000 min", "Monthly · 2 000 min",
                        "Monthly · 3 000 min", "Yearly · 12 000 min", "Yearly · 24 000 min", "Monthly · 500 min"][index % 8]
            return make(plan, "\(rng.next(in: 5...140)) active subscribers", StatusLabel("On sale", .good),
                        trailing: Money(minor: rng.next(in: 40...900) * 100).formatted(locale: .az), sections: [
                            RecordSection("Plan", [RecordField("Discount", "−30 %"), RecordField("Renews", "Automatically")]),
                        ])

        case .tariffs:
            let tariff = ["Per minute", "Hourly", "Daily", "With driver", "Golf hourly", "Golf daily", "Night", "Weekend"][index % 8]
            return make(tariff, module?.titleKey ?? "", StatusLabel("Active", .good),
                        trailing: Money(minor: [25, 900, 6_900, 3_500, 3_800, 18_000, 20, 7_900][index % 8]).formatted(locale: .az), sections: [
                            RecordSection("Tariff", [RecordField("Applies to", module?.titleKey ?? "All")]),
                        ])

        case .zones:
            let zone = ["City centre", "Airport GYD", "Sea Breeze resort", "White City", "Port Baku", "No-parking: Fountain Sq.", "Bayıl", "Nərimanov"][index % 8]
            return make(zone, index == 5 ? "Alert area" : "Parking area",
                        index == 5 ? StatusLabel("Alert", .attention) : StatusLabel("Active", .good), sections: [
                            RecordSection("Zone", [RecordField("Type", index == 5 ? "Alert" : "Parking"), RecordField("Cars inside", "\(rng.next(in: 0...20))")]),
                        ])

        case .staff, .transferDrivers, .adminAccounts:
            let role: String = switch page {
            case .transferDrivers: "Transfer host"
            case .adminAccounts: ["admin", "admin", "seabreeze_team", "driver_ev", "driver_golf", "admin", "seabreeze_team", "driver_ev"][index % 8]
            default: module == .golf ? rng.pick(["Sea Breeze team", "Golf driver"]) : "EV driver"
            }
            let status = rng.chance(0.6) ? StatusLabel("Online", .good) : StatusLabel("Offline", .neutral)
            return make(person, role + " · " + phone, status, trailing: "\(rng.next(in: 0...300)) jobs", symbol: "person.fill", sections: [
                RecordSection("Account", [RecordField("Role", role), RecordField("Phone", phone),
                                          RecordField("Rating", String(format: "%.1f ★", rng.nextDouble(4.3, 5.0)))]),
            ], actions: [.blockUser(id)])

        case .transferRoutes:
            let from = rng.pick(Self.places), to = rng.pick(["Qəbələ", "Şəki", "Quba", "Lənkəran", "Hava limanı GYD", "Şamaxı"])
            let status = rng.chance(0.75) ? StatusLabel("Live", .good) : StatusLabel("Paused", .neutral)
            return make("\(from) → \(to)", "\(person) · \(rng.next(in: 1...4)) seats left", status,
                        trailing: Money(minor: rng.next(in: 800...4_000)).formatted(locale: .az) + " / yer", sections: [
                            RecordSection("Route", [RecordField("Driver", person), RecordField("Departure", "\(rng.next(in: 7...21)):00"),
                                                    RecordField("Cancellation", rng.pick(["Flexible", "Strict"]))]),
                        ])

        case .companies:
            let company = rng.pick(["Azər Logistics MMC", "Caspian Media", "Baku Build", "Gilan Travel", "SOCAR Green"]) + " \(index + 1)"
            return make(company, "VÖEN \(rng.next(in: 1_000_000_000...1_999_999_999))", StatusLabel("Active", .good),
                        trailing: Money(minor: rng.next(in: 20_000...900_000)).formatted(locale: .az), sections: [
                            RecordSection("Company", [RecordField("Team", "\(rng.next(in: 3...40)) people"),
                                                      RecordField("Invoice e-mail", "finance@company.az"),
                                                      RecordField("Monthly limit", Money(minor: 50_000).formatted(locale: .az))]),
                        ])

        case .securityGroups:
            let group = ["Owners", "Operations", "Finance", "Support", "Sea Breeze team", "Drivers · EV", "Drivers · Golf", "Read only"][index]
            return make(group, "\(rng.next(in: 3...60)) permissions", StatusLabel("Active", .good),
                        trailing: "\(rng.next(in: 1...12)) people", symbol: "lock.shield.fill", sections: [
                            RecordSection("Group", [RecordField("Can write", index < 4 ? "Yes" : "Own module only")]),
                        ])

        case .localization:
            let file = ["Azərbaycan · app", "Русский · app", "English · app", "Azərbaycan · push", "Русский · push", "English · push", "Azərbaycan · legal", "Русский · legal"][index]
            return make(file, "853 strings", index % 3 == 1 ? StatusLabel("12 missing", .attention) : StatusLabel("Complete", .good),
                        symbol: "globe", sections: [RecordSection("File", [RecordField("Updated", created.formatted(date: .abbreviated, time: .omitted))])])

        case .carData:
            let make_ = ["Toyota", "Hyundai", "Kia", "BYD", "Chevrolet", "Mercedes-Benz", "Tesla", "Zeekr"][index]
            return make(make_, "\(rng.next(in: 4...40)) models · 2010–2026", StatusLabel("Active", .good), symbol: "list.bullet.rectangle.fill",
                        sections: [RecordSection("Make", [RecordField("Models", "\(rng.next(in: 4...40))")])])

        case .settings:
            let group = ["General", "Deposits", "Access rules", "Rush tariffs", "Tier discounts", "Telegram check bot", "Insurance", "App versions"][index]
            return make(group, module?.longTitleKey ?? "", nil, symbol: "gearshape.fill", sections: [
                RecordSection(group, [RecordField("Value", rng.pick(["On", "Off", "50,00 ₼", "15 min", "3.2.0"]))]),
            ])

        case .overview, .map, .statistics:
            return make(page.titleKey, "", nil, sections: [])
        }
    }

    private func name(_ rng: inout SeededRNG) -> String {
        let first = rng.pick(Self.firstNames)
        var last = rng.pick(Self.lastNames)
        // Female first names take the -va/-a surname form in the samples.
        let female: Set = ["Aysel", "Nigar", "Leyla", "Günel", "Səbinə", "Aynur", "Nərmin", "Lalə", "Zəhra", "Könül"]
        if female.contains(first), last.hasSuffix("ov") || last.hasSuffix("ev") { last += "a" }
        if !female.contains(first), last.hasSuffix("ova") || last.hasSuffix("eva") { last.removeLast() }
        return "\(first) \(last)"
    }
}

extension Locale {
    static let az = Locale(identifier: "az_AZ")
}
