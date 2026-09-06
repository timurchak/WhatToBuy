import html
import json
import re
from pathlib import Path

from collect_wowhead import ROOT, SPECS


SLOTS = {
    'Weapon': 'Main-Hand', 'Both Weapons': 'Main-Hand', 'Weapons (2h & Dual-Wield)': 'Main-Hand',
    'Weapon - Main Hand': 'Main-Hand', 'Main Hand': 'Main-Hand',
    'Weapon - Off Hand': 'Off-Hand', 'Off Hand': 'Off-Hand',
    'Head': 'Head', 'Helm': 'Head', 'Helmet': 'Head', 'Shoulder': 'Shoulders',
    'Shoulders': 'Shoulders', 'Chest': 'Chest', 'Legs': 'Legs',
    'Boots': 'Feet', 'Feet': 'Feet', 'Ring': 'Rings', 'Rings': 'Rings',
    'Bracers': 'Wrist', 'Belt': 'Waist',
}
CONSUMABLES = {
    'Flask': 'Flask', 'Combat Potion': 'Combat Potion', 'Stats Potion': 'Combat Potion',
    'Mana Potion': 'Mana Potion', 'Health Potion': 'Health Potion',
    'Weapon Buff': 'Weapon Buff', 'Weapon Buffs': 'Weapon Buff', 'Weapon Oil': 'Weapon Buff',
    'Weapon Buff (Main hand)': 'Weapon Buff', 'Weapon Buff (Off hand)': 'Weapon Buff',
    'Augment Rune': 'Augment Rune', 'Food': 'Food Buff', 'Food - Feast': 'Food Buff',
    'Food - Personal': 'Food Buff', 'Group Feast': 'Food Buff', 'Personal Food': 'Food Buff',
    'Tea': 'Drink', 'Invisiblity Potion': 'Utility',
}
ADDITIONS = {
    62: {'gems': [240892, 240908, 240918]},
    63: {'gems': [240906, 240983], 'Combat Potion': [241288], 'Health Potion': [241304], 'Food Buff': [242274]},
    65: {'gems': [240892, 240908, 240918, 240983], 'Food Buff': [242747, 275265]},
    70: {'Combat Potion': [241308]},
    71: {'Food Buff': [255848]},
    72: {'Food Buff': [255848]},
    102: {'gems': [240892, 240908, 240918], 'Flask': [241320, 241324, 241326]},
    103: {'gems': [240891, 240908, 240918], 'Combat Potion': [241292, 241308], 'Health Potion': [241304], 'Food Buff': [242273, 242277]},
    105: {'Health Potion': [271884]},
    250: {'gems': [240908], 'Flask': [241320], 'Food Buff': [255846]},
    251: {'gems': [240890, 240898, 240914], 'Combat Potion': [241308], 'Food Buff': [266985, 242744]},
    254: {'Combat Potion': [241308, 271887]},
    255: {'gems': [240900]},
    256: {'Utility': [241303]},
    257: {'Utility': [241303], 'Food Buff': [242275]},
    258: {'Food Buff': [242275]},
    260: {'gems': [240898, 240906, 240910, 240916], 'Main-Hand': [243970], 'Food Buff': [242747]},
    261: {'gems': [240892, 240898, 240908], 'Main-Hand': [243971, 243973, 244001, 244029, 244031], 'Off-Hand': [243971, 243973, 244001, 244029, 244031], 'Flask': [245931], 'Combat Potion': [241292]},
    262: {'Main-Hand': [244031], 'Weapon Buff': [243733]},
    263: {'gems': [240967, 240983, 240900, 240892, 240908, 240918], 'Flask': [241324], 'Combat Potion': [241308]},
    264: {'Health Potion': [241304]},
    265: {'Flask': [241322]},
    266: {'Food Buff': [255845]},
    268: {'gems': [240898, 240910], 'Main-Hand': [244001], 'Flask': [241322, 241326], 'Combat Potion': [241292], 'Food Buff': [242274, 255847], 'Utility': [244639, 269586]},
    269: {'gems': [240900, 240906]},
    270: {'Main-Hand': [243973], 'Flask': [241326], 'Food Buff': [268679], 'Drink': [242298, 242299, 242301, 242297, 242300]},
    577: {'Flask': [241322], 'Food Buff': [266996]},
    581: {'gems': [240900, 240906, 240916], 'Main-Hand': [244029, 273072], 'Off-Hand': [244029, 273072], 'Combat Potion': [241288], 'Weapon Buff': [237369, 237371, 243738], 'Food Buff': [242272, 242274, 255845, 255848, 275258]},
    1467: {'gems': [240890, 240898, 240914, 240967], 'Flask': [241324], 'Combat Potion': [241308], 'Health Potion': [241304], 'Food Buff': [242274], 'Drink': [242299]},
    1468: {'Flask': [241324], 'Health Potion': [271884]},
    1473: {'Food Buff': [242747]},
    1480: {'Flask': [241324]},
}
REPLACEMENTS = {245933: 241322, 245931: 241324, 266996: 255846, 266985: 255845,
                242744: 242272, 242747: 242275, 268679: 255847}
EXCLUDED = {275707: 'binds-on-pickup socket item', 5512: 'conjured Healthstone'}


def clean(value):
    return html.unescape(re.sub(r'\[[^\]]*\]', '', value)).strip()


def main():
    cache = ROOT / '.cache' / 'wowhead'
    guides = {spec: json.loads((cache / f'{spec}.json').read_text(encoding='utf-8')) for spec in SPECS}
    metadata = {}
    for guide in guides.values():
        metadata.update(guide['items'])
    result = {'source': 'Wowhead', 'generatedAtUtc': max(g['retrievedAtUtc'] for g in guides.values()),
              'schemaVersion': 2, 'specs': {}}
    for spec_id, guide in sorted(guides.items()):
        target = {'sourceUrl': guide['sourceUrl'], 'guideUpdated': guide['updated'].replace('/', '-'),
                  'retrievedAtUtc': guide['retrievedAtUtc'], 'contentSha256': guide['sha256'],
                  'season': 'Midnight Season 2', 'enchants': {}, 'gems': [], 'epicGems': [],
                  'consumables': {}, 'excluded': [], 'replacements': []}
        assert 'Midnight Season 2' in guide['markup'], spec_id

        def add(group, item_id):
            if item_id in EXCLUDED:
                entry = {'id': item_id, 'reason': EXCLUDED[item_id]}
                if entry not in target['excluded']:
                    target['excluded'].append(entry)
                return
            if item_id in REPLACEMENTS:
                replacement = REPLACEMENTS[item_id]
                entry = {'guideItemId': item_id, 'shoppingItemId': replacement}
                if entry not in target['replacements']:
                    target['replacements'].append(entry)
                item_id = replacement
            info = metadata[str(item_id)]
            name = info['name_enus']
            item = {'id': item_id, 'name': name, 'rank': info.get('qualityTier', 0)}
            if group == 'gems':
                items = target['epicGems' if 'Diamond' in name else 'gems']
            elif group in SLOTS.values():
                items = target['enchants'].setdefault(group, [])
            else:
                items = target['consumables'].setdefault(group, [])
            if not any(existing['id'] == item_id for existing in items):
                items.append(item)

        for table in re.findall(r'\[table[^\]]*\](.*?)\[/table\]', guide['markup'], re.S):
            previous, remaining = None, 0
            for row in re.findall(r'\[tr[^\]]*\](.*?)\[/tr\]', table, re.S):
                cells = re.findall(r'\[td([^\]]*)\](.*?)\[/td\]', row, re.S)
                if not cells:
                    continue
                if remaining:
                    label = previous
                    remaining -= 1
                    content = ''.join(c[1] for c in cells)
                else:
                    label = clean(cells[0][1])
                    content = ''.join(c[1] for c in cells[1:])
                    span = re.search(r'rowspan=(\d+)', cells[0][0])
                    remaining = int(span[1]) - 1 if span else 0
                    previous = label
                ids = [int(i) for i in re.findall(r'\[item=(\d+)', content)]
                if not ids:
                    continue
                group = SLOTS.get(label) or CONSUMABLES.get(label)
                if group is None and ('Gem' in label or 'Diamond' in label):
                    group = 'gems'
                if group is None:
                    raise ValueError(f'{spec_id}: unknown row {label}')
                for item_id in ids:
                    add(group, item_id)
        for group, ids in ADDITIONS.get(spec_id, {}).items():
            for item_id in ids:
                assert f'[item={item_id}' in guide['markup'], (spec_id, item_id)
                add(group, item_id)
        if spec_id in (250, 251, 252):
            target['excluded'].append({'category': 'enchants/Main-Hand', 'reason': 'class runeforging spells'})
        if spec_id in (263, 264):
            target['excluded'].append({'category': 'consumables/Weapon Buff', 'reason': 'class weapon imbue spells'})
        assert target['enchants'] and target['gems'] and target['epicGems'] and target['consumables'], spec_id
        result['specs'][str(spec_id)] = target
    destination = ROOT / 'data' / 'wowhead.json'
    destination.parent.mkdir(exist_ok=True)
    destination.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'Prepared {len(result["specs"])} reviewed guides at {destination}')


if __name__ == '__main__':
    main()
