import * as React from "react";
import { cn } from "@/lib/utils";

export function Input({ className, ...props }: React.InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      className={cn(
        "flex h-10 w-full rounded-full border border-cream-300 bg-cream-200 px-4 py-2 text-sm text-ink-900 placeholder:text-ink-400 hover:border-ink-400 focus-visible:border-brick-500 focus-visible:outline-2 focus-visible:outline-brick-500",
        className,
      )}
      {...props}
    />
  );
}

export function Label({ className, ...props }: React.LabelHTMLAttributes<HTMLLabelElement>) {
  return <label className={cn("text-sm font-medium text-ink-600", className)} {...props} />;
}
