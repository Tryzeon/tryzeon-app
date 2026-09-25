import { matchPath } from "react-router-dom";

export type Pane = "shop" | "home" | "chat" | "product";

/** `matchPath` rather than string equality: it accepts a trailing slash, which an exact compare would hand to the shop pane. */
export function paneOf(pathname: string): Pane {
  if (matchPath("/home", pathname)) return "home";
  if (matchPath("/chat", pathname)) return "chat";
  if (matchPath("/product/:id", pathname)) return "product";
  return "shop";
}
