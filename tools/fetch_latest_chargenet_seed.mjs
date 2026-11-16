import fs from 'node:fs/promises';

const CHARGENET_URL =
  'https://api.chargenet.lk:13100/ChargerHandler.asmx/ShowAllChargePointData';

async function main() {
  console.log('Fetching live ChargeNET charge points...');
  const res = await fetch(CHARGENET_URL);
  if (!res.ok) {
    throw new Error(`ChargeNET returned HTTP ${res.status}`);
  }
  const data = await res.json();
  const rawList = data?.listOfChargePoints || [];
  console.log(`Received ${rawList.length} raw charge points.`);

  const chargers = [];
  const seenIds = new Set();

  for (const p of rawList) {
    const ref = (p.reference || '').trim();
    const lat = parseFloat(p.latitude);
    const lng = parseFloat(p.longitude);
    if (!ref || isNaN(lat) || isNaN(lng)) continue;

    // Deduplicate refs
    const id = `chargenet-${ref}`;
    if (seenIds.has(id)) continue;
    seenIds.add(id);

    // Clean location name
    let name = (p.location || '').trim();
    if (!name || name.toLowerCase().includes('create for testing')) {
      name = `ChargeNET Station ${ref}`;
    }

    // Clean address
    const address = (p.address || '').trim().replace(/[\r\n]+/g, ' ');

    // Extract power
    let powerKw = null;
    const kwMatch =
      name.match(/(\d+(?:\.\d+)?)\s*kW/i) || address.match(/(\d+(?:\.\d+)?)\s*kW/i);
    if (kwMatch) {
      powerKw = parseFloat(kwMatch[1]);
    } else if (p.type === 'L3') {
      powerKw = 50.0;
    } else if (p.type === 'L2') {
      powerKw = 6.6;
    }

    // Status
    const status = (p.availability_status || 'UNKNOWN').toUpperCase();
    const slots = status === 'AVAILABLE' ? 1 : 0;

    // Connectors
    const type = (p.type || '').trim();
    const protocol = (p.protocol || '').replace(/_/g, ' ').trim();
    const connectorTypes = [];
    if (type) connectorTypes.push(type);
    if (protocol && !connectorTypes.includes(protocol)) {
      connectorTypes.push(protocol);
    }

    // Clean City extraction
    let city = 'Sri Lanka';
    if (address) {
      const parts = address
        .split(',')
        .map((s) => s.trim().replace(/\.$/, ''))
        .filter(Boolean);
      for (let i = parts.length - 1; i >= 0; i--) {
        let part = parts[i]
          .replace(/0\d{9}.*$/, '')
          .replace(/Station Owner.*$/i, '')
          .replace(/contact number.*$/i, '')
          .replace(/\+?\d{2,4}\s*\d{3,4}/g, '')
          .replace(/\(.*?\)/g, '')
          .trim();
        if (part.length >= 3 && !/^\d+$/.test(part) && !part.toLowerCase().includes('testing')) {
          city = part;
          break;
        }
      }
    }

    chargers.push({
      id,
      name,
      city,
      lat,
      lng,
      slots,
      powerKw,
      connectorTypes,
      address,
      status,
      network: 'ChargeNET',
    });
  }

  console.log(`Parsed ${chargers.length} valid charging stations.`);

  // Write to Dart file
  const dartCode = `// Generated from live ChargeNET API (315 stations) on ${new Date().toISOString()}
import '../models/charger.dart';

/// Pre-populated, offline-capable database of real ChargeNET charging stations in Sri Lanka.
final List<Charger> kChargeNetSeedChargers = <Charger>[
${chargers
  .map(
    (c) => `  Charger(
    id: ${JSON.stringify(c.id)},
    name: ${JSON.stringify(c.name)},
    city: ${JSON.stringify(c.city)},
    lat: ${c.lat},
    lng: ${c.lng},
    slots: ${c.slots},
    powerKw: ${c.powerKw ? c.powerKw.toFixed(1) : 'null'},
    connectorTypes: const <String>[${c.connectorTypes.map((t) => JSON.stringify(t)).join(', ')}],
    address: ${JSON.stringify(c.address)},
    network: ${JSON.stringify(c.network)},
    status: ${JSON.stringify(c.status)},
  ),`,
  )
  .join('\n')}
];
`;

  await fs.mkdir('evay_app/lib/data', { recursive: true });
  await fs.writeFile('evay_app/lib/data/chargenet_seed.dart', dartCode, 'utf8');
  console.log('Saved evay_app/lib/data/chargenet_seed.dart successfully.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
