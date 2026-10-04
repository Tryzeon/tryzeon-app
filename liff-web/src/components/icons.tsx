const STROKE = {
  fill: "none",
  stroke: "currentColor",
  strokeWidth: 1.75,
  strokeLinecap: "round",
  strokeLinejoin: "round",
} as const;

export function SearchIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" {...STROKE}>
      <circle cx="11" cy="11" r="7" />
      <path d="m20 20-3.5-3.5" />
    </svg>
  );
}

export function ChevronLeftIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" {...STROKE}>
      <path d="m14.5 6-6 6 6 6" />
    </svg>
  );
}

export function PersonIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" {...STROKE}>
      <circle cx="12" cy="8" r="4" />
      <path d="M4.5 20.5a7.5 7.5 0 0 1 15 0" />
    </svg>
  );
}

export function ShirtIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" {...STROKE}>
      <path d="M8.5 3.5 4 6l1.5 4.5L8 9.5V20h8V9.5l2.5 1L20 6l-4.5-2.5a3.5 3.5 0 0 1-7 0Z" />
    </svg>
  );
}

export function ChatIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" {...STROKE}>
      <path d="M20 12a8 8 0 0 1-11.6 7.1L4 20l1-4.2A8 8 0 1 1 20 12Z" />
    </svg>
  );
}

export function CameraPlusIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" {...STROKE}>
      <path d="M21 13v5a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h3l2-3h4" />
      <circle cx="12" cy="13" r="3.5" />
      <path d="M19 2v6M16 5h6" />
    </svg>
  );
}
