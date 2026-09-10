/**
 * Does NOT decide which size to recommend — that stays in the app's
 * `FitCalculator`.
 */
import type { BodyMeasurements } from "../user-profile.ts";
import { LIMITS } from "./types.ts";

/**
 * As stored in `product_sizes.garment_measurements`; sparse, since store owners
 * publish only what they actually measured.
 */
export interface GarmentMeasurements {
  shoulder_width?: number;
  chest_circumference?: number;
  sleeve_length?: number;
  waist_circumference?: number;
  hip_circumference?: number;
  thigh_circumference?: number;
  length?: number;
}

export interface MeasurementRange {
  min: number;
  max: number;
}

/**
 * As stored in `product_sizes.body_measurement_ranges`: the body a size is published as
 * fitting, keyed like `BodyMeasurements`. Height is centimeters, weight is
 * kilograms. Only height and weight are described here — for a circumference
 * the ease clause above already says how the garment sits.
 */
export type BodyMeasurementRanges = Partial<
  Record<keyof BodyMeasurements, MeasurementRange>
>;

/** The `product_sizes` row as the fit description needs it. */
export interface ProductSizeFit {
  name: string;
  garment_measurements: GarmentMeasurements | null;
  body_measurement_ranges: BodyMeasurementRanges | null;
}

const BODY_MEASUREMENT_RANGE_DIMENSIONS: ReadonlyArray<{
  key: "height" | "weight";
  unit: "cm" | "kg";
  phrase: (range: string) => string;
}> = [
  {
    key: "height",
    unit: "cm",
    phrase: (r) => `recommended for wearers ${r} tall`,
  },
  {
    key: "weight",
    unit: "kg",
    phrase: (r) => `recommended for wearers of ${r}`,
  },
];

/**
 * Ease thresholds in centimeters, per body dimension. DERIVED, NOT CALIBRATED:
 * every number is read off
 * `lib/feature/personal/shop/domain/services/ease_table.dart` by flattening its
 * `ProductFit` axis — `slimMin` is the slim band's lower bound, `regularMax`
 * the regular band's upper bound, `looseMax` the loose band's upper bound. If
 * that table is re-calibrated, re-derive these rather than tuning them here.
 *
 * Per-dimension because ease does not normalize across dimensions: `EaseTable`
 * calibrates waist/hips/thigh to trouser ease and chest to top ease, so the
 * same +6cm is ordinary on a chest and generous on a waist. Expressing ease as
 * a percentage of the body dimension was tried and left the two ladders more
 * than 3x apart.
 */
interface EaseLadder {
  slimMin: number;
  regularMax: number;
  looseMax: number;
}

/**
 * Exactly `EaseTable._circumferences` — the only dimensions with bands to
 * derive a ladder from.
 */
const CIRCUMFERENCES: ReadonlyArray<{
  label: string;
  garment: keyof GarmentMeasurements;
  body: keyof BodyMeasurements;
  ladder: EaseLadder;
}> = [
  {
    label: "chest",
    garment: "chest_circumference",
    body: "chest",
    ladder: { slimMin: 4, regularMax: 15, looseMax: 24 },
  },
  {
    label: "waist",
    garment: "waist_circumference",
    body: "waist",
    ladder: { slimMin: 0, regularMax: 4, looseMax: 8 },
  },
  {
    label: "hips",
    garment: "hip_circumference",
    body: "hips",
    ladder: { slimMin: 2, regularMax: 9, looseMax: 14 },
  },
  {
    label: "thigh",
    garment: "thigh_circumference",
    body: "thigh",
    ladder: { slimMin: 1, regularMax: 7, looseMax: 12 },
  },
];

/**
 * Waist's `slimMin` is 0, so its skin-close bucket is unreachable — the rule
 * applied uniformly, not a special case.
 */
function easePhrase(ease: number, ladder: EaseLadder): string {
  if (ease < 0) {
    return "compression — the fabric is pulled taut against the body";
  }
  if (ease < ladder.slimMin) {
    return "skin-close, follows the body with no slack";
  }
  if (ease <= ladder.regularMax) {
    return "fitted, follows the body with a little room";
  }
  if (ease <= ladder.looseMax) return "loose, hangs away from the body";
  return "billowy, drapes well clear of the body";
}

function cm(value: number): string {
  return `${Number(value.toFixed(1))}`;
}

function signedCm(value: number): string {
  return value >= 0 ? `+${cm(value)}cm` : `-${cm(Math.abs(value))}cm`;
}

function num(value: unknown): number | undefined {
  return typeof value === "number" && Number.isFinite(value)
    ? value
    : undefined;
}

/**
 * Truncation is safe here for the same reason it is in
 * `buildProductGarmentDetail`: this text is server-generated, so nobody is told
 * "accepted" while their input was quietly cut short.
 */
export function buildGarmentFitDetail(
  size: ProductSizeFit,
  body: BodyMeasurements,
): string | undefined {
  const clauses: string[] = [];
  if (size.garment_measurements) {
    appendMeasurementClauses(clauses, size.garment_measurements, body);
  }
  if (size.body_measurement_ranges) {
    appendBodyMeasurementRangeClauses(
      clauses,
      size.body_measurement_ranges,
      body,
    );
  }

  if (clauses.length === 0) return undefined;

  return `size ${size.name}: ${clauses.join("; ")}`.slice(
    0,
    LIMITS.MAX_GARMENT_FIT_LENGTH,
  );
}

function appendMeasurementClauses(
  clauses: string[],
  size: GarmentMeasurements,
  body: BodyMeasurements,
): void {
  for (const dim of CIRCUMFERENCES) {
    const garmentValue = num(size[dim.garment]);
    const bodyValue = num(body[dim.body]);
    if (garmentValue === undefined || bodyValue === undefined) continue;
    const ease = garmentValue - bodyValue;
    clauses.push(
      `${dim.label} ${cm(garmentValue)}cm on a ${
        cm(bodyValue)
      }cm ${dim.label} ` +
        `(${signedCm(ease)} — ${easePhrase(ease, dim.ladder)})`,
    );
  }

  // Shoulders are a linear seam, not a circumference: `EaseTable` gives them a
  // band barely wider than the body (-1..2, 0..3), so an adjective ladder would
  // drop every garment into one bucket.
  const shoulderGarment = num(size.shoulder_width);
  const shoulderBody = num(body.shoulder);
  if (shoulderGarment !== undefined && shoulderBody !== undefined) {
    const halfDiff = (shoulderGarment - shoulderBody) / 2;
    const seat = halfDiff === 0
      ? "sitting exactly on the shoulder points"
      : halfDiff > 0
      ? `sitting ${cm(halfDiff)}cm past each shoulder point`
      : `sitting ${cm(-halfDiff)}cm inside each shoulder point`;
    clauses.push(
      `shoulder seams ${cm(shoulderGarment)}cm on ${
        cm(shoulderBody)
      }cm shoulders, ${seat}`,
    );
  }

  // Body length and sleeve length have no body counterpart (see
  // `garment_fit_dimension.dart`, where both map to a null body type): deriving
  // "lands at the high hip" would need torso proportions we do not collect.
  const length = num(size.length);
  if (length !== undefined) {
    const height = num(body.height);
    clauses.push(
      height === undefined
        ? `body length ${cm(length)}cm`
        : `body length ${cm(length)}cm on a ${cm(height)}cm wearer`,
    );
  }

  const sleeve = num(size.sleeve_length);
  if (sleeve !== undefined) clauses.push(`sleeve length ${cm(sleeve)}cm`);
}

/**
 * Where the wearer falls against the store's stated range: outside it, a
 * taller wearer makes the same garment sit shorter and a heavier one fills it
 * further, which the ease clauses cannot say for a dimension with no garment
 * counterpart.
 */
function appendBodyMeasurementRangeClauses(
  clauses: string[],
  bodyMeasurementRanges: BodyMeasurementRanges,
  body: BodyMeasurements,
): void {
  for (const dim of BODY_MEASUREMENT_RANGE_DIMENSIONS) {
    const range = bodyMeasurementRanges[dim.key];
    const min = num(range?.min);
    const max = num(range?.max);
    const value = num(body[dim.key]);
    if (min === undefined || max === undefined || value === undefined) continue;
    const position = value < min
      ? `${cm(min - value)}${dim.unit} below that range`
      : value > max
      ? `${cm(value - max)}${dim.unit} above that range`
      : "within that range";
    clauses.push(
      `${dim.phrase(`${cm(min)}–${cm(max)}${dim.unit}`)}; this wearer is ${
        cm(value)
      }${dim.unit}, ${position}`,
    );
  }
}
