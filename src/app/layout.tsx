import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Rentbutik Admin",
  description: "Rentbutik admin panel",
  robots: { index: false, follow: false },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="az">
      <body>{children}</body>
    </html>
  );
}
