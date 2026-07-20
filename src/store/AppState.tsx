import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";
import type { Business } from "../data/businesses";

/* ----- earning model (tunable, all in one place) ----- */
export const STEPS_PER_KM = 1312; // ~0.76m stride
export const LEAVES_PER_1000_STEPS = 12;
export const CO2_KG_PER_KM = 0.192; // saved vs. a short car trip
export const DAILY_GOAL = 8000;

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

type Theme = "light" | "dark" | null;

type State = {
  name: string;
  stepsToday: number;
  leaves: number;
  lifetimeLeaves: number;
  streak: number;
  week: number[]; // Mon..Sun step counts, last entry = today
  vouchers: Voucher[];
  walking: boolean;
  session: { steps: number; seconds: number };
  theme: Theme;
};

type Ctx = State & {
  co2SavedKg: number;
  totalKm: number;
  toggleWalk: () => void;
  redeem: (b: Business) => { ok: boolean; voucher?: Voucher };
  markUsed: (voucherId: string) => void;
  setTheme: (t: Theme) => void;
};

const AppCtx = createContext<Ctx | null>(null);

const WEEK_SEED = [6420, 9310, 7180, 11240, 8600, 5230, 4120];

function makeCode() {
  const s = Math.random().toString(36).slice(2, 8).toUpperCase();
  return `LX-${s}`;
}

export function AppProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<State>(() => ({
    name: "Avi",
    stepsToday: WEEK_SEED[6],
    leaves: 1240,
    lifetimeLeaves: 8630,
    streak: 12,
    week: WEEK_SEED,
    vouchers: [
      {
        id: "seed-1",
        businessId: "milldon-bakery",
        businessName: "Milldon Street Bakery",
        offer: "20% off your first loaf",
        cost: 90,
        code: "LX-K7T2QM",
        redeemedAt: Date.now() - 1000 * 60 * 60 * 26,
        used: false,
      },
    ],
    walking: false,
    session: { steps: 0, seconds: 0 },
    theme: null,
  }));

  const tick = useRef<number | null>(null);

  // apply theme to <html> so tokens flip
  useEffect(() => {
    const root = document.documentElement;
    if (state.theme) root.setAttribute("data-theme", state.theme);
    else root.removeAttribute("data-theme");
  }, [state.theme]);

  const toggleWalk = useCallback(() => {
    setState((s) => {
      if (s.walking) {
        // stop: bank the session's leaves
        const earned = stepsToLeaves(s.session.steps);
        return {
          ...s,
          walking: false,
          leaves: s.leaves + earned,
          lifetimeLeaves: s.lifetimeLeaves + earned,
          session: { steps: 0, seconds: 0 },
        };
      }
      return { ...s, walking: true, session: { steps: 0, seconds: 0 } };
    });
  }, []);

  // walk simulation: accrue steps + reflect into today's total live
  useEffect(() => {
    if (!state.walking) {
      if (tick.current) window.clearInterval(tick.current);
      return;
    }
    tick.current = window.setInterval(() => {
      setState((s) => {
        const add = 22 + Math.floor(Math.random() * 14); // steps/sec cadence
        const week = [...s.week];
        week[6] = week[6] + add;
        return {
          ...s,
          stepsToday: s.stepsToday + add,
          week,
          session: {
            steps: s.session.steps + add,
            seconds: s.session.seconds + 1,
          },
        };
      });
    }, 1000);
    return () => {
      if (tick.current) window.clearInterval(tick.current);
    };
  }, [state.walking]);

  const redeem = useCallback((b: Business) => {
    let result: { ok: boolean; voucher?: Voucher } = { ok: false };
    setState((s) => {
      if (s.leaves < b.cost) {
        result = { ok: false };
        return s;
      }
      const voucher: Voucher = {
        id: `v-${Date.now()}`,
        businessId: b.id,
        businessName: b.name,
        offer: b.offer,
        cost: b.cost,
        code: makeCode(),
        redeemedAt: Date.now(),
        used: false,
      };
      result = { ok: true, voucher };
      return { ...s, leaves: s.leaves - b.cost, vouchers: [voucher, ...s.vouchers] };
    });
    return result;
  }, []);

  const markUsed = useCallback((voucherId: string) => {
    setState((s) => ({
      ...s,
      vouchers: s.vouchers.map((v) => (v.id === voucherId ? { ...v, used: true } : v)),
    }));
  }, []);

  const setTheme = useCallback((t: Theme) => setState((s) => ({ ...s, theme: t })), []);

  const value = useMemo<Ctx>(() => {
    const totalKm = stepsToKm(state.week.reduce((a, b) => a + b, 0));
    return {
      ...state,
      totalKm,
      co2SavedKg: totalKm * CO2_KG_PER_KM,
      toggleWalk,
      redeem,
      markUsed,
      setTheme,
    };
  }, [state, toggleWalk, redeem, markUsed, setTheme]);

  return <AppCtx.Provider value={value}>{children}</AppCtx.Provider>;
}

export function useApp() {
  const ctx = useContext(AppCtx);
  if (!ctx) throw new Error("useApp must be used within AppProvider");
  return ctx;
}
