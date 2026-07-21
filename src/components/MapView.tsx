import { businesses, categoryColor, type Business } from "../data/businesses";

/* A hand-composed neighbourhood map. Coordinates live in a 0..100 space
   (see businesses.ts); the walker "You" is anchored at the centre. Kept as
   bespoke vector art so it sits inside the brand rather than clashing with
   generic map tiles. */

export function MapView({
  selectedId,
  onSelect,
}: {
  selectedId: string | null;
  onSelect: (b: Business) => void;
}) {
  return (
    <div className="map-canvas">
      <svg viewBox="0 0 100 100" className="map-svg" role="img" aria-label="Map of nearby shops">
        {/* land */}
        <rect x="0" y="0" width="100" height="100" style={{ fill: "var(--map-land)" }} />

        {/* river */}
        <path
          d="M-5 78 C 20 70, 30 88, 52 82 S 88 66, 108 74 L 108 110 L -5 110 Z"
          style={{ fill: "var(--map-water)" }}
        />
        {/* parks */}
        <path
          d="M6 8 C 22 2, 34 10, 30 24 C 26 38, 8 36, 4 24 Z"
          style={{ fill: "var(--map-park)" }}
        />
        <path
          d="M72 14 C 92 10, 98 26, 90 34 C 80 44, 66 32, 68 22 Z"
          style={{ fill: "var(--map-park)" }}
        />

        {/* roads */}
        <g style={{ stroke: "var(--map-road)" }} strokeLinecap="round" fill="none">
          <path d="M50 -4 L50 104" strokeWidth="3.4" />
          <path d="M-4 50 L104 50" strokeWidth="3.4" />
          <path d="M14 -4 L22 104" strokeWidth="2" />
          <path d="M82 -4 L74 104" strokeWidth="2" />
          <path d="M-4 24 L104 30" strokeWidth="2" />
          <path d="M-4 72 L104 66" strokeWidth="2" />
        </g>
        <g style={{ stroke: "var(--map-road-mid)" }} strokeLinecap="round" fill="none">
          <path d="M50 -4 L50 104" strokeWidth="1.6" />
          <path d="M-4 50 L104 50" strokeWidth="1.6" />
        </g>

        {/* range rings around the walker */}
        <circle cx="50" cy="50" r="20" style={{ stroke: "var(--map-ring)" }} strokeWidth="0.5" fill="none" strokeDasharray="1.5 2" />
        <circle cx="50" cy="50" r="34" style={{ stroke: "var(--map-ring)" }} strokeWidth="0.5" fill="none" strokeDasharray="1.5 2" />

        {/* business pins */}
        {businesses.map((b) => {
          const active = b.id === selectedId;
          const color = categoryColor[b.category];
          return (
            <g
              key={b.id}
              className={"map-pin" + (active ? " active" : "")}
              transform={`translate(${b.map.x} ${b.map.y})`}
              onClick={() => onSelect(b)}
              role="button"
              aria-label={b.name}
            >
              <circle r="6.4" className="map-pin-hit" fill="transparent" />
              <circle r={active ? 3.6 : 2.9} fill={color} className="map-pin-dot" />
              <circle r={active ? 3.6 : 2.9} fill="none" stroke="#fff" strokeWidth="1" />
            </g>
          );
        })}

        {/* you */}
        <g transform="translate(50 50)">
          <circle r="8" className="you-halo" />
          <circle r="3.2" style={{ fill: "var(--brand)" }} stroke="#fff" strokeWidth="1.4" />
        </g>
      </svg>

      <div className="map-legend">
        <span className="map-you-key">
          <span className="you-swatch" /> You
        </span>
        {Object.entries(categoryColor).map(([cat, color]) => (
          <span key={cat} className="map-key">
            <span className="map-swatch" style={{ background: color }} />
            {cat}
          </span>
        ))}
      </div>
    </div>
  );
}
