// Honda listing site — static server with the same cookie password gate as vibe-mart.
// Node built-ins only. `node server.js` → http://localhost:4700
// AUTH_PASSWORD empty = no gate (local dev). Set it in .env for the public deploy.
const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// tiny .env loader (no deps)
try {
  fs.readFileSync(path.join(__dirname, '.env'), 'utf8').split('\n').forEach((l) => {
    const m = l.match(/^\s*([A-Z_][A-Z0-9_]*)\s*=\s*(.*?)\s*$/);
    if (m && process.env[m[1]] === undefined) process.env[m[1]] = m[2];
  });
} catch (_) {}

const CFG = {
  PORT: parseInt(process.env.PORT || '4700', 10),
  AUTH_PASSWORD: process.env.AUTH_PASSWORD || '',
};
const STATIC = path.join(__dirname, 'public');
const DATA = path.join(__dirname, 'data');
const SESSION_TOKEN = crypto.createHash('sha256').update('honda::' + (CFG.AUTH_PASSWORD || 'local')).digest('hex').slice(0, 32);

const MIME = { '.html': 'text/html; charset=utf-8', '.css': 'text/css', '.js': 'text/javascript', '.json': 'application/json',
  '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png', '.webp': 'image/webp', '.svg': 'image/svg+xml', '.pdf': 'application/pdf', '.ico': 'image/x-icon' };

function parseCookies(req) { const o = {}; (req.headers.cookie || '').split(';').forEach((p) => { const i = p.indexOf('='); if (i > 0) o[p.slice(0, i).trim()] = p.slice(i + 1).trim(); }); return o; }
function isAuthed(req) { return !CFG.AUTH_PASSWORD || parseCookies(req).honda_auth === SESSION_TOKEN; }
function send(res, code, obj) { res.writeHead(code, { 'Content-Type': 'application/json' }); res.end(JSON.stringify(obj)); }
function readBody(req) { return new Promise((r) => { let b = ''; req.on('data', (c) => (b += c)); req.on('end', () => { try { r(JSON.parse(b || '{}')); } catch { r({}); } }); }); }
function serveFile(res, file) {
  fs.readFile(file, (e, d) => {
    if (e) { res.writeHead(404); return res.end('not found'); }
    const ext = path.extname(file).toLowerCase();
    res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream', 'Cache-Control': ext === '.html' || ext === '.json' ? 'no-cache' : 'public, max-age=86400' });
    res.end(d);
  });
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://x');
  if (req.method === 'POST' && url.pathname === '/api/login') {
    const b = await readBody(req);
    if (CFG.AUTH_PASSWORD && (b.password || '') === CFG.AUTH_PASSWORD) {
      res.writeHead(200, { 'Content-Type': 'application/json', 'Set-Cookie': `honda_auth=${SESSION_TOKEN}; HttpOnly; Path=/; Max-Age=2592000; SameSite=Lax` });
      return res.end('{"ok":true}');
    }
    return send(res, 401, { error: 'wrong password' });
  }
  if (!isAuthed(req)) return serveFile(res, path.join(STATIC, 'login.html'));
  if (url.pathname === '/api/listing') return serveFile(res, path.join(DATA, 'listing.json'));
  if (url.pathname === '/api/photos') {
    return fs.readdir(path.join(STATIC, 'photos'), (e, files) => send(res, 200, (files || []).filter((f) => /\.(jpe?g|png|webp)$/i.test(f)).sort()));
  }
  let p = decodeURIComponent(url.pathname);
  if (p === '/') p = '/index.html';
  const file = path.normalize(path.join(STATIC, p));
  if (!file.startsWith(STATIC)) { res.writeHead(403); return res.end(); }
  serveFile(res, file);
});

server.listen(CFG.PORT, () => console.log(`\n  🚗  Honda listing at http://localhost:${CFG.PORT}  ${CFG.AUTH_PASSWORD ? '(password gate ON)' : '(no gate — local)'}\n`));
