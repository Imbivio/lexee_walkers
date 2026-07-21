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
import { getBadge, newlyUnlocked, type BadgeDef, type BadgeStats } from "../data/badges";
import { useAuth } from "./auth";
import {
  CO2_KG_PER_KM,
  loadData,
  makeDefaultData,
  saveData,
  stepsToKm,
  stepsToLeaves,
  type Theme,
  type UserData,
  type Voucher,
} from "./seed";

// re-export the earning model so screens have one import site
export {
  CO2_KG_PER_KM,
  LEAVES_PER_1000_STEPS,
  STEPS_PER_KM,
  stepsToKm,
  stepsToLeaves,
} from "./seed";
export type { Voucher } from "./seed";

type State = {
  data: UserData;
  walking: boolean;
  session: { steps: number; seconds: number };
  pending: string[]; // badge ids queued to celebrate
};

type Ctx = UserData & {
  walking: boolean;
  session: { steps: number; seconds: number };
  // derived
  weekKm: number;
  weekCo2Kg: number;
  lifetimeKm: number;
  lifetimeCo2Kg: number;
  shopsSupported: number;
  stats: BadgeStats;
  pendingBadge: BadgeDef | null;
  // actions
  toggleWalk: () => void;
  redeem: (b: Business) => { ok: boolean; voucher?: Voucher };
  markUsed: (voucherId: string) => void;
  setTheme: (t: Theme) => void;
  setGoal: (goal: number) => void;
  dismissBadge: () => void;
};

const AppCtx = createContext<Ctx | null>(null);

function makeCode() {
  const s = Math.random().toString(36).slice(2, 8).toUpperCase();
  return `LX-${s}`;
}

function computeStats(d: UserData): BadgeStats {
  const lifetimeKm = stepsToKm(d.lifetimeSteps);
  return {
    walksCompleted: d.walksCompleted,
    streak: d.streak,
    lifetimeKm,
    shopsSupported: new Set(d.vouchers.map((v) => v.businessId)).size,
    lifetimeLeaves: d.lifetimeLeaves,
    lifetimeCo2Kg: lifetimeKm * CO2_KG_PER_KM,
    earlyBird: d.earlyBird,
  };
}

export function AppProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const userId = user!.id;

  const [state, setState] = useState<State>(() => ({
    data: loadData(userId) ?? makeDefaultData(),
    walking: false,
    session: { steps: 0, seconds: 0 },
    pending: [],
  }));

  const tick = useRef<number | null>(null);

  // persist on every data change
  useEffect(() => {
    saveData(userId, state.data);
  }, [userId, state.data]);

  // apply theme to <html> so tokens flip; clean up when this account unmounts
  useEffect(() => {
    const root = document.documentElement;
    if (state.data.theme) root.setAttribute("data-theme", state.data.theme);
    else root.removeAttribute("data-theme");
    return () => root.removeAttribute("data-theme");
  }, [state.data.theme]);

  // badge engine: whenever earned stats change, unlock anything newly qualified
  useEffect(() => {
    const stats = computeStats(state.data);
    const fresh = newlyUnlocked(stats, state.data.badges);
    if (fresh.length === 0) return;
    const now = Date.now();
    setState((s) => {
      const badges = { ...s.data.badges };
      for (const id of fresh) badges[id] = now;
      return { ...s, data: { ...s.data, badges }, pending: [...s.pending, ...fresh] };
    });
  }, [
    state.data.walksCompleted,
    state.data.streak,
    state.data.lifetimeSteps,
    state.data.lifetimeLeaves,
    state.data.vouchers,
    state.data.earlyBird,
    state.data.badges,
  ]);

  const toggleWalk = useCallback(() => {
    setState((s) => {
      if (s.walking) {
        const earned = stepsToLeaves(s.session.steps);
        const counted = s.session.steps > 0;
        const before8 = new Date().getHours() < 8;
        return {
          ...s,
          walking: false,
          session: { steps: 0, seconds: 0 },
          data: {
            ...s.data,
            leaves: s.data.leaves + earned,
            lifetimeLeaves: s.data.lifetimeLeaves + earned,
            walksCompleted: s.data.walksCompleted + (counted ? 1 : 0),
            earlyBird: s.data.earlyBird || (counted && before8),
          },
        };
      }
      return { ...s, walking: true, session: { steps: 0, seconds: 0 } };
    });
  }, []);

  // walk simulation: accrue steps live into today + lifetime totals
  useEffect(() => {
    if (!state.walking) {
      if (tick.current) window.clearInterval(tick.current);
      return;
    }
    tick.current = window.setInterval(() => {
      setState((s) => {
        const add = 22 + Math.floor(Math.random() * 14);
        const week = [...s.data.week];
        week[6] = week[6] + add;
        return {
          ...s,
          session: { steps: s.session.steps + add, seconds: s.session.seconds + 1 },
          data: {
            ...s.data,
            stepsToday: s.data.stepsToday + add,
            lifetimeSteps: s.data.lifetimeSteps + add,
            week,
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
      if (s.data.leaves < b.cost) {
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
      return {
        ...s,
        data: {
          ...s.data,
          leaves: s.data.leaves - b.cost,
          vouchers: [voucher, ...s.data.vouchers],
        },
      };
    });
    return result;
  }, []);

  const markUsed = useCallback((voucherId: string) => {
    setState((s) => ({
      ...s,
      data: {
        ...s.data,
        vouchers: s.data.vouchers.map((v) =>
          v.id === voucherId ? { ...v, used: true } : v,
        ),
      },
    }));
  }, []);

  const setTheme = useCallback((t: Theme) => {
    setState((s) => ({ ...s, data: { ...s.data, theme: t } }));
  }, []);

  const setGoal = useCallback((goal: number) => {
    const clamped = Math.max(2000, Math.min(25000, Math.round(goal / 500) * 500));
    setState((s) => ({ ...s, data: { ...s.data, dailyGoal: clamped } }));
  }, []);

  const dismissBadge = useCallback(() => {
    setState((s) => ({ ...s, pending: s.pending.slice(1) }));
  }, []);

  const value = useMemo<Ctx>(() => {
    const d = state.data;
    const weekSteps = d.week.reduce((a, b) => a + b, 0);
    const weekKm = stepsToKm(weekSteps);
    const lifetimeKm = stepsToKm(d.lifetimeSteps);
    const pendingId = state.pending[0];
    return {
      ...d,
      walking: state.walking,
      session: state.session,
      weekKm,
      weekCo2Kg: weekKm * CO2_KG_PER_KM,
      lifetimeKm,
      lifetimeCo2Kg: lifetimeKm * CO2_KG_PER_KM,
      shopsSupported: new Set(d.vouchers.map((v) => v.businessId)).size,
      stats: computeStats(d),
      pendingBadge: pendingId ? getBadge(pendingId) ?? null : null,
      toggleWalk,
      redeem,
      markUsed,
      setTheme,
      setGoal,
      dismissBadge,
    };
  }, [state, toggleWalk, redeem, markUsed, setTheme, setGoal, dismissBadge]);

  return <AppCtx.Provider value={value}>{children}</AppCtx.Provider>;
}

export function useApp() {
  const ctx = useContext(AppCtx);
  if (!ctx) throw new Error("useApp must be used within AppProvider");
  return ctx;
}
