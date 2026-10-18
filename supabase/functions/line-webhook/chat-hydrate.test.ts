import { assertEquals } from "@std/assert";
import { makeLineAnswerRows } from "./chat-hydrate.ts";
import type { AnswerBlock } from "../_shared/chat/index.ts";
import type { LineProduct } from "./product-card.ts";

const BASE = "https://img.example";
const P1 = "8f14e45f-ceea-467a-9c8d-1b2c3d4e5f60";
const P2 = "a1b2c3d4-e5f6-4789-8abc-def012345678";
const W1 = "44444444-4444-4444-4444-444444444444";

const row = (over: Record<string, unknown> = {}) => ({
  id: P1,
  name: "白襯衫",
  price: 1200,
  image_paths: ["stores/s1/p1.jpg"],
  purchase_link: null,
  store_profiles: { name: "某店" },
  ...over,
});

function fakeAdmin(
  productRows: Record<string, unknown>[],
  wardrobeRows: Record<string, unknown>[] = [],
) {
  const tables: string[] = [];
  const queried: string[][] = [];
  const eqCalls: Array<[string, string]> = [];

  const client = {
    from(table: string) {
      const rows = table === "products" ? productRows : wardrobeRows;
      // Recorded on an actual `.in()` run, not on `.from()` alone: both
      // hydrators build their query unconditionally, so only the run itself
      // tells a real read apart from a query built and never fired.
      const runIn = (ids: string[]) => {
        tables.push(table);
        queried.push(ids);
        return Promise.resolve({ data: rows, error: null });
      };
      return {
        select() {
          return {
            in: (_c: string, ids: string[]) => runIn(ids),
            eq(column: string, value: string) {
              eqCalls.push([column, value]);
              return { in: (_c: string, ids: string[]) => runIn(ids) };
            },
          };
        },
      };
    },
    storage: {
      from() {
        return {
          createSignedUrls(paths: string[], _expiresIn: number) {
            return Promise.resolve({
              data: paths.map((p) => ({
                error: null,
                path: p,
                signedUrl: `https://sig.example/${p}?t=1`,
              })),
              error: null,
            });
          },
        };
      },
    },
  };

  // deno-lint-ignore no-explicit-any
  return { admin: client as any, tables, queried, eqCalls };
}

Deno.test("hydrates only the referenced product ids", async () => {
  const { admin, queried } = fakeAdmin([row(), row({ id: P2, name: "黑褲" })]);
  const hydrate = makeLineAnswerRows(BASE);
  const refs: AnswerBlock[] = [
    { type: "text", text: "為你找到" },
    { type: "picks", picks: [{ type: "product", id: P1 }, { type: "product", id: P2 }] },
  ];

  const rows = await hydrate(admin, "u1", refs);

  assertEquals(queried, [[P1, P2]]);
  assertEquals([...rows.products.keys()], [P1, P2]);
});

// Which rows survive the read is `fetchProductRows`' rule and is tested there.

Deno.test("the base url reaches the card", async () => {
  const { admin } = fakeAdmin([row()]);
  const rows = await makeLineAnswerRows(`${BASE}/`)(admin, "u1", [
    { type: "picks", picks: [{ type: "product", id: P1 }] },
  ]);

  assertEquals(
    (rows.products.get(P1) as LineProduct).imageUrl,
    "https://img.example/stores/s1/p1.jpg",
  );
});

Deno.test("a wardrobe ref reads the wardrobe, bound to the asking user", async () => {
  const wardrobeRow = {
    id: W1,
    image_path: "u1/top/w1.png",
    garment_type: "top",
    tags: ["寬鬆"],
  };
  const { admin, tables, eqCalls } = fakeAdmin([], [wardrobeRow]);

  const rows = await makeLineAnswerRows(BASE)(admin, "u1", [
    { type: "picks", picks: [{ type: "wardrobe", id: W1 }] },
  ]);

  assertEquals(tables, ["wardrobe_items"]);
  assertEquals(eqCalls, [["status", "active"], ["user_id", "u1"]]);
  assertEquals([...rows.wardrobe.keys()], [W1]);
});

Deno.test("neither kind of ref queries the other's table", async () => {
  const { admin, tables } = fakeAdmin([row()], []);

  await makeLineAnswerRows(BASE)(admin, "u1", [
    { type: "text", text: "再多說一點" },
    { type: "picks", picks: [{ type: "product", id: P1 }] },
  ]);

  assertEquals(tables, ["products"]);
});

Deno.test("a repeated id is asked for an id once however many rows name it", async () => {
  const { admin, queried } = fakeAdmin([row()]);

  await makeLineAnswerRows(BASE)(admin, "u1", [
    { type: "picks", picks: [{ type: "product", id: P1 }] },
    { type: "picks", picks: [{ type: "product", id: P1 }] },
  ]);

  assertEquals(queried, [[P1]]);
});

Deno.test("an outfit's pieces are read along with the row picks, each id once", async () => {
  const { admin, queried } = fakeAdmin([row(), row({ id: P2 })]);

  await makeLineAnswerRows(BASE)(admin, "u1", [
    { type: "picks", picks: [{ type: "product", id: P1 }] },
    {
      type: "outfits",
      outfits: [{ title: "週末休閒", pieces: [{ type: "product", id: P1 }, { type: "product", id: P2 }] }],
    },
  ]);

  assertEquals(queried, [[P1, P2]]);
});

Deno.test("an id that is not a uuid is never queried", async () => {
  const { admin, queried } = fakeAdmin([row()]);

  await makeLineAnswerRows(BASE)(admin, "u1", [
    { type: "picks", picks: [{ type: "product", id: "not-a-uuid" }, { type: "product", id: P1 }] },
  ]);

  assertEquals(queried, [[P1]]);
});
