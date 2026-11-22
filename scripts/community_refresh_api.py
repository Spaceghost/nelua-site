"""Authenticated requests from the admitted community workflow."""
import json
import os
import urllib.parse
import urllib.request

ROOT = 'https://spacegho.st/nelua/community'


def read_json(request, maximum=4 * 1024 * 1024):
    with urllib.request.urlopen(request, timeout=40) as response:
        raw = response.read(maximum + 1)
    if len(raw) > maximum:
        raise RuntimeError('response too large')
    return json.loads(raw)


def oidc():
    url = os.environ['ACTIONS_ID_TOKEN_REQUEST_URL']
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme != 'https' or not (parsed.hostname or '').endswith('.actions.githubusercontent.com'):
        raise RuntimeError('invalid Actions identity endpoint')
    url += ('&' if '?' in url else '?') + urllib.parse.urlencode({'audience': ROOT})
    request = urllib.request.Request(url, headers={'Authorization': 'Bearer ' + os.environ['ACTIONS_ID_TOKEN_REQUEST_TOKEN']})
    return read_json(request)['value']


def api(path, body=None):
    headers = {'Authorization': 'Bearer ' + oidc(), 'User-Agent': 'Mozilla/5.0 Nelua-Builders/1.0'}
    if body is not None:
        headers['Content-Type'] = 'application/json'
    request = urllib.request.Request(ROOT + '/api/refresh/' + path, headers=headers,
                                     data=(body if isinstance(body, bytes) else json.dumps(body).encode()) if body is not None else None)
    return read_json(request)
