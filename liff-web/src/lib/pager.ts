/** Rubber-banding past either edge would otherwise round to a page that does
 * not exist. */
export function nearestPage(
  scrollLeft: number,
  pageWidth: number,
  pageCount: number,
): number {
  const last = Math.max(0, pageCount - 1);
  return Math.min(last, Math.max(0, Math.round(scrollLeft / pageWidth)));
}
