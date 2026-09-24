import az from "./az.json";
import ru from "./ru.json";
import type { Lang } from "../domain/money.ts";

const DICTS: Record<Lang, Record<string, string>> = { az, ru, en: {} };

/** Translates an English key; unknown keys (names, plates, values) come back unchanged. `{0}` is replaced by arg. */
export function translate(lang: Lang, key: string, arg?: string | number): string {
  const text = DICTS[lang][key] ?? key;
  return arg === undefined ? text : text.replace("{0}", String(arg));
}

export const LANGS: { id: Lang; name: string }[] = [
  { id: "az", name: "Azərbaycan" },
  { id: "ru", name: "Русский" },
  { id: "en", name: "English" },
];
