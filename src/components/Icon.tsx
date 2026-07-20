type IconProps = {
  name: IconName;
  size?: number;
  strokeWidth?: number;
  className?: string;
};

export type IconName =
  | "home"
  | "walk"
  | "gift"
  | "wallet"
  | "user"
  | "leaf"
  | "bell"
  | "flame"
  | "cloud"
  | "route"
  | "clock"
  | "steps"
  | "chevron"
  | "check"
  | "play"
  | "stop"
  | "pin"
  | "star"
  | "sun"
  | "moon"
  | "close"
  | "trophy"
  | "shield";

// All icons drawn on a 24x24 grid, stroke-based, no fills — one visual family.
const paths: Record<IconName, JSX.Element> = {
  home: (
    <>
      <path d="M4 10.5 12 4l8 6.5" />
      <path d="M6 9.5V20h12V9.5" />
      <path d="M10 20v-5h4v5" />
    </>
  ),
  walk: (
    <>
      <circle cx="13" cy="4.5" r="1.6" />
      <path d="M12.5 8.5 10 12l2.2 2 1 5.5" />
      <path d="M12.5 8.5 16 10.5" />
      <path d="M12.2 14 9 20" />
    </>
  ),
  gift: (
    <>
      <rect x="4" y="9" width="16" height="4" rx="1" />
      <path d="M5 13v7h14v-7" />
      <path d="M12 9v11" />
      <path d="M12 9C12 6 10 4.5 8.5 5.2 7 6 8 9 12 9Z" />
      <path d="M12 9c0-3 2-4.5 3.5-3.8C17 6 16 9 12 9Z" />
    </>
  ),
  wallet: (
    <>
      <rect x="3.5" y="6" width="17" height="13" rx="3" />
      <path d="M3.5 10h17" />
      <circle cx="16.5" cy="14.5" r="1.2" />
    </>
  ),
  user: (
    <>
      <circle cx="12" cy="8" r="3.6" />
      <path d="M5 20c0-3.6 3.1-6 7-6s7 2.4 7 6" />
    </>
  ),
  leaf: (
    <>
      <path d="M5 19C5 11 11 5 19 5c0 8-6 14-14 14Z" />
      <path d="M5 19C8 15 11.5 12 15 10" />
    </>
  ),
  bell: (
    <>
      <path d="M6 16.5V11a6 6 0 0 1 12 0v5.5l1.4 2H4.6L6 16.5Z" />
      <path d="M10 19.5a2 2 0 0 0 4 0" />
    </>
  ),
  flame: (
    <>
      <path d="M12 3c3 3.5 5 5.5 5 9a5 5 0 0 1-10 0c0-1.6.7-2.8 1.6-3.8C9 10 10 9 10 7c1.2.8 2 1.8 2 3 0-2 0-4 0-7Z" />
    </>
  ),
  cloud: (
    <>
      <path d="M7 18h9.5a3.5 3.5 0 0 0 .3-7A5 5 0 0 0 7.2 10 3.5 3.5 0 0 0 7 18Z" />
    </>
  ),
  route: (
    <>
      <circle cx="6" cy="18" r="2" />
      <circle cx="18" cy="6" r="2" />
      <path d="M8 18h6a3 3 0 0 0 0-6H9a3 3 0 0 1 0-6h3" />
    </>
  ),
  clock: (
    <>
      <circle cx="12" cy="12" r="8" />
      <path d="M12 8v4.3l2.8 1.7" />
    </>
  ),
  steps: (
    <>
      <rect x="4" y="14" width="6" height="6" rx="2" />
      <rect x="14" y="4" width="6" height="6" rx="2" />
      <path d="M10 17h2a2 2 0 0 0 2-2V9" />
    </>
  ),
  chevron: <path d="m9 6 6 6-6 6" />,
  check: <path d="m5 12.5 4.5 4.5L19 7" />,
  play: <path d="M8 5.5v13l11-6.5-11-6.5Z" />,
  stop: <rect x="7" y="7" width="10" height="10" rx="2.5" />,
  pin: (
    <>
      <path d="M12 21c4-4 6.5-7 6.5-10.5A6.5 6.5 0 0 0 5.5 10.5C5.5 14 8 17 12 21Z" />
      <circle cx="12" cy="10.3" r="2.3" />
    </>
  ),
  star: (
    <path d="M12 4.5l2.3 4.7 5.2.8-3.7 3.6.9 5.1L12 16.4l-4.6 2.3.9-5.1L4.5 10l5.2-.8L12 4.5Z" />
  ),
  sun: (
    <>
      <circle cx="12" cy="12" r="4" />
      <path d="M12 3v2M12 19v2M3 12h2M19 12h2M5.6 5.6l1.4 1.4M17 17l1.4 1.4M18.4 5.6 17 7M7 17l-1.4 1.4" />
    </>
  ),
  moon: <path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5Z" />,
  close: <path d="M6 6l12 12M18 6 6 18" />,
  trophy: (
    <>
      <path d="M7 5h10v4a5 5 0 0 1-10 0V5Z" />
      <path d="M7 6.5H4.5V8a3 3 0 0 0 3 3M17 6.5h2.5V8a3 3 0 0 1-3 3" />
      <path d="M12 14v3M9 20h6M10 20l.5-3h3l.5 3" />
    </>
  ),
  shield: (
    <>
      <path d="M12 3.5 19 6v5c0 4.5-3 7.7-7 9-4-1.3-7-4.5-7-9V6l7-2.5Z" />
      <path d="m9 12 2 2 4-4" />
    </>
  ),
};

export function Icon({ name, size = 22, strokeWidth = 1.9, className }: IconProps) {
  return (
    <svg
      className={className}
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={strokeWidth}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      {paths[name]}
    </svg>
  );
}
