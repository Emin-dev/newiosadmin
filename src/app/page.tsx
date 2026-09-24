"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { formatMoney, formatNumber, formatPercent, type Lang } from "@/lib/domain/money.ts";
import { recordsToCsv } from "@/lib/domain/csv.ts";
import { SampleAdminService } from "@/lib/domain/sample.ts";
import {
  ACTION_KINDS, CUSTOM_PAGES, MODULES, MODULE_INFO, MODULE_PAGES, PAGE_TITLE, PLATFORM_PAGES, QUEUE_KINDS,
  type AdminAction, type AdminModule, type AdminPage, type AdminRecord, type AdminSession, type InvestorSnapshot,
  type ModuleOverview, type PageResult, type QueueItem, type Severity, type ViewMode,
} from "@/lib/domain/types.ts";
import { LANGS, translate } from "@/lib/i18n/index.ts";

// One service for the whole session. Swap for the real API client when the backend exists.
const service = new SampleAdminService();
const UNLOCK_MS = 15 * 60 * 1000;

type Place = { kind: "page"; page: AdminPage } | { kind: "inbox" } | { kind: "platform"; page: AdminPage | null };

export default function App() {
  const [lang, setLang] = useState<Lang>("az");
  const [session, setSession] = useState<AdminSession | null>(null);
  const [module, setModule] = useState<AdminModule>("p2p");
  const [view, setView] = useState<ViewMode>("ceo");
  const [place, setPlace] = useState<Place>({ kind: "page", page: "overview" });
  const [unlockedUntil, setUnlockedUntil] = useState(0);
  const [openId, setOpenId] = useState<string | null>(null);
  const [revision, setRevision] = useState(0);
  const [search, setSearch] = useState("");
  const [inboxCount, setInboxCount] = useState(0);
  const t = useCallback((key: string, arg?: string | number) => translate(lang, key, arg), [lang]);

  useEffect(() => {
    try {
      const saved = localStorage.getItem("rb.lang") as Lang | null;
      if (saved) setLang(saved);
      const s = sessionStorage.getItem("rb.session");
      if (s) setSession(JSON.parse(s));
    } catch { /* storage blocked: defaults stay */ }
  }, []);
  useEffect(() => { try { localStorage.setItem("rb.lang", lang); } catch {} }, [lang]);
  useEffect(() => { service.inbox().then((q) => setInboxCount(q.length)); }, [revision]);
  useEffect(() => {
    if (!unlockedUntil) return;
    const id = setTimeout(() => setUnlockedUntil(0), Math.max(0, unlockedUntil - Date.now()));
    return () => clearTimeout(id);
  }, [unlockedUntil]);

  const actionsOn = unlockedUntil > 0;

  if (!session) return <Login t={t} lang={lang} setLang={setLang} onSignedIn={(s) => {
    setSession(s);
    try { sessionStorage.setItem("rb.session", JSON.stringify(s)); } catch {}
  }} />;

  const pages = MODULE_PAGES[module];
  const go = (p: Place) => { setPlace(p); setSearch(""); window.scrollTo({ top: 0 }); };

  return (
    <div className="shell">
      <header className="header">
        <div className="brand">
          <img src="/logo.png" alt="" width={36} height={36} style={{ borderRadius: 9 }} />
          <div>Rentbutik<small>{t("Admin")} · {t(MODULE_INFO[module].long)}</small></div>
        </div>
        <div className="seg" role="tablist" aria-label={t("Module")}>
          {MODULES.map((m) => (
            <button key={m} className={m === module ? "on" : ""} onClick={() => { setModule(m); go({ kind: "page", page: "overview" }); }}>
              {t(MODULE_INFO[m].title)}
            </button>
          ))}
        </div>
        <input className="search" placeholder={t("Search name, phone or ID")} value={search} onChange={(e) => setSearch(e.target.value)} />
        <div className="seg" aria-label={t("Switch between CEO and Investor view")}>
          {(["investor", "ceo"] as const).map((v) => (
            <button key={v} className={v === view ? "on" : ""} onClick={() => setView(v)}>{t(v === "ceo" ? "CEO" : "Investor")}</button>
          ))}
        </div>
        <button className={"pill" + (actionsOn ? " danger" : "")} onClick={() => {
          if (actionsOn) setUnlockedUntil(0);
          else if (confirm(t("Unlock admin actions for 15 minutes") + "?")) setUnlockedUntil(Date.now() + UNLOCK_MS);
        }}>
          {actionsOn ? "🔓 " + t("Actions on. Tap to lock.") : "🔒 " + t("Actions off. Tap to unlock.")}
        </button>
        <select className="pill" value={lang} onChange={(e) => setLang(e.target.value as Lang)} aria-label={t("Language")}>
          {LANGS.map((l) => <option key={l.id} value={l.id}>{l.name}</option>)}
        </select>
        <button className="pill" onClick={() => { setSession(null); setUnlockedUntil(0); try { sessionStorage.removeItem("rb.session"); } catch {} }}>
          {t("Sign out")}
        </button>
      </header>

      <nav className="nav">
        {pages.map((p) => (
          <button key={p} className={"pill" + (place.kind === "page" && place.page === p ? " on" : "")} onClick={() => go({ kind: "page", page: p })}>
            {t(PAGE_TITLE[p])}
          </button>
        ))}
        <button className={"pill" + (place.kind === "inbox" ? " on" : "")} onClick={() => go({ kind: "inbox" })}>
          {t("Inbox")}{inboxCount > 0 && <span className="badge">{inboxCount}</span>}
        </button>
        <button className={"pill" + (place.kind === "platform" ? " on" : "")} onClick={() => go({ kind: "platform", page: null })}>{t("Platform")}</button>
      </nav>

      {search.trim().length >= 2 ? (
        <SearchResults key={search} text={search} t={t} open={setOpenId} />
      ) : place.kind === "inbox" ? (
        <Inbox t={t} open={setOpenId} revision={revision} />
      ) : place.kind === "platform" && !place.page ? (
        <>
          <h1>{t("Platform")}</h1>
          <p className="sub">{t("Across all modules")}</p>
          <div className="bento">
            {PLATFORM_PAGES.map((p) => (
              <button key={p} className="tile" onClick={() => go({ kind: "platform", page: p })}>
                <span className="num" style={{ fontSize: 18 }}>{t(PAGE_TITLE[p])}</span>
              </button>
            ))}
          </div>
        </>
      ) : place.page && place.page !== "overview" && !CUSTOM_PAGES.includes(place.page) ? (
        <RecordList key={`${place.page}-${module}`} page={place.page} module={place.kind === "platform" ? null : module}
          t={t} lang={lang} open={setOpenId} revision={revision} />
      ) : place.kind === "page" && place.page !== "overview" ? (
        <>
          <h1>{t(PAGE_TITLE[place.page])}</h1>
          <p className="sub"><span className="sample">{t("Sample data")}</span> Map and Statistics are built in the next step (see docs/PLAN.md).</p>
        </>
      ) : view === "ceo" ? (
        <Ceo module={module} t={t} lang={lang} open={setOpenId} goPage={(p) => go({ kind: "page", page: p })} revision={revision} />
      ) : (
        <Investor module={module} t={t} lang={lang} />
      )}

      {openId && (
        <Detail id={openId} t={t} actionsOn={actionsOn} close={() => setOpenId(null)} onChanged={() => setRevision((r) => r + 1)} />
      )}
    </div>
  );
}

type T = (key: string, arg?: string | number) => string;

function useLoad<V>(load: () => Promise<V>, deps: unknown[]): V | null {
  const [value, setValue] = useState<V | null>(null);
  useEffect(() => {
    let alive = true;
    load().then((v) => { if (alive) setValue(v); });
    return () => { alive = false; };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);
  return value;
}

function Chip({ status, t }: { status: { key: string; severity: Severity }; t: T }) {
  return <span className={`chip ${status.severity}`}>{t(status.key)}</span>;
}

function Login({ t, lang, setLang, onSignedIn }: { t: T; lang: Lang; setLang: (l: Lang) => void; onSignedIn: (s: AdminSession) => void }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  return (
    <form className="login" onSubmit={async (e) => {
      e.preventDefault();
      setBusy(true); setError("");
      try { onSignedIn(await service.signIn(email, password)); } catch (err) { setError(t((err as Error).message)); } finally { setBusy(false); }
    }}>
      <img src="/logo.png" alt="Rentbutik" width={76} height={76} style={{ borderRadius: 17, margin: "0 auto" }} />
      <h1 style={{ margin: 0 }}>Rentbutik Admin</h1>
      <p className="cap">{t("For Rentbutik admins only. Staff and drivers use the Rentbutik app.")}</p>
      <input type="email" placeholder={t("Email")} value={email} onChange={(e) => setEmail(e.target.value)} autoComplete="username" />
      <input type="password" placeholder={t("Password")} value={password} onChange={(e) => setPassword(e.target.value)} autoComplete="current-password" />
      {error && <p className="cap critical">{error}</p>}
      <button className="btn" disabled={busy || !email || !password}>{t("Sign in")}</button>
      <span className="sample" style={{ alignSelf: "center" }}>{t("Sample data")}</span>
      <p className="cap">{t("The new backend is not connected yet. Any email and a password of 4+ characters open the app with sample data.")}</p>
      <select className="pill" value={lang} onChange={(e) => setLang(e.target.value as Lang)} style={{ alignSelf: "center" }}>
        {LANGS.map((l) => <option key={l.id} value={l.id}>{l.name}</option>)}
      </select>
    </form>
  );
}

function Ceo({ module, t, lang, open, goPage, revision }: { module: AdminModule; t: T; lang: Lang; open: (id: string) => void; goPage: (p: AdminPage) => void; revision: number }) {
  const o = useLoad<ModuleOverview>(() => service.overview(module), [module, revision]);
  if (!o) return <p className="sub">{t("Loading")}…</p>;
  const max = Math.max(...o.revenueTrend);
  return (
    <>
      <h1>{t("Overview")}</h1>
      <p className="sub">{t(MODULE_INFO[module].long)} <span className="sample">{t("Sample data")}</span></p>
      <div className="bento">
        <div className="tile hero">
          <span className="chip good">{t("Live")}</span>
          <span className="num hero">{o.liveNow}</span>
          <span className="cap">{t(o.liveCaption)}</span>
          <span className="label" style={{ marginTop: "auto" }}>{t("Revenue today")}</span>
          <span className="num gold">{formatMoney(o.revenueTodayMinor, lang)}</span>
          <div className="bars" style={{ height: 70 }}>
            {o.revenueTrend.map((v, i) => <div key={i} style={{ height: `${(v / max) * 100}%` }} />)}
          </div>
        </div>
        {o.kpis.map((k) => (
          <button key={k.title} className="tile" onClick={() => k.opens && goPage(k.opens)}>
            <span className="label">{t(k.title)}</span>
            <span className="num">{k.value}</span>
            {k.caption && <span className={`cap ${k.severity}`}>{k.caption.split(" · ").map((part) => t(part)).join(" · ")}</span>}
          </button>
        ))}
      </div>

      {o.needsAttention.length > 0 && (
        <>
          <div className="section-title">{t("Needs you")}</div>
          <QueueList items={o.needsAttention} t={t} open={open} />
        </>
      )}

      <div className="section-title">{t("Pages")}</div>
      <div className="bento">
        {MODULE_PAGES[module].filter((p) => p !== "overview").map((p) => (
          <button key={p} className="tile" onClick={() => goPage(p)}>
            <span className="num" style={{ fontSize: 18 }}>{t(PAGE_TITLE[p])}</span>
            {o.pageBadges[p] ? <span className="cap attention">{t("{0} waiting", o.pageBadges[p]!)}</span> : null}
          </button>
        ))}
      </div>

      {o.recent.length > 0 && (
        <>
          <div className="section-title">{t("Recent trips")}</div>
          <div className="list">{o.recent.map((r) => <Row key={r.id} r={r} t={t} open={open} />)}</div>
        </>
      )}
    </>
  );
}

function Investor({ module, t, lang }: { module: AdminModule; t: T; lang: Lang }) {
  const s = useLoad<InvestorSnapshot>(() => service.investor(module), [module]);
  if (!s) return <p className="sub">{t("Loading")}…</p>;
  const maxGmv = Math.max(...s.gmvByMonth.map((g) => g.value));
  const maxHour = Math.max(...s.tripsByHour);
  return (
    <>
      <h1>{t("Investor")}</h1>
      <p className="sub">{t(MODULE_INFO[module].long)} <span className="sample">{t("Sample data")}</span></p>
      <div className="bento">
        <div className="tile hero">
          <span className="label">{t("Gross bookings this month")}</span>
          <span className="num hero">{formatMoney(s.gmvThisMonthMinor, lang, 0)}</span>
          <span className={`cap ${s.gmvGrowth >= 0 ? "good" : "critical"}`}>{s.gmvGrowth >= 0 ? "+" : ""}{formatPercent(s.gmvGrowth, lang)}</span>
          <div className="bars" style={{ marginTop: "auto" }}>
            {s.gmvByMonth.map((g) => <div key={g.label} title={t(g.label)} style={{ height: `${(g.value / maxGmv) * 100}%` }} />)}
          </div>
        </div>
        <div className="tile"><span className="label">{t("Active riders · 30 days")}</span><span className="num">{formatNumber(s.activeUsers30d, lang)}</span></div>
        <div className="tile"><span className="label">{t("Retention · 30 days")}</span><span className="num">{formatPercent(s.retention30d, lang)}</span><span className="cap">{t("came back for a second trip")}</span></div>
        <div className="tile"><span className="label">{t("Fleet utilisation")}</span><span className="num">{formatPercent(s.utilization, lang)}</span><span className="cap">{t("of fleet hours earning")}</span></div>
        <div className="tile"><span className="label">{t("Revenue per trip")}</span><span className="num">{formatMoney(s.revenuePerTripMinor, lang)}</span>
          <span className="cap">{s.takeRate < 1 ? t("{0} take rate", formatPercent(s.takeRate, lang)) : t("own fleet, full fare")}</span></div>
        <div className="tile wide">
          <span className="label">{t("Activation funnel")}</span>
          {s.funnel.map((f) => (
            <div key={f.label}>
              <div className="field" style={{ borderTop: 0, padding: "2px 0" }}><span>{t(f.label)}</span><strong>{formatNumber(f.count, lang)}</strong></div>
              <div className="funnel-bar"><div style={{ width: `${(f.count / s.funnel[0].count) * 100}%` }} /></div>
            </div>
          ))}
        </div>
        <div className="tile wide">
          <span className="label">{t("Revenue mix")}</span>
          {s.mix.map((x) => <div key={x.label} className="field"><span>{t(x.label)}</span><strong>{formatPercent(x.share, lang)}</strong></div>)}
        </div>
        <div className="tile full">
          <span className="label">{t("When people ride")}</span>
          <div className="bars">{s.tripsByHour.map((v, h) => <div key={h} title={`${h}:00`} style={{ height: `${(v / maxHour) * 100}%` }} />)}</div>
        </div>
      </div>
    </>
  );
}

function Row({ r, t, open }: { r: AdminRecord; t: T; open: (id: string) => void }) {
  return (
    <div className="row" role="button" tabIndex={0} onClick={() => open(r.id)} onKeyDown={(e) => e.key === "Enter" && open(r.id)}>
      <div className="main"><div className="title">{r.title}</div><div className="subtitle">{r.subtitle}</div></div>
      <div className="end">{r.status && <Chip status={r.status} t={t} />}<span>{r.trailing ?? new Date(r.createdAt).toLocaleDateString()}</span></div>
    </div>
  );
}

function QueueList({ items, t, open }: { items: QueueItem[]; t: T; open: (id: string) => void }) {
  return (
    <div className="list">
      {items.map((q) => (
        <div key={q.id} className="row" role="button" tabIndex={0} onClick={() => open(q.recordId)} onKeyDown={(e) => e.key === "Enter" && open(q.recordId)}>
          <div className="main">
            <div className={`cap ${q.urgent ? "critical" : "attention"}`}>{t(QUEUE_KINDS[q.kind].title)}</div>
            <div className="title">{q.title}</div>
            <div className="subtitle">{q.subtitle}</div>
          </div>
          <div className="end">{new Date(q.createdAt).toLocaleString()}</div>
        </div>
      ))}
    </div>
  );
}

function RecordList({ page, module, t, lang, open, revision }: { page: AdminPage; module: AdminModule | null; t: T; lang: Lang; open: (id: string) => void; revision: number }) {
  const [status, setStatus] = useState<string | null>(null);
  const [count, setCount] = useState(30);
  const result = useLoad<PageResult<AdminRecord>>(() => service.records(page, module, { status, pageSize: count }), [page, module, status, count, revision]);
  const csvHref = useMemo(() => (result ? "data:text/csv;charset=utf-8," + encodeURIComponent(recordsToCsv(result.items, (k) => translate(lang, k))) : ""), [result, lang]);
  return (
    <>
      <h1>{t(PAGE_TITLE[page])}</h1>
      <p className="sub">
        {result ? t("{0} items", result.total) : t("Loading")} <span className="sample">{t("Sample data")}</span>
        {result && result.items.length > 0 && <a className="pill" href={csvHref} download={`rentbutik-${page}.csv`}>{t("Export CSV")}</a>}
      </p>
      {result && (
        <>
          <div className="filters">
            <button className={"pill" + (status === null ? " on" : "")} onClick={() => setStatus(null)}>{t("All")}</button>
            {Object.entries(result.statusCounts).sort().map(([key, n]) => (
              <button key={key} className={"pill" + (status === key ? " on" : "")} onClick={() => setStatus(status === key ? null : key)}>{t(key)} · {n}</button>
            ))}
          </div>
          <div className="list">{result.items.map((r) => <Row key={r.id} r={r} t={t} open={open} />)}</div>
          {result.items.length < result.total && (
            <p style={{ textAlign: "center" }}><button className="pill" onClick={() => setCount((c) => c + 30)}>{t("Show more")}</button></p>
          )}
        </>
      )}
    </>
  );
}

function Inbox({ t, open, revision }: { t: T; open: (id: string) => void; revision: number }) {
  const items = useLoad<QueueItem[]>(() => service.inbox(), [revision]);
  return (
    <>
      <h1>{t("Inbox")}</h1>
      <p className="sub"><span className="sample">{t("Sample data")}</span></p>
      {!items ? <p className="sub">{t("Loading")}…</p> : items.length === 0 ? <p>{t("Every request has been handled.")}</p> : <QueueList items={items} t={t} open={open} />}
    </>
  );
}

function SearchResults({ text, t, open }: { text: string; t: T; open: (id: string) => void }) {
  const hits = useLoad<AdminRecord[]>(() => service.search(text), [text]);
  return (
    <>
      <h1>{t("Search")}</h1>
      {!hits ? <p className="sub">{t("Loading")}…</p> : <div className="list">{hits.map((r) => <Row key={r.id} r={r} t={t} open={open} />)}</div>}
    </>
  );
}

function Detail({ id, t, actionsOn, close, onChanged }: { id: string; t: T; actionsOn: boolean; close: () => void; onChanged: () => void }) {
  const [record, setRecord] = useState<AdminRecord | null>(null);
  const [busy, setBusy] = useState(false);
  useEffect(() => { service.record(id).then(setRecord); }, [id]);
  const run = async (action: AdminAction) => {
    const kind = ACTION_KINDS[action.kind];
    const warn = kind.destructive ? t("This changes live data. The user may be notified.") : t("This changes live data.");
    if (!confirm(`${t(kind.label)}?\n\n${warn}`)) return;
    setBusy(true);
    try { setRecord(await service.perform(action)); onChanged(); } finally { setBusy(false); }
  };
  return (
    <div className="overlay" onClick={close}>
      <aside className="drawer" onClick={(e) => e.stopPropagation()} aria-label={record?.title}>
        <button className="pill" style={{ alignSelf: "flex-end" }} onClick={close}>✕</button>
        {!record ? <p>{t("Loading")}…</p> : (
          <>
            <div className="tile">
              {record.status && <Chip status={record.status} t={t} />}
              <span className="num" style={{ fontSize: 24 }}>{record.title}</span>
              <span className="cap">{record.subtitle}</span>
              <span className="cap">ID {record.id} · {new Date(record.createdAt).toLocaleString()}</span>
              {record.trailing && <span className="num gold" style={{ fontSize: 20 }}>{record.trailing}</span>}
            </div>
            {record.actions.length > 0 && (
              <>
                {!actionsOn && <p className="cap">{t("Actions are off. Unlock with the lock button to use them.")}</p>}
                <div className="actions">
                  {record.actions.map((a) => (
                    <button key={a.kind} className={"btn" + (ACTION_KINDS[a.kind].destructive ? " destructive" : "")} disabled={!actionsOn || busy} onClick={() => run(a)}>
                      {t(ACTION_KINDS[a.kind].label)}
                    </button>
                  ))}
                </div>
              </>
            )}
            {record.sections.map((s) => (
              <div key={s.title} className="tile">
                <span className="label">{t(s.title)}</span>
                {s.fields.map((f) => (
                  <div key={f.label} className="field"><span>{t(f.label)}</span><span className={`cap ${f.severity ?? ""}`} style={{ color: f.severity && f.severity !== "neutral" ? undefined : "var(--ink)" }}>{t(f.value)}</span></div>
                ))}
              </div>
            ))}
          </>
        )}
      </aside>
    </div>
  );
}
