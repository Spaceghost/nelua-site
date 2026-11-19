// Publish the browser entry points under the existing static asset paths.
import { copyFileSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

for (const [build, name, destination] of [
  ['explorer', 'explorer', 'public/nelua/assets/explorer.js'],
  ['community-app', 'app', 'public/nelua/community/app.js'],
  ['community-account', 'account', 'public/nelua/community/account.js'],
]) {
  const directory = join('build', build);
  const manifest = JSON.parse(readFileSync(join(directory, 'manifest.json'), 'utf8'));
  if (!manifest.main?.startsWith('assets/' + name + '.')) throw new Error('Missing browser entry in ' + directory);
  const entry = join(directory, manifest.main);
  if (build === 'explorer') {
    copyFileSync(entry, destination);
  } else {
    // These classic scripts share a page. Keep minified identifiers local.
    writeFileSync(destination, '(() => {\n' + readFileSync(entry, 'utf8') + '\n})();\n');
  }
}
