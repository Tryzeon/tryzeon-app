import { useEffect, useRef, useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import type { CatalogItem } from "../api/catalog";
import { Header } from "../components/Header";
import { ProductCard } from "../components/ProductCard";
import { WardrobeCard } from "../components/WardrobeCard";
import { useChat } from "../hooks/useChat";

const GREETING = "嗨！我是你的穿搭顧問 👗 告訴我你的需求吧 — 例如場合、風格，或想搭配的某件單品，我會幫你推薦合適的穿搭。";
const STARTERS = ["上班約會穿搭", "週末休閒風", "幫我搭一件白襯衫", "參加婚禮要穿什麼"];
const MAX_TEXT_LENGTH = 2000;

export function Chat() {
  const chat = useChat();
  const navigate = useNavigate();
  const [draft, setDraft] = useState("");
  const end = useRef<HTMLDivElement>(null);

  useEffect(() => {
    end.current?.scrollIntoView({ block: "end", behavior: "smooth" });
  }, [chat.entries.length, chat.busy]);

  function submit(e: FormEvent) {
    e.preventDefault();
    if (chat.send(draft)) setDraft("");
  }

  function openProduct(item: CatalogItem) {
    navigate(`/product/${item.productId}`, { state: { item } });
  }

  return (
    <div className="app chat">
      <Header />
      <main className="main chat__log">
        <p className="chat__bubble chat__bubble--bot">{GREETING}</p>

        {chat.entries.length === 0 && (
          <div className="chat__starters">
            {STARTERS.map((prompt) => (
              <button key={prompt} type="button" className="chat__starter" onClick={() => chat.send(prompt)}>
                {prompt}
              </button>
            ))}
          </div>
        )}

        {chat.entries.map((entry, i) => {
          switch (entry.kind) {
            case "user":
              return <p key={i} className="chat__bubble chat__bubble--user">{entry.text}</p>;
            case "text":
              return <p key={i} className="chat__bubble chat__bubble--bot">{entry.text}</p>;
            case "notice":
              return <p key={i} className="chat__notice">{entry.text}</p>;
            case "product":
              return (
                <div key={i} className="chat__product">
                  <ProductCard item={entry.item} onOpen={() => openProduct(entry.item)} />
                </div>
              );
            case "wardrobe":
              return (
                <div key={i} className="chat__product">
                  <WardrobeCard imagePath={entry.imagePath} />
                </div>
              );
          }
        })}

        {chat.busy && (
          <p className="chat__step">
            <span className="spinner spinner--ink" aria-hidden="true" />
            正在思考…
          </p>
        )}
        <div ref={end} />
      </main>

      <form className="chat__composer" onSubmit={submit}>
        <input
          className="chat__input"
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          maxLength={MAX_TEXT_LENGTH}
          placeholder="想找什麼？"
          enterKeyHint="send"
        />
        <button type="submit" className="chat__send" disabled={chat.busy || draft.trim().length === 0}>
          送出
        </button>
      </form>
    </div>
  );
}
