const encoder = new TextEncoder();
export const bytes = value => encoder.encode(value);
export const b64 = value => btoa(String.fromCharCode(...new Uint8Array(value))).replaceAll('+', '-').replaceAll('/', '_').replace(/=+$/, '');
export const unb64 = value => Uint8Array.from(atob(value.replaceAll('-', '+').replaceAll('_', '/')), c => c.charCodeAt(0));
export const random = () => b64(crypto.getRandomValues(new Uint8Array(32)));
export const hash = async value => b64(await crypto.subtle.digest('SHA-256', bytes(value)));
export async function equal(a, b) {
  const values = await Promise.all([a, b].map(value => crypto.subtle.digest('SHA-256', bytes(value))));
  return crypto.subtle.timingSafeEqual(values[0], values[1]);
}
export async function seal(value, secret, context) {
  const key = await crypto.subtle.importKey('raw', unb64(secret), 'AES-GCM', false, ['encrypt']);
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const ciphertext = await crypto.subtle.encrypt({name: 'AES-GCM', iv, additionalData: bytes(context)}, key, bytes(JSON.stringify(value)));
  return `${b64(iv)}.${b64(ciphertext)}`;
}
export async function open(value, secret, context) {
  const [iv, ciphertext] = value.split('.');
  const key = await crypto.subtle.importKey('raw', unb64(secret), 'AES-GCM', false, ['decrypt']);
  const plain = await crypto.subtle.decrypt({name: 'AES-GCM', iv: unb64(iv), additionalData: bytes(context)}, key, unb64(ciphertext));
  return JSON.parse(new TextDecoder().decode(plain));
}
export async function verifyJwt(token, jwks, {issuer, audience, algorithm, now}) {
  if (typeof token !== 'string' || token.length > 16000) throw new Error('invalid token');
  const parts = token.split('.');
  if (parts.length !== 3) throw new Error('invalid token');
  const header = JSON.parse(new TextDecoder().decode(unb64(parts[0])));
  const payload = JSON.parse(new TextDecoder().decode(unb64(parts[1])));
  if (header.alg !== algorithm || !header.kid) throw new Error('invalid algorithm');
  const jwk = jwks.keys.find(key => key.kid === header.kid && (!key.alg || key.alg === algorithm));
  if (!jwk) throw new Error('unknown key');
  const alg = algorithm === 'ES256' ? {name: 'ECDSA', namedCurve: 'P-256'} : {name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256'};
  const key = await crypto.subtle.importKey('jwk', jwk, alg, false, ['verify']);
  const verify = algorithm === 'ES256' ? {name: 'ECDSA', hash: 'SHA-256'} : {name: 'RSASSA-PKCS1-v1_5'};
  if (!await crypto.subtle.verify(verify, key, unb64(parts[2]), bytes(parts[0] + '.' + parts[1]))) throw new Error('bad signature');
  if (payload.iss !== issuer || payload.aud !== audience || !Number.isFinite(payload.exp)
      || payload.exp <= now || !Number.isFinite(payload.iat) || payload.iat > now + 60
      || (payload.nbf && payload.nbf > now + 60)) throw new Error('invalid claims');
  return payload;
}
// GitHub manifests return PKCS#1 PEMs; Web Crypto imports PKCS#8.
function der(tag, content) {
  let length = content.length;
  const octets = [];
  if (length < 128) octets.push(length);
  else {
    while (length) { octets.unshift(length & 255); length >>= 8; }
    octets.unshift(128 + octets.length);
  }
  return new Uint8Array([tag, ...octets, ...content]);
}
export async function appJwt(app, now) {
  let pk = unb64(app.pem.replace(/-----[^-]+-----|\s/g, ''));
  if (app.pem.includes('BEGIN RSA PRIVATE KEY')) {
    pk = der(48, new Uint8Array([2, 1, 0, 48, 13, 6, 9, 42, 134, 72, 134, 247, 13, 1, 1, 1, 5, 0, ...der(4, pk)]));
  }
  const key = await crypto.subtle.importKey('pkcs8', pk, {name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256'}, false, ['sign']);
  const body = b64(bytes(JSON.stringify({alg: 'RS256', typ: 'JWT'}))) + '.' + b64(bytes(JSON.stringify({iss: String(app.id), iat: now - 60, exp: now + 540})));
  return body + '.' + b64(await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, bytes(body)));
}
