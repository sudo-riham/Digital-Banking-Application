'use strict';

// Invoked by Windows when the browser redirects to dabi-lab3://callback?...
// Forwards the deep-link URI to the running local proxy server so the Flutter
// app can receive the dabi-lab3://callback redirect even when testing on desktop.

const http = require('http');

const rawUri = process.argv[2] || '';
if (!rawUri) {
  process.exit(0);
}

const payload = JSON.stringify({ uri: rawUri });

const req = http.request(
  {
    hostname: '127.0.0.1',
    port: process.env.PORT || 4000,
    path: '/proxy/deep-link-relay',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(payload),
    },
  },
  () => {
    process.exit(0);
  }
);

req.on('error', () => {
  process.exit(0);
});

req.write(payload);
req.end();
