import argparse
import hashlib
import json
import re
import time
import urllib.request
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPECS = {
    250: ('death-knight', 'blood', 'tank'),
    251: ('death-knight', 'frost', 'dps'),
    252: ('death-knight', 'unholy', 'dps'),
    577: ('demon-hunter', 'havoc', 'dps'),
    581: ('demon-hunter', 'vengeance', 'tank'),
    1480: ('demon-hunter', 'devourer', 'dps'),
    102: ('druid', 'balance', 'dps'),
    103: ('druid', 'feral', 'dps'),
    104: ('druid', 'guardian', 'tank'),
    105: ('druid', 'restoration', 'healer'),
    1467: ('evoker', 'devastation', 'dps'),
    1468: ('evoker', 'preservation', 'healer'),
    1473: ('evoker', 'augmentation', 'dps'),
    253: ('hunter', 'beast-mastery', 'dps'),
    254: ('hunter', 'marksmanship', 'dps'),
    255: ('hunter', 'survival', 'dps'),
    62: ('mage', 'arcane', 'dps'),
    63: ('mage', 'fire', 'dps'),
    64: ('mage', 'frost', 'dps'),
    268: ('monk', 'brewmaster', 'tank'),
    270: ('monk', 'mistweaver', 'healer'),
    269: ('monk', 'windwalker', 'dps'),
    65: ('paladin', 'holy', 'healer'),
    66: ('paladin', 'protection', 'tank'),
    70: ('paladin', 'retribution', 'dps'),
    256: ('priest', 'discipline', 'healer'),
    257: ('priest', 'holy', 'healer'),
    258: ('priest', 'shadow', 'dps'),
    259: ('rogue', 'assassination', 'dps'),
    260: ('rogue', 'outlaw', 'dps'),
    261: ('rogue', 'subtlety', 'dps'),
    262: ('shaman', 'elemental', 'dps'),
    263: ('shaman', 'enhancement', 'dps'),
    264: ('shaman', 'restoration', 'healer'),
    265: ('warlock', 'affliction', 'dps'),
    266: ('warlock', 'demonology', 'dps'),
    267: ('warlock', 'destruction', 'dps'),
    71: ('warrior', 'arms', 'dps'),
    72: ('warrior', 'fury', 'dps'),
    73: ('warrior', 'protection', 'tank'),
}


def parse(body):
    decoder = json.JSONDecoder()
    markup = []
    for match in re.finditer(r'WH\.markup\.printHtml\(\s*(?=")', body):
        value, _ = decoder.raw_decode(body[match.end():])
        if '[item=' in value:
            markup.append(value)
    items = {}
    for match in re.finditer(r'WH\.Gatherer\.addData\(3,\s*1,\s*', body):
        value, _ = decoder.raw_decode(body[match.end():])
        items.update(value)
    if not markup or not items:
        raise ValueError('Guide markup or item metadata missing')
    dates = re.findall(r'\b2026/\d{2}/\d{2}\b', body)
    title = re.search(r'<title>(.*?)</title>', body, re.S)
    return {'title': title[1] if title else '', 'updated': dates[0] if dates else None,
            'markup': '\n'.join(markup), 'items': items}


def main():
    parser = argparse.ArgumentParser(description='Manually invoked one-off guide capture; never writes Data.lua.')
    parser.add_argument('--spec', type=int, choices=sorted(SPECS), action='append')
    parser.add_argument('--offline', action='store_true')
    args = parser.parse_args()
    cache = ROOT / '.cache' / 'wowhead'
    cache.mkdir(parents=True, exist_ok=True)
    missing = []
    for spec_id in args.spec or sorted(SPECS):
        cls, spec, role = SPECS[spec_id]
        url = f'https://www.wowhead.com/guide/classes/{cls}/{spec}/enchants-gems-pve-{role}'
        path = cache / f'{spec_id}.json'
        try:
            if path.exists():
                result = json.loads(path.read_text(encoding='utf-8'))
            elif args.offline:
                raise ValueError('Not cached')
            else:
                request = urllib.request.Request(url, headers={'User-Agent': 'WhatToBuy-one-off-research/0.1'})
                with urllib.request.urlopen(request, timeout=25) as response:
                    body = response.read().decode('utf-8')
                    actual_url = response.url
                result = parse(body)
                result.update(sourceUrl=actual_url, retrievedAtUtc=datetime.now(timezone.utc).isoformat(),
                              sha256=hashlib.sha256(body.encode()).hexdigest())
                path.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
                time.sleep(1)
            print(spec_id, result['title'], result['updated'], len(result['items']))
        except Exception as exc:
            missing.append(spec_id)
            print(spec_id, type(exc).__name__, str(exc))
    print('Missing:', missing)
    if missing:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
