import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "דירה — ניהול בניין משותף",
  description:
    "ניהול בניין משותף: דמי ועד, תחזוקה עם שיגור ספקים אוטומטי מבוסס AI, אסיפות דיירים, הצבעות וארכיון מסמכים.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="he" dir="rtl">
      <body className="min-h-screen antialiased">{children}</body>
    </html>
  );
}
