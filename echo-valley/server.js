// Minimal static server for the Echo Valley web build.
// Sends the COOP/COEP headers Godot's web export needs (SharedArrayBuffer).
const http = require("http");
const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "build", "web");
const PORT = process.env.PORT || 8080;

const TYPES = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript",
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".json": "application/json",
  ".ico": "image/x-icon",
  ".audio.worklet.js": "text/javascript",
};

const server = http.createServer((req, res) => {
  let urlPath = decodeURIComponent(req.url.split("?")[0]);
  if (urlPath === "/") urlPath = "/index.html";
  const filePath = path.join(ROOT, urlPath);

  if (!filePath.startsWith(ROOT)) {
    res.writeHead(403);
    res.end("Forbidden");
    return;
  }

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end("Not found: " + urlPath);
      return;
    }
    const ext = path.extname(filePath);
    res.setHeader("Cross-Origin-Opener-Policy", "same-origin");
    res.setHeader("Cross-Origin-Embedder-Policy", "require-corp");
    if ([".pck", ".wasm", ".js", ".html"].includes(ext)) {
      res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    }
    res.setHeader("Content-Type", TYPES[ext] || "application/octet-stream");
    res.writeHead(200);
    res.end(data);
  });
});

server.listen(PORT, () => {
  console.log(`Echo Valley running at http://localhost:${PORT}`);
});
