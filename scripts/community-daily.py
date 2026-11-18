#!/usr/bin/env python3
"""Collect, validate, commit and publish the daily static community snapshot.

Run through GitHub Actions or the manual host launcher documented in README.md.
Credentials come from the workflow's job token and deployment secret, or from
the operator's existing gh and Wrangler configuration, never from source.
Each run has its own Git worktree and evidence directory. Failed runs retain
their evidence and leave the last published snapshot available.
"""
import argparse
import base64
import datetime as dt
import fcntl
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import tomllib
import urllib.request


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workspace', type=Path, required=True)
    parser.add_argument('--cache-dir', type=Path, required=True)
    parser.add_argument('--artifact-dir', type=Path, required=True)
    args = parser.parse_args()
    args.workspace.mkdir(parents=True, exist_ok=True)
    with (args.workspace / 'daily.lock').open('a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print('A community refresh is already running; skipped.')
            return
        run(args)


def run(args):
    control = Path(__file__).resolve().parents[1]
    stamp = dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    evidence = args.artifact_dir / stamp
    evidence.mkdir(parents=True)
    args.cache_dir.mkdir(parents=True, exist_ok=True)
    worktree = args.workspace / 'runs' / stamp
    worktree.parent.mkdir(parents=True, exist_ok=True)
    print(f'Daily community refresh: {stamp}\nEvidence: {evidence}', flush=True)
    report = {'run': stamp, 'status': 'running', 'worktree': str(worktree)}
    log = (evidence / 'run.log').open('w', buffering=1)

    def command(argv, cwd=control, capture=False, timeout=180):
        log.write('+ ' + ' '.join(str(a) for a in argv) + '\n')
        result = subprocess.run([str(a) for a in argv], cwd=cwd, check=True,
                                stdout=subprocess.PIPE if capture else log,
                                stderr=log, text=True, timeout=timeout)
        return result.stdout.strip() if capture else None

    def save_report():
        (evidence / 'report.json').write_text(json.dumps(report, indent=2) + '\n')

    try:
        os.environ['CI'] = 'true'
        os.environ['GIT_TERMINAL_PROMPT'] = '0'
        os.environ['WRANGLER_SEND_METRICS'] = 'false'
        os.environ['WRANGLER_LOG_PATH'] = str(evidence / 'wrangler.log')
        if os.environ.get('GITHUB_ACTIONS') == 'true':
            if (os.environ.get('GITHUB_REPOSITORY') != 'Spaceghost/nelua-site'
                    or os.environ.get('GITHUB_REF') != 'refs/heads/main'
                    or os.environ.get('GITHUB_EVENT_NAME') not in ('schedule', 'workflow_dispatch')):
                raise RuntimeError('Only default-branch scheduled or manual Actions runs may publish')
            token = os.environ.get('GH_TOKEN', '')
            if not token:
                raise RuntimeError('The Actions job token is missing')
            # Environment-only authentication also works in linked Git worktrees.
            # Do not persist the job token in a checkout, log or artifact.
            auth = base64.b64encode(('x-access-token:' + token).encode()).decode()
            os.environ['GIT_CONFIG_COUNT'] = '1'
            os.environ['GIT_CONFIG_KEY_0'] = 'http.https://github.com/.extraheader'
            os.environ['GIT_CONFIG_VALUE_0'] = 'AUTHORIZATION: basic ' + auth
        # Keep the control checkout clean: every data change happens in a run worktree.
        if command(['git', 'status', '--porcelain'], capture=True):
            raise RuntimeError('Control checkout has local changes; refusing to overwrite them')
        command(['git', 'fetch', '--quiet', 'origin', 'main'])
        command(['git', 'merge', '--ff-only', 'origin/main'])
        base = command(['git', 'rev-parse', 'origin/main'], capture=True)
        command(['git', 'worktree', 'add', '-b', f'release/community-{stamp}', worktree, base])
        config = tomllib.loads((worktree / 'wrangler.toml').read_text())
        if config.get('name') != 'nelua-site' or 'main' in config or config.get('assets', {}).get('directory') != 'public':
            raise RuntimeError('Expected the existing assets-only nelua-site configuration')
        if not os.environ.get('CLOUDFLARE_ACCOUNT_ID'):
            raise RuntimeError('CLOUDFLARE_ACCOUNT_ID must select the established deployment account')
        command(['gh', 'api', 'repos/Spaceghost/nelua-site', '--jq', '.full_name'])

        # Reuse exactly the locked dependencies; install only when the lock changes.
        key = hashlib.sha256((worktree / 'package-lock.json').read_bytes()
                             + (worktree / 'package.json').read_bytes()).hexdigest()[:20]
        dependencies = args.cache_dir / 'dependencies' / key
        if not (dependencies / '.ready').exists():
            dependencies.mkdir(parents=True, exist_ok=True)
            for name in ('package.json', 'package-lock.json'):
                shutil.copy2(worktree / name, dependencies / name)
            command(['npm', 'ci', '--ignore-scripts', '--no-audit', '--no-fund'], cwd=dependencies, timeout=600)
            (dependencies / '.ready').touch()
        wrangler = ['node', dependencies / 'node_modules/wrangler/bin/wrangler.js']

        stage = evidence / 'snapshot'
        stage.mkdir()
        published = worktree / 'public/nelua/community'
        command([sys.executable, 'scripts/community-update.py', '--candidates', 'scripts/community-candidates.json',
                 '--output', stage / 'data.json', '--cache-dir', args.cache_dir / 'public-blobs'],
                cwd=worktree, timeout=1200)
        command([sys.executable, 'scripts/community-assets.py', '--directory', stage, '--no-fonts'],
                cwd=worktree, timeout=300)
        command([sys.executable, 'scripts/community-validate.py', '--previous', published / 'data.json',
                 '--snapshot', stage / 'data.json', '--assets', stage], cwd=worktree)
        shutil.copytree(stage, published, dirs_exist_ok=True)
        command(['git', 'diff', '--check'], cwd=worktree)
        command(wrangler + ['deploy', '--config', 'wrangler.toml', '--dry-run', '--strict', '--keep-vars',
                            '--outdir', evidence / 'dry-run'], cwd=worktree)
        command(['git', 'add', '--', 'public/nelua/community/data.json', 'public/nelua/community/avatars'], cwd=worktree)
        command(['git', 'commit', '-m', f'Refresh Nelua community snapshot ({stamp[:8]})'], cwd=worktree)
        command(['git', 'fetch', '--quiet', 'origin', 'main'], cwd=worktree)
        if command(['git', 'rev-parse', 'origin/main'], cwd=worktree, capture=True) != base:
            raise RuntimeError('Main advanced during collection; next run will use its newer source')
        command(['git', 'push', 'origin', 'HEAD:main'], cwd=worktree)
        report['commit'] = command(['git', 'rev-parse', 'HEAD'], cwd=worktree, capture=True)
        report['status'] = 'source-pushed'
        save_report()
        command(wrangler + ['deploy', '--config', 'wrangler.toml', '--strict', '--keep-vars',
                            '--message', f'Daily Nelua community snapshot {stamp[:8]}'], cwd=worktree, timeout=300)

        # Check the deployed bytes using a fresh cache key, without watching CI.
        expected = hashlib.sha256((stage / 'data.json').read_bytes()).hexdigest()
        url = 'https://spacegho.st/nelua/community/data.json?snapshot=' + expected
        for attempt in range(3):
            try:
                request = urllib.request.Request(url, headers={
                    'User-Agent': 'Mozilla/5.0 Chrome/131.0.0.0 Safari/537.36', 'Cache-Control': 'no-cache'})
                with urllib.request.urlopen(request, timeout=30) as response:
                    actual = hashlib.sha256(response.read()).hexdigest()
                if actual != expected:
                    raise RuntimeError('Published data does not match the validated snapshot')
                break
            except Exception:
                if attempt == 2:
                    raise
                time.sleep(2)
        snapshot = json.loads((stage / 'data.json').read_text())
        report.update(status='published', generatedAt=snapshot['generatedAt'], sha256=expected,
                      coverage=snapshot['coverage'])
        save_report()
        last = args.artifact_dir / 'last-success.json'
        temporary = last.with_suffix('.tmp')
        temporary.write_text(json.dumps(report, indent=2) + '\n')
        temporary.replace(last)
        print(f"Published {snapshot['generatedAt']}: {snapshot['coverage']['lines']:,} source lines", flush=True)
    except Exception as error:
        report.update(status='failed', error=f'{type(error).__name__}: {error}')
        save_report()
        print(f'Community refresh failed; see {evidence / "run.log"}: {error}', file=sys.stderr)
        raise
    finally:
        log.close()


if __name__ == '__main__':
    main()
