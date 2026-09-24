# Rentbutik Admin (iOS)

Native iPhone app for Rentbutik admins. It replaces the web admin panel
(`Emin-dev/rentbutik-admin`) with the same structure and a bento design that
follows the main app's design system.

- Who uses it: Rentbutik admins only, with full access. CEO view (operations) and Investor view (growth story).
- Staff and drivers do not use this app. The Sea Breeze team, EV drivers, golf drivers and transfer hosts work in the main Rentbutik app (Host module).
- iPhone only, iOS 27. Languages: Azərbaycan (default), Русский, English.
- Data: the new backend is not built yet. The app runs on `SampleAdminService`, clearly labelled "Sample data".

## Run

```bash
brew install xcodegen
xcodegen generate
open RentbutikAdmin.xcodeproj
```

Sign in with any email and a password of 4+ characters (sample mode).
CI builds and tests every push on GitHub Actions (`.github/workflows/ios.yml`).

## Structure

```
App/                         app target: entry point, app icon
Packages/AdminKit/
  Sources/DesignSystem/      tokens (Theme), haptics, bento components. Shared values with the main app.
  Sources/AdminDomain/       models, AdminService protocol, sample data, CSV. Pure Swift, no UI.
  Sources/AdminFeatures/     screens. Home (CEO / Investor), Inbox, Platform, Search, lists, details, map.
  Tests/AdminDomainTests/    Swift Testing
docs/PARITY.md               every old panel feature and its status here
scripts/strings.py           generates the AZ / RU string catalogue
```

Rules the code follows:

- Screens talk only to the `AdminService` protocol. Swapping sample data for the real API changes one line in `RootView`.
- One list screen (`RecordListView`) serves every list page: search, status chips, paging, swipe action, CSV export. One detail screen serves every record.
- Every write goes through `AppModel.perform`: the Actions lock must be open (Face ID, 15 minutes) and the admin confirms first.
- Money is always minor units (`Money.minor`, qəpik). Shown as "16,00 ₼" in AZ and RU, "₼16.00" in EN.
- Design tokens mirror `Rentbutik/Design/Theme.swift` in `Emin-dev/figma`. Change both together.
- Swift 6 strict concurrency, `@Observable`, `NavigationStack`, SF Symbols only.

## Navigation

| Tab | Content |
|---|---|
| Home | Module switch (P2P, EV, Golf, Transfer), CEO / Investor switch, dashboard, every page of the module as a tile with its live count |
| Inbox | Everything waiting for an admin: document checks, listing reviews, golf bookings, driver requests, parking appeals, support, transfer car checks, cancellations, damage reports |
| Platform | Pages that belong to no single module (documents, listings, support, companies, news, admins and roles, security groups, localization, car data) and app settings |
| Search | Every record by name, phone, plate, promo code or ID |

## Not done yet

See `docs/PARITY.md`. The backend contract (`AdminService`) comes first; the API will be designed from it.
The app icon asset is empty: the only source logo is 512 px, the icon needs 1024 px.
