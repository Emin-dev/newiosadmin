# Plan · Rentbutik admin

State on 24.09.2026. Read this first in a new session.

## Decisions made

- Work is split between two Claude sessions:
  - **iOS/Figma session** (`session_01CfbgfhugfvbdN8DuxoRyyh`, repos Emin-dev/iOS + Emin-dev/figma): designs the admin panel in Figma (`Ereat5qYENeSKTvW473gn5`) and the staff/driver views in the Host module of the main app. It records frame names, roles and job statuses in HANDOFF-NOTES.md and the Figma "Handoff notes" frame.
  - **This repo (Emin-dev/newiosadmin)**: the admin panel as a real web app. Every feature of the current panel (Emin-dev/rentbutik-admin, admin.dev.rentbutik.com) with a better bento UI, plus the admin side of the new app flows.
- Staff and drivers never use the admin panel. Sea Breeze team, EV drivers, golf drivers and transfer hosts work in the main app's Host module.
- Admin panel users: full admins, with CEO view (operations) and Investor view (growth story).
- Data: sample data only (`SampleAdminService`) until the new backend is built. The backend will be designed from `AdminService` in `src/lib/domain/types.ts`.
- Languages: Azərbaycan (default), Русский, English. Terms follow the main app's dictionary.
- Hosting: Vercel (new project on this repo).
- Order agreed with Emin: 1) deploy this simple version, 2) finish the iOS app, 3) then improve this web panel.

## Done

- Next.js 16 + React 19 + TypeScript strict, one-page app (`src/app/page.tsx`).
- Domain in `src/lib/domain`: modules, pages (same order as the live panel), records, actions, inbox, seeded sample data, CSV with formula-injection guard, money in minor units. Tests: `npm test`.
- UI: header like the current panel (module switch P2P / EV / Golf / Transfer, search, Investor / CEO, Actions lock with 15-minute auto-off, language, sign out), page pills, CEO bento overview, Investor bento, every list page with status filters, paging and CSV export, record drawer with actions and confirmation, Inbox, Platform pages, global search.
- A first native iOS (SwiftUI) version of the admin was built earlier and replaced by this web app. It is in git history (commit f2ea518) if parts are needed later.

## Next (web panel, after the iOS app is finished)

1. Split `page.tsx` into routes (`/[module]/[page]`, `/[module]/[page]/[id]`, `/inbox`, `/platform/[page]`) so every screen has a shareable URL, as the old hash deep links did.
2. Build the missing custom pages: Map (Leaflet + CARTO, status filter, parking and alert areas), Statistics (time of day, intervals, unique users, date range).
3. Deeper old-panel features, per `docs/PARITY.md`: vehicle remote control, availability windows, trip check-in / check-out, card operations, portal paper, misconduct log, insurance details, push composer, promo create, golf cart picker on approve, hold / discounts / extensions, settings editing, Golf financial report export.
4. New-flow admin features: driver request assignment (cart + driver + arrival 5 / 10 / 15 / 20 min), support chat thread, staff invites and roles, company invoices, EV plan prices.
5. Follow the iOS/Figma session's admin frames once published (read its HANDOFF-NOTES.md in Emin-dev/figma) and match role and status names.
6. Money format: Chromium lacks `az-AZ` number data, so AZ amounts show as "1,568.00 ₼". Format AZ manually (space thousands, comma decimals) like the app ("16,00 ₼").
7. Write the backend contract (`docs/API.md`) from `AdminService` for the backend team.
8. CI: GitHub Actions running `npm run lint`, `npm run typecheck`, `npm test`, `npm run build`.

## Open questions for Emin

- Screenshot of the live panel's "Filters" menu (the page is not built without it).
- A 1024 px app logo.
