import { useEffect, useRef, useState } from "react";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { businesses, categoryColor, type Business } from "../data/businesses";
import { MapView } from "./MapView";
import { Icon } from "./Icon";

/* A real, free street map via Leaflet + OpenStreetMap tiles — no API key,
   no billing. The demo shops don't have real-world addresses, so they're
   laid out as small offsets around the map centre (reusing their relative
   positions from businesses.ts), which keeps them a walkable cluster around
   wherever the map is centred, including the user's real location. */

const DEFAULT_CENTER: [number, number] = [40.7215, -73.9968];
const SPREAD_LAT = 0.018;
const SPREAD_LNG = 0.024;

function businessGeo(center: [number, number], b: Business): [number, number] {
  return [
    center[0] + ((50 - b.map.y) / 100) * SPREAD_LAT,
    center[1] + ((b.map.x - 50) / 100) * SPREAD_LNG,
  ];
}

function pinStyle(color: string, active: boolean): L.CircleMarkerOptions {
  return {
    radius: active ? 10 : 7,
    fillColor: color,
    color: "#ffffff",
    weight: 2.5,
    opacity: 1,
    fillOpacity: 1,
  };
}

export function MapLeaflet({
  selectedId,
  onSelect,
}: {
  selectedId: string | null;
  onSelect: (b: Business) => void;
}) {
  // If the browser is offline the tiles can't load, so use the offline-safe
  // stylized map instead.
  const [offline] = useState(() => typeof navigator !== "undefined" && navigator.onLine === false);

  const divRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<L.Map | null>(null);
  const markersRef = useRef<Record<string, L.CircleMarker>>({});
  const userRef = useRef<L.CircleMarker | null>(null);
  const centerRef = useRef<[number, number]>(DEFAULT_CENTER);

  useEffect(() => {
    if (offline || !divRef.current || mapRef.current) return;

    const map = L.map(divRef.current, {
      center: DEFAULT_CENTER,
      zoom: 15,
      zoomControl: false,
      attributionControl: true,
    });
    mapRef.current = map;
    L.control.zoom({ position: "bottomleft" }).addTo(map);

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    }).addTo(map);

    for (const b of businesses) {
      const marker = L.circleMarker(
        businessGeo(centerRef.current, b),
        pinStyle(categoryColor[b.category], b.id === selectedId),
      )
        .addTo(map)
        .on("click", () => onSelect(b));
      marker.bindTooltip(b.name, { direction: "top", offset: [0, -6] });
      markersRef.current[b.id] = marker;
    }

    userRef.current = L.circleMarker(DEFAULT_CENTER, {
      radius: 8,
      fillColor: "#1e6e45",
      color: "#ffffff",
      weight: 3,
      fillOpacity: 1,
    })
      .addTo(map)
      .bindTooltip("You", { direction: "top", offset: [0, -6] });

    // Leaflet needs a nudge once the container has its final size
    setTimeout(() => map.invalidateSize(), 60);

    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => recenter([pos.coords.latitude, pos.coords.longitude], false),
        () => {},
        { timeout: 6000 },
      );
    }

    function recenter(c: [number, number], zoom: boolean) {
      const m = mapRef.current;
      if (!m) return;
      centerRef.current = c;
      m.panTo(c);
      if (zoom) m.setZoom(15);
      for (const b of businesses) markersRef.current[b.id]?.setLatLng(businessGeo(c, b));
      userRef.current?.setLatLng(c);
    }

    return () => {
      map.remove();
      mapRef.current = null;
      markersRef.current = {};
      userRef.current = null;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [offline]);

  // reflect selection: restyle pins + pan to the chosen shop
  useEffect(() => {
    for (const b of businesses) {
      markersRef.current[b.id]?.setStyle(pinStyle(categoryColor[b.category], b.id === selectedId));
    }
    if (selectedId) {
      const b = businesses.find((x) => x.id === selectedId);
      if (b) {
        markersRef.current[b.id]?.bringToFront();
        mapRef.current?.panTo(businessGeo(centerRef.current, b));
      }
    }
  }, [selectedId]);

  function locateMe() {
    if (!navigator.geolocation || !mapRef.current) return;
    navigator.geolocation.getCurrentPosition((pos) => {
      const c: [number, number] = [pos.coords.latitude, pos.coords.longitude];
      centerRef.current = c;
      mapRef.current!.setView(c, 15);
      for (const b of businesses) markersRef.current[b.id]?.setLatLng(businessGeo(c, b));
      userRef.current?.setLatLng(c);
    });
  }

  if (offline) return <MapView selectedId={selectedId} onSelect={onSelect} />;

  return (
    <div className="gmap-wrap">
      <div ref={divRef} className="gmap" aria-label="Map of nearby shops" />
      <button className="gmap-locate" onClick={locateMe} aria-label="Center on my location">
        <Icon name="pin" size={19} strokeWidth={2.2} />
      </button>
      <div className="map-legend gmap-legend">
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
