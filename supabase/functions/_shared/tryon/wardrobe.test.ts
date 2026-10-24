import { assertEquals, assertRejects } from "@std/assert";
import {
  buildWardrobeGarmentDetail,
  resolveWardrobeGarment,
} from "./wardrobe.ts";
import { LIMITS } from "./types.ts";
import { WARDROBE_IMAGES_BUCKET } from "../supabase-storage.ts";
import { ValidationError } from "./errors.ts";
import type { DbClient } from "../supabase.ts";

const ID = "44444444-4444-4444-4444-444444444444";

interface LookupStub {
  row: Record<string, unknown> | null;
  error?: { message: string };
}

/** Records every `.eq()` the resolver applied, so a test can prove the
 * ownership bound reached the query. */
function fakeAdmin(stub: LookupStub) {
  const filters: Array<[string, string]> = [];
  const admin = {
    from: (_table: string) => ({
      select: () => {
        const chain = {
          eq: (column: string, value: string) => {
            filters.push([column, value]);
            return chain;
          },
          maybeSingle: () => {
            // The row comes back only when every filter matches it: recording
            // the filters is not enough, since without this, deleting the
            // ownership bound would leave the SECURITY test below passing.
            const row = stub.row;
            const match = row !== null &&
              filters.every(([column, value]) => row[column] === value);
            return Promise.resolve({
              data: match ? row : null,
              error: stub.error ?? null,
            });
          },
        };
        return chain;
      },
    }),
  } as unknown as DbClient;
  return { admin, filters };
}

Deno.test("buildWardrobeGarmentDetail lists the tags", () => {
  assertEquals(
    buildWardrobeGarmentDetail({
      image_path: "u1/top/a.png",
      garment_type: "top",
      tags: ["寬鬆", "米色"],
    }),
    "Tags: 寬鬆, 米色",
  );
});

Deno.test("buildWardrobeGarmentDetail has nothing to say for a row with no tags", () => {
  assertEquals(
    buildWardrobeGarmentDetail({
      image_path: "p",
      garment_type: "pants",
      tags: null,
    }),
    undefined,
  );
  assertEquals(
    buildWardrobeGarmentDetail({
      image_path: "p",
      garment_type: "pants",
      tags: [],
    }),
    undefined,
  );
});

Deno.test("buildWardrobeGarmentDetail ignores blank and non-string tags", () => {
  // `tags` is `text[]` with no element constraint, so a row can hold a NULL the
  // generated `string[]` says is impossible.
  assertEquals(
    buildWardrobeGarmentDetail({
      image_path: "p",
      garment_type: "top",
      tags: ["a", 7, "", null, "  ", "b"] as unknown as string[],
    }),
    "Tags: a, b",
  );
});

Deno.test("buildWardrobeGarmentDetail caps overlong detail at the limit", () => {
  const detail = buildWardrobeGarmentDetail({
    image_path: "p",
    garment_type: "top",
    tags: ["x".repeat(LIMITS.MAX_GARMENT_DETAIL_LENGTH + 200)],
  });
  assertEquals(detail?.length, LIMITS.MAX_GARMENT_DETAIL_LENGTH);
});

Deno.test("resolveWardrobeGarment rejects an id that cannot name a row", async () => {
  const { admin } = fakeAdmin({ row: null });
  await assertRejects(
    () => resolveWardrobeGarment(admin, "u1", "not-a-uuid"),
    ValidationError,
    "invalid wardrobeItemId",
  );
});

Deno.test("resolveWardrobeGarment binds the read to the asking user", async () => {
  const { admin, filters } = fakeAdmin({
    row: {
      id: ID,
      user_id: "u1",
      image_path: "u1/top/a.png",
      garment_type: "top",
      tags: ["寬鬆"],
    },
  });
  await resolveWardrobeGarment(admin, "u1", ID);

  assertEquals(filters, [["id", ID], ["user_id", "u1"]]);
});

Deno.test("resolveWardrobeGarment yields one image source, the garment type, and the detail", async () => {
  const { admin } = fakeAdmin({
    row: {
      id: ID,
      user_id: "u1",
      image_path: "u1/top/a.png",
      garment_type: "one_piece",
      tags: ["寬鬆"],
    },
  });
  const garment = await resolveWardrobeGarment(admin, "u1", ID);

  assertEquals(garment, {
    images: [{ bucket: WARDROBE_IMAGES_BUCKET, path: "u1/top/a.png" }],
    garmentType: "one_piece",
    detail: "Tags: 寬鬆",
  });
});

Deno.test("resolveWardrobeGarment passes a scopeless garment type through for the prompt to leave open", async () => {
  const { admin } = fakeAdmin({
    row: {
      id: ID,
      user_id: "u1",
      image_path: "u1/top/a.png",
      garment_type: "others",
      tags: [],
    },
  });
  const garment = await resolveWardrobeGarment(admin, "u1", ID);

  assertEquals(garment, {
    images: [{ bucket: WARDROBE_IMAGES_BUCKET, path: "u1/top/a.png" }],
    garmentType: "others",
  });
});

Deno.test("resolveWardrobeGarment leaves the detail out for a row with no tags", async () => {
  const { admin } = fakeAdmin({
    row: {
      id: ID,
      user_id: "u1",
      image_path: "u1/top/a.png",
      garment_type: "top",
      tags: [],
    },
  });
  const garment = await resolveWardrobeGarment(admin, "u1", ID);

  assertEquals(garment, {
    images: [{ bucket: WARDROBE_IMAGES_BUCKET, path: "u1/top/a.png" }],
    garmentType: "top",
  });
});

Deno.test("SECURITY: another user's item is indistinguishable from one that does not exist", async () => {
  // If the two ever report differently, this function becomes an oracle for
  // probing whether an id sits in somebody else's wardrobe. Do not "improve"
  // either message.
  const missing = await assertRejects(
    () => resolveWardrobeGarment(fakeAdmin({ row: null }).admin, "u1", ID),
    ValidationError,
  );
  const someoneElses = await assertRejects(
    () =>
      resolveWardrobeGarment(
        fakeAdmin({
          row: {
            id: ID,
            user_id: "u1",
            image_path: "u1/top/a.png",
            garment_type: "top",
            tags: [],
          },
        }).admin,
        "u2",
        ID,
      ),
    ValidationError,
  );

  assertEquals(missing.message, `no wardrobe item for wardrobeItemId: ${ID}`);
  assertEquals(missing.message, someoneElses.message);
});

Deno.test("resolveWardrobeGarment treats a blank image_path as no item", async () => {
  const { admin } = fakeAdmin({
    row: {
      id: ID,
      user_id: "u1",
      image_path: "   ",
      garment_type: "top",
      tags: [],
    },
  });
  await assertRejects(
    () => resolveWardrobeGarment(admin, "u1", ID),
    ValidationError,
    "no wardrobe item",
  );
});

Deno.test("resolveWardrobeGarment rejects a row whose path points outside its owner's folder", async () => {
  // The row passes the `user_id` filter, but `image_path` is client-written
  // free text and here names another user's folder.
  const { admin } = fakeAdmin({
    row: {
      id: ID,
      user_id: "u1",
      image_path: "u2/top/a.png",
      garment_type: "top",
      tags: [],
    },
  });
  await assertRejects(
    () => resolveWardrobeGarment(admin, "u1", ID),
    ValidationError,
    `no wardrobe item for wardrobeItemId: ${ID}`,
  );
});

Deno.test("resolveWardrobeGarment raises a broken query as a fault, not a bad request", async () => {
  const { admin } = fakeAdmin({ row: null, error: { message: "boom" } });
  const err = await assertRejects(
    () => resolveWardrobeGarment(admin, "u1", ID),
    Error,
  );
  assertEquals(err instanceof ValidationError, false);
  assertEquals(err.message.includes("boom"), true);
});
