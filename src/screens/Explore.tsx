import { useMemo, useState } from "react";
import { AppHeader } from "../components/AppHeader";
import { BusinessCard } from "../components/BusinessCard";
import { Icon } from "../components/Icon";
import { ExploreMap, usingLiveMap } from "../components/ExploreMap";
import {
  businesses,
  categories,
  categoryColor,
  type Business,
  type Category,
} from "../data/businesses";
import { useApp, type Voucher } from "../store/AppState";

type Sheet =
  | { kind: "success"; voucher: Voucher }
  | { kind: "short"; business: Business }
  | null;

function initials(name: string) {
  return name.replace(/&/g, "").split(" ").filter(Boolean).slice(0, 2).map((w) => w[0]).join("");
}

export function Explore() {
  const { leaves, redeem } = useApp();
  const [view, setView] = useState<"map" | "list">("map");
  const [filter, setFilter] = useState<Category | "All">("All");
  const [selectedId, setSelectedId] = useState<string | null>("fern-yard");
  const [sheet, setSheet] = useState<Sheet>(null);

  const list = useMemo(
    () => (filter === "All" ? businesses : businesses.filter((b) => b.category === filter)),
    [filter],
  );
  const selected = businesses.find((b) => b.id === selectedId) ?? null;

  function handleRedeem(b: Business) {
    if (leaves < b.cost) {
      setSheet({ kind: "short", business: b });
      return;
    }
    const res = redeem(b);
    if (res.ok && res.voucher) setSheet({ kind: "success", voucher: res.voucher });
  }

  return (
    <>
      <AppHeader />
      <div className="screen view-enter">
        <section className="rw-head">
          <p className="eyebrow">Explore</p>
          <h1 className="display rw-title">Spend Leaves at the shops nearby.</h1>
          <p className="muted">
            Every redemption keeps money on your street. You have{" "}
            <strong style={{ color: "var(--accent-strong)" }}>
              {leaves.toLocaleString()} Leaves
            </strong>{" "}
            to spend.
          </p>
        </section>

        <div className="seg seg-wide">
          <button className={"seg-btn" + (view === "map" ? " on" : "")} onClick={() => setView("map")}>
            <Icon name="pin" size={16} strokeWidth={2.2} /> Map
          </button>
          <button className={"seg-btn" + (view === "list" ? " on" : "")} onClick={() => setView("list")}>
            <Icon name="gift" size={16} strokeWidth={2.2} /> List
          </button>
        </div>

        {view === "map" ? (
          <>
            <ExploreMap selectedId={selectedId} onSelect={(b) => setSelectedId(b.id)} />
            {!usingLiveMap && (
              <p className="map-hint muted">
                Showing the built-in map. Add a Google Maps key in your{" "}
                <code>.env</code> file to see the live map.
              </p>
            )}
            {selected && (
              <article className="map-pick card" key={selected.id}>
                <div className="biz-top">
                  <div className="biz-badge" style={{ background: categoryColor[selected.category] }}>
                    {initials(selected.name)}
                  </div>
                  <div className="biz-head">
                    <h3 className="biz-name">{selected.name}</h3>
                    <div className="biz-meta">
                      <span>{selected.category}</span>
                      <span className="dot-sep" />
                      <span className="row" style={{ gap: 3 }}>
                        <Icon name="pin" size={13} strokeWidth={2} />
                        {selected.distanceKm.toFixed(1)} km
                      </span>
                      <span className="dot-sep" />
                      <span>{selected.hours}</span>
                    </div>
                  </div>
                </div>
                <p className="biz-offer">{selected.offer}</p>
                <div className="biz-foot">
                  <div className="stack" style={{ gap: 5 }}>
                    <span className="leaves-chip">
                      <Icon name="leaf" size={15} strokeWidth={2} />
                      {selected.cost}
                    </span>
                    <span className="biz-value">{selected.discount}</span>
                  </div>
                  <button
                    className="btn btn-primary biz-cta"
                    onClick={() => handleRedeem(selected)}
                    disabled={leaves < selected.cost}
                  >
                    {leaves >= selected.cost ? "Redeem" : "Keep walking"}
                  </button>
                </div>
              </article>
            )}
          </>
        ) : (
          <>
            <div className="chips" role="tablist" aria-label="Categories">
              {(["All", ...categories] as (Category | "All")[]).map((c) => (
                <button
                  key={c}
                  role="tab"
                  aria-selected={filter === c}
                  className={"chip" + (filter === c ? " on" : "")}
                  onClick={() => setFilter(c)}
                >
                  {c}
                </button>
              ))}
            </div>
            <div className="biz-list">
              {list.map((b) => (
                <BusinessCard key={b.id} b={b} affordable={leaves >= b.cost} onRedeem={handleRedeem} />
              ))}
            </div>
          </>
        )}
      </div>

      {sheet && (
        <div className="sheet-scrim" onClick={() => setSheet(null)}>
          <div className="sheet" role="dialog" aria-modal="true" onClick={(e) => e.stopPropagation()}>
            <div className="sheet-grip" />
            {sheet.kind === "success" ? (
              <div className="stack" style={{ alignItems: "center", textAlign: "center", gap: 6 }}>
                <div className="sheet-mark">
                  <Icon name="check" size={30} strokeWidth={2.6} />
                </div>
                <h2 className="display sheet-title">Redeemed.</h2>
                <p className="muted">
                  {sheet.voucher.offer} at <strong>{sheet.voucher.businessName}</strong>
                </p>
                <div className="code-box">
                  <span className="eyebrow">Show this at the counter</span>
                  <span className="code tnum">{sheet.voucher.code}</span>
                </div>
                <p className="sheet-note muted">Saved to your Wallet. Valid for 14 days.</p>
                <button className="btn btn-primary btn-block" onClick={() => setSheet(null)}>
                  Done
                </button>
              </div>
            ) : (
              <div className="stack" style={{ alignItems: "center", textAlign: "center", gap: 8 }}>
                <div className="sheet-mark short">
                  <Icon name="leaf" size={28} strokeWidth={2.2} />
                </div>
                <h2 className="display sheet-title">Almost there.</h2>
                <p className="muted">
                  You need{" "}
                  <strong>{(sheet.business.cost - leaves).toLocaleString()} more Leaves</strong> for{" "}
                  {sheet.business.name}. That's about{" "}
                  {Math.ceil((sheet.business.cost - leaves) / 12).toLocaleString()}k more steps.
                </p>
                <button className="btn btn-primary btn-block" onClick={() => setSheet(null)}>
                  Keep walking
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </>
  );
}
