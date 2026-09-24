import type { AdminRecord } from "./types.ts";

/** Quotes every cell and neutralises cells a spreadsheet would run as a formula. */
export function csvEscape(raw: string): string {
  let cell = raw;
  if (cell.length > 0 && "=+-@\t\r".includes(cell[0])) cell = "'" + cell;
  return '"' + cell.replaceAll('"', '""') + '"';
}

/** CSV of the rows on screen (search and filter included), as in the old panel. */
export function recordsToCsv(records: AdminRecord[], t: (key: string) => string = (k) => k): string {
  const header = ["ID", "Title", "Details", "Status", "Value", "Created"].map(t);
  const rows = records.map((r) => [
    r.id,
    r.title,
    r.subtitle,
    r.status ? t(r.status.key) : "",
    r.trailing ?? "",
    new Date(r.createdAt).toISOString(),
  ]);
  return [header, ...rows].map((row) => row.map(csvEscape).join(",")).join("\r\n") + "\r\n";
}
