import { useApp } from "../store/AppState";
import { Icon } from "./Icon";

const TIER_LABEL: Record<string, string> = {
  start: "Getting started",
  bronze: "Bronze badge",
  silver: "Silver badge",
  gold: "Gold badge",
};

export function BadgeUnlock() {
  const { pendingBadge, dismissBadge } = useApp();
  if (!pendingBadge) return null;

  return (
    <div className="unlock-scrim" onClick={dismissBadge}>
      <div
        className="unlock card"
        role="dialog"
        aria-modal="true"
        aria-label={`Badge unlocked: ${pendingBadge.name}`}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="unlock-rays" aria-hidden="true" />
        <div className={"unlock-medal tier-" + pendingBadge.tier}>
          <Icon name={pendingBadge.icon} size={40} strokeWidth={2} />
        </div>
        <span className="eyebrow">Badge unlocked</span>
        <h2 className="display unlock-name">{pendingBadge.name}</h2>
        <p className="unlock-note muted">{pendingBadge.note}</p>
        <span className="unlock-tier">{TIER_LABEL[pendingBadge.tier]}</span>
        <button className="btn btn-primary btn-block" onClick={dismissBadge}>
          Nice
        </button>
      </div>
    </div>
  );
}
