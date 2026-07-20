import { useApp } from "../store/AppState";
import { Icon } from "./Icon";

export function AppHeader({ showLeaves = true }: { showLeaves?: boolean }) {
  const { leaves } = useApp();
  return (
    <header className="appbar">
      <div className="wordmark">
        lexee<span className="dot" />
      </div>
      <div className="row" style={{ gap: 10 }}>
        {showLeaves && (
          <span className="leaves-chip tnum">
            <Icon name="leaf" size={15} strokeWidth={2} />
            {leaves.toLocaleString()}
          </span>
        )}
        <button className="icon-btn" aria-label="Notifications">
          <Icon name="bell" size={20} />
        </button>
      </div>
    </header>
  );
}
