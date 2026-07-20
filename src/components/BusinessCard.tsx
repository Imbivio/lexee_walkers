import type { Business } from "../data/businesses";
import { Icon } from "./Icon";

function initials(name: string) {
  return name
    .replace(/&/g, "")
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0])
    .join("")
    .toUpperCase();
}

export function BusinessCard({
  b,
  affordable,
  onRedeem,
}: {
  b: Business;
  affordable: boolean;
  onRedeem: (b: Business) => void;
}) {
  return (
    <article className="biz card">
      <div className="biz-top">
        <div className="biz-badge" style={{ background: b.hue }}>
          {initials(b.name)}
        </div>
        <div className="biz-head">
          <div className="between">
            <h3 className="biz-name">{b.name}</h3>
          </div>
          <div className="biz-meta">
            <span>{b.category}</span>
            <span className="dot-sep" />
            <span className="row" style={{ gap: 3 }}>
              <Icon name="pin" size={13} strokeWidth={2} />
              {b.distanceKm.toFixed(1)} km
            </span>
          </div>
        </div>
      </div>

      <p className="biz-offer">{b.offer}</p>

      <div className="biz-foot">
        <div className="stack">
          <span className="leaves-chip">
            <Icon name="leaf" size={15} strokeWidth={2} />
            {b.cost}
          </span>
          <span className="biz-value">{b.discount}</span>
        </div>
        <button
          className="btn btn-primary biz-cta"
          onClick={() => onRedeem(b)}
          disabled={!affordable}
        >
          {affordable ? "Redeem" : "Keep walking"}
        </button>
      </div>
    </article>
  );
}
