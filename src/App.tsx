import { Route, Routes, useLocation } from "react-router-dom";
import { BottomNav } from "./components/BottomNav";
import { Home } from "./screens/Home";
import { Track } from "./screens/Track";
import { Rewards } from "./screens/Rewards";
import { Wallet } from "./screens/Wallet";
import { Profile } from "./screens/Profile";

export default function App() {
  const location = useLocation();
  return (
    <div className="stage">
      <div className="shell">
        <Routes location={location} key={location.pathname}>
          <Route path="/" element={<Home />} />
          <Route path="/track" element={<Track />} />
          <Route path="/rewards" element={<Rewards />} />
          <Route path="/wallet" element={<Wallet />} />
          <Route path="/profile" element={<Profile />} />
        </Routes>
        <BottomNav />
      </div>
    </div>
  );
}
