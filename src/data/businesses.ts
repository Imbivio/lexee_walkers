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
