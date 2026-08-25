"use client";

import * as React from "react";
import { Button } from "@/components/ui/button";

interface SuccessModalProps {
  open: boolean;
  onClose: () => void;
  title: string;
  message: React.ReactNode;
  /** Manual invite code — rendered in an LTR box with a copy button. */
  code?: string;
  /** When set, shows a "send via WhatsApp" button opening this URL. */
  whatsappUrl?: string;
}

export function SuccessModal({ open, onClose, title, message, code, whatsappUrl }: SuccessModalProps) {
  const [copied, setCopied] = React.useState(false);

  React.useEffect(() => {
    if (open) setCopied(false);
  }, [open]);

  if (!open) return null;

  async function copyCode() {
    if (!code) return;
    await navigator.clipboard.writeText(code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  return (
    <div
      className="fixed inset-0 z-[60] flex items-center justify-center bg-ink-900/40 p-4"
      onClick={onClose}
    >
      <div
        className="success-card w-full max-w-sm rounded-xl2 bg-cream-50 p-8 text-center shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <svg className="mx-auto mb-4 h-20 w-20" viewBox="0 0 56 56" fill="none">
          <circle
            className="success-circle"
            cx="28"
            cy="28"
            r="26"
            stroke="var(--color-sage-500)"
            strokeWidth="3"
            strokeLinecap="round"
            transform="rotate(-90 28 28)"
          />
          <path
            className="success-check"
            d="M17 29l8 8 15-16"
            stroke="var(--color-sage-700)"
            strokeWidth="4"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
        <h3 className="mb-2 text-xl font-bold text-ink-900">{title}</h3>
        <div className="text-sm leading-relaxed text-ink-600">{message}</div>

        {code && (
          <div className="mt-4 text-start">
            <p className="mb-1 text-xs font-medium text-ink-600">קוד הצטרפות ידני</p>
            <div className="flex items-stretch gap-2">
              <code
                dir="ltr"
                className="flex-1 overflow-x-auto whitespace-nowrap rounded-lg border border-sage-300 bg-cream-200 px-3 py-2 font-mono text-xs leading-6 text-ink-900"
              >
                {code}
              </code>
              <button
                type="button"
                onClick={copyCode}
                className="shrink-0 rounded-lg border border-sage-300 bg-cream-50 px-3 text-xs font-medium text-sage-700 hover:bg-sage-100"
              >
                {copied ? "הועתק ✓" : "העתקה"}
              </button>
            </div>
          </div>
        )}

        <div className="mt-6 space-y-2">
          {whatsappUrl && (
            <a
              href={whatsappUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="flex h-10 w-full items-center justify-center gap-2 rounded-lg bg-[#25D366] text-sm font-semibold text-white hover:bg-[#1fb959]"
            >
              <svg className="h-5 w-5" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 2a10 10 0 0 0-8.6 15.1L2 22l5.1-1.3A10 10 0 1 0 12 2zm0 18.2c-1.5 0-3-.4-4.2-1.2l-.3-.2-3 .8.8-3-.2-.3A8.2 8.2 0 1 1 12 20.2zm4.6-6.1c-.3-.1-1.5-.7-1.7-.8-.2-.1-.4-.1-.6.1-.2.3-.6.8-.8 1-.1.2-.3.2-.5.1a6.7 6.7 0 0 1-3.4-3c-.3-.4 0-.5.2-.8l.4-.5c.1-.2.1-.3 0-.5l-.8-1.9c-.2-.5-.4-.4-.6-.4h-.5c-.2 0-.5.1-.7.3-.2.3-.9.9-.9 2.2s.9 2.5 1 2.7c.2.2 1.8 2.8 4.4 3.9 2.6 1.1 2.6.8 3.1.7.5 0 1.5-.6 1.7-1.2.2-.6.2-1.1.2-1.2-.1-.1-.3-.2-.5-.3z" />
              </svg>
              שליחת ההזמנה בוואטסאפ
            </a>
          )}
          <Button onClick={onClose} className="w-full">
            סגירה
          </Button>
        </div>
      </div>
    </div>
  );
}
