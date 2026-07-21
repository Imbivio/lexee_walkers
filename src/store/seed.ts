/* =========================================================================
   seed.ts — the data shape, the earning model, and local persistence.
   Shared by the auth layer (which creates accounts) and AppState (runtime).

   NOTE: this prototype persists everything in the browser's localStorage.
   A production build would move accounts + data behind an API and a real
   database; the shapes here are intentionally close to what those rows
   would look like so that migration is straightforward.
   ========================================================================= */

/* ----- earning model (tunable, all in one place) ----- */
export const STEPS_PER_KM = 1312; // ~0.76m stride
export const LEAVES_PER_1000_STEPS = 12;
export const CO2_KG_PER_KM = 0.192; // saved vs. a short car trip
export const DEFAULT_GOAL = 8000;

export function stepsToLeaves(steps: number) {
  return Math.floor((steps / 1000) * LEAVES_PER_1000_STEPS);
}
export function stepsToKm(steps: number) {
  return steps / STEPS_PER_KM;
}

export type Voucher = {
  id: string;
  businessId: string;
  businessName: string;
  offer: string;
  cost: number;
  code: string;
  redeemedAt: number;
  used: boolean;
};

export type Theme = "light" | "dark" | null;

/** Everything that is saved for a single account. */
export type UserData = {
  stepsToday: number;
  leaves: number;
  lifetimeLeaves: number;
  lifetimeSteps: number;
  walksCompleted: number;
  streak: number;
  dailyGoal: number;
  week: number[]; // 7 buckets, last entry = today
  vouchers: Voucher[];
  badges: Record<string, number>; // badgeId -> unlockedAt (ms)
  earlyBird: boolean;
  theme: Theme;
};

const DATA_PREFIX = "lexee:data:";

export function loadData(userId: string): UserData | null {
  try {
    const raw = localStorage.getItem(DATA_PREFIX + userId);
    if (!raw) return null;
    return { ...makeDefaultData(), ...(JSON.parse(raw) as UserData) };
  } catch {
    return null;
  }
}

export function saveData(userId: string, data: UserData) {
  try {
    localStorage.setItem(DATA_PREFIX + userId, JSON.stringify(data));
  } catch {
    /* storage full or unavailable — non-fatal for a prototype */
  }
}

export function clearData(userId: string) {
  try {
    localStorage.removeItem(DATA_PREFIX + userId);
  } catch {
    /* ignore */
  }
}

/** A fresh account: day one, nothing earned yet. */
export function makeDefaultData(): UserData {
  return {
    stepsToday: 0,
    leaves: 0,
    lifetimeLeaves: 0,
    lifetimeSteps: 0,
    walksCompleted: 0,
    streak: 1,
    dailyGoal: DEFAULT_GOAL,
    week: [0, 0, 0, 0, 0, 0, 0],
    vouchers: [],
    badges: {},
    earlyBird: false,
    theme: null,
  };
}

/** A lived-in account for the "Try a demo" button. */
export function makeDemoData(): UserData {
  const now = Date.now();
  const day = 1000 * 60 * 60 * 24;
  return {
    stepsToday: 7620,
    leaves: 1240,
    lifetimeLeaves: 8630,
    lifetimeSteps: 168000, // ~128 km lifetime
    walksCompleted: 34,
    streak: 12,
    dailyGoal: DEFAULT_GOAL,
    week: [6420, 9310, 7180, 11240, 8600, 5230, 7620],
    vouchers: [
      {
        id: "seed-1",
        businessId: "milldon-bakery",
        businessName: "Milldon Street Bakery",
        offer: "20% off your first loaf",
        cost: 90,
        code: "LX-K7T2QM",
        redeemedAt: now - day,
        used: false,
      },
      {
        id: "seed-2",
        businessId: "fern-yard",
        businessName: "Fern & Yard Coffee",
        offer: "Free filter coffee with any pastry",
        cost: 120,
        code: "LX-B2M9WQ",
        redeemedAt: now - day * 5,
        used: true,
      },
      {
        id: "seed-3",
        businessId: "cedar-grocer",
        businessName: "Cedar Lane Grocer",
        offer: "$3 off fresh produce",
        cost: 110,
        code: "LX-P4R7KD",
        redeemedAt: now - day * 9,
        used: true,
      },
    ],
    // pre-unlocked so they don't all "celebrate" on first open
    badges: {
      "first-steps": now - day * 40,
      "streak-7": now - day * 20,
      "km-10": now - day * 38,
      "km-100": now - day * 6,
      "shops-1": now - day * 9,
      "leaves-1000": now - day * 30,
      "co2-10": now - day * 12,
      "early-bird": now - day * 33,
    },
    earlyBird: true,
    theme: null,
  };
}
