import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
import {runConsole} from './wasi.mjs';
const dir = process.argv[2];
const compile = async name => WebAssembly.compile(await readFile(resolve(dir, name + '.wasm')));
const rules = (await import(pathToFileURL(resolve(dir, 'rule.mjs')))).default;
const {exports: op} = await WebAssembly.instantiate(await compile('opcode'), {env: rules});
for (let index = 0; index < 23; index++) {
  assert.equal(op.encode(index, 15, 7, 9), index + (15 << 8) + (7 << 16) + (9 << 24));
}
assert.equal(op.encode(23, 0, 0, 0) >>> 0, 0xffffffff);
const {exports: arena} = await WebAssembly.instantiate(await compile('arena'));
const base = arena.mx_alloc(13);
assert.ok(base);
assert.equal(arena.mx_alloc(0), base + 16);
assert.equal(arena.mx_arena_used(), 24);
arena.mx_reset();
assert.equal(arena.mx_alloc(arena.mx_arena_capacity()), base);
assert.equal(arena.mx_alloc(1), 0);
for (const [name, expected] of [['c-call', 'Hello from Nelua\n'], ['comptime', '256\n'], ['point', '8\t4\n']]) {
  assert.equal(await runConsole(await compile(name)), expected);
}
