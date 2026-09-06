import argparse
import json
import re
import time
import urllib.request

from collect_wowhead import ROOT


def main():
    parser = argparse.ArgumentParser(description='One-off item tooltip check; cached pages are reused.')
    parser.add_argument('--offline', action='store_true')
    args = parser.parse_args()
    snapshot = json.loads((ROOT / 'data' / 'wowhead.json').read_text(encoding='utf-8'))
    items = {}
    for spec in snapshot['specs'].values():
        for group in list(spec['enchants'].values()) + list(spec['consumables'].values()) + [spec['gems'], spec['epicGems']]:
            for item in group:
                items[item['id']] = item
    checks, missing = {}, []
    for item_id, item in sorted(items.items()):
        path = ROOT / '.cache' / 'wowhead' / f'item-{item_id}.html'
        try:
            if not path.exists():
                if args.offline:
                    raise ValueError('Not cached')
                request = urllib.request.Request(f'https://www.wowhead.com/item={item_id}',
                                                headers={'User-Agent': 'WhatToBuy-one-off-research/0.1'})
                with urllib.request.urlopen(request, timeout=25) as response:
                    body = response.read().decode('utf-8')
                path.write_text(body, encoding='utf-8')
                time.sleep(0.5)
            body = path.read_text(encoding='utf-8')
            match = re.search(r'g_items\[' + str(item_id) + r'\]\.tooltip_enus\s*=\s*', body)
            if not match:
                raise ValueError('Item tooltip missing')
            tooltip, _ = json.JSONDecoder().raw_decode(body[match.end():])
            forbidden = [term for term in ('Binds when picked up', 'Binds to Warband', 'Binds to account', 'Conjured Item') if term in tooltip]
            if forbidden:
                raise ValueError(', '.join(forbidden))
            metadata = {}
            for entry in re.finditer(r'WH\.Gatherer\.addData\(3,\s*1,\s*', body):
                metadata.update(json.JSONDecoder().raw_decode(body[entry.end():])[0])
            info = metadata[str(item_id)]
            if info['name_enus'] != item['name'] or info.get('qualityTier', 0) != item['rank']:
                raise ValueError('Guide name/rank differs from item page')
            checks[str(item_id)] = {'sourceUrl': f'https://www.wowhead.com/item={item_id}',
                                    'name': item['name'], 'rank': item['rank'],
                                    'bindingCheck': 'no auction-preventing binding in tooltip'}
            print(item_id, 'OK', flush=True)
        except Exception as exc:
            missing.append(item_id)
            print(item_id, str(exc), flush=True)
    print('Missing or non-auctionable:', missing)
    if missing:
        raise SystemExit(1)
    (ROOT / 'data' / 'wowhead_item_checks.json').write_text(json.dumps(checks, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
