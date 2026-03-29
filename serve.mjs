import http from 'http';
import fs from 'fs';
import path from 'path';

const PORT = 4001;
const MIME = {
  '.html': 'text/html',
  '.css': 'text/css',
  '.js': 'application/javascript',
  '.mjs': 'text/javascript',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.ico': 'image/x-icon',
  '.webp': 'image/webp',
  '.woff2': 'font/woff2',
  '.woff': 'font/woff',
};

http.createServer((req, res) => {
  let urlPath = req.url.split('?')[0];

  // Remove trailing slash for non-root paths and try index.html
  let filePath = '.' + urlPath;

  if (filePath === './') {
    filePath = './index.html';
  } else if (!path.extname(filePath)) {
    // No extension — try as directory with index.html
    if (!filePath.endsWith('/')) filePath += '/';
    filePath += 'index.html';
  }

  const ext = path.extname(filePath).toLowerCase();

  fs.readFile(filePath, (err, data) => {
    if (err) {
      // Try index.html fallback
      const altPath = filePath.replace(/\.html$/, '') + '/index.html';
      fs.readFile(altPath, (err2, data2) => {
        if (err2) {
          res.writeHead(404, { 'Content-Type': 'text/html' });
          res.end('<h1>404 Not Found</h1><p><a href="/">← Home</a></p>');
          return;
        }
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(data2);
      });
      return;
    }
    res.writeHead(200, { 'Content-Type': MIME[ext] || 'text/plain' });
    res.end(data);
  });
}).listen(PORT, () => {
  console.log(`\nServing at http://localhost:${PORT}\n`);
  console.log('Press Ctrl+C to stop.\n');
});
