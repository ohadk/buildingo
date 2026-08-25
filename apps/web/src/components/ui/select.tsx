"use client";

import * as React from "react";
import { cn } from "@/lib/utils";

export interface SelectOption {
  value: string;
  label: React.ReactNode;
}

interface SelectProps {
  value: string;
  onChange: (value: string) => void;
  options: SelectOption[];
  placeholder?: string;
  required?: boolean;
  className?: string;
  panelClassName?: string;
}

/** Themed replacement for the native <select>, matching the Input styling. */
export function Select({
  value,
  onChange,
  options,
  placeholder = "בחירה…",
  required,
  className,
  panelClassName,
}: SelectProps) {
  const [open, setOpen] = React.useState(false);
  const rootRef = React.useRef<HTMLDivElement>(null);

  React.useEffect(() => {
    if (!open) return;
    function onOutside(e: MouseEvent) {
      if (!rootRef.current?.contains(e.target as Node)) setOpen(false);
    }
    function onEscape(e: KeyboardEvent) {
      if (e.key === "Escape") setOpen(false);
    }
    document.addEventListener("mousedown", onOutside);
    document.addEventListener("keydown", onEscape);
    return () => {
      document.removeEventListener("mousedown", onOutside);
      document.removeEventListener("keydown", onEscape);
    };
  }, [open]);

  const selected = options.find((o) => o.value === value);

  return (
    <div ref={rootRef} className={cn("relative", className)}>
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className={cn(
          "flex h-10 w-full items-center justify-between gap-2 rounded-lg border border-sage-300 bg-cream-50 px-3 py-2 text-sm",
          selected ? "text-ink-900" : "text-ink-400",
          "focus-visible:outline-2 focus-visible:outline-sage-500",
        )}
      >
        <span className="truncate">{selected ? selected.label : placeholder}</span>
        <svg
          className={cn("h-4 w-4 shrink-0 text-ink-400 transition-transform", open && "rotate-180")}
          viewBox="0 0 20 20"
          fill="none"
          stroke="currentColor"
          strokeWidth={2}
        >
          <path d="M6 8l4 4 4-4" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </button>
      {/* Hidden input keeps native form "required" validation working */}
      {required && (
        <input
          tabIndex={-1}
          aria-hidden
          required
          value={value}
          onChange={() => {}}
          className="pointer-events-none absolute inset-0 h-full w-full opacity-0"
        />
      )}
      {open && (
        <div
          className={cn(
            "absolute z-20 mt-1 max-h-56 w-full overflow-y-auto rounded-lg border border-sage-300 bg-cream-50 py-1 shadow-lg",
            panelClassName,
          )}
        >
          {options.map((o) => (
            <button
              key={o.value}
              type="button"
              onClick={() => {
                onChange(o.value);
                setOpen(false);
              }}
              className={cn(
                "flex w-full items-center gap-2 px-3 py-2 text-start text-sm text-ink-900 hover:bg-sage-100",
                o.value === value && "bg-sage-100 font-semibold",
              )}
            >
              {o.label}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
