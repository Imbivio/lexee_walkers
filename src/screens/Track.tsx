import { AppHeader } from "../components/AppHeader";
import { Icon } from "../components/Icon";
import {
  CO2_KG_PER_KM,
  stepsToKm,
  stepsToLeaves,
  useApp,
} from "../store/AppState";

function fmtTime(total: number) {
  const m = Math.floor(total / 60)
    .toString()
    .padStart(2, "0");
  const s = (total % 60).toString().padStart(2, "0");
  return `${m}:${s}`;
}

export function Track() {
  const { walking, session, toggleWalk, stepsToday } = useApp();
  const km = stepsToKm(session.steps);
  const pace = session.steps > 0 ? session.seconds / km : 0; // sec per km

  return (
    <>
      <AppHeader />
      <div className="screen view-enter">
        <section className="track-head">
          <p className="eyebrow">{walking ? "Walk in progress" : "Ready when you are"}</p>
          <h1 className="display track-title">
            {walking ? "Keep going." : "Walk to earn."}
          </h1>
          <p className="muted track-lead">
            Every 1,000 steps banks 12 Leaves. Start a session and watch it climb —
            it flows straight into your balance when you stop.
          </p>
        </section>

        <section className={"track-orb card" + (walking ? " active" : "")}>
          <div className="orb-leaves">
            <Icon name="leaf" size={22} strokeWidth={2} />
            <span className="display tnum">{stepsToLeaves(session.steps)}</span>
            <span className="orb-leaves-lbl">Leaves this walk</span>
          </div>

          <div className="orb-grid">
            <div className="orb-stat">
              <Icon name="steps" size={18} className="orb-ic" />
              <span className="orb-val tnum">{session.steps.toLocaleString()}</span>
              <span className="orb-lbl">steps</span>
            </div>
            <div className="orb-stat">
              <Icon name="clock" size={18} className="orb-ic" />
              <span className="orb-val tnum">{fmtTime(session.seconds)}</span>
              <span className="orb-lbl">time</span>
            </div>
            <div className="orb-stat">
              <Icon name="route" size={18} className="orb-ic" />
              <span className="orb-val tnum">{km.toFixed(2)}</span>
              <span className="orb-lbl">km</span>
            </div>
            <div className="orb-stat">
              <Icon name="cloud" size={18} className="orb-ic" />
              <span className="orb-val tnum">{(km * CO2_KG_PER_KM).toFixed(2)}</span>
              <span className="orb-lbl">kg CO₂ saved</span>
            </div>
          </div>

          {walking && pace > 0 && (
            <div className="orb-pace muted">
              Current pace · {fmtTime(Math.round(pace))} / km
            </div>
          )}
        </section>

        <button
          className={"btn btn-block " + (walking ? "btn-danger" : "btn-primary")}
          onClick={toggleWalk}
          style={{ height: 60, fontSize: 17 }}
        >
          <Icon name={walking ? "stop" : "play"} size={20} strokeWidth={2.2} />
          {walking ? "End walk & bank Leaves" : "Start walking"}
        </button>

        <div className="track-today card">
          <span className="muted">Total steps today</span>
          <span className="tnum" style={{ fontWeight: 700 }}>
            {stepsToday.toLocaleString()}
          </span>
        </div>
      </div>
    </>
  );
}
