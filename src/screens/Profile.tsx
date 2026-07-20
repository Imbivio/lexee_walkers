import { AppHeader } from "../components/AppHeader";
import { Icon, type IconName } from "../components/Icon";
import { useApp } from "../store/AppState";

const badges: { icon: IconName; name: string; note: string; earned: boolean }[] = [
  { icon: "flame", name: "12-day streak", note: "Walked every day", earned: true },
  { icon: "route", name: "Century club", note: "100 km walked", earned: true },
  { icon: "shield", name: "Local hero", note: "10 shops supported", earned: true },
  { icon: "trophy", name: "Marathon month", note: "42 km in 30 days", earned: false },
];

export function Profile() {
  const { name, streak, totalKm, co2SavedKg, lifetimeLeaves, theme, setTheme } = useApp();
  const isDark =
    theme === "dark" ||
    (theme === null &&
      typeof window !== "undefined" &&
      window.matchMedia?.("(prefers-color-scheme: dark)").matches);

  return (
    <>
      <AppHeader showLeaves={false} />
      <div className="screen view-enter">
        <section className="prof-head">
          <div className="prof-avatar">{name[0]}</div>
          <div className="stack" style={{ gap: 2 }}>
            <h1 className="display prof-name">{name} Kumar</h1>
            <span className="muted">Walking since March · Riverside</span>
          </div>
        </section>

        <section className="prof-stats">
          <div className="pstat card">
            <span className="pstat-val display tnum">{streak}</span>
            <span className="pstat-lbl">day streak</span>
          </div>
          <div className="pstat card">
            <span className="pstat-val display tnum">{totalKm.toFixed(0)}</span>
            <span className="pstat-lbl">km this week</span>
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
            By choosing your feet over four wheels, you've kept about{" "}
            <strong className="tnum">{(co2SavedKg * 8).toFixed(0)} kg</strong> of CO₂ out of
            the air this month — and put real spending back into{" "}
            <strong>independent shops</strong> near you.
          </p>
        </section>

        <section className="block-head">
          <span className="eyebrow">Milestones</span>
          <span className="section-title">Badges</span>
        </section>
        <div className="badge-grid">
          {badges.map((b) => (
            <div key={b.name} className={"badge card" + (b.earned ? "" : " locked")}>
              <div className="badge-ic">
                <Icon name={b.icon} size={22} strokeWidth={2} />
              </div>
              <span className="badge-name">{b.name}</span>
              <span className="badge-note muted">{b.note}</span>
            </div>
          ))}
        </div>

        <section className="block-head">
          <span className="eyebrow">Settings</span>
          <span className="section-title">Preferences</span>
        </section>
        <div className="card settings">
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
          <div className="set-div" />
          <div className="set-row">
            <div className="row" style={{ gap: 11 }}>
              <Icon name="steps" size={19} />
              <span>Daily step goal</span>
            </div>
            <span className="tnum" style={{ fontWeight: 700 }}>8,000</span>
          </div>
          <div className="set-div" />
          <div className="set-row">
            <div className="row" style={{ gap: 11 }}>
              <Icon name="shield" size={19} />
              <span>Health data source</span>
            </div>
            <span className="muted">Device motion</span>
          </div>
        </div>

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
