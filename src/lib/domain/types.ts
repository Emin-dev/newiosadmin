// Domain model of the admin panel. Pure TypeScript, no React, no browser APIs.
// Every English string here is a translation key (see src/lib/i18n).

export const MODULES = ["p2p", "ev", "golf", "transfer"] as const;
export type AdminModule = (typeof MODULES)[number];

export type ViewMode = "ceo" | "investor";

export const MODULE_INFO: Record<AdminModule, { title: string; long: string; icon: string }> = {
  p2p: { title: "P2P", long: "Car rental (P2P)", icon: "🚗" },
  ev: { title: "EV", long: "Electric carsharing", icon: "⚡" },
  golf: { title: "Golf", long: "Golf · Sea Breeze", icon: "⛳" },
  transfer: { title: "Transfer", long: "Transfer marketplace", icon: "🛣️" },
};

export const PAGES = [
  // module pages
  "overview", "users", "vehicles", "trips", "map", "reserves", "outstanding", "damageReports", "statistics",
  "hostReviews", "renterReviews", "opsQueues", "notifications", "promoCodes", "settings",
  "evPlans", "parkingWarnings", "driverRequests", "fleet", "transactions", "tariffs", "zones", "staff",
  "transferRoutes", "transferBookings", "transferDrivers", "carChecks", "payouts",
  // platform pages
  "documentChecks", "listingReviews", "supportInbox", "companies", "news",
  "adminAccounts", "securityGroups", "localization", "carData",
] as const;
export type AdminPage = (typeof PAGES)[number];

export const PAGE_TITLE: Record<AdminPage, string> = {
  overview: "Overview", users: "Users", vehicles: "Vehicles", trips: "Trips", map: "Map",
  reserves: "Reserves", outstanding: "Outstanding debt", damageReports: "Damage reports",
  statistics: "Statistics", hostReviews: "Host reviews", renterReviews: "Renter reviews",
  opsQueues: "Ops queues", notifications: "Notifications", promoCodes: "Promo codes", settings: "Settings",
  evPlans: "EV plans", parkingWarnings: "Parking warnings", driverRequests: "Driver requests", fleet: "Fleet",
  transactions: "Transactions", tariffs: "Tariffs", zones: "Zones", staff: "Staff & drivers",
  transferRoutes: "Routes", transferBookings: "Bookings", transferDrivers: "Drivers", carChecks: "Car checks",
  payouts: "Payouts & fees", documentChecks: "Document checks", listingReviews: "Listing reviews",
  supportInbox: "Support inbox", companies: "Company accounts", news: "News & push",
  adminAccounts: "Admins & roles", securityGroups: "Security groups", localization: "Localization", carData: "Car data",
};

/** Emoji-free glyph names map to inline SVG icons in the UI (src/components/Icon.tsx). */
export const PAGE_ICON: Record<AdminPage, string> = {
  overview: "grid", users: "users", vehicles: "car", trips: "route", map: "map", reserves: "clock",
  outstanding: "alert", damageReports: "wrench", statistics: "chart", hostReviews: "star", renterReviews: "star",
  opsQueues: "tray", notifications: "bell", promoCodes: "ticket", settings: "gear", evPlans: "calendar",
  parkingWarnings: "parking", driverRequests: "steering", fleet: "cart", transactions: "card", tariffs: "tag",
  zones: "pin", staff: "badge", transferRoutes: "route", transferBookings: "ticket", transferDrivers: "steering",
  carChecks: "check", payouts: "banknote", documentChecks: "id", listingReviews: "search", supportInbox: "chat",
  companies: "building", news: "megaphone", adminAccounts: "key", securityGroups: "shield", localization: "globe",
  carData: "list",
};

/** Pages in the order the live panel shows them. Overview first, Settings last. */
export const MODULE_PAGES: Record<AdminModule, AdminPage[]> = {
  p2p: ["overview", "users", "vehicles", "trips", "hostReviews", "renterReviews", "opsQueues", "notifications", "promoCodes", "settings"],
  ev: ["overview", "users", "vehicles", "trips", "map", "reserves", "outstanding", "damageReports", "statistics", "evPlans", "parkingWarnings", "staff", "settings"],
  golf: ["overview", "trips", "reserves", "driverRequests", "fleet", "transactions", "tariffs", "promoCodes", "zones", "staff", "settings"],
  transfer: ["overview", "transferRoutes", "transferBookings", "transferDrivers", "carChecks", "payouts", "settings"],
};

/** Pages that belong to no single module. */
export const PLATFORM_PAGES: AdminPage[] = [
  "documentChecks", "listingReviews", "supportInbox", "companies", "news",
  "adminAccounts", "securityGroups", "localization", "carData",
];

/** Pages with their own screen; every other page is a record list. */
export const CUSTOM_PAGES: AdminPage[] = ["overview", "map", "statistics"];

export const isPlatformPage = (page: AdminPage) => PLATFORM_PAGES.includes(page);

// ---------- records ----------

export type Severity = "neutral" | "good" | "attention" | "critical" | "info";

export interface StatusLabel {
  key: string;
  severity: Severity;
}

export interface RecordField {
  label: string;
  value: string;
  severity?: Severity;
}

export interface RecordSection {
  title: string;
  fields: RecordField[];
}

/** One row of any list page plus everything its detail view shows. */
export interface AdminRecord {
  id: string;
  page: AdminPage;
  module: AdminModule | null;
  title: string;
  subtitle: string;
  status: StatusLabel | null;
  trailing: string | null;
  sections: RecordSection[];
  actions: AdminAction[];
  createdAt: number;
}

export interface ListQuery {
  text?: string;
  status?: string | null;
  page?: number;
  pageSize?: number;
}

export interface PageResult<T> {
  items: T[];
  total: number;
  statusCounts: Record<string, number>;
}

// ---------- actions ----------

export const ACTION_KINDS = {
  blockUser: { label: "Block user", destructive: true },
  unblockUser: { label: "Unblock user", destructive: false },
  verifyDocuments: { label: "Verify documents", destructive: false },
  rejectDocuments: { label: "Reject documents", destructive: true },
  approveListing: { label: "Approve listing", destructive: false },
  requestListingChanges: { label: "Request changes", destructive: false },
  blockVehicle: { label: "Block vehicle", destructive: true },
  unblockVehicle: { label: "Unblock vehicle", destructive: false },
  approveBooking: { label: "Approve and assign", destructive: false },
  declineBooking: { label: "Decline booking", destructive: true },
  cancelTrip: { label: "Cancel trip", destructive: true },
  endTrip: { label: "End trip", destructive: false },
  assignDriver: { label: "Assign driver", destructive: false },
  declineDriverRequest: { label: "Decline request", destructive: true },
  approveCarCheck: { label: "Approve car check", destructive: false },
  rejectCarCheck: { label: "Reject car check", destructive: true },
  resolve: { label: "Mark resolved", destructive: false },
  hideReview: { label: "Hide review", destructive: true },
  deactivatePromo: { label: "Deactivate promo", destructive: true },
} as const;
export type ActionKind = keyof typeof ACTION_KINDS;

export interface AdminAction {
  kind: ActionKind;
  target: string;
}

// ---------- dashboards ----------

export interface Kpi {
  title: string;
  value: string;
  caption?: string;
  severity: Severity;
  trend?: number[];
  opens?: AdminPage;
}

export interface QueueItem {
  id: string;
  kind: QueueKind;
  module: AdminModule | null;
  title: string;
  subtitle: string;
  createdAt: number;
  urgent: boolean;
  recordId: string;
}

export const QUEUE_KINDS = {
  documentCheck: { title: "Document check", page: "documentChecks" },
  listingReview: { title: "Listing review", page: "listingReviews" },
  golfBooking: { title: "Golf booking", page: "reserves" },
  golfDriverRequest: { title: "Golf driver request", page: "driverRequests" },
  parkingAppeal: { title: "Parking appeal", page: "parkingWarnings" },
  supportChat: { title: "Support chat", page: "supportInbox" },
  transferCarCheck: { title: "Transfer car check", page: "carChecks" },
  cancellationRequest: { title: "Cancellation request", page: "opsQueues" },
  damageReport: { title: "Damage report", page: "damageReports" },
} as const satisfies Record<string, { title: string; page: AdminPage }>;
export type QueueKind = keyof typeof QUEUE_KINDS;

export interface ModuleOverview {
  module: AdminModule;
  liveNow: number;
  liveCaption: string;
  revenueTodayMinor: number;
  revenueTrend: number[];
  kpis: Kpi[];
  needsAttention: QueueItem[];
  recent: AdminRecord[];
  pageBadges: Partial<Record<AdminPage, number>>;
  updatedAt: number;
}

export interface InvestorSnapshot {
  module: AdminModule;
  gmvThisMonthMinor: number;
  gmvGrowth: number;
  gmvByMonth: { label: string; value: number }[];
  activeUsers30d: number;
  activeTrend: number[];
  retention30d: number;
  utilization: number;
  takeRate: number;
  revenuePerTripMinor: number;
  funnel: { label: string; count: number }[];
  mix: { label: string; share: number }[];
  tripsByHour: number[];
}

export interface MapPin {
  id: string;
  title: string;
  lat: number;
  lng: number;
  status: StatusLabel;
  battery: number | null;
}

export interface AdminSession {
  name: string;
  email: string;
  sample: boolean;
}

/**
 * The contract between the panel and the backend. Written from the panel's needs
 * first; the new backend will implement it. Screens only ever use this interface.
 */
export interface AdminService {
  signIn(email: string, password: string): Promise<AdminSession>;
  overview(module: AdminModule): Promise<ModuleOverview>;
  investor(module: AdminModule): Promise<InvestorSnapshot>;
  records(page: AdminPage, module: AdminModule | null, query: ListQuery): Promise<PageResult<AdminRecord>>;
  record(id: string): Promise<AdminRecord>;
  inbox(): Promise<QueueItem[]>;
  mapPins(module: AdminModule): Promise<MapPin[]>;
  search(text: string): Promise<AdminRecord[]>;
  perform(action: AdminAction): Promise<AdminRecord>;
}
