// tools/test_network_endpoints.js
const https = require('https');

function testUrl(name, url, headers = {}) {
  return new Promise((resolve) => {
    const start = Date.now();
    const req = https.get(
      url,
      { headers: { 'User-Agent': 'EVayLanka/1.0 (lk.evaylanka.app)', ...headers } },
      (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          const ms = Date.now() - start;
          const ok = res.statusCode >= 200 && res.statusCode < 400;
          console.log(`[${ok ? 'PASS' : 'FAIL'}] ${name}: HTTP ${res.statusCode} (${ms}ms, payload: ${data.length} bytes)`);
          resolve({ name, status: res.statusCode, timeMs: ms, ok, length: data.length });
        });
      }
    );
    req.on('error', (err) => {
      console.log(`[FAIL] ${name}: Network Error: ${err.message}`);
      resolve({ name, error: err.message, ok: false });
    });
    req.setTimeout(8000, () => {
      req.destroy();
      console.log(`[FAIL] ${name}: Request Timed Out (8000ms)`);
      resolve({ name, timeout: true, ok: false });
    });
  });
}

async function run() {
  console.log('================================================================');
  console.log('LIVE NETWORK CONNECTIVITY & THIRD-PARTY ENDPOINTS VERIFICATION');
  console.log('================================================================');
  await testUrl('OpenStreetMap Raster Tiles (Web Mercator)', 'https://tile.openstreetmap.org/7/96/60.png');
  await testUrl('OSRM Driving Router (Colombo -> Nuwara Eliya)', 'https://router.project-osrm.org/route/v1/driving/79.8612,6.9271;80.7800,6.9700?overview=full');
  await testUrl('Nominatim Geocoding API (Nuwara Eliya, LK)', 'https://nominatim.openstreetmap.org/search?q=Nuwara+Eliya,+Sri+Lanka&format=json&limit=1&countrycodes=lk');
  await testUrl('Firebase Auth API Gateway', 'https://identitytoolkit.googleapis.com');
  console.log('================================================================');
}

run();
