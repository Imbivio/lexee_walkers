import type { IconName } from "../components/Icon";

/** The measurable facts a badge can be earned against. */
export type BadgeStats = {
  walksCompleted: number;
  streak: number;
  lifetimeKm: number;
  shopsSupported: number;
  lifetimeLeaves: number;
  lifetimeCo2Kg: number;
  earlyBird: boolean;
};

export type BadgeTier = "start" | "bronze" | "silver" | "gold";

export type BadgeDef = {
  id: string;
  name: string;
  note: string; // the goal, in words
  icon: IconName;
  tier: BadgeTier;
  goal: number;
  unit: string;
  /** current progress value for this account */
  value: (s: BadgeStats) => number;
};

export const badgeDefs: BadgeDef[] = [
  {
    id: "first-steps",
    name: "First steps",
    note: "Finish your first walk",
    icon: "walk",
    tier: "start",
    goal: 1,
    unit: "walk",
    value: (s) => s.walksCompleted,
  },
  {
    id: "early-bird",
    name: "Early bird",
    note: "Walk before 8am",
    icon: "sun",
    tier: "bronze",
    goal: 1,
    unit: "",
    value: (s) => (s.earlyBird ? 1 : 0),
  },
  {
    id: "km-10",
    name: "Getting going",
    note: "Walk 10 km in total",
    icon: "route",
    tier: "bronze",
    goal: 10,
    unit: "km",
    value: (s) => s.lifetimeKm,
  },
  {
    id: "shops-1",
    name: "Local supporter",
    note: "Redeem at your first shop",
    icon: "gift",
    tier: "bronze",
    goal: 1,
    unit: "shop",
    value: (s) => s.shopsSupported,
  },
  {
    id: "leaves-1000",
    name: "Leaf collector",
    note: "Earn 1,000 Leaves",
    icon: "leaf",
    tier: "silver",
    goal: 1000,
    unit: "Leaves",
    value: (s) => s.lifetimeLeaves,
  },
  {
    id: "streak-7",
    name: "Week on foot",
    note: "Keep a 7-day streak",
    icon: "flame",
    tier: "silver",
    goal: 7,
    unit: "days",
    value: (s) => s.streak,
  },
  {
    id: "co2-10",
    name: "Clean air",
    note: "Save 10 kg of CO₂",
    icon: "cloud",
    tier: "silver",
    goal: 10,
    unit: "kg",
    value: (s) => s.lifetimeCo2Kg,
  },
  {
    id: "km-100",
    name: "Century club",
    note: "Walk 100 km in total",
    icon: "star",
    tier: "gold",
    goal: 100,
    unit: "km",
    value: (s) => s.lifetimeKm,
  },
  {
    id: "shops-10",
    name: "Local hero",
    note: "Support 10 different shops",
    icon: "shield",
    tier: "gold",
    goal: 10,
    unit: "shops",
    value: (s) => s.shopsSupported,
  },
  {
    id: "streak-30",
    name: "Unstoppable",
    note: "Keep a 30-day streak",
    icon: "flame",
    tier: "gold",
    goal: 30,
    unit: "days",
    value: (s) => s.streak,
  },
  {
    id: "km-250",
    name: "Trailblazer",
    note: "Walk 250 km in total",
    icon: "route",
    tier: "gold",
    goal: 250,
    unit: "km",
    value: (s) => s.lifetimeKm,
  },
  {
    id: "leaves-10000",
    name: "Full canopy",
    note: "Earn 10,000 Leaves",
    icon: "trophy",
    tier: "gold",
    goal: 10000,
    unit: "Leaves",
    value: (s) => s.lifetimeLeaves,
  },
];

export function badgeProgress(def: BadgeDef, stats: BadgeStats) {
  const value = def.value(stats);
  const ratio = Math.max(0, Math.min(1, value / def.goal));
  return { value, ratio, unlocked: value >= def.goal };
}

/**
 * Compare current stats against already-unlocked badges and return the ids
 * of any that have newly crossed their goal.
 */
export function newlyUnlocked(
  stats: BadgeStats,
  unlocked: Record<string, number>,
): string[] {
  return badgeDefs
    .filter((d) => !unlocked[d.id] && badgeProgress(d, stats).unlocked)
    .map((d) => d.id);
}

export function getBadge(id: string) {
  return badgeDefs.find((d) => d.id === id);
}
