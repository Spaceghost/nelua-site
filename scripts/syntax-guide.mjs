// Render the compiler's canonical guide into this site's static layout.
// npm run guide -- ../nelua-lang/docs/pages/syntax-extensions.md
import { readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { marked, Renderer } from 'marked';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const source = resolve(process.argv[2] ?? resolve(root, '../nelua-lang/docs/pages/syntax-extensions.md'));
const output = resolve(root, 'public/nelua/compiler/syntax-extensions/index.html');
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
const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Syntax extensions: the full guide · Nelua · spacegho.st</title>
<meta name="description" content="Load Nelua syntax modules for control flow, lambdas, destructuring, scoped resources, comprehensions, literals, pipes and interpolation. A complete guide to file-local grammars, templates, precedence and reusable packs.">
<link rel="stylesheet" href="/nelua/assets/site.css">
<link rel="icon" href="/nelua/assets/icon.svg" type="image/svg+xml">
<link rel="canonical" href="https://spacegho.st/nelua/compiler/syntax-extensions/">
</head>
<body>
<a class="skip-link" href="#guide">Skip to guide</a>
<div class="wrap">
<header class="top">
  <a class="home" href="/nelua/">spacegho.st / nelua</a>
  <nav aria-label="Sections">
    <a href="/nelua/">Overview</a>
    <a href="/nelua/compiler/" aria-current="page">Compiler</a>
    <a href="/nelua/nelibc/">nelibc</a>
    <a href="/nelua/nebox/">nebox</a>
    <a href="https://nelua.io/" rel="external">nelua.io ↗</a>
  </nav>
</header>
<section class="hero">
  <p class="eyebrow">Compiler · syntax workshop</p>
  <h1>Make room for your notation</h1>
  <p class="tagline">A full guide to Nelua's file-local syntax extensions.</p>
  <p class="blurb">Start with the opt-in library, compose a project pack, then build your own grammar rules. Every form becomes ordinary Nelua before type checking.</p>
  <div class="actions">
    <a class="button" href="#start-here">Try the complete pack</a>
    <a class="button button-ghost" href="#write-an-inline-extension">Write an extension</a>
  </div>
</section>
<div class="guide-layout">
  <nav class="guide-toc" aria-label="Guide contents">
    <p class="eyebrow">In this guide</p>
    <ol>${toc}</ol>
  </nav>
  <main class="guide-article" id="guide" tabindex="-1">
${body}
  </main>
</div>
<footer>
  <span>spacegho.st / nelua / compiler / syntax extensions</span>
  <a href="/nelua/compiler/">← Compiler</a>
  <a href="https://github.com/Spaceghost/nelua-lang/blob/master/docs/pages/syntax-extensions.md">Guide source ↗</a>
  <a href="https://github.com/Spaceghost/nelua-lang/blob/master/examples/syntax_tour.nelua">Runnable tour ↗</a>
</footer>
</div>
</body>
</html>
`;
mkdirSync(dirname(output), { recursive: true });
writeFileSync(output, html);
console.log(`Rendered ${sections.length} sections from ${source} to ${output}`);
