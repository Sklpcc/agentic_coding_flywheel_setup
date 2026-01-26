"use client";

/**
 * ThemeToggle — Cycles between dark, light, and system theme modes.
 *
 * Shows a sun/moon/monitor icon depending on the current mode.
 * Click to cycle: dark → light → system → dark.
 *
 * @see bd-331g
 */

import { Moon, Sun, Monitor } from "lucide-react";
import { useTheme, type ThemeMode } from "@/lib/hooks/useTheme";
import { cn } from "@/lib/utils";

const MODE_CONFIG: Record<ThemeMode, { icon: typeof Moon; label: string }> = {
  dark: { icon: Moon, label: "Dark mode (click for light)" },
  light: { icon: Sun, label: "Light mode (click for system)" },
  system: { icon: Monitor, label: "System theme (click for dark)" },
};

interface ThemeToggleProps {
  className?: string;
}

export function ThemeToggle({ className }: ThemeToggleProps) {
  const { mode, cycle } = useTheme();
  const { icon: Icon, label } = MODE_CONFIG[mode];

  return (
    <button
      type="button"
      onClick={cycle}
      className={cn(
        "flex h-8 w-8 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:bg-muted hover:text-foreground",
        className
      )}
      aria-label={label}
      title={label}
    >
      <Icon className="h-4 w-4" />
    </button>
  );
}
