import { useEffect, useRef, useState } from "react";
import { Loader } from "@googlemaps/js-api-loader";
import { businesses, categoryColor, type Business } from "../data/businesses";
import { Icon } from "./Icon";

/* Real Google Maps view. Rendered only when a key is present (see
   ExploreMap.tsx); otherwise the stylized MapView is used instead.

   The demo shops don't have real-world addresses, so we lay them out as small
   offsets around the map centre using the same relative positions defined in
   businesses.ts. That way they always appear as a walkable cluster around
   wherever the map is centred — including the user's real location. */

const DEFAULT_CENTER = { lat: 40.7215, lng: -73.9968 }; // a walkable neighbourhood
const SPREAD_LAT = 0.018;
const SPREAD_LNG = 0.024;

function businessGeo(center: { lat: number; lng: number }, b: Business) {
  return {
    lat: center.lat + ((50 - b.map.y) / 100) * SPREAD_LAT,
    lng: center.lng + ((b.map.x - 50) / 100) * SPREAD_LNG,
  };
}

// Low-saturation style tuned to the brand: soft greens, muted roads, few POIs.
const MAP_STYLE: google.maps.MapTypeStyle[] = [
  { elementType: "geometry", stylers: [{ color: "#eef1ea" }] },
  { elementType: "labels.icon", stylers: [{ visibility: "off" }] },
  { elementType: "labels.text.fill", stylers: [{ color: "#6b7a6f" }] },
  { elementType: "labels.text.stroke", stylers: [{ color: "#f4f6f2" }] },
  { featureType: "poi", stylers: [{ visibility: "off" }] },
  { featureType: "poi.park", elementType: "geometry", stylers: [{ color: "#d5e3d3" }] },
  { featureType: "poi.park", elementType: "labels.text", stylers: [{ visibility: "off" }] },
  { featureType: "road", elementType: "geometry", stylers: [{ color: "#ffffff" }] },
  { featureType: "road", elementType: "labels", stylers: [{ visibility: "off" }] },
  { featureType: "road.arterial", elementType: "geometry", stylers: [{ color: "#f7f8f5" }] },
  { featureType: "road.highway", elementType: "geometry", stylers: [{ color: "#eae7dd" }] },
  { featureType: "transit", stylers: [{ visibility: "off" }] },
  { featureType: "water", elementType: "geometry", stylers: [{ color: "#bcd8de" }] },
];

function pinIcon(color: string, active: boolean): google.maps.Symbol {
  return {
    path: google.maps.SymbolPath.CIRCLE,
    fillColor: color,
    fillOpacity: 1,
    strokeColor: "#ffffff",
    strokeWeight: 2,
    scale: active ? 9 : 6.5,
  };
}

export function MapGoogle({
  apiKey,
  selectedId,
  onSelect,
}: {
  apiKey: string;
  selectedId: string | null;
  onSelect: (b: Business) => void;
}) {
  const divRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<google.maps.Map | null>(null);
  const markersRef = useRef<Record<string, google.maps.Marker>>({});
  const userMarkerRef = useRef<google.maps.Marker | null>(null);
  const centerRef = useRef(DEFAULT_CENTER);
  const [status, setStatus] = useState<"loading" | "ready" | "error">("loading");

  // load the API + build the map once
  useEffect(() => {
    let cancelled = false;
    const loader = new Loader({ apiKey, version: "weekly" });

    loader
      .importLibrary("maps")
      .then(({ Map }) => {
        if (cancelled || !divRef.current) return;
        const map = new Map(divRef.current, {
          center: DEFAULT_CENTER,
          zoom: 15,
          disableDefaultUI: true,
          zoomControl: true,
          clickableIcons: false,
          styles: MAP_STYLE,
          backgroundColor: "#eef1ea",
        });
        mapRef.current = map;

        for (const b of businesses) {
          const marker = new google.maps.Marker({
            position: businessGeo(centerRef.current, b),
            map,
            title: b.name,
            icon: pinIcon(categoryColor[b.category], b.id === selectedId),
          });
          marker.addListener("click", () => onSelect(b));
          markersRef.current[b.id] = marker;
        }
        setStatus("ready");

        // try to recentre on the user's real location
        if (navigator.geolocation) {
          navigator.geolocation.getCurrentPosition(
            (pos) => {
              if (cancelled) return;
              const c = { lat: pos.coords.latitude, lng: pos.coords.longitude };
              centerRef.current = c;
              map.panTo(c);
              for (const b of businesses) {
                markersRef.current[b.id]?.setPosition(businessGeo(c, b));
              }
              placeUser(c);
            },
            () => placeUser(DEFAULT_CENTER),
            { timeout: 6000 },
          );
        } else {
          placeUser(DEFAULT_CENTER);
        }
      })
      .catch(() => !cancelled && setStatus("error"));

    function placeUser(c: { lat: number; lng: number }) {
      if (!mapRef.current) return;
      userMarkerRef.current?.setMap(null);
      userMarkerRef.current = new google.maps.Marker({
        position: c,
        map: mapRef.current,
        title: "You",
        zIndex: 999,
        icon: {
          path: google.maps.SymbolPath.CIRCLE,
          fillColor: "#1e6e45",
          fillOpacity: 1,
          strokeColor: "#ffffff",
          strokeWeight: 3,
          scale: 7,
        },
      });
    }

    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [apiKey]);

  // reflect selection: resize icons + pan to the chosen shop
  useEffect(() => {
    for (const b of businesses) {
      markersRef.current[b.id]?.setIcon(pinIcon(categoryColor[b.category], b.id === selectedId));
    }
    if (selectedId && mapRef.current) {
      const b = businesses.find((x) => x.id === selectedId);
      if (b) mapRef.current.panTo(businessGeo(centerRef.current, b));
    }
  }, [selectedId]);

  function locateMe() {
    if (!navigator.geolocation || !mapRef.current) return;
    navigator.geolocation.getCurrentPosition((pos) => {
      const c = { lat: pos.coords.latitude, lng: pos.coords.longitude };
      centerRef.current = c;
      mapRef.current!.panTo(c);
      mapRef.current!.setZoom(15);
      for (const b of businesses) markersRef.current[b.id]?.setPosition(businessGeo(c, b));
      userMarkerRef.current?.setPosition(c);
    });
  }

  return (
    <div className="gmap-wrap">
      <div ref={divRef} className="gmap" aria-label="Map of nearby shops" />
      {status !== "error" && (
        <button className="gmap-locate" onClick={locateMe} aria-label="Center on my location">
          <Icon name="pin" size={19} strokeWidth={2.2} />
        </button>
      )}
      {status === "loading" && <div className="gmap-note">Loading map…</div>}
      {status === "error" && (
        <div className="gmap-note error">
          Couldn't load Google Maps. Check the API key in your .env file.
        </div>
      )}
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
