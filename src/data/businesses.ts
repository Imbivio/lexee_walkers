export type Category = "Cafe" | "Grocer" | "Wellness" | "Books" | "Bakery" | "Refill";

export type Business = {
  id: string;
  name: string;
  category: Category;
  blurb: string;
  distanceKm: number;
  offer: string;
  cost: number; // Leaves
  discount: string; // human-readable value
  featured?: boolean;
  // brand color used sparingly for the storefront initial tile
  hue: string;
  address: string;
  hours: string;
  // position on the stylized Explore map, in a 0..100 coordinate space
  // (the walker "You" is anchored at 50,50)
  map: { x: number; y: number };
};

// Per-category accent used for map pins and category labels.
export const categoryColor: Record<Category, string> = {
  Cafe: "#2f7d52",
  Bakery: "#b7791f",
  Grocer: "#4e8b3a",
  Refill: "#3f8f6a",
  Books: "#7a5cc0",
  Wellness: "#2f7d8f",
};

export const businesses: Business[] = [
  {
    id: "fern-yard",
    name: "Fern & Yard Coffee",
    category: "Cafe",
    blurb: "Slow-roasted beans from a family lot. Two blocks from the greenway.",
    distanceKm: 0.4,
    offer: "Free filter coffee with any pastry",
    cost: 120,
    discount: "Worth ~$4.50",
    featured: true,
    hue: "#2f7d52",
    address: "12 Greenway Row",
    hours: "Open until 5:00 PM",
    map: { x: 41, y: 40 },
  },
  {
    id: "milldon-bakery",
    name: "Milldon Street Bakery",
    category: "Bakery",
    blurb: "Sourdough baked at 5am. First loaf out is always still warm.",
    distanceKm: 0.7,
    offer: "20% off your first loaf",
    cost: 90,
    discount: "Save up to $2.20",
    hue: "#b7791f",
    address: "3 Milldon Street",
    hours: "Open until 2:00 PM",
    map: { x: 62, y: 34 },
  },
  {
    id: "greenhaus",
    name: "Greenhaus Refill",
    category: "Refill",
    blurb: "Bring your own jars. Pantry staples by weight, zero packaging.",
    distanceKm: 1.1,
    offer: "$5 off a refill over $25",
    cost: 200,
    discount: "Save $5.00",
    featured: true,
    hue: "#3f8f6a",
    address: "48 Canal Walk",
    hours: "Open until 6:00 PM",
    map: { x: 33, y: 61 },
  },
  {
    id: "marlow-books",
    name: "Marlow & Co. Books",
    category: "Books",
    blurb: "Independent shelves, handwritten staff picks, a reading nook out back.",
    distanceKm: 1.4,
    offer: "15% off any single title",
    cost: 150,
    discount: "Up to $4.00",
    hue: "#7a5cc0",
    address: "27 Marlow Lane",
    hours: "Open until 7:00 PM",
    map: { x: 68, y: 63 },
  },
  {
    id: "cedar-grocer",
    name: "Cedar Lane Grocer",
    category: "Grocer",
    blurb: "Produce from three farms inside 40 miles. Ask for the seconds box.",
    distanceKm: 0.9,
    offer: "$3 off fresh produce",
    cost: 110,
    discount: "Save $3.00",
    hue: "#4e8b3a",
    address: "5 Cedar Lane",
    hours: "Open until 8:00 PM",
    map: { x: 55, y: 58 },
  },
  {
    id: "still-water",
    name: "Still Water Studio",
    category: "Wellness",
    blurb: "Neighborhood yoga and stretch classes in a converted print shop.",
    distanceKm: 1.8,
    offer: "Drop-in class for half price",
    cost: 320,
    discount: "Save ~$11",
    hue: "#2f7d8f",
    address: "90 Printers Yard",
    hours: "Classes to 9:00 PM",
    map: { x: 24, y: 33 },
  },
  {
    id: "juniper-cafe",
    name: "Juniper Corner Cafe",
    category: "Cafe",
    blurb: "Oat-milk everything and a patio that catches the morning sun.",
    distanceKm: 2.2,
    offer: "Buy one, gift one drink",
    cost: 140,
    discount: "Worth ~$5",
    hue: "#2f7d52",
    address: "14 Juniper Corner",
    hours: "Open until 4:00 PM",
    map: { x: 78, y: 46 },
  },
  {
    id: "hearth-bakery",
    name: "Hearth & Rye",
    category: "Bakery",
    blurb: "Cardamom buns on weekends. They sell out by ten, walk early.",
    distanceKm: 2.6,
    offer: "Free bun with any coffee",
    cost: 100,
    discount: "Worth ~$3.75",
    hue: "#b7791f",
    address: "2 Rye Court",
    hours: "Weekends from 8:00 AM",
    map: { x: 19, y: 74 },
  },
];

export const categories: Category[] = [
  "Cafe",
  "Bakery",
  "Grocer",
  "Refill",
  "Books",
  "Wellness",
];
