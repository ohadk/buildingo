/** Normalize parking input from API clients into a clean string[]. */
export function normalizeParkingSpots(input: {
  parkingSpots?: string[] | null;
  parkingSpot?: string | null;
}): string[] {
  const fromList = (input.parkingSpots ?? [])
    .map((s) => s.trim())
    .filter(Boolean);
  if (fromList.length) {
    return [...new Set(fromList)].slice(0, 10);
  }
  const single = input.parkingSpot?.trim();
  return single ? [single] : [];
}

/** Human-readable parking line for search / labels. */
export function formatParkingSpots(spots: string[] | null | undefined): string | null {
  if (!spots?.length) return null;
  return spots.join(" · ");
}
