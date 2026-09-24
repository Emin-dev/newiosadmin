import { test } from "node:test";
import assert from "node:assert/strict";
import { csvEscape } from "./csv.ts";
import { formatMoney } from "./money.ts";
import { SampleAdminService } from "./sample.ts";
import { CUSTOM_PAGES, MODULE_PAGES, PLATFORM_PAGES, type AdminModule, type AdminPage } from "./types.ts";

const service = () => new SampleAdminService({ seed: 7, now: 1_790_000_000_000, latency: 0 });

test("money formats per language", () => {
  assert.equal(formatMoney(1600, "en"), "₼16.00");
  assert.ok(formatMoney(1600, "az").endsWith(" ₼"));
});

test("csv neutralises formulas and doubles quotes", () => {
  assert.equal(csvEscape("=SUM(A1)"), "\"'=SUM(A1)\"");
  assert.equal(csvEscape('a "b"'), '"a ""b"""');
});

test("every module starts with overview and ends with settings", () => {
  for (const pages of Object.values(MODULE_PAGES)) {
    assert.equal(pages[0], "overview");
    assert.equal(pages.at(-1), "settings");
  }
});

test("every list page has sample records", async () => {
  const s = service();
  for (const [module, pages] of Object.entries(MODULE_PAGES) as [AdminModule, AdminPage[]][]) {
    for (const page of pages.filter((p) => !CUSTOM_PAGES.includes(p))) {
      assert.ok((await s.records(page, module, {})).total > 0, `${module}/${page}`);
    }
  }
  for (const page of PLATFORM_PAGES) assert.ok((await s.records(page, null, {})).total > 0, page);
});

test("same seed, same data", async () => {
  const a = await service().records("users", "ev", {});
  const b = await service().records("users", "ev", {});
  assert.deepEqual(a.items.map((r) => r.title), b.items.map((r) => r.title));
});

test("an action changes status and leaves the inbox", async () => {
  const s = service();
  const item = (await s.inbox()).find((q) => q.kind === "documentCheck")!;
  const updated = await s.perform({ kind: "verifyDocuments", target: item.recordId });
  assert.equal(updated.status?.key, "Verified");
  assert.ok(!(await s.inbox()).some((q) => q.recordId === item.recordId));
});
