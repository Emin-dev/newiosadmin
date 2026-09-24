# Parity checklist

> Written for the first (SwiftUI) version. The web version in this repo has the same scope; Map and Statistics pages are not built yet in the web version. See docs/PLAN.md.

Every feature of the old web panel must exist in this app. Sources:

- Old panel code: `Emin-dev/rentbutik-admin` (20 pages, state on 17.07.2026).
- Live panel `admin.dev.rentbutik.com` (screenshot 24.09.2026): extra P2P pages Host reviews, Renter reviews, Promo Codes, Security Groups, Notifications, Car Data, Localization, Filters.
- New admin features that the new app design needs (Figma `Ereat5qYENeSKTvW473gn5`).

Status: ✅ built on sample data · 🟡 partly built · ⬜ not built yet.
"Built" means the screen, list, detail and actions work against `AdminService`. The data is sample data until the new backend exists.

## Shell (old header)

| Old panel | New app | Status |
|---|---|---|
| Module switch P2P / EV / Golf | Segmented control on Home, plus Transfer | ✅ |
| Investor / CEO switch | Toolbar menu on Home | ✅ |
| Global search (name, phone, user id) | Search tab, all records | ✅ |
| Live indicator with 60 s heartbeat | "Updated hh:mm" on the live tile, pull to refresh | 🟡 no auto refresh yet |
| Actions off / ON, auto-off after 15 min | Lock button, Face ID to unlock, auto-lock after 15 min, confirm before every write | ✅ |
| Export CSV (visible rows, formula-injection safe) | Share button on every list | ✅ |
| Admin name and role | Account menu | ✅ |
| Sign out | Account menu and Platform tab | ✅ |
| Light / dark | System / Light / Dark | ✅ |
| Deep links `#module/view/page/id` | — | ⬜ |
| Nav badges (reserves, outstanding) | Counts on page tiles and the Inbox tab badge | ✅ |

## EV

| Old page | What it had | Status |
|---|---|---|
| Overview (CEO) | Fleet board, fleet right now, on the road now, needs attention | ✅ live tile, KPI tiles, needs-you list, recent trips |
| Users | List, filters, search | ✅ |
| User detail | Account, EV/Golf status, trips, reserves, transactions, payment cards, misconduct records, logs, status history | 🟡 profile, documents, activity; ⬜ cards, misconduct, logs, EV/Golf status change |
| Vehicles | List | ✅ |
| Vehicle detail | Battery and range, location, trips, earnings, damage, admin comments, availability windows, reserve car, doors / engine / windows control (Geotek), trip event logs, portal registration log, photos | 🟡 info, performance, papers, block; ⬜ remote control, availability, comments, logs, photos |
| Trips | List and detail | ✅ |
| Map | Live fleet, parking areas, alert areas, trip start / end points | 🟡 live fleet with status filter; ⬜ areas, trip points |
| Reserves | Active holds | ✅ |
| Outstanding | Riders with debt | ✅ |
| Damage reports | All reports | ✅ |
| Statistics | Main statistics, intervals between trips, time of day, hourly breakdown, unique users, custom date range | 🟡 time of day, by hour, unique riders; ⬜ intervals, date range |
| Settings | EV settings, rush tariffs, extra tariffs, Telegram check bot, admins group | 🟡 settings groups as records; ⬜ editing |
| Investor view | Activation funnel, active users, day mix, demand gaps, fleet mix, marketplace health, revenue by month, trips by hour, value of a rider, risk | 🟡 bookings trend, active riders, retention, utilisation, revenue per trip, funnel, mix, by hour; ⬜ demand gaps, risk, value of a rider |

## P2P

| Old page | What it had | Status |
|---|---|---|
| Overview (CEO) | Fleet board, needs attention | ✅ |
| Users | List, filters (first name, last name, phone) | ✅ search covers all three |
| User detail | Contact info, documents (ID, licence, selfie, power of attorney), insurance details, misconduct log, internal comment, wallet activity, portal logs, host and renter trips, listed vehicles, status P2P / EV / Golf | 🟡 profile, documents, activity, block, verify; ⬜ insurance, misconduct, comments, wallet log, portal logs |
| Vehicles | List | ✅ |
| Vehicle detail | Availabilities, insurance policy, portal car-sharing service, trips | 🟡 info, papers, block, approve; ⬜ availabilities |
| Trips | List | ✅ |
| Trip detail | Check-in, check-out, odometer, card operations, finish payment, gateway response, insurance log, portal paper, price breakdown, cancellation requests, damage reports, reviews, trip logs | 🟡 trip, money, photos, cancel / end; ⬜ check-in/out, card operations, portal paper, logs |
| Host reviews | Review queue | ✅ hide, resolve |
| Renter reviews | Review queue | ✅ hide, resolve |
| Ops queues | Pre-set filter queues, active reserves and trips | ✅ cancellation requests |
| Notifications | Send notification to a user | 🟡 list of sent pushes; ⬜ composer |
| Promo codes | List, create, deactivate | 🟡 list, deactivate; ⬜ create |
| Security groups | Roles and permissions | 🟡 list; ⬜ edit |
| Car data | Makes, models, years | 🟡 list; ⬜ edit |
| Localization | Localization files | 🟡 list; ⬜ edit |
| Filters (live panel menu) | Not visible in the screenshot | ⬜ need a screenshot of the open menu |
| Settings | Marketplace settings | 🟡 |

## Golf (Sea Breeze)

| Old page | What it had | Status |
|---|---|---|
| Overview | Fleet now, revenue all time, revenue split, trips by status, recent trips | ✅ |
| Trips | List and filters | ✅ |
| Trip detail | Approve and assign cart, decline, cancel, end, hold / unhold, discounts, extensions, pre-trip and after-trip photos, tariff snapshot, timeline, logs, renter licence and selfie | 🟡 approve, decline, cancel, end, photos, money; ⬜ cart picker on approve, hold, discounts, extensions, timeline |
| Reserves | Pending, approved, ongoing, on hold | ✅ |
| Fleet | Profiles and assets, block / unblock | 🟡 carts, block / unblock; ⬜ create profile, add asset, images |
| Transactions | List | ✅ |
| Settings | General, deposits, access rules, tariffs, tier discounts, promo codes, zones, golf admins | 🟡 tariffs, promo codes, zones, staff as lists; ⬜ editing |
| Financial report | xlsx export | ⬜ |
| Investor view | Revenue trend, revenue mix, fleet utilisation, rider activation, tariff economics, plans, periods | 🟡 no period picker |

## New in this app (from the new app design)

| Feature | Status |
|---|---|
| Inbox: everything waiting for an admin across modules | ✅ |
| Transfer module: routes, bookings, drivers, car checks (HO07a), payouts and the 10 % fee | ✅ lists, approve / reject car checks |
| Document checks (MyGov or 5 photos): verify / reject | ✅ |
| Listing reviews (In review → Live / Needs changes) | ✅ |
| Driver requests (EV01d, G01d) | 🟡 list, assign, decline; ⬜ pick cart + driver + arrival time 5 / 10 / 15 / 20 |
| Staff and drivers (EV drivers, Sea Breeze team, golf drivers) | 🟡 list, block; ⬜ invite, set role |
| Admins and roles (admin, seabreeze_team, driver_ev, driver_golf) | 🟡 list |
| Company accounts (VÖEN, team, invoices, monthly limit) | 🟡 list |
| EV plans (weekly, monthly, yearly packages) | 🟡 list; ⬜ edit prices |
| Parking warnings and appeals (EV05a) | ✅ resolve |
| Support inbox (C03) | 🟡 list; ⬜ chat thread and reply |
| News and push (H03) | 🟡 list; ⬜ composer |
| Languages AZ / RU / EN, AZ default | ✅ |
