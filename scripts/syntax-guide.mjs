// Render the compiler's canonical guide into this site's static layout.
// npm run guide -- ../nelua-lang/docs/pages/syntax-extensions.md
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { marked, Renderer } from 'marked';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const source = resolve(process.argv[2] ?? resolve(root, '../nelua-lang/docs/pages/syntax-extensions.md'));
const output = resolve(root, 'src/content');
const markdown = readFileSync(source, 'utf8')
  .replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/, '')
  .replace(/\{%\s*(?:endraw|raw)\s*%\}/g, '');
const escape = (value) => value.replace(/[&<>"']/g, c => ({'&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;'}[c]));
const sections = [];
const ids = new Set();
const renderer = new Renderer();
renderer.heading = function ({ tokens, depth }) {
  const content = this.parser.parseInline(tokens);
  const title = content.replace(/<[^>]*>/g, '');
  const id = title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
  if (ids.has(id)) throw new Error(`Duplicate guide heading: ${id}`);
  ids.add(id);
  if (depth === 2) sections.push({ id, title });
  return `<h${depth} class="section" id="${id}">${content}</h${depth}>\n`;
};
const renderTable = renderer.table;
renderer.table = function (token) {
  return `<div class="table-wrap">${renderTable.call(this, token)}</div>\n`;
};
const body = marked.parse(markdown, { renderer, gfm: true, async: false });
const toc = sections.map(({id, title}) => `<li><a href="#${id}">${escape(title)}</a></li>`).join('\n');
writeFileSync(resolve(output, 'syntax-guide.html'), body.trim() + '\n');
writeFileSync(resolve(output, 'syntax-toc.html'), toc.trim() + '\n');
console.log(`Refreshed ${sections.length} syntax guide sections from ${source}`);
