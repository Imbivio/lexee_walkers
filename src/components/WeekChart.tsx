import { DAILY_GOAL } from "../store/AppState";

const DAYS = ["M", "T", "W", "T", "F", "S", "S"];

export function WeekChart({ week }: { week: number[] }) {
  const max = Math.max(DAILY_GOAL, ...week);
  return (
    <div className="week">
      {week.map((v, i) => {
        const h = Math.max(6, Math.round((v / max) * 100));
        const isToday = i === week.length - 1;
        const hitGoal = v >= DAILY_GOAL;
        return (
          <div className="week-col" key={i}>
            <div className="week-track">
              <div
                className={
                  "week-bar" +
                  (isToday ? " is-today" : "") +
                  (hitGoal ? " hit" : "")
                }
                style={{ height: `${h}%` }}
                title={`${v.toLocaleString()} steps`}
              />
            </div>
            <span className={"week-day" + (isToday ? " is-today" : "")}>{DAYS[i]}</span>
          </div>
        );
      })}
    </div>
  );
}
