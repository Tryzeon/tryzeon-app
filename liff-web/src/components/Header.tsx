export function Header({ title }: { title?: string | null }) {
  return (
    <header className="header">
      <p className="header__eyebrow">Virtual Try-On</p>
      <h1 className="header__mark">{title ?? "Tryzeon"}</h1>
    </header>
  );
}
