# Rentbutik Admin (web)

Admin panel for Rentbutik admins. Same structure as the current panel
(Emin-dev/rentbutik-admin) in the new bento design, plus the admin side of the new app flows.
Staff and drivers do not use it; they work in the main app's Host module.

Runs on sample data until the new backend exists. Sign in with any email and a password of 4+ characters.

```bash
npm install
npm run dev        # http://localhost:3000
npm test           # domain tests (node:test)
npm run lint && npm run typecheck && npm run build
```

Deploy: import this repo as a new Vercel project (framework: Next.js, no settings needed).

- `src/lib/domain` — types, `AdminService` contract, sample data, CSV, money. No React.
- `src/lib/i18n` — AZ and RU dictionaries (English keys).
- `src/app/page.tsx` — the panel.
- `docs/PLAN.md` — decisions and next steps. `docs/PARITY.md` — old panel features and their status.
