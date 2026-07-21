import { Link } from "react-router-dom";
import { AppHeader } from "../components/AppHeader";
import { ProgressRing } from "../components/ProgressRing";
import { WeekChart } from "../components/WeekChart";
import { Icon } from "../components/Icon";
import { businesses } from "../data/businesses";
import { stepsToKm, stepsToLeaves, useApp } from "../store/AppState";
import { useAuth } from "../store/auth";

function greeting() {
  const h = new Date().getHours();
  if (h < 12) return "Good morning";
  if (h < 18) return "Good afternoon";
  return "Good evening";
}

export function Home() {
  const { user } = useAuth();
  const { stepsToday, week, weekCo2Kg, weekKm, dailyGoal, streak, walking, session } = useApp();
  const firstName = (user?.name ?? "there").split(" ")[0];
  const progress = stepsToday / dailyGoal;
  const remaining = Math.max(0, dailyGoal - stepsToday);
  const featured = businesses.filter((b) => b.featured);

  return (
    <>
      <AppHeader />
      <div className="screen view-enter">
        <section className="hero-greet">
          <p className="eyebrow">{greeting()}</p>
          <h1 className="display greet-name">{firstName}.</h1>
        </section>

        <section className="ring-card card">
          {walking && (
            <div className="live-pill">
              <span className="live-dot" />
              Walking — earning {stepsToLeaves(session.steps)} Leaves
            </div>
          )}
          <ProgressRing progress={progress}>
            <span className="ring-steps display tnum">
              {stepsToday.toLocaleString()}
            </span>
            <span className="ring-sub">
              of {dailyGoal.toLocaleString()} steps
            </span>
          </ProgressRing>
          <p className="ring-note">
            {remaining > 0 ? (
              <>
                <strong>{remaining.toLocaleString()}</strong> steps to today's goal
              </>
            ) : (
              <>Goal reached. Every step past this still earns Leaves.</>
            )}
          </p>
          <Link to="/track" className="btn btn-primary btn-block">
            <Icon name={walking ? "route" : "play"} size={20} strokeWidth={2.2} />
            {walking ? "See live walk" : "Start a walk"}
          </Link>
        </section>

        <section className="mini-stats">
          <div className="mini card">
            <Icon name="leaf" size={19} className="mini-ic" />
            <span className="mini-val tnum">{stepsToLeaves(stepsToday)}</span>
            <span className="mini-lbl">Leaves today</span>
          </div>
          <div className="mini card">
            <Icon name="route" size={19} className="mini-ic" />
            <span className="mini-val tnum">{stepsToKm(stepsToday).toFixed(1)}</span>
            <span className="mini-lbl">km today</span>
          </div>
        </section>

        <section className="card block-card">
          <div className="between">
            <div className="stack">
              <span className="eyebrow">This week</span>
              <span className="section-title">Steps &amp; streak</span>
            </div>
            <span className="leaves-chip" style={{ background: "var(--brand-tint)", color: "var(--brand)", borderColor: "transparent" }}>
              <Icon name="flame" size={15} strokeWidth={2} />
              {streak}-day streak
            </span>
          </div>
          <WeekChart week={week} goal={dailyGoal} />
        </section>

        <section className="card impact-card">
          <div className="impact-head">
            <Icon name="cloud" size={20} />
            <span className="section-title">Your footprint, going down</span>
          </div>
          <div className="impact-grid">
            <div className="stack">
              <span className="impact-num display tnum">{weekCo2Kg.toFixed(1)}</span>
              <span className="impact-unit">kg CO₂ not driven this week</span>
            </div>
            <div className="impact-div" />
            <div className="stack">
              <span className="impact-num display tnum">{weekKm.toFixed(0)}</span>
              <span className="impact-unit">km walked this week</span>
            </div>
          </div>
          <p className="impact-foot muted">
            That's roughly {Math.max(1, Math.round(weekCo2Kg * 41))} phone charges' worth of
            carbon, kept out of the air.
          </p>
        </section>

        <section className="block-head between">
          <div className="stack">
            <span className="eyebrow">Near you</span>
            <span className="section-title">Spend Leaves locally</span>
          </div>
          <Link to="/explore" className="link-more">
            Explore
            <Icon name="chevron" size={16} strokeWidth={2.4} />
          </Link>
        </section>

        <div className="feat-row">
          {featured.map((b) => (
            <Link to="/explore" key={b.id} className="feat card">
              <div className="feat-badge" style={{ background: b.hue }}>
                {b.name.replace(/&/g, "").split(" ").slice(0, 2).map((w) => w[0]).join("")}
              </div>
              <div className="stack" style={{ gap: 3 }}>
                <span className="feat-name">{b.name}</span>
                <span className="feat-offer muted">{b.offer}</span>
              </div>
              <span className="leaves-chip feat-cost">
                <Icon name="leaf" size={14} strokeWidth={2} />
                {b.cost}
              </span>
            </Link>
          ))}
        </div>
      </div>
    </>
  );
}
