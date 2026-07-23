import type { Business } from "../data/businesses";
import { MapLeaflet } from "./MapLeaflet";

type Props = {
  selectedId: string | null;
  onSelect: (b: Business) => void;
};

/** The Explore map: a real OpenStreetMap street map (no key needed), with an
    offline-safe stylized fallback handled inside MapLeaflet. */
export function ExploreMap(props: Props) {
  return <MapLeaflet {...props} />;
}
