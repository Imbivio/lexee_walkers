import { useMemo, useState } from "react";
import { AppHeader } from "../components/AppHeader";
import { BusinessCard } from "../components/BusinessCard";
import { Icon } from "../components/Icon";
import { businesses, categories, type Business, type Category } from "../data/businesses";
import { useApp, type Voucher } from "../store/AppState";

export function Rewards() {
  const { leaves, redeem } = useApp();
  const [filter, setFilter] = useState<Category | "All">("All");
  const [sheet, setSheet] = useState<
    | { kind: "success"; voucher: Voucher }
    | { kind: "short"; business: Business }
    | null
  >(null);

  const list = useMemo(
    () => (filter === "All" ? businesses : businesses.filter((b) => b.category === filter)),
    [filter],
  );

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
          <p className="eyebrow">Rewards</p>
          <h1 className="display rw-title">Spend Leaves at the shops nearby.</h1>
          <p className="muted">
            Every redemption is money that stays on your street. You have{" "}
            <strong style={{ color: "var(--accent-strong)" }}>
              {leaves.toLocaleString()} Leaves
            </strong>{" "}
            to spend.
          </p>
        </section>

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
            <BusinessCard
              key={b.id}
              b={b}
              affordable={leaves >= b.cost}
              onRedeem={handleRedeem}
            />
          ))}
        </div>
      </div>

      {sheet && (
        <div className="sheet-scrim" onClick={() => setSheet(null)}>
          <div
            className="sheet"
            role="dialog"
            aria-modal="true"
            onClick={(e) => e.stopPropagation()}
          >
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
                <p className="sheet-note muted">
                  Saved to your Wallet. Valid for 14 days.
                </p>
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
                  <strong>{(sheet.business.cost - leaves).toLocaleString()} more Leaves</strong>{" "}
                  for {sheet.business.name}. That's about{" "}
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
