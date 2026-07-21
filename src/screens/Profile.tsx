import { useState } from "react";
import { AppHeader } from "../components/AppHeader";
import { Icon } from "../components/Icon";
import { badgeDefs, badgeProgress } from "../data/badges";
import { useApp } from "../store/AppState";
import { useAuth } from "../store/auth";

function fmtValue(v: number, unit: string) {
  const n = unit === "km" || unit === "kg" ? v.toFixed(0) : Math.floor(v).toLocaleString();
  return unit ? `${n} ${unit}` : `${n}`;
}

export function Profile() {
  const { user, logOut, updateName } = useAuth();
  const {
    streak,
    lifetimeKm,
    lifetimeCo2Kg,
    lifetimeLeaves,
    shopsSupported,
    dailyGoal,
    badges,
    stats,
    theme,
    setTheme,
    setGoal,
  } = useApp();

  const [editingName, setEditingName] = useState(false);
  const [nameDraft, setNameDraft] = useState(user?.name ?? "");

  const isDark =
    theme === "dark" ||
    (theme === null &&
      typeof window !== "undefined" &&
      window.matchMedia?.("(prefers-color-scheme: dark)").matches);

  const earnedCount = badgeDefs.filter((d) => badges[d.id]).length;
  const memberSince = user
    ? new Date(user.createdAt).toLocaleDateString(undefined, { month: "long", year: "numeric" })
    : "";

  function saveName() {
    updateName(nameDraft);
    setEditingName(false);
  }

  return (
    <>
      <AppHeader showLeaves={false} />
      <div className="screen view-enter">
        <section className="prof-head">
          <div className="prof-avatar">{(user?.name ?? "L")[0].toUpperCase()}</div>
          <div className="stack" style={{ gap: 2 }}>
            <h1 className="display prof-name">{user?.name}</h1>
            <span className="muted">Walking since {memberSince}</span>
          </div>
        </section>

        <section className="prof-stats">
          <div className="pstat card">
            <span className="pstat-val display tnum">{streak}</span>
            <span className="pstat-lbl">day streak</span>
          </div>
          <div className="pstat card">
            <span className="pstat-val display tnum">{lifetimeKm.toFixed(0)}</span>
            <span className="pstat-lbl">km walked</span>
          </div>
          <div className="pstat card">
            <span className="pstat-val display tnum">{lifetimeLeaves.toLocaleString()}</span>
            <span className="pstat-lbl">Leaves earned</span>
          </div>
        </section>

        <section className="card impact-card">
          <div className="impact-head">
            <Icon name="cloud" size={20} />
            <span className="section-title">Your impact so far</span>
          </div>
          <p className="prof-impact">
            You've kept about{" "}
            <strong className="tnum">{lifetimeCo2Kg.toFixed(0)} kg</strong> of CO₂ out of the air
            by choosing your feet — and put real spending back into{" "}
            <strong>{shopsSupported} independent {shopsSupported === 1 ? "shop" : "shops"}</strong>{" "}
            near you.
          </p>
        </section>

        <section className="block-head between">
          <div className="stack" style={{ gap: 2 }}>
            <span className="eyebrow">Milestones</span>
            <span className="section-title">Badges</span>
          </div>
          <span className="badge-count tnum">
            {earnedCount}/{badgeDefs.length}
          </span>
        </section>

        <div className="badge-grid">
          {badgeDefs.map((d) => {
            const { value, ratio, unlocked } = badgeProgress(d, stats);
            return (
              <div key={d.id} className={"badge card" + (unlocked ? " earned" : " locked")}>
                <div className={"badge-ic tier-" + d.tier}>
                  <Icon name={d.icon} size={22} strokeWidth={2} />
                </div>
                <span className="badge-name">{d.name}</span>
                <span className="badge-note muted">{d.note}</span>
                {unlocked ? (
                  <span className="badge-earned">
                    <Icon name="check" size={13} strokeWidth={2.6} /> Earned
                  </span>
                ) : (
                  <div className="badge-prog">
                    <div className="badge-prog-track">
                      <div className="badge-prog-fill" style={{ width: `${ratio * 100}%` }} />
                    </div>
                    <span className="badge-prog-lbl tnum">
                      {fmtValue(value, d.unit)} / {d.goal.toLocaleString()}
                    </span>
                  </div>
                )}
              </div>
            );
          })}
        </div>

        <section className="block-head">
          <span className="eyebrow">Settings</span>
          <span className="section-title">Preferences</span>
        </section>
        <div className="card settings">
          <div className="set-row">
            <div className="row" style={{ gap: 11 }}>
              <Icon name="user" size={19} />
              <span>Display name</span>
            </div>
            {editingName ? (
              <div className="row" style={{ gap: 6 }}>
                <input
                  className="input input-sm"
                  value={nameDraft}
                  onChange={(e) => setNameDraft(e.target.value)}
                  autoFocus
                />
                <button className="mini-save" onClick={saveName} aria-label="Save name">
                  <Icon name="check" size={17} strokeWidth={2.4} />
                </button>
              </div>
            ) : (
              <button
                className="set-edit"
                onClick={() => {
                  setNameDraft(user?.name ?? "");
                  setEditingName(true);
                }}
              >
                {user?.name} <Icon name="chevron" size={15} strokeWidth={2.4} />
              </button>
            )}
          </div>
          <div className="set-div" />

          <div className="set-row">
            <div className="row" style={{ gap: 11 }}>
              <Icon name="steps" size={19} />
              <span>Daily step goal</span>
            </div>
            <div className="stepper">
              <button onClick={() => setGoal(dailyGoal - 500)} aria-label="Lower goal">
                −
              </button>
              <span className="tnum stepper-val">{dailyGoal.toLocaleString()}</span>
              <button onClick={() => setGoal(dailyGoal + 500)} aria-label="Raise goal">
                +
              </button>
            </div>
          </div>
          <div className="set-div" />

          <div className="set-row">
            <div className="row" style={{ gap: 11 }}>
              <Icon name={isDark ? "moon" : "sun"} size={19} />
              <span>Appearance</span>
            </div>
            <div className="seg">
              <button className={"seg-btn" + (!isDark ? " on" : "")} onClick={() => setTheme("light")}>
                Light
              </button>
              <button className={"seg-btn" + (isDark ? " on" : "")} onClick={() => setTheme("dark")}>
                Dark
              </button>
            </div>
          </div>
        </div>

        <button className="btn btn-danger btn-block logout-btn" onClick={logOut}>
          Log out
        </button>

        <p className="brand-foot">
          <span className="wordmark" style={{ fontSize: 18 }}>
            lexee<span className="dot" style={{ marginBottom: 8 }} />
          </span>
          Walk. Earn. Support local.
        </p>
      </div>
    </>
  );
}
