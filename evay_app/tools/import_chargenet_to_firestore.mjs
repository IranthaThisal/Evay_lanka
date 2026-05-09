import crypto from 'node:crypto';
import fs from 'node:fs/promises';

const chargeNetUrl =
  'https://api.chargenet.lk:13100/ChargerHandler.asmx/ShowAllChargePointData';
const firestoreScope = 'https://www.googleapis.com/auth/datastore';
const tokenUrl = 'https://oauth2.googleapis.com/token';

const serviceAccountPath = process.argv[2];
const collection = process.argv[3] ?? 'chargers';

if (!serviceAccountPath) {
  console.error(
    'Usage: node tools/import_chargenet_to_firestore.mjs path/to/serviceAccount.json [collection]',
  );
  process.exit(1);
}

const serviceAccount = JSON.parse(await fs.readFile(serviceAccountPath, 'utf8'));
const projectId = serviceAccount.project_id;

if (!projectId || !serviceAccount.client_email || !serviceAccount.private_key) {
  console.error('The service account JSON is missing required fields.');
  process.exit(1);
}

const accessToken = await getAccessToken(serviceAccount);
const chargePoints = await fetchChargeNetPoints();
const chargers = chargePoints.map(toFirestoreWrite).filter(Boolean);

for (let i = 0; i < chargers.length; i += 450) {
  const writes = chargers.slice(i, i + 450);
  await commitWrites(writes, accessToken);
  console.log(`Imported ${Math.min(i + writes.length, chargers.length)} / ${chargers.length}`);
}

console.log(`Done. Imported ${chargers.length} ChargeNet markers into ${collection}.`);

async function fetchChargeNetPoints() {
  const response = await fetch(chargeNetUrl);
  if (!response.ok) {
    throw new Error(`ChargeNet returned ${response.status}`);
  }

  const data = await response.json();
  return Array.isArray(data.listOfChargePoints) ? data.listOfChargePoints : [];
}

function toFirestoreWrite(point) {
  const reference = text(point.reference);
  const latitude = numberFrom(point.latitude);
  const longitude = numberFrom(point.longitude);

  if (!reference || latitude == null || longitude == null) {
    return null;
  }

  const type = text(point.type);
  const protocol = text(point.protocol).replaceAll('_', ' ');
  const name = text(point.location) || `ChargeNet ${reference}`;
  const address = text(point.address);
  const status = text(point.availability_status).toUpperCase();
  const powerKw = powerFrom(type, name);
  const docId = `chargenet-${reference}`;
  const docPath = `projects/${projectId}/databases/(default)/documents/${collection}/${docId}`;

  return {
    update: {
      name: docPath,
      fields: {
        id: stringValue(docId),
        source: stringValue('chargenet'),
        reference: stringValue(reference),
        name: stringValue(name),
        city: stringValue(cityFromAddress(address)),
        address: stringValue(address),
        lat: doubleValue(latitude),
        lng: doubleValue(longitude),
        location: {
          geoPointValue: {
            latitude,
            longitude,
          },
        },
        slots: integerValue(status === 'AVAILABLE' ? 1 : 0),
        availabilityStatus: stringValue(status || 'UNKNOWN'),
        power: stringValue(text(point.power)),
        type: stringValue(type),
        protocol: stringValue(protocol),
        connectorTypes: arrayValue([type, protocol].filter(Boolean)),
        powerKw: powerKw == null ? { nullValue: null } : doubleValue(powerKw),
        openingHours: stringValue(text(point.opening_hours)),
        rating: stringValue(text(point.rating)),
        privateNetwork: stringValue(text(point.private_network)),
        mobile: stringValue(text(point.mobile)),
        updatedFromChargeNetAt: {
          timestampValue: new Date().toISOString(),
        },
      },
    },
  };
}

async function commitWrites(writes, accessToken) {
  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents:commit`;
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ writes }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Firestore commit failed ${response.status}: ${body}`);
  }
}

async function getAccessToken(serviceAccount) {
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claims = base64Url(
    JSON.stringify({
      iss: serviceAccount.client_email,
      scope: firestoreScope,
      aud: tokenUrl,
      iat: now,
      exp: now + 3600,
    }),
  );
  const unsignedJwt = `${header}.${claims}`;
  const signature = crypto
    .createSign('RSA-SHA256')
    .update(unsignedJwt)
    .sign(serviceAccount.private_key);
  const jwt = `${unsignedJwt}.${base64Url(signature)}`;

  const response = await fetch(tokenUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`OAuth token request failed ${response.status}: ${body}`);
  }

  const token = await response.json();
  return token.access_token;
}

function cityFromAddress(address) {
  const parts = address
    .split(',')
    .map((part) => part.trim())
    .filter(Boolean);

  if (parts.length === 0) return 'ChargeNet';
  return parts.length >= 2 ? parts[parts.length - 2] : parts[0];
}

function powerFrom(type, name) {
  const match = name.match(/(\d+(?:\.\d+)?)\s*kW/i);
  if (match) return Number(match[1]);
  if (type.toUpperCase() === 'L3') return 50;
  if (type.toUpperCase() === 'L2') return 6.6;
  return null;
}

function arrayValue(values) {
  return { arrayValue: { values: values.map(stringValue) } };
}

function stringValue(value) {
  return { stringValue: value };
}

function doubleValue(value) {
  return { doubleValue: value };
}

function integerValue(value) {
  return { integerValue: String(value) };
}

function numberFrom(value) {
  if (typeof value === 'number') return value;
  if (typeof value === 'string') {
    const parsed = Number(value.trim());
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function text(value) {
  return value == null ? '' : String(value).trim();
}

function base64Url(value) {
  const buffer = Buffer.isBuffer(value) ? value : Buffer.from(value);
  return buffer
    .toString('base64')
    .replaceAll('+', '-')
    .replaceAll('/', '_')
    .replaceAll('=', '');
}
