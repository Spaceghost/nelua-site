#!/usr/bin/env python3
"""Cache the public profile thumbnails and OFL fonts as same-origin static assets."""
import argparse
import concurrent.futures
import hashlib
import json
import re
import urllib.parse
import urllib.request
from pathlib import Path


def fetch(url):
    request = urllib.request.Request(url, headers={
        'User-Agent': 'Mozilla/5.0 Chrome/131.0.0.0 Safari/537.36'})
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', type=Path, default=Path('dist'))
    parser.add_argument('--no-fonts', action='store_true', help='Use system fonts; localize only profile thumbnails')
    args = parser.parse_args()
    root = args.directory
    (root / 'fonts').mkdir(exist_ok=True)
    (root / 'avatars').mkdir(exist_ok=True)
    data = json.loads((root / 'data.json').read_text())

    def profile(person):
        login = person['login'].lower()
        assert re.fullmatch(r'[a-z0-9-]+', login)
        url = urllib.parse.urlparse(person['avatarUrl'])
        assert url.hostname == 'avatars.githubusercontent.com'
        image = fetch(person['avatarUrl'] + '&s=96')
        extension = 'png' if image.startswith(b'\x89PNG') else 'webp' if image[8:12] == b'WEBP' else 'jpg'
        name = f'avatars/{login}.{extension}'
        (root / name).write_bytes(image)
        person['localAvatarUrl'] = name

    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        list(pool.map(profile, data['people']))
    if args.no_fonts:
        (root / 'data.json').write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
        print(f'Localized {len(data["people"])} public profile thumbnails')
        return
    css = fetch('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=Space+Grotesk:wght@400;500;600;700&family=IBM+Plex+Mono:wght@400;500;600&display=swap').decode()
    for url in set(re.findall(r'url\((https://fonts\.gstatic\.com/[^)]+)\)', css)):
        content = fetch(url)
        extension = urllib.parse.urlparse(url).path.rsplit('.', 1)[-1]
        name = 'fonts/' + hashlib.sha256(content).hexdigest()[:16] + '.' + extension
        (root / name).write_bytes(content)
        css = css.replace(url, name)
    for font in ('dmsans', 'spacegrotesk', 'ibmplexmono'):
        (root / 'fonts' / (font + '-OFL.txt')).write_bytes(
            fetch(f'https://raw.githubusercontent.com/google/fonts/main/ofl/{font}/OFL.txt'))
    (root / 'fonts.css').write_text(css)
    (root / 'data.json').write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
    print(f'Localized {len(data["people"])} public profile thumbnails and all font assets')


if __name__ == '__main__':
    main()
