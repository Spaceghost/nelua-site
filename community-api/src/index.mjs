import {appJwt, bytes, equal, hash, open, random, seal, verifyJwt} from './crypto.mjs';

export const ORIGIN = 'https://spacegho.st';
export const BASE = '/nelua/community/api';
export const PRIVATE_METRIC = 'current-authored-nelua-v1';
const HOME = ORIGIN + '/nelua/community/';
const CALLBACK = ORIGIN + BASE + '/auth/callback';
const SESSION = '__Secure-nelua_session';
const FLOW = '__Secure-nelua_flow';
const CLIENT = 'nelua-community';
const NOW = () => Math.floor(Date.now() / 1000);
class Failure extends Error { constructor(status, code) { super(code); this.status = status; } }
const need = (condition, status, code) => { if (!condition) throw new Failure(status, code); };
const cookie = (name, value, age) => `${name}=${value}; Path=${BASE}; Max-Age=${age}; Secure; HttpOnly; SameSite=Lax`;
const cookies = request => Object.fromEntries((request.headers.get('Cookie') || '').split(';').map(s => s.trim().split('=')));
const json = (body, status = 200) => Response.json(body, {status, headers: {'Cache-Control': 'private, no-store', 'X-Content-Type-Options': 'nosniff', 'Referrer-Policy': 'no-referrer'}});
function redirect(url, ...values) {
  const headers = new Headers({Location: url, 'Cache-Control': 'no-store', 'Referrer-Policy': 'no-referrer'});
  for (const value of values) headers.append('Set-Cookie', value);
  return new Response(null, {status: 302, headers});
}
const escape = value => String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
async function limitedBody(request, maximum = 16384) {
  need(Number(request.headers.get('content-length') || 0) <= maximum, 413, 'request_too_large');
  const reader = request.body?.getReader();
  if (!reader) return '';
  const chunks = []; let length = 0;
  for (;;) {
    const {value, done} = await reader.read();
    if (done) break;
    length += value.byteLength;
    if (length > maximum) { await reader.cancel(); throw new Failure(413, 'request_too_large'); }
    chunks.push(value);
  }
  const output = new Uint8Array(length); let offset = 0;
  for (const chunk of chunks) { output.set(chunk, offset); offset += chunk.length; }
  return new TextDecoder().decode(output);
}
async function session(request, env, now, required = true) {
  const token = cookies(request)[SESSION];
  const user = token ? await env.DB.prepare('SELECT u.*,s.csrf,s.hash AS session_hash FROM sessions s JOIN users u ON u.id=s.user_id WHERE s.hash=? AND s.expires>?')
    .bind(await hash(token), now).first() : null;
  if (required) need(user, 401, 'sign_in_required');
  return user;
}
async function csrf(request, user) {
  need(request.headers.get('Origin') === ORIGIN, 403, 'same_origin_required');
  need(await equal(request.headers.get('X-CSRF-Token') || '', user.csrf), 403, 'invalid_csrf');
  need(request.headers.get('Content-Type')?.split(';')[0] === 'application/json', 415, 'json_required');
}
async function appOf(env) {
  const row = await env.DB.prepare('SELECT value FROM app_config WHERE id=1').first();
  return row ? open(row.value, env.ENCRYPTION_KEY, 'github-app') : null;
}
function appRecovery(user, code, reason) {
  reason = ({pending_connection:'The App has a saved setup attempt. Confirm its connection below.',
    invalid_state:'The original setup session is no longer available. Confirm to reconnect your existing App.',
    expired_state:'The setup session expired. Confirm to reconnect your existing App.',
    github_access_unavailable:'GitHub has not completed the connection. Retry using the saved setup.',
    app_requires_read_only_contents:'Set the App’s Contents permission to read-only in GitHub, then retry.',
    app_owner_mismatch:'Connect the GitHub App owned by Spaceghost.'})[reason] || 'The App connection is not complete yet. Retry below.';
  const html = '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Finish GitHub App connection</title><link rel="stylesheet" href="/nelua/community/styles.css"><main class="page-shell private-panel"><h1>Finish the App connection</h1><p>Your existing App can be connected here. You do not need to create another App.</p><p class="account-status">Connection status: ' + escape(reason) + '</p><form method="post" action="' + BASE + '/app/retry"><input type="hidden" name="csrf" value="' + escape(user.csrf) + '"><input type="hidden" name="code" value="' + escape(code) + '"><button class="account-button" type="submit">Retry App connection</button></form><p><a href="/nelua/community/">Return to the community</a></p></main></html>';
  return new Response(html, {headers: {'Content-Type':'text/html; charset=utf-8', 'Cache-Control':'private, no-store', 'Referrer-Policy':'strict-origin',
    'Content-Security-Policy':"default-src 'none'; style-src 'self'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'"}});
}
function installationRecovery(user, id) {
  const html = '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Finish connecting your repositories</title><link rel="stylesheet" href="/nelua/community/styles.css"><main class="page-shell private-panel"><h1>Finish connecting your repositories</h1><p>Your GitHub installation can be connected here. Confirm to finish; you do not need to reinstall the App.</p><form method="post" action="' + BASE + '/installation/retry"><input type="hidden" name="csrf" value="' + escape(user.csrf) + '"><input type="hidden" name="installation_id" value="' + escape(id) + '"><button class="account-button" type="submit">Finish repository connection</button></form><p><a href="/nelua/community/#private-projects">Return to your project choices</a></p></main></html>';
  return new Response(html, {headers: {'Content-Type':'text/html; charset=utf-8', 'Cache-Control':'private, no-store', 'Referrer-Policy':'strict-origin',
    'Content-Security-Policy':"default-src 'none'; style-src 'self'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'"}});
}
async function connectInstallation(env, user, app, id, fetcher, now) {
  need(/^\d+$/.test(id) && Number.isSafeInteger(Number(id)) && Number(id) > 0, 400, 'invalid_installation');
  const info = await github('/app/installations/' + id, await appJwt(app, now), fetcher);
  need(String(info.account?.id) === user.id && info.target_type === 'User' && !info.suspended_at, 403, 'installation_owner_mismatch');
  if (String(user.installation_id) !== id)
    await env.DB.prepare('UPDATE users SET installation_id=?,selection=NULL,consent=0,totals=NULL,counted_at=NULL,version=version+1 WHERE id=?').bind(Number(id), user.id).run();
}
async function finishApp(env, code, fetcher, now) {
  // A failed metadata request must not discard the one-time manifest credentials.
  const pending = await env.DB.prepare("SELECT payload FROM states WHERE hash='github-app-pending' AND purpose='app-recovery' AND expires>?").bind(now).first();
  let app;
  if (pending) app = await open(pending.payload, env.ENCRYPTION_KEY, 'pending-github-app');
  else {
    if (!code) {
      const saved = await env.DB.prepare("SELECT payload FROM states WHERE hash='github-app-code' AND expires>?").bind(now).first();
      if (saved) code = (await open(saved.payload, env.ENCRYPTION_KEY, 'pending-github-code')).code;
    }
    need(typeof code === 'string' && code.length > 0 && code.length <= 512 && !/[\u0000-\u001f]/.test(code), 400, 'invalid_code');
    await env.DB.prepare("INSERT INTO states(hash,purpose,payload,expires) VALUES('github-app-code','app-recovery',?,?) ON CONFLICT(hash) DO UPDATE SET payload=excluded.payload,expires=excluded.expires")
      .bind(await seal({code}, env.ENCRYPTION_KEY, 'pending-github-code'), now + 3600).run();
    const converted = await github('/app-manifests/' + encodeURIComponent(code) + '/conversions', null, fetcher, {});
    need(converted.id && converted.pem && converted.webhook_secret, 502, 'incomplete_app_configuration');
    app = {id: converted.id, pem: converted.pem, webhook_secret: converted.webhook_secret};
    await env.DB.prepare("INSERT INTO states(hash,purpose,payload,expires) VALUES('github-app-pending','app-recovery',?,?) ON CONFLICT(hash) DO UPDATE SET payload=excluded.payload,expires=excluded.expires")
      .bind(await seal(app, env.ENCRYPTION_KEY, 'pending-github-app'), now + 7 * 86400).run();
  }
  const info = await github('/app', await appJwt(app, now), fetcher);
  if (String(info.owner?.id) !== env.OWNER_ID) {
    // A rejected foreign App must not trap the owner in a retry loop.
    await env.DB.prepare("DELETE FROM states WHERE hash IN ('github-app-pending','github-app-code')").run();
    throw new Failure(403, 'app_owner_mismatch');
  }
  need(info.permissions?.contents === 'read' && Object.values(info.permissions).every(value => value === 'read'), 403, 'app_requires_read_only_contents');
  need(typeof info.slug === 'string' && info.slug.length > 0 && info.slug.length <= 200, 502, 'invalid_app_name');
  app.slug = info.slug;
  await env.DB.prepare('INSERT INTO app_config(id,value) VALUES(1,?) ON CONFLICT(id) DO NOTHING')
    .bind(await seal(app, env.ENCRYPTION_KEY, 'github-app')).run();
  await env.DB.prepare("DELETE FROM states WHERE hash IN ('github-app-pending','github-app-code')").run();
}
async function state(env, purpose, payload, now) {
  const value = random();
  await env.DB.prepare('INSERT INTO states(hash,purpose,payload,expires) VALUES(?,?,?,?)')
    .bind(await hash(value), purpose, await seal(payload, env.ENCRYPTION_KEY, 'state:' + purpose), now + 600).run();
  return value;
}
async function consume(request, env, url, purpose, now) {
  const value = url.searchParams.get('state') || '';
  need(value && await equal(value, cookies(request)[FLOW] || ''), 400, 'invalid_state');
  const row = await env.DB.prepare('DELETE FROM states WHERE hash=? RETURNING purpose,payload,expires').bind(await hash(value)).first();
  need(row && row.purpose === purpose && row.expires > now, 400, 'expired_state');
  return open(row.payload, env.ENCRYPTION_KEY, 'state:' + purpose);
}
async function github(path, token, fetcher, body) {
  const response = await fetcher('https://api.github.com' + path, {
    // Workers rejects redirect:"error" before sending the request. Manual
    // mode keeps credentials on this origin and the status check rejects 3xx.
    method: body ? 'POST' : 'GET', redirect: 'manual',
    headers: {'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'nelua-builders', ...(token ? {Authorization: 'Bearer ' + token} : {}),
      ...(body ? {'Content-Type': 'application/json'} : {})},
    ...(body ? {body: JSON.stringify(body)} : {}), signal: AbortSignal.timeout(15000),
  });
  need(response.ok, response.status === 404 ? 409 : 502, 'github_access_unavailable');
  return JSON.parse(await limitedBody(response, 4 * 1024 * 1024));
}
async function installation(env, user, app, fetcher, now) {
  need(user.installation_id, 409, 'connect_private_repositories');
  const jwt = await appJwt(app, now);
  const info = await github('/app/installations/' + user.installation_id, jwt, fetcher);
  need(String(info.account?.id) === user.id && !info.suspended_at && info.target_type === 'User', 403, 'installation_owner_mismatch');
  if (/^[a-z0-9-]+$/i.test(info.account.login || '') && info.account.login !== user.login)
    await env.DB.prepare('UPDATE users SET login=?,name=CASE WHEN name=login THEN ? ELSE name END WHERE id=?')
      .bind(info.account.login, info.account.login, user.id).run();
  return jwt;
}
async function repositories(env, user, app, fetcher, now) {
  const jwt = await installation(env, user, app, fetcher, now);
  const grant = await github('/app/installations/' + user.installation_id + '/access_tokens', jwt, fetcher, {permissions: {metadata: 'read'}});
  const found = [];
  for (let page = 1; page <= 20; page++) {
    const part = await github('/installation/repositories?per_page=100&page=' + page, grant.token, fetcher);
    for (const repo of part.repositories) if (String(repo.owner.id) === user.id && repo.private && !repo.fork)
      found.push({id: repo.id, name: repo.full_name});
    if (page * 100 >= part.total_count) return found;
  }
  throw new Failure(422, 'too_many_repositories');
}
async function actionsIdentity(request, env, fetcher, now) {
  const authorization = request.headers.get('Authorization') || '';
  need(authorization.startsWith('Bearer '), 401, 'actions_identity_required');
  try {
    const response = await fetcher('https://token.actions.githubusercontent.com/.well-known/jwks', {cf: {cacheTtl: 300}, signal: AbortSignal.timeout(10000)});
    const claims = await verifyJwt(authorization.slice(7), await response.json(), {issuer: 'https://token.actions.githubusercontent.com', audience: HOME.slice(0, -1), algorithm: 'RS256', now});
    need(claims.repository === 'Spaceghost/nelua-site' && String(claims.repository_id) === env.ACTIONS_REPOSITORY_ID
      && String(claims.repository_owner_id) === env.OWNER_ID && claims.ref === 'refs/heads/main'
      && String(claims.actor_id) === env.OWNER_ID
      && claims.workflow_ref === 'Spaceghost/nelua-site/.github/workflows/community.yml@refs/heads/main'
      && ['schedule', 'workflow_dispatch'].includes(claims.event_name)
      && claims.runner_environment === 'self-hosted', 403, 'actions_workflow_not_allowed');
    return claims;
  } catch (error) {
    if (error instanceof Failure) throw error;
    throw new Failure(401, 'invalid_actions_identity');
  }
}

export async function handle(request, env, options = {}) {
  const now = options.now ?? NOW();
  const fetcher = options.fetch ?? fetch;
  const url = new URL(request.url);
  const path = url.pathname.slice(BASE.length);
  let operation = 'route';
  try {
    if (url.pathname === '/nelua/community/data.json' && [ORIGIN, 'https://nelua.tech'].includes(url.origin)) {
      if (!['GET', 'HEAD'].includes(request.method)) {
        return new Response(null, {status: 405, headers: {Allow: 'GET, HEAD'}});
      }
      const object = request.method === 'HEAD'
        ? await env.PUBLIC_SNAPSHOTS.head('data.json')
        : await env.PUBLIC_SNAPSHOTS.get('data.json');
      need(object, 503, 'snapshot_unavailable');
      return new Response(object.body ?? null, {headers: {
        'Content-Type': 'application/json', 'Cache-Control': 'public, max-age=60',
        'Content-Length': String(object.size), 'ETag': object.httpEtag,
        'X-Content-Type-Options': 'nosniff'
      }});
    }
    const publicTotals = url.origin === 'https://nelua.tech' && url.pathname === BASE + '/private-totals' && request.method === 'GET';
    need((url.origin === ORIGIN || publicTotals) && url.pathname.startsWith(BASE + '/'), 404, 'not_found');
    if (path === '/private-totals' && request.method === 'GET') {
      const result = await env.DB.prepare('SELECT id,login,name,totals,counted_at FROM users WHERE consent=1 AND totals IS NOT NULL AND counted_at>?').bind(now - 36 * 3600).all();
      return json({people: result.results.filter(row => JSON.parse(row.totals).metric === PRIVATE_METRIC).map(row => ({id: row.id, login: row.login, name: row.login, ...JSON.parse(row.totals), generatedAt: new Date(row.counted_at * 1000).toISOString()}))});
    }
    if (path === '/auth/start' && request.method === 'GET') {
      const verifier = random() + random(); const nonce = random();
      const value = await state(env, 'auth', {verifier, nonce, setup: url.searchParams.get('setup') === '1'}, now);
      const query = new URLSearchParams({client_id: CLIENT, response_type: 'code', redirect_uri: CALLBACK,
        scope: 'openid profile', state: value, nonce, code_challenge: await hash(verifier), code_challenge_method: 'S256'});
      return redirect(ORIGIN + '/oauth/github/start?next=' + encodeURIComponent('/oauth/authorize?' + query), cookie(FLOW, value, 600));
    }
    if (path === '/auth/callback' && request.method === 'GET') {
      const flow = await consume(request, env, url, 'auth', now);
      need(url.searchParams.get('code') && url.searchParams.get('iss') === ORIGIN, 400, 'invalid_authorization');
      const response = await env.AUTH.fetch(ORIGIN + '/oauth/token', {method: 'POST', headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: new URLSearchParams({client_id: CLIENT, grant_type: 'authorization_code', code: url.searchParams.get('code'), redirect_uri: CALLBACK, code_verifier: flow.verifier})});
      need(response.ok, 401, 'authorization_failed');
      const tokens = await response.json();
      const keys = await (await env.AUTH.fetch(ORIGIN + '/oauth/jwks')).json();
      let access, identity;
      try {
        access = await verifyJwt(tokens.access_token, keys, {issuer: ORIGIN, audience: CLIENT, algorithm: 'ES256', now});
        identity = await verifyJwt(tokens.id_token, keys, {issuer: ORIGIN, audience: CLIENT, algorithm: 'ES256', now});
      } catch { throw new Failure(401, 'invalid_identity'); }
      need(identity.sub === access.sub && await equal(identity.nonce || '', flow.nonce)
        && /^\d+$/.test(access.gh_id || ''), 401, 'github_identity_required');
      // The shared GitHub provider refreshes these signed claims during sign-in.
      // Ownership always uses immutable gh_id, never a potentially reassigned login.
      need(/^[a-z0-9-]+$/i.test(access.gh || ''), 401, 'github_identity_required');
      const profile = {login: access.gh, name: access.name || access.gh};
      await env.DB.prepare('INSERT INTO users(id,login,name) VALUES(?,?,?) ON CONFLICT(id) DO UPDATE SET login=excluded.login,name=excluded.name')
        .bind(access.gh_id, profile.login, profile.name || profile.login).run();
      const value = random();
      await env.DB.prepare('INSERT INTO sessions(hash,user_id,csrf,expires) VALUES(?,?,?,?)')
        .bind(await hash(value), access.gh_id, random(), now + 7 * 86400).run();
      return redirect(flow.setup ? ORIGIN + BASE + '/app/setup' : HOME + '#private-projects', cookie(SESSION, value, 7 * 86400), cookie(FLOW, '', 0));
    }
    if (path === '/me' && request.method === 'GET') {
      const user = await session(request, env, now, false); const app = await appOf(env);
      if (!user) return json({signedIn: false, privateAvailable: Boolean(app)});
      const totals = user.totals ? JSON.parse(user.totals) : null;
      const current = totals?.metric === PRIVATE_METRIC;
      return json({signedIn: true, csrf: user.csrf, profile: {id: user.id, login: user.login, name: user.name},
        owner: user.id === env.OWNER_ID, privateAvailable: Boolean(app), connected: Boolean(user.installation_id),
        enabled: Boolean(user.consent), selected: user.selection ? await open(user.selection, env.ENCRYPTION_KEY, 'selection:' + user.id) : [],
        totals: current ? totals : null, countedAt: current && user.counted_at ? new Date(user.counted_at * 1000).toISOString() : null,
        installUrl: app ? ORIGIN + BASE + '/installation/start' : null});
    }
    if (path === '/app/setup' && request.method === 'GET') {
      const user = await session(request, env, now, false);
      if (!user) return redirect(ORIGIN + BASE + '/auth/start?setup=1');
      need(user.id === env.OWNER_ID, 403, 'owner_required');
      if (await appOf(env)) return redirect(HOME + '#private-projects');
      const pending = await env.DB.prepare("SELECT hash FROM states WHERE purpose='app-recovery' AND expires>? LIMIT 1").bind(now).first();
      if (pending) return appRecovery(user, '', 'pending_connection');
      const value = await state(env, 'app', {id: user.id}, now);
      const manifest = {name: 'Nelua Builders at spacegho.st', url: HOME, public: true,
        redirect_url: ORIGIN + BASE + '/app/callback', setup_url: ORIGIN + BASE + '/installation/callback',
        hook_attributes: {url: ORIGIN + BASE + '/webhook', active: true},
        default_permissions: {contents: 'read', metadata: 'read'}, default_events: [],
        description: 'Count selected private Nelua projects. Publish aggregate source totals only.', request_oauth_on_install: false, setup_on_update: true};
      const html = '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Connect private Nelua projects</title><link rel="stylesheet" href="/nelua/community/styles.css"><main class="page-shell private-panel"><h1>Enable private projects</h1><p>Create the community GitHub App under Spaceghost. It requests read-only contents and metadata access to repositories each person selects.</p><form method="post" action="https://github.com/settings/apps/new?state=' + value + '"><input type="hidden" name="manifest" value="' + escape(JSON.stringify(manifest)) + '"><button class="account-button" type="submit">Create GitHub App</button></form><p>Repository names, source and credentials stay private. Only opted-in totals enter the ranking.</p></main></html>';
      return new Response(html, {headers: {'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store', 'Referrer-Policy': 'no-referrer',
        'Content-Security-Policy': "default-src 'none'; style-src 'self'; form-action https://github.com; base-uri 'none'; frame-ancestors 'none'",
        'Set-Cookie': cookie(FLOW, value, 600)}});
    }
    if (path === '/app/callback' && request.method === 'GET') {
      const user = await session(request, env, now);
      need(user.id === env.OWNER_ID, 403, 'owner_required');
      if (await appOf(env)) return redirect(HOME + '#private-projects');
      const code = url.searchParams.get('code') || '';
      try {
        const flow = await consume(request, env, url, 'app', now);
        need(flow.id === user.id, 403, 'owner_required');
        await finishApp(env, code, fetcher, now);
      } catch (error) {
        return appRecovery(user, code, error instanceof Failure ? error.message : 'temporarily_unavailable');
      }
      return redirect(HOME + '#private-projects', cookie(FLOW, '', 0));
    }
    if (path === '/app/retry' && request.method === 'GET') {
      if (await appOf(env)) return redirect(HOME + '#private-projects');
      const user = await session(request, env, now, false);
      if (!user) return redirect(ORIGIN + BASE + '/auth/start?setup=1');
      need(user.id === env.OWNER_ID, 403, 'owner_required');
      return appRecovery(user, '', 'pending_connection');
    }
    if (path === '/app/retry' && request.method === 'POST') {
      const user = await session(request, env, now);
      need(user.id === env.OWNER_ID, 403, 'owner_required');
      need(request.headers.get('Origin') === ORIGIN, 403, 'same_origin_required');
      need(request.headers.get('Content-Type')?.split(';')[0] === 'application/x-www-form-urlencoded', 415, 'form_required');
      const form = new URLSearchParams(await limitedBody(request));
      need(await equal(form.get('csrf') || '', user.csrf), 403, 'invalid_csrf');
      if (await appOf(env)) return redirect(HOME + '#private-projects');
      const code = form.get('code') || '';
      try { await finishApp(env, code, fetcher, now); }
      catch (error) { return appRecovery(user, code, error instanceof Failure ? error.message : 'temporarily_unavailable'); }
      return redirect(HOME + '#private-projects', cookie(FLOW, '', 0));
    }
    if (path === '/installation/start' && request.method === 'GET') {
      const user = await session(request, env, now); const app = await appOf(env);
      need(app, 409, 'private_app_not_configured');
      const value = await state(env, 'installation', {id: user.id}, now);
      return redirect('https://github.com/apps/' + encodeURIComponent(app.slug) + '/installations/new?state=' + value, cookie(FLOW, value, 600));
    }
    if (path === '/installation/callback' && request.method === 'GET') {
      operation = 'installation_session';
      const user = await session(request, env, now); const app = await appOf(env);
      need(app, 409, 'private_app_not_configured');
      const id = url.searchParams.get('installation_id') || '';
      need(/^\d+$/.test(id) && Number.isSafeInteger(Number(id)) && Number(id) > 0, 400, 'invalid_installation');
      // Reopening a completed callback only returns to the existing choices.
      if (String(user.installation_id) === id) return redirect(HOME + '#private-projects', cookie(FLOW, '', 0));
      operation = 'installation_state';
      let flow;
      try { flow = await consume(request, env, url, 'installation', now); }
      catch (error) {
        if (error instanceof Failure && ['invalid_state','expired_state'].includes(error.message)) return installationRecovery(user, id);
        throw error;
      }
      need(flow.id === user.id, 403, 'installation_owner_mismatch');
      operation = 'installation_lookup';
      try { await connectInstallation(env, user, app, id, fetcher, now); }
      catch (error) {
        if (error instanceof Failure && error.message === 'github_access_unavailable') return installationRecovery(user, id);
        throw error;
      }
      return redirect(HOME + '#private-projects', cookie(FLOW, '', 0));
    }
    if (path === '/installation/retry' && request.method === 'POST') {
      const user = await session(request, env, now);
      need(request.headers.get('Origin') === ORIGIN, 403, 'same_origin_required');
      need(request.headers.get('Content-Type')?.split(';')[0] === 'application/x-www-form-urlencoded', 415, 'form_required');
      const form = new URLSearchParams(await limitedBody(request));
      need(await equal(form.get('csrf') || '', user.csrf), 403, 'invalid_csrf');
      const app = await appOf(env); need(app, 409, 'private_app_not_configured');
      const id = form.get('installation_id') || '';
      operation = 'installation_retry';
      await connectInstallation(env, user, app, id, fetcher, now);
      return redirect(HOME + '#private-projects', cookie(FLOW, '', 0));
    }
    if (path === '/repositories' && request.method === 'GET') {
      const user = await session(request, env, now); const app = await appOf(env);
      need(app, 409, 'private_app_not_configured');
      return json({repositories: await repositories(env, user, app, fetcher, now)});
    }
    if (path === '/settings' && request.method === 'POST') {
      const user = await session(request, env, now); await csrf(request, user);
      const body = JSON.parse(await limitedBody(request));
      if (body.enabled === false) {
        await env.DB.prepare('UPDATE users SET consent=0,totals=NULL,counted_at=NULL,version=version+1 WHERE id=?').bind(user.id).run();
        return json({enabled: false});
      }
      need(body.enabled === true && Array.isArray(body.repositories) && body.repositories.length > 0 && body.repositories.length <= 100
        && body.repositories.every(id => Number.isSafeInteger(id) && id > 0), 400, 'select_private_repositories');
      const app = await appOf(env); need(app, 409, 'private_app_not_configured');
      const allowed = new Set((await repositories(env, user, app, fetcher, now)).map(repo => repo.id));
      const selected = [...new Set(body.repositories)].sort((a,b) => a-b);
      need(selected.every(id => allowed.has(id)), 403, 'repository_not_owned_or_not_selected');
      await env.DB.prepare('UPDATE users SET selection=?,consent=1,totals=NULL,counted_at=NULL,version=version+1 WHERE id=?')
        .bind(await seal(selected, env.ENCRYPTION_KEY, 'selection:' + user.id), user.id).run();
      return json({enabled: true, nextRefresh: '07:17 America/Los_Angeles'});
    }
    if ((path === '/logout' || path === '/disconnect') && request.method === 'POST') {
      const user = await session(request, env, now); await csrf(request, user);
      if (path === '/disconnect') await env.DB.prepare('DELETE FROM users WHERE id=?').bind(user.id).run();
      else await env.DB.prepare('DELETE FROM sessions WHERE hash=?').bind(user.session_hash).run();
      const response = json({signedIn: false}); response.headers.append('Set-Cookie', cookie(SESSION, '', 0)); return response;
    }
    if (path === '/webhook' && request.method === 'POST') {
      const app = await appOf(env); need(app, 503, 'private_app_not_configured');
      const text = await limitedBody(request, 1024 * 1024);
      const signature = request.headers.get('X-Hub-Signature-256') || '';
      need(/^sha256=[0-9a-f]{64}$/.test(signature), 401, 'invalid_webhook');
      const key = await crypto.subtle.importKey('raw', bytes(app.webhook_secret), {name: 'HMAC', hash: 'SHA-256'}, false, ['verify']);
      const supplied = Uint8Array.from(signature.slice(7).match(/../g), s => parseInt(s, 16));
      need(await crypto.subtle.verify('HMAC', key, supplied, bytes(text)), 401, 'invalid_webhook');
      const event = request.headers.get('X-GitHub-Event'); const body = JSON.parse(text);
      if (['installation', 'installation_repositories'].includes(event) && Number.isSafeInteger(body.installation?.id)) {
        const deleted = event === 'installation' && body.action === 'deleted';
        await env.DB.prepare('UPDATE users SET consent=0,selection=NULL,totals=NULL,counted_at=NULL,version=version+1,installation_id=CASE WHEN ? THEN NULL ELSE installation_id END WHERE installation_id=?')
          .bind(deleted ? 1 : 0, body.installation.id).run();
      }
      return new Response(null, {status: 204});
    }
    if (path.startsWith('/refresh/')) {
      const identity = await actionsIdentity(request, env, fetcher, now);
      if (path === '/refresh/owners' && request.method === 'GET') {
        await env.DB.batch(['DELETE FROM states WHERE expires<?', 'DELETE FROM sessions WHERE expires<?', 'DELETE FROM scan_tasks WHERE expires<?'].map(sql => env.DB.prepare(sql).bind(now)));
        const result = await env.DB.prepare('SELECT id FROM users WHERE consent=1 AND installation_id IS NOT NULL AND selection IS NOT NULL ORDER BY CAST(id AS INTEGER) LIMIT 1000').all();
        return json({owners: result.results.map(row => row.id)});
      }
      if (/^\/refresh\/task\/\d+$/.test(path) && request.method === 'GET') {
        const id = path.split('/').at(-1);
        const user = await env.DB.prepare('SELECT * FROM users WHERE id=? AND consent=1').bind(id).first();
        need(user?.selection, 409, 'private_counting_disabled');
        const app = await appOf(env); need(app, 409, 'private_app_not_configured');
        const selected = await open(user.selection, env.ENCRYPTION_KEY, 'selection:' + user.id);
        const jwt = await installation(env, user, app, fetcher, now);
        const grant = await github('/app/installations/' + user.installation_id + '/access_tokens', jwt, fetcher, {repository_ids: selected, permissions: {contents: 'read', metadata: 'read'}});
        const task = random();
        await env.DB.prepare('INSERT INTO scan_tasks(hash,user_id,version,repository_count,run_id,expires) VALUES(?,?,?,?,?,?)')
          .bind(await hash(task), id, user.version, selected.length, String(identity.run_id), now + 3600).run();
        return json({task, owner: id, repositories: selected, token: grant.token});
      }
      if (path === '/refresh/result' && request.method === 'POST') {
        const body = JSON.parse(await limitedBody(request));
        need(body.metric === PRIVATE_METRIC, 400, 'authored_metric_required');
        const task = await env.DB.prepare('DELETE FROM scan_tasks WHERE hash=? RETURNING *').bind(await hash(String(body.task || ''))).first();
        need(task && task.expires > now && task.run_id === String(identity.run_id), 403, 'invalid_scan_task');
        const totals = {metric: PRIVATE_METRIC};
        for (const field of ['lines', 'bytes', 'files', 'repositories']) {
          need(Number.isSafeInteger(body[field]) && body[field] >= 0 && body[field] <= 2 ** 40, 400, 'invalid_totals'); totals[field] = body[field];
        }
        need(totals.repositories <= task.repository_count, 400, 'invalid_totals');
        const result = await env.DB.prepare('UPDATE users SET totals=?,counted_at=? WHERE id=? AND consent=1 AND version=?')
          .bind(JSON.stringify(totals), now, task.user_id, task.version).run();
        return json({published: result.meta.changes === 1});
      }
    }
    throw new Failure(404, 'not_found');
  } catch (error) {
    if (error instanceof Failure) return json({error: error.message}, error.status);
    console.error(JSON.stringify({event: 'community_api_error', path, operation, type: error?.name || 'Error'}));
    return json({error: 'temporarily_unavailable'}, 503);
  }
}

export default {fetch: (request, env) => handle(request, env)};
