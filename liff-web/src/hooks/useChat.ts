import { useCallback, useReducer, useRef } from "react";
import { catalogItemFromRow } from "../api/catalog";
import { sendChat } from "../api/chat";
import { userText } from "../api/chat-wire";
import { createChatReducer, initialChatState } from "../state/chat";

const chatReducer = createChatReducer(catalogItemFromRow);

/**
 * `inFlight` is the guard, not `state.turn`: two taps inside one render both
 * read the same state and would each start a request.
 */
export function useChat() {
  const [state, dispatch] = useReducer(chatReducer, initialChatState);
  const historyRef = useRef(state.history);
  historyRef.current = state.history;
  const inFlight = useRef(false);

  const send = useCallback((text: string): boolean => {
    const trimmed = text.trim();
    if (trimmed.length === 0 || inFlight.current) return false;
    inFlight.current = true;
    dispatch({ type: "send", text: trimmed });

    sendChat([...historyRef.current, userText(trimmed)])
      .then((events) => {
        for (const event of events) dispatch({ type: "event", event });
      })
      .catch((err) => console.error("[chat] turn failed:", err))
      .finally(() => {
        inFlight.current = false;
        dispatch({ type: "ended" });
      });
    return true;
  }, []);

  return { entries: state.entries, busy: state.turn !== null, send };
}
