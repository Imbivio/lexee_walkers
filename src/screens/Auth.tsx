import { useState } from "react";
import { Icon } from "../components/Icon";
import { useAuth } from "../store/auth";

type Mode = "welcome" | "login" | "signup";

export function Auth() {
  const { signUp, logIn, logInDemo } = useAuth();
  const [mode, setMode] = useState<Mode>("welcome");
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);

  function submit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    const res =
      mode === "signup" ? signUp(name, email, password) : logIn(email, password);
    if (!res.ok) setError(res.error ?? "Something went wrong.");
  }

  return (
    <div className="stage">
      <div className="shell auth-shell">
        <div className="auth-art" aria-hidden="true">
          <div className="auth-blob b1" />
          <div className="auth-blob b2" />
          <div className="auth-grid" />
        </div>

        <div className="auth-body">
          <div className="auth-brand">
            <span className="wordmark auth-wordmark">
              lexee<span className="dot" />
            </span>
            <p className="auth-tag">Walk. Earn. Support local.</p>
          </div>

          {mode === "welcome" ? (
            <div className="auth-welcome view-enter">
              <h1 className="display auth-head">
                Turn your steps into something the whole street feels.
              </h1>
              <p className="auth-sub muted">
                Earn Leaves for every walk and spend them at the independent shops
                near you. Better for your day, your neighbourhood, and the air.
              </p>
              <div className="auth-actions">
                <button className="btn btn-primary btn-block" onClick={() => setMode("signup")}>
                  Create your account
                </button>
                <button className="btn btn-ghost btn-block" onClick={() => setMode("login")}>
                  I already have an account
                </button>
                <button className="auth-demo" onClick={logInDemo}>
                  <Icon name="play" size={16} strokeWidth={2.2} />
                  Explore a demo account
                </button>
              </div>
            </div>
          ) : (
            <form className="auth-form view-enter" onSubmit={submit}>
              <button
                type="button"
                className="auth-back"
                onClick={() => {
                  setMode("welcome");
                  setError(null);
                }}
              >
                <Icon name="chevron" size={18} strokeWidth={2.4} className="flip" />
                Back
              </button>

              <h1 className="display auth-head sm">
                {mode === "signup" ? "Create your account" : "Welcome back"}
              </h1>

              {mode === "signup" && (
                <label className="field">
                  <span className="field-lbl">Name</span>
                  <input
                    className="input"
                    type="text"
                    autoComplete="name"
                    placeholder="Your name"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                  />
                </label>
              )}

              <label className="field">
                <span className="field-lbl">Email</span>
                <input
                  className="input"
                  type="email"
                  autoComplete="email"
                  placeholder="you@email.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                />
              </label>

              <label className="field">
                <span className="field-lbl">Password</span>
                <input
                  className="input"
                  type="password"
                  autoComplete={mode === "signup" ? "new-password" : "current-password"}
                  placeholder={mode === "signup" ? "At least 6 characters" : "Your password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                />
              </label>

              {error && (
                <p className="auth-error" role="alert">
                  {error}
                </p>
              )}

              <button className="btn btn-primary btn-block" type="submit">
                {mode === "signup" ? "Create account" : "Log in"}
              </button>

              <p className="auth-switch muted">
                {mode === "signup" ? "Already have an account?" : "New to Lexee?"}{" "}
                <button
                  type="button"
                  className="auth-link"
                  onClick={() => {
                    setMode(mode === "signup" ? "login" : "signup");
                    setError(null);
                  }}
                >
                  {mode === "signup" ? "Log in" : "Create one"}
                </button>
              </p>
            </form>
          )}

          <p className="auth-fineprint">
            Prototype — your account lives only in this browser.
          </p>
        </div>
      </div>
    </div>
  );
}
