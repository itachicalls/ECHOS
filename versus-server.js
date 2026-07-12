/**
 * Harmona versus lobby — WebSocket only (for Render).
 * Serves wss://ws.harmona.fun/versus while the game stays on Vercel at harmona.fun.
 */
const http = require("http");
const { WebSocketServer } = require("ws");
const versusLobby = require("./versus/lobby");

const PORT = Number(process.env.PORT || 4174);

const server = http.createServer((req, res) => {
  const path = (req.url || "/").split("?")[0];
  if (path === "/" || path === "/health") {
    res.writeHead(200, { "Content-Type": "text/plain; charset=utf-8" });
    res.end("harmona versus lobby ok\n");
    return;
  }
  res.writeHead(404).end("Not found");
});

const wss = new WebSocketServer({ server, path: "/versus" });
wss.on("connection", (ws) => {
  ws.on("message", (raw) => versusLobby.handleMessage(ws, raw.toString()));
  ws.on("close", () => versusLobby.handleClose(ws));
});

server.listen(PORT, () => {
  console.log(`Versus lobby listening on port ${PORT} (path /versus)`);
});
