import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {join} from 'node:path';
import {pathToFileURL} from 'node:url';

const dir = process.argv[2];
const {default: rules} = await import(pathToFileURL(join(dir, 'rule.mjs')));
const {instance, module} = await WebAssembly.instantiate(readFileSync(join(dir, 'life.wasm')), {env: {survives: (alive, neighbors) => rules.survives(alive >>> 0, neighbors >>> 0)}});
assert.deepEqual(WebAssembly.Module.imports(module), [{module: 'env', name: 'survives', kind: 'function'}]);
for (let alive = 0; alive <= 1; alive++) {
  for (let neighbors = 0; neighbors <= 8; neighbors++) {
    assert.equal(rules.survives(alive, neighbors), Number(neighbors === 3 || (alive === 1 && neighbors === 2)));
  }
}
// Exhaust every 3-by-3 neighborhood, including the wrap across column zero.
for (let mask = 0; mask < 512; mask++) {
  const rows = [0, 0, 0];
  let neighbors = 0;
  for (let i = 0; i < 9; i++) {
    const bit = (mask >> i) & 1;
    rows[Math.floor(i / 3)] |= bit << ((15 + i % 3) % 16);
    if (i !== 4) neighbors += bit;
  }
  const expected = neighbors === 3 || (neighbors === 2 && Boolean(mask & 16));
  assert.equal(instance.exports.next_row(...rows) & 1, Number(expected));
}
