# Kai Hohonu — Game Design Notes

## Design pillars

1. **Slow, honest progression.** No fast dopamine faucet — every
   upgrade is a goal you work toward for a session or three. Target
   pacing below.
2. **Skill matters.** Approach (fish spook by distance and rarity),
   charge timing, breath management, and depth risk are all player
   skill, not just stats.
3. **Authentically Hawai'i.** Real species with Hawaiian names, the
   state fish (humuhumunukunukuāpua'a), invasive-species culling
   (roi/ta'ape/to'au — a real practice), FAD buoys, and pidgin-flavored
   quest text.
4. **Shareable moments.** Golden fish (1/200, 6x value), trophy sizes,
   and legendary catches fire server-wide announcements — free
   word-of-mouth inside every server.

## Progression pacing (tuned targets)

Income with starter gear on the shallow reef ≈ **1,000 coins/hour**,
rising to ~3–5k/hour at the drop-off with mid gear.

| Milestone | Approx. playtime |
|---|---|
| Three-prong spear (250) | 15–20 min |
| Rubber fins (800) | ~1 h |
| Kayak (3,500) | 2–3 h |
| Mini speargun (12,000) | 5–6 h |
| Skiff (16,000) | ~8 h |
| Bluewater gun (90,000) | 20+ h |
| Sportfisher (300,000) + railgun (220,000) | end-game, quest-locked |

Breath: level N needs `90 * N^1.7` cumulative underwater seconds.
Level 5 ≈ 23 min of dive time, level 12 ≈ 2 h, level 50 (125s hold)
≈ 19 h. Diving *is* the training — no separate minigame.

## Catch math

- Size roll `norm = rand^2.2` — big fish are genuinely rare.
- Value = `baseValue * (0.55 + 1.45 * norm^1.6)`, golden ×6.
- Catch chance = `clamp(power * (0.4 + 0.6*charge) / (0.7 + kg/6), 0.08, 0.95)`
  — a bamboo pole *can* land a 40 kg ulua at ~8%: viral-clip material.
- Risk: blacking out underwater drops 25% of your bag where you died.

## Zones

| Zone | Distance | Depth | Highlights |
|---|---|---|---|
| Shallow Reef | 168–295 | 3–12 | manini, weke, humuhumu, kūmū |
| Outer Reef | 305–535 | 8–27 | uhu, 'ōmilu, mū, roi, menpachi (night) |
| The Drop-off | 550–980 | 18–80 | uku, kāhala, 'ōpakapaka, ulua — needs light below 30 |
| Open Ocean (FAD) | ~1,500 out | 4–55 | aku, mahimahi, ono, 'ahi, kajiki (mythic) |

Distance is the gate: far zones are *technically* swimmable but boats
make them practical (kayak 35 → sportfisher 90 speed).

## Post-launch roadmap (not yet implemented)

**Retention**
- Daily bounty board ("3 kūmū today, 2x price") and daily login streaks.
- Weekly server tournaments: biggest fish / heaviest bag, with title
  rewards ("Lawai'a Nui").
- Aquarium housing system — display trophy fish, visit friends' tanks.
- Night sharks near the drop-off that steal bagged fish — risk spike.
- Rebirth system: reset coins/gear for a permanent sell multiplier +
  cosmetic wetsuit tier.

**Monetization (fair, no pay-to-win fish)**
- Game passes: VIP (+25% sell price, golden name), extra bag slots,
  cosmetic wetsuits/spear skins, boat horn/colors.
- Dev products: coin packs (small, price-anchored), "Boat delivery"
  (spawn boat anywhere once).
- Nothing that raises catch chance — skill stays sacred.

**Social**
- Dive buddy bonus: +10% lung XP when diving within 20 studs of a
  friend.
- Photo mode with fish-hold pose for thumbnails/shares.

## Engineering notes / known simplifications

- Fish are anchored parts CFramed by a 10 Hz server loop. Fine for
  ~120 fish; if server bandwidth becomes an issue, move rendering
  client-side and replicate only spawn/waypoint seeds.
- Boats are server-owned physics (input has slight latency but can't
  be exploited). Flip network ownership to the driver if it feels
  sluggish and add server speed checks.
- NPCs are stylized pedestal figures built in code; replace with rigged
  R15 models + animations when art exists.
- Fish visuals are colored ellipsoids with a wagging tail. Swap in
  MeshParts per species later — ids/attributes already carry everything
  needed.
