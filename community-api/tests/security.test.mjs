import {test} from 'node:test';
import assert from 'node:assert/strict';
import {timingSafeEqual} from 'node:crypto';
import {DatabaseSync} from 'node:sqlite';
import {readFileSync} from 'node:fs';
import {handle, BASE, ORIGIN, PRIVATE_METRIC} from '../src/index.mjs';
import {b64, bytes, hash, open, random, seal} from '../src/crypto.mjs';

crypto.subtle.timingSafeEqual = (a,b) => timingSafeEqual(new Uint8Array(a),new Uint8Array(b));
const now = 1800000000;
const schema = readFileSync(new URL('../migrations/0001_initial.sql',import.meta.url),'utf8');
function database() {
  const db = new DatabaseSync(':memory:'); db.exec('PRAGMA foreign_keys=ON;'+schema);
  const wrap = (sql, values=[]) => ({bind(...args){return wrap(sql,args);},
    async first(){return db.prepare(sql).get(...values) || null;},
    async all(){return {results:db.prepare(sql).all(...values)};},
    async run(){return {meta:{changes:Number(db.prepare(sql).run(...values).changes)}};}});
  return {prepare:wrap, async batch(statements){return Promise.all(statements.map(s=>s.run()));}};
}
const environment = () => ({DB:database(),ENCRYPTION_KEY:random(),OWNER_ID:'251370',ACTIONS_REPOSITORY_ID:'1447444568'});
async function user(env,id='251370') {
  const token=random(); const csrf=random();
  await env.DB.prepare('INSERT INTO users(id,login,name) VALUES(?,?,?)').bind(id,'builder-'+id,'Builder').run();
  await env.DB.prepare('INSERT INTO sessions(hash,user_id,csrf,expires) VALUES(?,?,?,?)').bind(await hash(token),id,csrf,now+3600).run();
  return {id,csrf,cookie:'__Secure-nelua_session='+token};
}
const request = (path,who,body,headers={}) => new Request(ORIGIN+BASE+path,{method:body===undefined?'GET':'POST',headers:{...(who?{Cookie:who.cookie}:{}),...(body!==undefined?{Origin:ORIGIN,'Content-Type':'application/json','X-CSRF-Token':who?.csrf||''}:{}),...headers},...(body!==undefined?{body:typeof body==='string'?body:JSON.stringify(body)}:{})});
const go = (env,path,who,body,headers,extra={}) => handle(request(path,who,body,headers),env,{now,...extra});
async function app(env) {
  const key=await crypto.subtle.generateKey({name:'RSASSA-PKCS1-v1_5',modulusLength:2048,publicExponent:new Uint8Array([1,0,1]),hash:'SHA-256'},true,['sign','verify']);
  const value={id:1,slug:'test-nelua',pem:'-----BEGIN PRIVATE KEY-----\n'+b64(await crypto.subtle.exportKey('pkcs8',key.privateKey))+'\n-----END PRIVATE KEY-----',webhook_secret:random()};
  await env.DB.prepare('INSERT INTO app_config(id,value) VALUES(1,?)').bind(await seal(value,env.ENCRYPTION_KEY,'github-app')).run();
  return value;
}
const signing=crypto.subtle.generateKey({name:'RSASSA-PKCS1-v1_5',modulusLength:2048,publicExponent:new Uint8Array([1,0,1]),hash:'SHA-256'},true,['sign','verify']);
async function actions(overrides={}) {
  const key=await signing;
  const jwk={...await crypto.subtle.exportKey('jwk',key.publicKey),kid:'actions-test',alg:'RS256'};
  const claims={iss:'https://token.actions.githubusercontent.com',aud:ORIGIN+'/nelua/community',iat:now-1,exp:now+300,repository:'Spaceghost/nelua-site',repository_id:'1447444568',repository_owner_id:'251370',actor_id:'251370',ref:'refs/heads/main',workflow_ref:'Spaceghost/nelua-site/.github/workflows/community.yml@refs/heads/main',runner_environment:'self-hosted',event_name:'schedule',run_id:'123',...overrides};
  const message=b64(bytes(JSON.stringify({alg:'RS256',kid:jwk.kid})))+'.'+b64(bytes(JSON.stringify(claims)));
  const token=message+'.'+b64(await crypto.subtle.sign('RSASSA-PKCS1-v1_5',key.privateKey,bytes(message)));
  return {headers:{Authorization:'Bearer '+token},fetch:async url=>{assert.equal(url,'https://token.actions.githubusercontent.com/.well-known/jwks');return Response.json({keys:[jwk]});}};
}
test('signed-out account is private and OAuth starts GitHub with PKCE and state',async()=>{
  const env=environment();
  assert.deepEqual(await (await go(env,'/me')).json(),{signedIn:false,privateAvailable:false});
  const response=await go(env,'/auth/start');
  assert.equal(response.status,302); assert.match(response.headers.get('Set-Cookie'),/Secure; HttpOnly; SameSite=Lax/);
  const location=new URL(response.headers.get('Location')); assert.equal(location.pathname,'/oauth/github/start');
  const next=new URL(location.searchParams.get('next'),ORIGIN);
  assert.equal(next.searchParams.get('code_challenge_method'),'S256'); assert.ok(next.searchParams.get('nonce'));
  assert.equal((await go(env,'/auth/callback?state=forged&code=forged')).status,400);
});
test('selection encryption is bound to its owner',async()=>{
  const env=environment(); const value=await seal([5,8],env.ENCRYPTION_KEY,'selection:1');
  assert.deepEqual(await open(value,env.ENCRYPTION_KEY,'selection:1'),[5,8]);
  await assert.rejects(open(value,env.ENCRYPTION_KEY,'selection:2'));
});
test('signed shared GitHub identity completes PKCE sign-in without an extra GitHub API request',async()=>{
  const env=environment();
  const start=await go(env,'/auth/start');
  const location=new URL(start.headers.get('Location'));
  const query=new URL(location.searchParams.get('next'),ORIGIN).searchParams;
  const value=query.get('state'); const nonce=query.get('nonce');
  const key=await crypto.subtle.generateKey({name:'ECDSA',namedCurve:'P-256'},true,['sign','verify']);
  const jwk={...await crypto.subtle.exportKey('jwk',key.publicKey),kid:'auth-test',alg:'ES256'};
  const sign=async payload=>{
    const data=b64(bytes(JSON.stringify({alg:'ES256',kid:'auth-test'})))+'.'+b64(bytes(JSON.stringify(payload)));
    return data+'.'+b64(await crypto.subtle.sign({name:'ECDSA',hash:'SHA-256'},key.privateKey,bytes(data)));
  };
  const common={iss:ORIGIN,aud:'nelua-community',sub:'u_test',iat:now,exp:now+3600};
  env.AUTH={fetch:async(url,init)=>{
    if(url.endsWith('/jwks'))return Response.json({keys:[jwk]});
    assert.equal(url,ORIGIN+'/oauth/token');
    assert.equal(await hash(init.body.get('code_verifier')),query.get('code_challenge'));
    return Response.json({access_token:await sign({...common,gh:'verified-builder',gh_id:'11',name:'Builder'}),id_token:await sign({...common,nonce})});
  }};
  const response=await go(env,'/auth/callback?code=test&state='+value+'&iss='+encodeURIComponent(ORIGIN),{cookie:'__Secure-nelua_flow='+value},undefined,undefined,{fetch:async()=>{throw new Error('Unexpected external request');}});
  assert.equal(response.status,302);
  const sessionCookie=response.headers.getSetCookie().find(s=>s.startsWith('__Secure-nelua_session='));
  assert.ok(sessionCookie);
  const account=await(await go(env,'/me',{cookie:sessionCookie.split(';')[0]})).json();
  assert.equal(account.profile.id,'11'); assert.equal(account.profile.login,'verified-builder');
});
test('settings require a signed-in owner, same origin and a matching CSRF token',async()=>{
  const env=environment(); const who=await user(env);
  assert.equal((await go(env,'/settings',null,{enabled:false})).status,401);
  assert.equal((await go(env,'/settings',who,{enabled:false},{Origin:'https://attacker.example'})).status,403);
  assert.equal((await go(env,'/settings',who,{enabled:false},{'X-CSRF-Token':'forged'})).status,403);
});
test('public totals contain aggregates only and opt-out removes them immediately',async()=>{
  const env=environment(); const who=await user(env);
  await env.DB.prepare('UPDATE users SET consent=1,installation_id=789,selection=?,totals=?,counted_at=? WHERE id=?').bind(await seal([999],env.ENCRYPTION_KEY,'selection:'+who.id),JSON.stringify({metric:PRIVATE_METRIC,lines:50,files:2,bytes:400,repositories:1}),now,who.id).run();
  const before=await (await go(env,'/private-totals')).json();
  assert.equal(before.people[0].lines,50);
  assert.equal(before.people[0].name,'builder-251370','shared account names stay private; public identity uses GitHub');
  assert.doesNotMatch(JSON.stringify(before),/installation|selection|token|task|sourceFiles|789|999/);
  assert.equal((await go(env,'/settings',who,{enabled:false})).status,200);
  assert.deepEqual(await (await go(env,'/private-totals')).json(),{people:[]});
});
test('only the site owner can create the read-only GitHub App',async()=>{
  const env=environment(); const other=await user(env,'11');
  const anonymous=await go(env,'/app/setup'); assert.equal(anonymous.status,302);
  assert.equal(anonymous.headers.get('Location'),ORIGIN+BASE+'/auth/start?setup=1');
  assert.equal((await go(env,'/app/setup',other)).status,403);
  const owner=await user(env); const response=await go(env,'/app/setup',owner);
  assert.equal(response.status,200); const html=await response.text();
  assert.match(html,/contents&quot;:&quot;read/); assert.doesNotMatch(html,/&quot;write&quot;/);
  assert.match(response.headers.get('Content-Security-Policy'),/form-action https:\/\/github.com/);
});
test('opening the retry URL returns to project choices after App setup',async()=>{
  const env=environment();
  const anonymous=await go(env,'/app/retry');
  assert.equal(anonymous.status,302);
  assert.equal(anonymous.headers.get('Location'),ORIGIN+BASE+'/auth/start?setup=1');
  const who=await user(env);
  const pending=await go(env,'/app/retry',who);
  assert.equal(pending.status,200);assert.match(await pending.text(),/Retry App connection/);
  await app(env);
  const complete=await go(env,'/app/retry');
  assert.equal(complete.status,302);
  assert.equal(complete.headers.get('Location'),ORIGIN+'/nelua/community/#private-projects');
});
test('a valid app installation for a different numeric GitHub owner is rejected',async()=>{
  const env=environment(); const who=await user(env); await app(env);
  const start=await go(env,'/installation/start',who);
  const value=new URL(start.headers.get('Location')).searchParams.get('state');
  const response=await go(env,'/installation/callback?installation_id=44&state='+value,{...who,cookie:who.cookie+'; __Secure-nelua_flow='+value},undefined,undefined,{fetch:async()=>Response.json({account:{id:999},target_type:'User'})});
  assert.equal(response.status,403);
  assert.equal((await env.DB.prepare('SELECT installation_id FROM users WHERE id=?').bind(who.id).first()).installation_id,null);
});
async function manifestFixture() {
  const key=await signing;
  return {id:1,pem:'-----BEGIN PRIVATE KEY-----\n'+b64(await crypto.subtle.exportKey('pkcs8',key.privateKey))+'\n-----END PRIVATE KEY-----',webhook_secret:random(),owner:{id:251370},slug:'nelua-builders',permissions:{contents:'read',metadata:'read'}};
}
test('opaque manifest codes complete setup and credentials are encrypted',async()=>{
  const env=environment(); const who=await user(env); const configured=await manifestFixture();
  const start=await go(env,'/app/setup',who);
  const html=await start.text(); const value=html.match(/apps\/new\?state=([^\"]+)/)[1];
  const fetch=async url=>{
    if(url.includes('/app-manifests/')){assert.match(url,/opaque_code%3Awith-prefix\/conversions$/);return Response.json(configured,{status:201});}
    assert.equal(url,'https://api.github.com/app');return Response.json(configured);
  };
  const response=await go(env,'/app/callback?code=opaque_code%3Awith-prefix&state='+value,{...who,cookie:who.cookie+'; __Secure-nelua_flow='+value},undefined,undefined,{fetch});
  assert.equal(response.status,302);
  assert.equal((await(await go(env,'/me')).json()).privateAvailable,true);
  const row=await env.DB.prepare('SELECT value FROM app_config').first();
  assert.doesNotMatch(row.value,/BEGIN PRIVATE KEY/);
  assert.equal((await open(row.value,env.ENCRYPTION_KEY,'github-app')).id,1);
});
test('expired setup state can recover only through owner same-origin CSRF confirmation',async()=>{
  const env=environment(); const who=await user(env); const configured=await manifestFixture();
  const page=await go(env,'/app/callback?code=opaque_code&state=expired',who);
  assert.equal(page.status,200); assert.match(await page.text(),/Retry App connection/);
  const body=new URLSearchParams({csrf:who.csrf,code:'opaque_code'}).toString();
  const headers={'Content-Type':'application/x-www-form-urlencoded'};
  assert.equal((await go(env,'/app/retry',who,body,{...headers,Origin:'https://attacker.example'})).status,403);
  assert.equal((await go(env,'/app/retry',who,new URLSearchParams({csrf:'forged',code:'opaque_code'}).toString(),headers)).status,403);
  const response=await go(env,'/app/retry',who,body,headers,{fetch:async()=>Response.json(configured)});
  assert.equal(response.status,302); assert.equal((await(await go(env,'/me')).json()).privateAvailable,true);
});
test('a failed metadata call retains encrypted manifest keys for retry without redeeming again',async()=>{
  const env=environment(); const who=await user(env); const configured=await manifestFixture();
  const body=new URLSearchParams({csrf:who.csrf,code:'opaque_code'}).toString();
  const headers={'Content-Type':'application/x-www-form-urlencoded'};
  let conversions=0;let fail=true;
  const fetch=async url=>{
    if(url.includes('/app-manifests/')){conversions++;return Response.json(configured,{status:201});}
    return fail?new Response(null,{status:503}):Response.json(configured);
  };
  assert.equal((await go(env,'/app/retry',who,body,headers,{fetch})).status,200);
  const pending=await env.DB.prepare("SELECT payload FROM states WHERE hash='github-app-pending'").first();
  assert.ok(pending);assert.doesNotMatch(pending.payload,/BEGIN PRIVATE KEY/);
  fail=false;
  assert.equal((await go(env,'/app/retry',who,body,headers,{fetch})).status,302);
  assert.equal(conversions,1);
});
test('a rejected foreign App does not block a subsequent correct App registration',async()=>{
  const env=environment(); const who=await user(env); const configured=await manifestFixture();
  const headers={'Content-Type':'application/x-www-form-urlencoded'}; let foreign=true; let conversions=0;
  const fetch=async url=>{
    if(url.includes('/app-manifests/')){conversions++;return Response.json(configured);}
    return Response.json({...configured,owner:{id:foreign?999:251370}});
  };
  const body=code=>new URLSearchParams({csrf:who.csrf,code}).toString();
  assert.equal((await go(env,'/app/retry',who,body('foreign-code'),headers,{fetch})).status,200);
  assert.equal(await env.DB.prepare("SELECT payload FROM states WHERE hash='github-app-pending'").first(),null);
  foreign=false;
  assert.equal((await go(env,'/app/retry',who,body('correct-code'),headers,{fetch})).status,302);
  assert.equal(conversions,2);
});
test('expired pending credentials are not reused instead of a fresh manifest code',async()=>{
  const env=environment(); const who=await user(env); const configured=await manifestFixture();
  await env.DB.prepare("INSERT INTO states(hash,purpose,payload,expires) VALUES('github-app-pending','app-recovery',?,?)")
    .bind(await seal(configured,env.ENCRYPTION_KEY,'pending-github-app'),now-1).run();
  let conversions=0;
  const fetch=async url=>{if(url.includes('/app-manifests/'))conversions++;return Response.json(configured);};
  const response=await go(env,'/app/retry',who,new URLSearchParams({csrf:who.csrf,code:'fresh-code'}).toString(),{'Content-Type':'application/x-www-form-urlencoded'},{fetch});
  assert.equal(response.status,302);assert.equal(conversions,1);
});
test('public, forked and unowned repository IDs cannot be selected',async()=>{
  const env=environment(); const who=await user(env); await app(env);
  await env.DB.prepare('UPDATE users SET installation_id=44 WHERE id=?').bind(who.id).run();
  const fetch=async url=>url.endsWith('/access_tokens')?Response.json({token:'never-log-this-token'}):url.includes('/installation/repositories')?Response.json({total_count:3,repositories:[{id:1,full_name:'private-name-a',owner:{id:251370},private:false,fork:false},{id:2,full_name:'private-name-b',owner:{id:251370},private:true,fork:true},{id:3,full_name:'private-name-c',owner:{id:999},private:true,fork:false}]}):Response.json({account:{id:251370},target_type:'User'});
  const response=await go(env,'/settings',who,{enabled:true,repositories:[1,2,3]},undefined,{fetch});
  assert.equal(response.status,403); assert.doesNotMatch(await response.text(),/private-name|never-log/);
});
test('valid Actions signatures from another workflow, actor, branch or repository are rejected',async()=>{
  const env=environment();
  for(const override of [{ref:'refs/heads/other'},{repository_id:'9'},{workflow_ref:'Spaceghost/nelua-site/.github/workflows/other.yml@refs/heads/main'},{actor_id:'9'},{event_name:'pull_request'}]){
    const identity=await actions(override);
    const response=await go(env,'/refresh/owners',null,undefined,identity.headers,{fetch:identity.fetch});
    assert.equal(response.status,403);
  }
});
test('a result issued before opt-out cannot restore private totals',async()=>{
  const env=environment(); const who=await user(env); const task=random();
  await env.DB.prepare('UPDATE users SET consent=1 WHERE id=?').bind(who.id).run();
  await env.DB.prepare('INSERT INTO scan_tasks(hash,user_id,version,repository_count,run_id,expires) VALUES(?,?,?,?,?,?)').bind(await hash(task),who.id,0,1,'123',now+3600).run();
  await go(env,'/settings',who,{enabled:false}); const identity=await actions();
  const response=await go(env,'/refresh/result',null,{task,metric:PRIVATE_METRIC,lines:100,bytes:1000,files:2,repositories:1},identity.headers,{fetch:identity.fetch});
  assert.deepEqual(await response.json(),{published:false});
  assert.deepEqual(await (await go(env,'/private-totals')).json(),{people:[]});
});
test('old repository-size totals are hidden and new scans must attest authored lines',async()=>{
  const env=environment(); const who=await user(env);
  await env.DB.prepare('UPDATE users SET consent=1,totals=?,counted_at=? WHERE id=?').bind(JSON.stringify({lines:999,bytes:999,files:1,repositories:1}),now,who.id).run();
  assert.deepEqual(await (await go(env,'/private-totals')).json(),{people:[]});
  const own=await (await go(env,'/me',who)).json();
  assert.equal(own.totals,null); assert.equal(own.countedAt,null);
  const identity=await actions();
  const response=await go(env,'/refresh/result',null,{task:'old',lines:999,bytes:999,files:1,repositories:1},identity.headers,{fetch:identity.fetch});
  assert.equal(response.status,400);
  assert.deepEqual(await response.json(),{error:'authored_metric_required'});
});
test('an admitted authored result publishes only fresh consented aggregate totals',async()=>{
  const env=environment(); const who=await user(env); const task=random();
  await env.DB.prepare('UPDATE users SET consent=1 WHERE id=?').bind(who.id).run();
  await env.DB.prepare('INSERT INTO scan_tasks(hash,user_id,version,repository_count,run_id,expires) VALUES(?,?,?,?,?,?)').bind(await hash(task),who.id,0,1,'123',now+3600).run();
  const identity=await actions();
  const response=await go(env,'/refresh/result',null,{task,metric:PRIVATE_METRIC,lines:100,bytes:1000,files:2,repositories:1},identity.headers,{fetch:identity.fetch});
  assert.deepEqual(await response.json(),{published:true});
  const result=await (await go(env,'/private-totals')).json();
  assert.deepEqual(result.people,[{id:who.id,login:'builder-'+who.id,name:'builder-'+who.id,
    metric:PRIVATE_METRIC,lines:100,bytes:1000,files:2,repositories:1,generatedAt:new Date(now*1000).toISOString()}]);
  const replay=await go(env,'/refresh/result',null,{task,metric:PRIVATE_METRIC,lines:100,bytes:1000,files:2,repositories:1},identity.headers,{fetch:identity.fetch});
  assert.equal(replay.status,403);
});
test('a signed uninstall webhook clears connection, consent and totals',async()=>{
  const env=environment(); const who=await user(env); const configured=await app(env);
  await env.DB.prepare('UPDATE users SET installation_id=44,consent=1 WHERE id=?').bind(who.id).run();
  const body=JSON.stringify({action:'deleted',installation:{id:44}});
  const key=await crypto.subtle.importKey('raw',bytes(configured.webhook_secret),{name:'HMAC',hash:'SHA-256'},false,['sign']);
  const signature=Array.from(new Uint8Array(await crypto.subtle.sign('HMAC',key,bytes(body))),v=>v.toString(16).padStart(2,'0')).join('');
  const response=await go(env,'/webhook',null,body,{'X-Hub-Signature-256':'sha256='+signature,'X-GitHub-Event':'installation'});
  assert.equal(response.status,204);
  const current=await (await go(env,'/me',who)).json(); assert.equal(current.connected,false); assert.equal(current.enabled,false);
});
