// In-memory AdminService with generated sample data.
// Exists so every screen can be built, tested and demoed before the new backend.
// Deterministic (seeded); writes change it; the UI labels it "Sample data" everywhere.

import { formatMoney } from "./money.ts";
import { Rng } from "./rng.ts";
import {
  CUSTOM_PAGES, MODULE_PAGES, PAGE_TITLE, PLATFORM_PAGES, isPlatformPage,
  type ActionKind, type AdminAction, type AdminModule, type AdminPage, type AdminRecord, type AdminService,
  type AdminSession, type InvestorSnapshot, type Kpi, type ListQuery, type MapPin, type ModuleOverview,
  type PageResult, type QueueItem, type QueueKind, type RecordSection, type Severity, type StatusLabel,
} from "./types.ts";

const S = (key: string, severity: Severity): StatusLabel => ({ key, severity });
const F = (label: string, value: string, severity: Severity = "neutral") => ({ label, value, severity });
const A = (kind: ActionKind, target: string): AdminAction => ({ kind, target });
const m = (minor: number) => formatMoney(minor, "az");

const FIRST = ["Aysel", "Rauf", "Nigar", "Elvin", "Leyla", "Tural", "Günel", "Kamran", "Səbinə", "Orxan",
  "Aynur", "Fərid", "Nərmin", "Rəşad", "Lalə", "Murad", "Zəhra", "Emil", "Könül", "Vüsal"];
const FEMALE = new Set(["Aysel", "Nigar", "Leyla", "Günel", "Səbinə", "Aynur", "Nərmin", "Lalə", "Zəhra", "Könül"]);
const LAST = ["Məmmədov", "Əliyev", "Həsənov", "Quliyev", "Hüseynov", "Kərimov", "Nəbiyev", "İsmayılov", "Rzayev", "Abbasov", "Cəfərov", "Bağırov"];
const PLACES = ["Sahil", "28 May", "Nizami", "Gənclik", "İçərişəhər", "Heydər Əliyev Mərkəzi", "Ağ şəhər", "Port Baku",
  "Hava limanı GYD", "Elmlər Akademiyası", "Nərimanov", "Bayıl"];
const EV_MODELS = ["BYD Seagull (2024)", "BYD Dolphin (2024)", "BYD Atto 3 (2025)", "Tesla Model 3 (2023)", "Zeekr X (2025)"];
const P2P_MODELS = ["Toyota Prius (2019)", "Hyundai Elantra (2021)", "Kia K5 (2022)", "Chevrolet Malibu (2020)",
  "Toyota Camry (2023)", "Hyundai Tucson (2022)", "Mercedes E 200 (2019)", "Kia Sportage (2024)"];
const SEA_BREEZE = ["Sea Breeze Golf desk", "Beach Club", "Marina", "Villa 12", "Hotel lobby", "Nobu", "Aqua park"];
const REGIONS = ["Qəbələ", "Şəki", "Quba", "Lənkəran", "Hava limanı GYD", "Şamaxı"];

function personName(rng: Rng): string {
  const first = rng.pick(FIRST);
  return `${first} ${rng.pick(LAST)}${FEMALE.has(first) ? "a" : ""}`;
}

function phoneNumber(rng: Rng): string {
  return `+994 ${rng.pick(["50", "51", "55", "70", "77", "99"])} ${rng.int(200, 999)} ${rng.int(10, 99)} ${rng.int(10, 99)}`;
}

function countFor(page: AdminPage): number {
  if (["users", "trips", "transactions"].includes(page)) return 60;
  if (["vehicles", "fleet", "transferBookings", "hostReviews", "renterReviews"].includes(page)) return 36;
  if (["settings", "tariffs", "zones", "localization", "securityGroups", "adminAccounts", "carData", "evPlans"].includes(page)) return 8;
  return 18;
}

class Generator {
  private serial = 1000;
  private readonly now: number;
  constructor(now: number) {
    this.now = now;
  }

  make(page: AdminPage, module: AdminModule | null, rng: Rng): AdminRecord[] {
    return Array.from({ length: countFor(page) }, (_, i) => this.build(page, module, i, rng))
      .sort((a, b) => b.createdAt - a.createdAt);
  }

  private build(page: AdminPage, module: AdminModule | null, index: number, rng: Rng): AdminRecord {
    this.serial += 1;
    const id = `${module ?? "pl"}-${page}-${this.serial}`;
    const createdAt = this.now - rng.int(60, 60 * 60 * 24 * 30) * 1000;
    const person = personName(rng);
    const phone = phoneNumber(rng);

    const make = (title: string, subtitle: string, status: StatusLabel | null, sections: RecordSection[],
      actions: AdminAction[] = [], trailing: string | null = null): AdminRecord => {
      if (status && sections[0]) sections[0] = { ...sections[0], fields: [F("Status", status.key, status.severity), ...sections[0].fields] };
      return { id, page, module, title, subtitle, status, trailing, sections, actions, createdAt };
    };

    switch (page) {
      case "users":
      case "documentChecks":
      case "staff":
      case "transferDrivers":
      case "adminAccounts": {
        if (page === "users" || page === "documentChecks") {
          const status = page === "documentChecks"
            ? rng.pick([S("Waiting for check", "attention"), S("Waiting for check", "attention"), S("Verified", "good"), S("Rejected", "critical")])
            : rng.pick([S("Active", "good"), S("Active", "good"), S("Active", "good"), S("Waiting for check", "attention"), S("Unverified", "neutral"), S("Blocked", "critical")]);
          const actions = status.key === "Waiting for check" ? [A("verifyDocuments", id), A("rejectDocuments", id)]
            : status.key === "Blocked" ? [A("unblockUser", id)] : [A("blockUser", id)];
          const trips = rng.int(0, 64);
          const debt = rng.chance(0.15) ? rng.int(500, 18_000) : 0;
          return make(person, phone, status, [
            { title: "Profile", fields: [F("Phone", phone), F("Email", person.toLowerCase().replace(" ", ".") + "@mail.az"),
              F("Account type", rng.chance(0.12) ? "Company" : "Personal"), F("Language", rng.pick(["Azərbaycan", "Русский", "English"]))] },
            { title: "Documents", fields: [F("Verification", rng.chance(0.4) ? "MyGov" : "5 photos"),
              F("ID card", rng.chance(0.9) ? "Uploaded" : "Missing"), F("Driving licence", `Valid until ${rng.int(2027, 2034)}`), F("Selfie with ID", "Uploaded")] },
            { title: "Activity", fields: [F("Trips", String(trips)), F("Modules", rng.pick(["EV", "EV · P2P", "Golf", "P2P", "EV · Golf · Transfer"])),
              F("Wallet balance", m(rng.int(0, 9_000))), F("Debt", m(debt), debt > 0 ? "critical" : "neutral")] },
          ], actions, `${trips} trips`);
        }
        const role = page === "transferDrivers" ? "Transfer host"
          : page === "adminAccounts" ? ["admin", "admin", "seabreeze_team", "driver_ev", "driver_golf", "admin", "seabreeze_team", "driver_ev"][index % 8]
          : module === "golf" ? rng.pick(["Sea Breeze team", "Golf driver"]) : "EV driver";
        const status = rng.chance(0.6) ? S("Online", "good") : S("Offline", "neutral");
        return make(person, `${role} · ${phone}`, status, [
          { title: "Account", fields: [F("Role", role), F("Phone", phone), F("Rating", `${rng.float(4.3, 5).toFixed(1)} ★`)] },
        ], [A("blockUser", id)], `${rng.int(0, 300)} jobs`);
      }

      case "vehicles":
      case "listingReviews":
      case "fleet": {
        const isEV = module === "ev";
        const isGolf = page === "fleet";
        const title = isGolf ? `Golf cart ${index + 1}` : rng.pick(isEV ? EV_MODELS : P2P_MODELS);
        const plate = isGolf ? `SB-${String(index + 1).padStart(2, "0")}` : `${rng.pick(["10", "77", "90", "99"])}-${rng.pick(["AB", "BK", "RB", "EV", "ZZ"])}-${rng.int(100, 999)}`;
        const status = page === "listingReviews"
          ? rng.pick([S("In review", "attention"), S("In review", "attention"), S("Live", "good"), S("Needs changes", "neutral")])
          : isGolf ? rng.pick([S("Available", "good"), S("Available", "good"), S("On rental", "info"), S("Blocked", "critical")])
          : isEV ? rng.pick([S("Available", "good"), S("On trip", "info"), S("Charging", "info"), S("Low battery", "attention"), S("Blocked", "critical")])
          : rng.pick([S("Live", "good"), S("Live", "good"), S("On trip", "info"), S("In review", "attention"), S("Paused", "neutral"), S("Blocked", "critical")]);
        const actions = status.key === "In review" ? [A("approveListing", id), A("requestListingChanges", id)]
          : status.key === "Blocked" ? [A("unblockVehicle", id)] : [A("blockVehicle", id)];
        const battery = rng.int(9, 100);
        const price = isEV ? `${m(25)} / dəq` : isGolf ? `${m(3_800)} / saat` : `${m(rng.int(45, 140) * 100)} / gün`;
        const info = [F("Plate", plate), F("Price", price)];
        if (isEV) info.push(F("Battery", `${battery} %`, battery < 20 ? "attention" : "neutral"));
        if (!isEV && !isGolf) info.push(F("Host", personName(rng)));
        return make(title, `${plate} · ${isGolf ? "Sea Breeze" : rng.pick(PLACES)}`, status, [
          { title: "Vehicle", fields: info },
          { title: "Performance", fields: [F("Trips", String(rng.int(0, 140))), F("Earnings", m(rng.int(0, 900_000))),
            F("Rating", `${rng.float(4.1, 5).toFixed(1)} ★`), F("Damage reports", String(rng.int(0, 3)))] },
          { title: "Papers", fields: [F("Insurance", `Valid until ${rng.pick(["03.2027", "11.2026", "07.2027"])}`),
            F("Portal registration", rng.chance(0.85) ? "Registered" : "Missing")] },
        ], actions, isEV ? `${battery} %` : price);
      }

      case "trips":
      case "transferBookings":
      case "reserves":
      case "driverRequests": {
        const golf = module === "golf";
        const from = golf ? rng.pick(SEA_BREEZE) : rng.pick(PLACES);
        const to = golf ? rng.pick(SEA_BREEZE) : page === "transferBookings" ? rng.pick(REGIONS) : rng.pick(PLACES);
        const vehicle = golf ? `Golf cart ${rng.int(1, 24)}` : module === "ev" ? rng.pick(EV_MODELS) : rng.pick(P2P_MODELS);
        const status = page === "reserves" && golf ? rng.pick([S("Pending approval", "attention"), S("Approved", "good"), S("Pending approval", "attention")])
          : page === "reserves" ? rng.pick([S("Active hold", "info"), S("Expired", "neutral")])
          : page === "driverRequests" ? rng.pick([S("Waiting", "attention"), S("Driver assigned", "info"), S("Finished", "good")])
          : rng.pick([S("Finished", "good"), S("Finished", "good"), S("Finished", "good"), S("Ongoing", "info"), S("Cancelled", "neutral"),
            module === "p2p" ? S("Waiting for host", "attention") : S("Upcoming", "info")]);
        const actions = status.key === "Ongoing" ? [A("endTrip", id), A("cancelTrip", id)]
          : status.key === "Pending approval" ? [A("approveBooking", id), A("declineBooking", id)]
          : status.key === "Waiting" ? [A("assignDriver", id), A("declineDriverRequest", id)]
          : ["Waiting for host", "Upcoming", "Active hold"].includes(status.key) ? [A("cancelTrip", id)] : [];
        const minutes = rng.int(8, 240);
        const price = golf ? 3_800 * Math.max(1, Math.floor(minutes / 60)) : rng.int(300, 9_000);
        const trip = [F("Renter", person), F("Phone", phone), F("Vehicle", vehicle), F("From", from), F("To", to), F("Duration", `${minutes} min`)];
        if (page === "driverRequests") trip.push(F("Passengers", String(rng.int(1, 4))), F("Arrival", `about ${rng.pick([5, 10, 15, 20])} min`));
        return make(person, `${vehicle} · ${from} → ${to}`, status, [
          { title: "Trip", fields: trip },
          { title: "Money", fields: [F("Price", m(price)), F("Paid with", rng.pick(["Wallet", "Card ·· 4412", "Apple Pay", "Company invoice"])),
            F("Promo", rng.chance(0.2) ? "FIRST5 · −5,00 ₼" : "None"), F("Fee", page === "transferBookings" ? m(Math.round(price / 10)) : "—")] },
          { title: "Photos", fields: [F("Before", rng.chance(0.9) ? "5 photos" : "Missing"), F("After", status.key === "Finished" ? "6 photos + signature" : "—")] },
        ], actions, m(price));
      }

      case "outstanding": {
        const debt = rng.int(300, 40_000);
        const days = rng.int(1, 60);
        return make(person, phone, days > 14 ? S("Overdue", "critical") : S("Owes", "attention"), [
          { title: "Debt", fields: [F("Amount", m(debt)), F("Days open", String(days)), F("Last trip", rng.pick(EV_MODELS))] },
        ], [A("resolve", id)], m(debt));
      }

      case "damageReports":
      case "parkingWarnings":
      case "opsQueues":
      case "supportInbox":
      case "carChecks": {
        const [kind, detail] = page === "damageReports" ? ["Damage report", rng.pick(["Scratch on rear bumper", "Cracked mirror", "Dirty interior", "Flat tyre"])]
          : page === "parkingWarnings" ? ["Parking warning", rng.pick(["Parked outside the zone", "Blocking a driveway", "Left on a pavement"])]
          : page === "opsQueues" ? ["Cancellation request", rng.pick(["Host cannot hand over", "Renter changed plans", "Car not as listed"])]
          : page === "supportInbox" ? ["Support chat", rng.pick(["Card was charged twice", "Car does not unlock", "How do I extend?", "Refund question"])]
          : ["Car check", rng.pick(P2P_MODELS)];
        const status = page === "parkingWarnings" ? rng.pick([S("Appealed", "attention"), S("Fee charged", "neutral"), S("Warning sent", "info")])
          : page === "carChecks" ? rng.pick([S("Waiting for approval", "attention"), S("Approved", "good"), S("Rejected", "critical")])
          : rng.pick([S("Open", "attention"), S("Open", "attention"), S("Resolved", "good")]);
        const actions = status.severity !== "attention" ? [] : page === "carChecks" ? [A("approveCarCheck", id), A("rejectCarCheck", id)] : [A("resolve", id)];
        return make(detail, `${person} · ${rng.pick(PLACES)}`, status, [
          { title: kind, fields: [F("User", person), F("Phone", phone), F("Details", detail), F("Photos", String(rng.int(0, 4)))] },
        ], actions);
      }

      case "hostReviews":
      case "renterReviews": {
        const rating = rng.int(1, 5);
        const flagged = rating <= 2;
        const text = flagged ? rng.pick(["Car was late and dirty", "Rude on handover", "Smelled of smoke"])
          : rng.pick(["Great car, easy handover", "Clean and on time", "Would rent again", "Helpful host"]);
        return make("★".repeat(rating) + "☆".repeat(5 - rating), `${person} · ${text}`, flagged ? S("Flagged", "attention") : S("Published", "good"), [
          { title: "Review", fields: [F("Author", person), F("Rating", `${rating} / 5`), F("Text", text)] },
        ], flagged ? [A("hideReview", id), A("resolve", id)] : [A("hideReview", id)], `${rating}.0`);
      }

      case "transactions":
      case "payouts": {
        const amount = rng.int(200, 20_000);
        const method = rng.pick(["Wallet", "Card ·· 4412", "Apple Pay", "Company invoice"]);
        return make(m(amount), `${person} · ${method}`, rng.pick([S("Paid", "good"), S("Paid", "good"), S("Paid", "good"), S("Refunded", "neutral"), S("Failed", "critical")]), [
          { title: "Payment", fields: [F("Payer", person), F("Method", method), F("Gateway", rng.pick(["Kapital Bank", "Pasha Pay"])), F("Reference", `TX${rng.int(100_000, 999_999)}`)] },
        ], [], m(amount));
      }

      case "notifications":
      case "news": {
        const title = rng.pick(["Weekend −20 % on EV", "New cars near Sahil", "Golf season opens", "App update 3.2", "Parking rules changed"]);
        const audience = rng.pick(["All users", "EV riders", "Hosts", "Golf guests"]);
        return make(title, `${audience} · ${rng.pick(["Push", "Push + News card"])}`, rng.pick([S("Sent", "good"), S("Scheduled", "info"), S("Draft", "neutral")]), [
          { title: "Message", fields: [F("Audience", audience), F("Opened", `${rng.int(12, 61)} %`)] },
        ], [], `${rng.int(200, 9_000)} users`);
      }

      case "promoCodes": {
        const code = rng.pick(["FIRST5", "SAHIL20", "GOLF10", "WEEKEND", "HOST15", "BAKU25"]) + index;
        const active = rng.chance(0.7);
        return make(code, rng.pick(["−5,00 ₼ first ride", "−20 % weekend", "−10 % golf hourly"]), active ? S("Active", "good") : S("Expired", "neutral"), [
          { title: "Promo", fields: [F("Code", code), F("Limit", String(rng.int(100, 1_000))), F("Valid until", `${rng.int(10, 28)}.12.2026`)] },
        ], active ? [A("deactivatePromo", id)] : [], `${rng.int(0, 400)} used`);
      }

      case "evPlans": {
        const plan = ["Weekly · 300 min", "Weekly · 600 min", "Monthly · 1 000 min", "Monthly · 2 000 min", "Monthly · 3 000 min",
          "Yearly · 12 000 min", "Yearly · 24 000 min", "Monthly · 500 min"][index % 8];
        return make(plan, `${rng.int(5, 140)} active subscribers`, S("On sale", "good"), [
          { title: "Plan", fields: [F("Discount", "−30 %"), F("Renews", "Automatically")] },
        ], [], m(rng.int(40, 900) * 100));
      }

      case "tariffs": {
        const names = ["Per minute", "Hourly", "Daily", "With driver", "Golf hourly", "Golf daily", "Night", "Weekend"];
        const prices = [25, 900, 6_900, 3_500, 3_800, 18_000, 20, 7_900];
        return make(names[index % 8], module ? PAGE_TITLE.tariffs : "", S("Active", "good"), [
          { title: "Tariff", fields: [F("Applies to", module ?? "All")] },
        ], [], m(prices[index % 8]));
      }

      case "zones": {
        const zone = ["City centre", "Airport GYD", "Sea Breeze resort", "White City", "Port Baku", "No-parking: Fountain Sq.", "Bayıl", "Nərimanov"][index % 8];
        const alert = index === 5;
        return make(zone, alert ? "Alert area" : "Parking area", alert ? S("Alert", "attention") : S("Active", "good"), [
          { title: "Zone", fields: [F("Type", alert ? "Alert" : "Parking"), F("Cars inside", String(rng.int(0, 20)))] },
        ]);
      }

      case "transferRoutes": {
        const from = rng.pick(PLACES);
        const to = rng.pick(REGIONS);
        return make(`${from} → ${to}`, `${person} · ${rng.int(1, 4)} seats left`, rng.chance(0.75) ? S("Live", "good") : S("Paused", "neutral"), [
          { title: "Route", fields: [F("Driver", person), F("Departure", `${rng.int(7, 21)}:00`), F("Cancellation", rng.pick(["Flexible", "Strict"]))] },
        ], [], `${m(rng.int(800, 4_000))} / yer`);
      }

      case "companies": {
        const company = rng.pick(["Azər Logistics MMC", "Caspian Media", "Baku Build", "Gilan Travel", "Green Energy"]) + ` ${index + 1}`;
        return make(company, `VÖEN ${rng.int(1_000_000_000, 1_999_999_999)}`, S("Active", "good"), [
          { title: "Company", fields: [F("Team", `${rng.int(3, 40)}`), F("Invoice e-mail", "finance@company.az"), F("Monthly limit", m(50_000))] },
        ], [], m(rng.int(20_000, 900_000)));
      }

      case "securityGroups": {
        const group = ["Owners", "Operations", "Finance", "Support", "Sea Breeze team", "Drivers · EV", "Drivers · Golf", "Read only"][index];
        return make(group, `${rng.int(3, 60)} permissions`, S("Active", "good"), [
          { title: "Group", fields: [F("Can write", index < 4 ? "Yes" : "Own module only")] },
        ], [], `${rng.int(1, 12)} people`);
      }

      case "localization": {
        const file = ["Azərbaycan · app", "Русский · app", "English · app", "Azərbaycan · push", "Русский · push", "English · push", "Azərbaycan · legal", "Русский · legal"][index];
        return make(file, "853 strings", index % 3 === 1 ? S("12 missing", "attention") : S("Complete", "good"), [
          { title: "File", fields: [F("Updated", new Date(createdAt).toLocaleDateString("az-AZ"))] },
        ]);
      }

      case "carData": {
        const make_ = ["Toyota", "Hyundai", "Kia", "BYD", "Chevrolet", "Mercedes-Benz", "Tesla", "Zeekr"][index];
        const models = rng.int(4, 40);
        return make(make_, `${models} models · 2010–2026`, S("Active", "good"), [{ title: "Make", fields: [F("Models", String(models))] }]);
      }

      case "settings": {
        const group = ["General", "Deposits", "Access rules", "Rush tariffs", "Tier discounts", "Telegram check bot", "Insurance", "App versions"][index];
        return make(group, "", null, [{ title: group, fields: [F("Value", rng.pick(["On", "Off", "50,00 ₼", "15 min", "3.2.0"]))] }]);
      }

      default:
        return make(PAGE_TITLE[page], "", null, []);
    }
  }
}

/** What each action does to a record's status and next actions. */
export function outcomeOf(action: AdminAction): [StatusLabel, AdminAction[]] {
  const id = action.target;
  switch (action.kind) {
    case "blockUser": return [S("Blocked", "critical"), [A("unblockUser", id)]];
    case "unblockUser": return [S("Active", "good"), [A("blockUser", id)]];
    case "verifyDocuments": return [S("Verified", "good"), [A("blockUser", id)]];
    case "rejectDocuments": return [S("Rejected", "critical"), [A("verifyDocuments", id)]];
    case "approveListing": return [S("Live", "good"), [A("blockVehicle", id)]];
    case "requestListingChanges": return [S("Needs changes", "neutral"), [A("approveListing", id)]];
    case "blockVehicle": return [S("Blocked", "critical"), [A("unblockVehicle", id)]];
    case "unblockVehicle": return [S("Available", "good"), [A("blockVehicle", id)]];
    case "approveBooking": return [S("Approved", "good"), [A("cancelTrip", id)]];
    case "declineBooking": return [S("Declined", "critical"), []];
    case "cancelTrip": return [S("Cancelled", "neutral"), []];
    case "endTrip": return [S("Finished", "good"), []];
    case "assignDriver": return [S("Driver assigned", "info"), []];
    case "declineDriverRequest": return [S("Declined", "critical"), []];
    case "approveCarCheck": return [S("Approved", "good"), []];
    case "rejectCarCheck": return [S("Rejected", "critical"), [A("approveCarCheck", id)]];
    case "resolve": return [S("Resolved", "good"), []];
    case "hideReview": return [S("Hidden", "neutral"), []];
    case "deactivatePromo": return [S("Inactive", "neutral"), []];
  }
}

function matches(record: AdminRecord, needle: string): boolean {
  return [record.title, record.subtitle, record.id, ...record.sections.flatMap((s) => s.fields.map((f) => f.value))]
    .some((text) => text.toLowerCase().includes(needle));
}

const INBOX_SOURCES: [AdminPage, AdminModule | null, QueueKind][] = [
  ["documentChecks", null, "documentCheck"],
  ["listingReviews", null, "listingReview"],
  ["supportInbox", null, "supportChat"],
  ["reserves", "golf", "golfBooking"],
  ["driverRequests", "golf", "golfDriverRequest"],
  ["parkingWarnings", "ev", "parkingAppeal"],
  ["damageReports", "ev", "damageReport"],
  ["opsQueues", "p2p", "cancellationRequest"],
  ["carChecks", "transfer", "transferCarCheck"],
];

export class SampleAdminService implements AdminService {
  private store = new Map<string, AdminRecord>();
  private lists = new Map<string, string[]>();
  private readonly now: number;
  private readonly latency: number;

  constructor(options: { seed?: number; now?: number; latency?: number } = {}) {
    this.now = options.now ?? Date.now();
    this.latency = options.latency ?? 200;
    const rng = new Rng(options.seed ?? 2026);
    const generator = new Generator(this.now);
    const add = (page: AdminPage, module: AdminModule | null) => {
      const made = generator.make(page, module, rng);
      this.lists.set(this.key(page, module), made.map((r) => r.id));
      for (const record of made) this.store.set(record.id, record);
    };
    for (const [module, pages] of Object.entries(MODULE_PAGES) as [AdminModule, AdminPage[]][]) {
      for (const page of pages) if (!CUSTOM_PAGES.includes(page)) add(page, module);
    }
    for (const page of PLATFORM_PAGES) add(page, null);
  }

  private key(page: AdminPage, module: AdminModule | null) {
    return `${page}|${isPlatformPage(page) ? "" : module ?? ""}`;
  }

  private list(page: AdminPage, module: AdminModule | null): AdminRecord[] {
    return (this.lists.get(this.key(page, module)) ?? []).map((id) => this.store.get(id)!).filter(Boolean);
  }

  private pause() {
    return this.latency > 0 ? new Promise((resolve) => setTimeout(resolve, this.latency)) : Promise.resolve();
  }

  async signIn(email: string, password: string): Promise<AdminSession> {
    await this.pause();
    const trimmed = email.trim();
    if (!trimmed.includes("@") || password.length < 4) throw new Error("Email or password is wrong.");
    const name = trimmed.split("@")[0].replace(/[._]/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
    return { name, email: trimmed, sample: true };
  }

  async overview(module: AdminModule): Promise<ModuleOverview> {
    await this.pause();
    const trips = [...this.list("trips", module), ...this.list("transferBookings", module)];
    const badges: Partial<Record<AdminPage, number>> = {};
    for (const page of MODULE_PAGES[module]) {
      const count = this.list(page, module).filter((r) => r.status?.severity === "attention").length;
      if (count > 0) badges[page] = count;
    }
    const rng = new Rng(11 + ["p2p", "ev", "golf", "transfer"].indexOf(module));
    const trend = Array.from({ length: 14 }, (_, i) => 900 + i * 38 + rng.int(0, 260));
    const items = (await this.inbox()).filter((q) => q.module === module);
    return {
      module,
      liveNow: trips.filter((r) => r.status?.key === "Ongoing").length,
      liveCaption: module === "golf" ? "carts out now" : module === "transfer" ? "rides on the road" : "trips on the road",
      revenueTodayMinor: Math.round(trend[trend.length - 1] * 100),
      revenueTrend: trend,
      kpis: this.kpis(module),
      needsAttention: items.slice(0, 4),
      recent: trips.slice(0, 5),
      pageBadges: badges,
      updatedAt: Date.now(),
    };
  }

  private kpis(module: AdminModule): Kpi[] {
    const n = (page: AdminPage, severity?: Severity) =>
      this.list(page, module).filter((r) => !severity || r.status?.severity === severity).length;
    const sev = (count: number, when: Severity = "attention"): Severity => (count > 0 ? when : "good");
    switch (module) {
      case "p2p": return [
        { title: "Users", value: String(n("users")), caption: `${n("users", "attention")} · Waiting for check`, severity: sev(n("users", "attention")), opens: "users" },
        { title: "Listed cars", value: String(n("vehicles")), caption: `${n("vehicles", "attention")} · In review`, severity: "neutral", opens: "vehicles" },
        { title: "Trips", value: String(n("trips")), caption: `${n("trips", "attention")} · Waiting for host`, severity: "neutral", trend: [4, 6, 5, 8, 7, 9, 11], opens: "trips" },
        { title: "Reviews to check", value: String(n("hostReviews", "attention") + n("renterReviews", "attention")), severity: "attention", opens: "hostReviews" },
      ];
      case "ev": return [
        { title: "Fleet", value: String(n("vehicles")), caption: `${n("vehicles", "attention")} · Low battery`, severity: sev(n("vehicles", "attention")), opens: "map" },
        { title: "Trips", value: String(n("trips")), severity: "neutral", trend: [22, 25, 21, 30, 34, 31, 38], opens: "trips" },
        { title: "Reserves", value: String(n("reserves")), caption: "active holds", severity: "neutral", opens: "reserves" },
        { title: "Outstanding debt", value: String(n("outstanding")), caption: "users owe money", severity: "critical", opens: "outstanding" },
        { title: "Damage reports", value: String(n("damageReports", "attention")), caption: "open", severity: sev(n("damageReports", "attention")), opens: "damageReports" },
        { title: "Parking warnings", value: String(n("parkingWarnings", "attention")), caption: "appeals to review", severity: "neutral", opens: "parkingWarnings" },
      ];
      case "golf": return [
        { title: "Carts", value: String(n("fleet")), caption: `${n("fleet", "critical")} · Blocked`, severity: "neutral", opens: "fleet" },
        { title: "Bookings to approve", value: String(n("reserves", "attention")), severity: sev(n("reserves", "attention")), opens: "reserves" },
        { title: "Driver requests", value: String(n("driverRequests", "attention")), caption: "waiting for the Sea Breeze team", severity: "attention", opens: "driverRequests" },
        { title: "Trips", value: String(n("trips")), severity: "neutral", trend: [9, 12, 10, 14, 18, 22, 19], opens: "trips" },
      ];
      case "transfer": return [
        { title: "Live routes", value: String(n("transferRoutes", "good")), severity: "neutral", opens: "transferRoutes" },
        { title: "Bookings", value: String(n("transferBookings")), severity: "neutral", trend: [2, 3, 3, 5, 4, 6, 8], opens: "transferBookings" },
        { title: "Car checks", value: String(n("carChecks", "attention")), caption: "waiting for approval", severity: "attention", opens: "carChecks" },
        { title: "Drivers", value: String(n("transferDrivers")), severity: "neutral", opens: "transferDrivers" },
      ];
    }
  }

  async investor(module: AdminModule): Promise<InvestorSnapshot> {
    await this.pause();
    const scale = { ev: 1, p2p: 1.6, golf: 0.45, transfer: 0.3 }[module];
    const gmv = ["Apr", "May", "Jun", "Jul", "Aug", "Sep"].map((label, i) => ({ label, value: (18_000 + i * i * 2_100) * scale }));
    const last = gmv[gmv.length - 1].value;
    const previous = gmv[gmv.length - 2].value;
    return {
      module,
      gmvThisMonthMinor: Math.round(last * 100),
      gmvGrowth: (last - previous) / previous,
      gmvByMonth: gmv,
      activeUsers30d: Math.round(1_240 * scale),
      activeTrend: Array.from({ length: 12 }, (_, i) => 400 + i * i * 6 * scale),
      retention30d: 0.41 + (0.04 * scale) / 1.6,
      utilization: module === "golf" ? 0.62 : 0.34 * scale,
      takeRate: module === "p2p" || module === "transfer" ? 0.1 : 1,
      revenuePerTripMinor: Math.round((module === "golf" ? 38 : 14.6 * scale) * 100),
      funnel: [
        { label: "Registered", count: Math.round(3_900 * scale) },
        { label: "Documents verified", count: Math.round(2_300 * scale) },
        { label: "First trip", count: Math.round(1_450 * scale) },
        { label: "Second trip", count: Math.round(880 * scale) },
        { label: "Active in 30 days", count: Math.round(1_240 * scale) },
      ],
      mix: module === "golf" ? [{ label: "Hourly", share: 0.58 }, { label: "Daily", share: 0.27 }, { label: "With driver", share: 0.15 }]
        : module === "ev" ? [{ label: "Per minute", share: 0.46 }, { label: "Hourly", share: 0.22 }, { label: "Daily", share: 0.12 }, { label: "EV plans", share: 0.12 }, { label: "With driver", share: 0.08 }]
        : [{ label: "Personal hosts", share: 0.63 }, { label: "Commercial hosts", share: 0.37 }],
      tripsByHour: Array.from({ length: 24 }, (_, h) =>
        Math.round((Math.exp(-((h - 18) ** 2) / 18) + 0.6 * Math.exp(-((h - 9) ** 2) / 8)) * 40 * scale)),
    };
  }

  async records(page: AdminPage, module: AdminModule | null, query: ListQuery = {}): Promise<PageResult<AdminRecord>> {
    await this.pause();
    const needle = (query.text ?? "").trim().toLowerCase();
    const searched = needle ? this.list(page, module).filter((r) => matches(r, needle)) : this.list(page, module);
    const statusCounts: Record<string, number> = {};
    for (const r of searched) if (r.status) statusCounts[r.status.key] = (statusCounts[r.status.key] ?? 0) + 1;
    const filtered = query.status ? searched.filter((r) => r.status?.key === query.status) : searched;
    const end = (query.page ?? 1) * (query.pageSize ?? 30);
    return { items: filtered.slice(0, end), total: filtered.length, statusCounts };
  }

  async record(id: string): Promise<AdminRecord> {
    await this.pause();
    const record = this.store.get(id);
    if (!record) throw new Error("This item no longer exists.");
    return record;
  }

  async inbox(): Promise<QueueItem[]> {
    const items: QueueItem[] = [];
    for (const [page, module, kind] of INBOX_SOURCES) {
      for (const r of this.list(page, module)) {
        if (r.status?.severity !== "attention") continue;
        items.push({ id: `q-${r.id}`, kind, module: module ?? r.module, title: r.title, subtitle: r.subtitle,
          createdAt: r.createdAt, urgent: this.now - r.createdAt > 3 * 3600_000, recordId: r.id });
      }
    }
    return items.sort((a, b) => b.createdAt - a.createdAt);
  }

  async mapPins(module: AdminModule): Promise<MapPin[]> {
    await this.pause();
    const rng = new Rng(77);
    const [lat, lng, spread] = module === "golf" ? [40.589, 50.003, 0.006] : [40.3953, 49.8822, 0.05];
    return this.list(module === "golf" ? "fleet" : "vehicles", module).map((r) => ({
      id: r.id, title: r.title,
      lat: lat + rng.float(-spread, spread), lng: lng + rng.float(-spread * 1.4, spread * 1.4),
      status: r.status ?? S("Available", "good"),
      battery: module === "ev" ? rng.int(8, 100) : null,
    }));
  }

  async search(text: string): Promise<AdminRecord[]> {
    await this.pause();
    const needle = text.trim().toLowerCase();
    if (needle.length < 2) return [];
    return [...this.store.values()].filter((r) => matches(r, needle)).sort((a, b) => b.createdAt - a.createdAt).slice(0, 40);
  }

  async perform(action: AdminAction): Promise<AdminRecord> {
    await this.pause();
    const record = this.store.get(action.target);
    if (!record) throw new Error("This item no longer exists.");
    const [status, actions] = outcomeOf(action);
    const updated: AdminRecord = {
      ...record,
      status,
      actions,
      sections: record.sections.map((s) => ({
        ...s,
        fields: s.fields.map((f) => (f.label === "Status" ? F("Status", status.key, status.severity) : f)),
      })),
    };
    this.store.set(updated.id, updated);
    return updated;
  }
}
