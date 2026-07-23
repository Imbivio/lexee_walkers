import type { Business } from "../data/businesses";
import { MapView } from "./MapView";
import { MapGoogle } from "./MapGoogle";

const KEY = import.meta.env.VITE_GOOGLE_MAPS_API_KEY?.trim();

type Props = {
  selectedId: string | null;
  onSelect: (b: Business) => void;
};

/** Live Google map when a key is configured, otherwise the stylized map. */
export function ExploreMap(props: Props) {
  if (KEY) return <MapGoogle apiKey={KEY} {...props} />;
  return <MapView {...props} />;
}

export const usingLiveMap = Boolean(KEY);
