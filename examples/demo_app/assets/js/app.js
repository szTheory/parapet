// Standard Phoenix 1.8 / phoenix_live_view ~> 1.1 entry point.
// Read the CSRF token so the LiveSocket can authenticate the WebSocket connection.
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

// phoenix_html side effects: form/link behavior (data-confirm, etc.)
import "phoenix_html";

// Phoenix Socket and LiveSocket
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken }
});

// Connect the LiveSocket so the WebSocket is established and phx-click events fire.
liveSocket.connect();

// Expose on window for debugging.
window.liveSocket = liveSocket;
