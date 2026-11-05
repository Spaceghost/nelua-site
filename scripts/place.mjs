// Copy the Imba bundle entry to its fixed public path so the HTML can reference
// it without a hashed name. Imba writes build/explorer/<name>.js (+ manifest).
import { readdirSync, copyFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
const dir = 'build/explorer/assets';
const entries = readdirSync(dir).filter(f => f.endsWith('.js'));
if (entries.length === 0) throw new Error('no bundle in ' + dir);
entries.sort((a, b) => statSync(join(dir, b)).size - statSync(join(dir, a)).size);
copyFileSync(join(dir, entries[0]), 'public/nelua/assets/explorer.js');
console.log('explorer.js <-', entries[0], statSync(join(dir, entries[0])).size, 'bytes');
