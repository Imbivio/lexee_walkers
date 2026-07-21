import { Route, Routes, useLocation } from "react-router-dom";
import { BottomNav } from "./components/BottomNav";
import { BadgeUnlock } from "./components/BadgeUnlock";
import { Auth } from "./screens/Auth";
import { Home } from "./screens/Home";
import { Track } from "./screens/Track";
import { Explore } from "./screens/Explore";
import { Wallet } from "./screens/Wallet";
import { Profile } from "./screens/Profile";
import { AppProvider } from "./store/AppState";
import { useAuth } from "./store/auth";

function MainApp() {
  const location = useLocation();
  return (
    <div className="stage">
      <div className="shell">
        <Routes location={location} key={location.pathname}>
          <Route path="/" element={<Home />} />
          <Route path="/track" element={<Track />} />
          <Route path="/explore" element={<Explore />} />
          <Route path="/wallet" element={<Wallet />} />
          <Route path="/profile" element={<Profile />} />
          <Route path="*" element={<Home />} />
        </Routes>
        <BottomNav />
        <BadgeUnlock />
      </div>
    </div>
  );
}

export default function App() {
  const { user, ready } = useAuth();

  if (!ready) {
    return (
      <div className="stage">
        <div className="shell splash">
          <span className="wordmark splash-mark">
            lexee<span className="dot" />
          </span>
        </div>
      </div>
    );
  }

  if (!user) return <Auth />;

  // key by user id so switching accounts fully re-initialises app state
  return (
    <AppProvider key={user.id}>
      <MainApp />
    </AppProvider>
  );
}
