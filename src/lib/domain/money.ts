// Money is always minor units (qəpik). One unit everywhere, so the old panel's
// minor/decimal split (P2P minor, EV/Golf decimal) never comes back.

export type Lang = "az" | "ru" | "en";

const LOCALE: Record<Lang, string> = { az: "az-AZ", ru: "ru-RU", en: "en-US" };

export function localeOf(lang: Lang): string {
  return LOCALE[lang];
}

/** "16,00 ₼" in AZ and RU, "₼16.00" in EN. */
export function formatMoney(minor: number, lang: Lang = "az", fractionDigits = 2): string {
  const number = new Intl.NumberFormat(LOCALE[lang], {
    minimumFractionDigits: fractionDigits,
    maximumFractionDigits: fractionDigits,
  }).format(minor / 100);
  return lang === "en" ? `₼${number}` : `${number} ₼`;
}

/** Compact form for tiles: "₼12.4K" / "12,4 min ₼". */
export function formatMoneyCompact(minor: number, lang: Lang = "az"): string {
  const number = new Intl.NumberFormat(LOCALE[lang], { notation: "compact", maximumFractionDigits: 1 }).format(minor / 100);
  return lang === "en" ? `₼${number}` : `${number} ₼`;
}

export function formatNumber(value: number, lang: Lang = "az"): string {
  return new Intl.NumberFormat(LOCALE[lang]).format(value);
}

export function formatPercent(value: number, lang: Lang = "az"): string {
  return new Intl.NumberFormat(LOCALE[lang], { style: "percent", maximumFractionDigits: 0 }).format(value);
}
