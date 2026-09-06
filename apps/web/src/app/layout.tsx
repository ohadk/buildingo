import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: {
    default: "Buildingo — ניהול בניין משותף",
    template: "%s — Buildingo",
  },
  description:
    "אפליקציה לוועד ולדיירים: דמי ועד, תקלות עם שיגור סוכן AI לספקים, הודעות, דיירים, מסמכים ואסיפות.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="he" dir="rtl">
      <body className="min-h-screen antialiased">{children}</body>
    </html>
  );
}
