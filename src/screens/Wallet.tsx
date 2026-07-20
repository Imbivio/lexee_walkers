import { AppHeader } from "../components/AppHeader";
import { Icon } from "../components/Icon";
import { useApp } from "../store/AppState";

function timeAgo(ts: number) {
  const mins = Math.round((Date.now() - ts) / 60000);
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.round(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  return `${Math.round(hrs / 24)}d ago`;
}

export function Wallet() {
  const { leaves, lifetimeLeaves, vouchers, markUsed } = useApp();
  const active = vouchers.filter((v) => !v.used);
  const past = vouchers.filter((v) => v.used);

  return (
    <>
      <AppHeader showLeaves={false} />
      <div className="screen view-enter">
        <section className="wallet-card">
          <div className="wallet-glow" />
          <span className="wallet-lbl">Leaves balance</span>
          <div className="wallet-bal">
            <Icon name="leaf" size={34} strokeWidth={2} />
            <span className="display tnum">{leaves.toLocaleString()}</span>
          </div>
          <div className="wallet-foot">
            <span>Lifetime earned</span>
            <span className="tnum">{lifetimeLeaves.toLocaleString()} Leaves</span>
          </div>
        </section>

        <section className="block-head">
          <span className="eyebrow">Ready to use</span>
          <span className="section-title">Your vouchers</span>
        </section>

        {active.length === 0 ? (
          <div className="empty card">
            <Icon name="gift" size={26} className="empty-ic" />
            <p>No vouchers yet. Redeem Leaves in Rewards to see them here.</p>
          </div>
        ) : (
          <div className="voucher-list">
            {active.map((v) => (
              <article className="voucher card" key={v.id}>
                <div className="voucher-perf" aria-hidden="true" />
                <div className="voucher-main">
                  <div className="between">
                    <span className="voucher-biz">{v.businessName}</span>
                    <span className="leaves-chip">
                      <Icon name="leaf" size={14} strokeWidth={2} />
                      {v.cost}
                    </span>
                  </div>
                  <p className="voucher-offer">{v.offer}</p>
                  <div className="voucher-code-row">
                    <div className="stack">
                      <span className="eyebrow">Code</span>
                      <span className="code sm tnum">{v.code}</span>
                    </div>
                    <button className="btn btn-ghost voucher-btn" onClick={() => markUsed(v.id)}>
                      <Icon name="check" size={17} strokeWidth={2.2} />
                      Mark used
                    </button>
                  </div>
                  <span className="voucher-time muted">Redeemed {timeAgo(v.redeemedAt)}</span>
                </div>
              </article>
            ))}
          </div>
        )}

        {past.length > 0 && (
          <>
            <section className="block-head" style={{ marginTop: 24 }}>
              <span className="eyebrow">History</span>
              <span className="section-title">Used</span>
            </section>
            <div className="voucher-list">
              {past.map((v) => (
                <div className="used-row card" key={v.id}>
                  <div className="stack" style={{ gap: 2 }}>
                    <span className="voucher-biz">{v.businessName}</span>
                    <span className="muted" style={{ fontSize: 13 }}>{v.offer}</span>
                  </div>
                  <span className="used-tag">Used</span>
                </div>
              ))}
            </div>
          </>
        )}
      </div>
    </>
  );
}
