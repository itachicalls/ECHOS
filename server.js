const http = require("http");
const fs = require("fs");
const path = require("path");
const { WebSocketServer } = require("ws");
const versusLobby = require("./versus/lobby");

const ROOT = path.join(__dirname, "build", "web");
const PORT = Number(process.env.PORT || 4173);

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".json": "application/json",
};

const server = http.createServer((req, res) => {
  const urlPath = decodeURIComponent((req.url || "/").split("?")[0]);
  const filePath = path.join(ROOT, urlPath === "/" ? "index.html" : urlPath);

  if (!filePath.startsWith(ROOT)) {
    res.writeHead(403).end("Forbidden");
    return;
  }

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404).end("Not found");
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    res.writeHead(200, {
      "Content-Type": MIME[ext] || "application/octet-stream",
      "Cross-Origin-Opener-Policy": "same-origin",
      "Cross-Origin-Embedder-Policy": "require-corp",
      "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
      "Pragma": "no-cache",
      "Expires": "0",
      "ETag": `"${Date.now()}-${data.length}"`,
    });
    res.end(data);
  });
});

const wss = new WebSocketServer({ server, path: "/versus" });
wss.on("connection", (ws) => {
  ws.on("message", (raw) => versusLobby.handleMessage(ws, raw.toString()));
  ws.on("close", () => versusLobby.handleClose(ws));
});

if (!fs.existsSync(path.join(ROOT, "index.html"))) {
  console.error("Missing web build. Run: npm run export:web");
  process.exit(1);
}

server.listen(PORT, () => {
  console.log(`Echoheart web build: http://localhost:${PORT}`);
  console.log(`Versus lobby: ws://localhost:${PORT}/versus`);
});
