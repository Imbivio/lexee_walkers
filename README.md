# Lexee

**Walk. Earn. Support local.**

Lexee turns everyday steps into spending power at independent, local
businesses. You walk, you earn a currency called **Leaves**, and you redeem
those Leaves for real discounts at nearby cafés, bakeries, grocers, refill
stores, book shops, and studios. Two things happen at once: fewer short car
trips (measured as CO₂ kept out of the air) and more money flowing back into
small shops on your own street.

This repository is a working, mobile-first prototype — a React + TypeScript
single-page app you run in any browser and operate like a native phone app.
Everything you do persists on your device between sessions.

## Features

- **Accounts** — sign up, log in, and log out. Your session is remembered.
  A **"Try a demo account"** button drops you into a fully-populated app so you
  can see everything working immediately.
- **Persistence** — every account's steps, Leaves, vouchers, streak, badges,
  and settings are saved per-user and survive reloads and logouts.
- **Home** — daily step ring, live Leaves earned, a week chart, and your
  carbon impact for the week.
- **Track** — a live walk session. Steps, distance, time, CO₂ saved, and
  Leaves all climb in real time; end it and the Leaves bank into your balance.
- **Explore** — a real street **map** (Leaflet + OpenStreetMap, no API key or
  billing) with your location and business pins by category, plus a **list**
  view with filters. Redeem an offer and get a voucher code back.
- **Wallet** — Leaves balance, lifetime earnings, and redeemed vouchers.
- **Real badges** — 12 milestones that unlock from your actual activity
  (distance, streak, shops supported, Leaves, CO₂, early walks). Each shows a
  live progress bar, and earning one triggers a celebration.
- **Profile & settings** — lifetime impact, editable display name and daily
  step goal, and a light/dark toggle.

Because a browser can't read a real pedometer, walks use simulated step data so
the full earn → redeem → badge loop is interactive without device sensors.

## Design

- **Currency:** *Leaves* — ties the reward to sustainability and growth.
- **Palette:** a trail-green brand on a warm, green-biased near-white, with a
  single amber-gold accent reserved exclusively for the Leaves currency.
- **Type:** *Fraunces* (a warm serif, used sparingly for the wordmark and hero
  numbers) paired with *Hanken Grotesk* for the interface.
- **Themes:** full light and dark support, driven entirely by design tokens.
- No emoji — all iconography is a single family of hand-drawn SVG line icons.
- The Explore map uses OpenStreetMap tiles, gently tuned to the brand, and
  falls back to a bespoke stylized vector map when offline.

## Running it

```bash
npm install
npm run dev      # http://localhost:5173
```

```bash
npm run build    # type-check + production build to dist/
npm run preview  # serve the production build
```

## Tech

React 18, TypeScript, Vite, React Router.

- `src/store/auth.tsx` — accounts and session.
- `src/store/AppState.tsx` — per-user runtime state, the earning model, and the
  badge engine.
- `src/store/seed.ts` — the saved-data shape, the earning constants, and
  localStorage read/write in one place.

## Data & security

This prototype stores everything in the browser's `localStorage`, including
accounts. Passwords are only lightly obfuscated — this is fine for a local demo
but is **not** production security. The data shapes in `seed.ts` and `auth.tsx`
are intentionally close to what database rows would look like, so the natural
next step is to move accounts and data behind an API and a real database, with
passwords hashed server-side and the client holding only a session token.

## Project layout

```
src/
  main.tsx              app entry
  App.tsx               auth gate, routes, phone shell
  index.css             design tokens, themes, shell, shared primitives
  components.css        component styles
  store/
    auth.tsx            accounts + session
    AppState.tsx        runtime state, earning model, badge engine
    seed.ts             saved-data shape + persistence
  data/
    businesses.ts       local-business catalog (with map coordinates)
    badges.ts           badge definitions + progress logic
  components/           Icon, BottomNav, ProgressRing, WeekChart, ExploreMap,
                        MapLeaflet, MapView, BadgeUnlock, cards, header
  screens/              Auth, Home, Track, Explore, Wallet, Profile
```

Next steps toward a real product: a backend for accounts and cross-device sync,
genuine step tracking via the device's health APIs, a business-onboarding side,
and a real redemption/settlement flow with participating shops.
