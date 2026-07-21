import { NavLink } from "react-router-dom";
import { Icon, type IconName } from "./Icon";

const tabs: { to: string; label: string; icon: IconName }[] = [
  { to: "/", label: "Home", icon: "home" },
  { to: "/track", label: "Track", icon: "walk" },
  { to: "/explore", label: "Explore", icon: "pin" },
  { to: "/wallet", label: "Wallet", icon: "wallet" },
  { to: "/profile", label: "Profile", icon: "user" },
];

export function BottomNav() {
  return (
    <nav className="tabbar" aria-label="Primary">
      {tabs.map((t) => (
        <NavLink
          key={t.to}
          to={t.to}
          end={t.to === "/"}
          className={({ isActive }) => "tab" + (isActive ? " active" : "")}
        >
          <span className="tab-icon">
            <Icon name={t.icon} size={23} strokeWidth={2} />
          </span>
          <span className="tab-label">{t.label}</span>
        </NavLink>
      ))}
    </nav>
  );
}
