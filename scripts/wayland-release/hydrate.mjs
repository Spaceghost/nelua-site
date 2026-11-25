// The site's runtime has no remote origin. Restore immutable release artifacts
// at build time, before mirroring them into both final static URL layouts.
import { createHash } from 'node:crypto';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { join, dirname } from 'node:path';

const lock = JSON.parse(await readFile(new URL('./assets.json', import.meta.url), 'utf8'));
const prefix = 'https://nelua.tech/init/wayland/';
const valid = (data, { bytes, sha256 }) =>
  data.byteLength === bytes && createHash('sha256').update(data).digest('hex') === sha256;

async function local(file) {
  try { return await readFile(file); }
  catch (err) { if (err.code !== 'ENOENT') throw err; return null; }
}

export async function hydrateWayland(output) {
  const entries = Object.entries(lock);
  let at = 0;
  async function next() {
    while (at < entries.length) {
      const [rel, info] = entries[at++];
      if (!/^(?:runtime|sources)\/[a-zA-Z0-9._+/-]+$/.test(rel) ||
          rel.split('/').some(part => part === '.' || part === '..' || !part) ||
          !/^[0-9a-f]{64}$/.test(info.sha256) || !Number.isSafeInteger(info.bytes) ||
          info.bytes < 1 || info.bytes > 25 * 1024 * 1024) throw Error('Invalid Wayland asset lock');
      const sitePath = join(output, 'init/wayland', rel);
      const supplied = await local(sitePath);
      if (supplied && !valid(supplied, info)) throw Error('Wrong local Wayland asset: ' + rel);
      if (supplied) continue;
      const cacheRoot = process.env.NELUA_WAYLAND_ASSET_CACHE ||
        (process.env.RUNNER_TEMP && join(process.env.RUNNER_TEMP, 'nelua-wayland-assets'));
      const cache = cacheRoot && join(cacheRoot, info.sha256);
      let data = cache && await local(cache);
      if (!data || !valid(data, info)) {
        if (process.env.NELUA_WAYLAND_OFFLINE === '1') throw Error('Missing offline Wayland asset: ' + rel);
        const res = await fetch(new URL(rel, prefix), {redirect:'error',signal:AbortSignal.timeout(60_000)});
        if (!res.ok) throw Error('Wayland asset unavailable: ' + rel + ' (' + res.status + ')');
        if (Number(res.headers.get('content-length') ?? 0) > 25 * 1024 * 1024) throw Error('Oversized Wayland response');
        const reader=res.body.getReader(), parts=[];
        let bytes=0;
        for(;;){
          const {done,value}=await reader.read();
          if(done)break;
          bytes+=value.byteLength;
          if(bytes>info.bytes){await reader.cancel();throw Error('Oversized Wayland asset: '+rel);}
          parts.push(value);
        }
        data = Buffer.concat(parts, bytes);
        if (!valid(data, info)) throw Error('Wrong public Wayland asset: ' + rel);
        if (cache) {
          await mkdir(cacheRoot, {recursive:true});
          await writeFile(cache, data);
        }
      }
      for (const prefix of ['init/wayland', 'nelua/init/wayland']) {
        const dest = join(output, prefix, rel);
        await mkdir(dirname(dest), {recursive:true});
        await writeFile(dest, data);
      }
    }
  }
  await Promise.all(Array.from({length:4},next));
}
