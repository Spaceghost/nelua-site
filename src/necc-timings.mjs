// Render both compiler tables from the published medians.
import { readFileSync } from 'node:fs';

const csv = readFileSync('public/nelua/assets/necc-20261121/summary.csv', 'utf8');
const [header, ...lines] = csv.trim().split(/\r?\n/);
const columns = header.split(',');
const records = lines.map(line => {
  const cells = line.split(',');
  return Object.fromEntries(columns.map((name, i) => [name, cells[i]]));
});
const workloads = [
  ['compile', 'tiny', 'Compile tiny C input', 'Tiny C'],
  ['compile', '128-functions', 'Compile 128 functions', '128 functions'],
  ['compile', 'arithmetic', 'Compile arithmetic kernel', 'Arithmetic'],
  ['compile', 'lua-lctype', 'Compile Lua character table', 'Lua characters'],
  ['compile', 'lua-lopcodes', 'Compile Lua opcode table', 'Lua opcodes'],
  ['compile', 'selfhost', 'Compile bootstrap compiler', 'Bootstrap C'],
  ['run', 'arithmetic', 'Run six million iterations', 'Run arithmetic'],
  ['run', 'selfhost', 'Regenerate bootstrap C', 'Run bootstrap'],
];

function toolLabel(name) {
  if (name === 'necc-base') return 'necc before';
  if (name === 'necc-next') return 'necc updated SDK';
  return name.replace('Zig-cc', 'Zig cc').replace('Clang14', 'Clang 14').replace('cproc-QBE', 'cproc/QBE').replace(/-O(\d)?$/, ' -O$1');
}

export const comparisons = workloads.map(([phase, name, label, short]) => {
  const results = records.filter(row => row.case === name && row.phase === phase);
  const before = results.find(row => row.tool === 'necc-base');
  const after = results.find(row => row.tool === 'necc-next');
  const [best] = results.filter(row => !row.tool.startsWith('necc-'))
    .sort((a, b) => Number(a.median_ms) - Number(b.median_ms));
  if (!before || !after || !best) throw new Error('Incomplete compiler results for ' + label);
  return { label, short, results, before: Number(before.median_ms).toFixed(3),
    after: Number(after.median_ms).toFixed(3), best: Number(best.median_ms).toFixed(3),
    external: toolLabel(best.tool), bytes: after.text_bytes };
});

const names = [...new Set(records.map(row => row.tool))];
export const field = names.map(name => ({
  label: toolLabel(name),
  medians: comparisons.map(work => {
    const row = work.results.find(row => row.tool === name);
    return row ? Number(row.median_ms).toFixed(3) : '—';
  }),
}));
