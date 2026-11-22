// Assemble both URL layouts from the same committed pages and dated assets.
import { cpSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const output = 'build/site';
rmSync(output, { recursive: true, force: true });
mkdirSync(output, { recursive: true });
cpSync('public/nelua', join(output, 'nelua'), { recursive: true });
for (const entry of readdirSync('public/nelua')) {
  cpSync(join('public/nelua', entry), join(output, entry), { recursive: true });
}

// Only change site-local URL attributes. Source examples, GitHub links and
// the account flow on spacegho.st retain their original paths.
for (const path of readdirSync('public/nelua', { recursive: true })) {
  if (path.endsWith('.html')) {
    const file = join(output, path);
    const html = readFileSync(file, 'utf8');
    writeFileSync(file, html.replace(/\b(href|src)="\/nelua\//g, '$1="/'));
  }
}
const profiles = join(output, 'assets/nelibc-coverage-profiles.json');
writeFileSync(profiles, readFileSync(profiles, 'utf8').replaceAll('"/nelua/assets/', '"/assets/'));
cpSync('public/_headers', join(output, '_headers'));
