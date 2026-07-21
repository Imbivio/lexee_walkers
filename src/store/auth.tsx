import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import {
  clearData,
  makeDefaultData,
  makeDemoData,
  saveData,
} from "./seed";

/* =========================================================================
   auth.tsx — accounts + session, persisted to localStorage.

   PROTOTYPE-GRADE ONLY. Passwords are lightly hashed and stored in the
   browser; this is fine for a local demo but is NOT real security. In
   production, authentication moves to a server: passwords are hashed with
   bcrypt/argon2 server-side and the client only ever holds a session token.
   ========================================================================= */

export type AuthUser = {
  id: string;
  name: string;
  email: string;
  createdAt: number;
};

type Account = AuthUser & { pass: string };

type AuthCtx = {
  user: AuthUser | null;
  ready: boolean;
  signUp: (name: string, email: string, password: string) => { ok: boolean; error?: string };
  logIn: (email: string, password: string) => { ok: boolean; error?: string };
  logInDemo: () => void;
  logOut: () => void;
  updateName: (name: string) => void;
};

const Ctx = createContext<AuthCtx | null>(null);

const USERS_KEY = "lexee:users";
const SESSION_KEY = "lexee:session";
const DEMO_EMAIL = "demo@lexee.app";

// Small, deterministic string hash. Obfuscation, not cryptography.
function hash(input: string) {
  let h = 5381;
  for (let i = 0; i < input.length; i++) h = (h * 33) ^ input.charCodeAt(i);
  return (h >>> 0).toString(36);
}

function readAccounts(): Account[] {
  try {
    return JSON.parse(localStorage.getItem(USERS_KEY) || "[]") as Account[];
  } catch {
    return [];
  }
}
function writeAccounts(list: Account[]) {
  localStorage.setItem(USERS_KEY, JSON.stringify(list));
}
function toUser(a: Account): AuthUser {
  return { id: a.id, name: a.name, email: a.email, createdAt: a.createdAt };
}
function newId() {
  return "u_" + Math.random().toString(36).slice(2, 10);
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [ready, setReady] = useState(false);

  // restore a session on first load
  useEffect(() => {
    try {
      const id = localStorage.getItem(SESSION_KEY);
      if (id) {
        const acct = readAccounts().find((a) => a.id === id);
        if (acct) setUser(toUser(acct));
      }
    } catch {
      /* ignore */
    }
    setReady(true);
  }, []);

  const signUp = useCallback(
    (name: string, email: string, password: string) => {
      const trimmed = name.trim();
      const mail = email.trim().toLowerCase();
      if (trimmed.length < 2) return { ok: false, error: "Please enter your name." };
      if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(mail))
        return { ok: false, error: "That email doesn't look right." };
      if (password.length < 6)
        return { ok: false, error: "Use at least 6 characters for your password." };

      const accounts = readAccounts();
      if (accounts.some((a) => a.email === mail))
        return { ok: false, error: "An account with that email already exists." };

      const acct: Account = {
        id: newId(),
        name: trimmed,
        email: mail,
        pass: hash(password),
        createdAt: Date.now(),
      };
      writeAccounts([...accounts, acct]);
      saveData(acct.id, makeDefaultData());
      localStorage.setItem(SESSION_KEY, acct.id);
      setUser(toUser(acct));
      return { ok: true };
    },
    [],
  );

  const logIn = useCallback((email: string, password: string) => {
    const mail = email.trim().toLowerCase();
    const acct = readAccounts().find((a) => a.email === mail);
    if (!acct) return { ok: false, error: "No account found for that email." };
    if (acct.pass !== hash(password)) return { ok: false, error: "Incorrect password." };
    localStorage.setItem(SESSION_KEY, acct.id);
    setUser(toUser(acct));
    return { ok: true };
  }, []);

  const logInDemo = useCallback(() => {
    const accounts = readAccounts();
    let acct = accounts.find((a) => a.email === DEMO_EMAIL);
    if (!acct) {
      acct = {
        id: newId(),
        name: "Sam Rivera",
        email: DEMO_EMAIL,
        pass: hash("demo-account"),
        createdAt: Date.now(),
      };
      writeAccounts([...accounts, acct]);
    }
    // always refresh the demo with its lived-in dataset
    saveData(acct.id, makeDemoData());
    localStorage.setItem(SESSION_KEY, acct.id);
    setUser(toUser(acct));
  }, []);

  const logOut = useCallback(() => {
    localStorage.removeItem(SESSION_KEY);
    setUser((u) => {
      // wipe the throwaway demo account entirely on logout
      if (u && u.email === DEMO_EMAIL) {
        writeAccounts(readAccounts().filter((a) => a.id !== u.id));
        clearData(u.id);
      }
      return null;
    });
  }, []);

  const updateName = useCallback((name: string) => {
    const trimmed = name.trim();
    if (trimmed.length < 2) return;
    setUser((u) => {
      if (!u) return u;
      const accounts = readAccounts().map((a) =>
        a.id === u.id ? { ...a, name: trimmed } : a,
      );
      writeAccounts(accounts);
      return { ...u, name: trimmed };
    });
  }, []);

  const value = useMemo<AuthCtx>(
    () => ({ user, ready, signUp, logIn, logInDemo, logOut, updateName }),
    [user, ready, signUp, logIn, logInDemo, logOut, updateName],
  );

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useAuth() {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
