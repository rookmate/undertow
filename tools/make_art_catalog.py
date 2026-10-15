#!/usr/bin/env python3
"""Build Godot crop metadata from original painted sheets; never alter source pixels.

Requires Pillow. Alpha above 32 identifies painted silhouettes while excluding nearly
transparent antialias fringes. Overrides handle objects extending beyond grid cells.
"""
import json
import re
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'assets/art/complete'
SPECS = json.loads((ART / 'specs.json').read_text())
# Reviewed search boxes isolate objects that cross the nominal grid.
SEARCH_BOXES = {'low_wall': [57, 58, 376, 332],
 'shelf': [584, 0, 259, 413],
 'kiosk': [1036, 0, 362, 419],
 'bollard': [137, 417, 217, 307],
 'sprinkler': [625, 489, 202, 199],
 'bed': [1024, 412, 376, 313],
 'desk': [34, 738, 403, 343],
 'tram_side': [489, 761, 469, 287],
 'tram_roof': [963, 770, 485, 270],
 'container': [42, 103, 310, 327],
 'turbine_mast': [506, 13, 201, 424],
 'turbine_blades': [819, 14, 410, 415],
 'rack': [100, 462, 195, 429],
 'pane': [510, 446, 221, 465],
 'crane_leg': [911, 433, 260, 475],
 'crane_load': [68, 944, 267, 289],
 'crane_jib': [391, 1043, 481, 109],
 'gantry_frame': [921, 938, 239, 320],
 'route_light': [141, 7, 139, 379],
 'tide_gauge': [468, 11, 118, 384],
 'news_desk': [731, 15, 352, 379],
 'paper_slip': [1168, 139, 247, 178],
 'laundry': [7, 431, 400, 260],
 'rose': [409, 395, 321, 309],
 'shutter': [750, 409, 342, 291],
 'bridge_rebar': [1107, 417, 341, 298],
 'council': [23, 788, 436, 253],
 'ladder': [552, 700, 137, 385],
 'lantern_housing': [867, 725, 154, 332],
 'valve_wheel': [1139, 740, 296, 289],
 'lantern': [192, 0, 163, 386],
 'piling': [634, 98, 172, 286],
 'boat': [1034, 89, 368, 296],
 'dock': [65, 412, 393, 289],
 'crate': [578, 449, 295, 249],
 'reliquary': [1012, 424, 386, 283],
 'hatch': [74, 721, 382, 350],
 'crank': [627, 716, 274, 360],
 'rebar': [1019, 744, 381, 331],
 'signal_box': [95, 20, 263, 372],
 'hoist_brake': [463, 66, 371, 294],
 'theatre_switch': [949, 8, 222, 398],
 'hand_valve': [123, 398, 235, 424],
 'relay_mast': [549, 342, 159, 465],
 'bale_stack': [838, 475, 395, 305],
 'barrier': [9, 856, 431, 289],
 'smart_gate': [486, 808, 292, 412],
 'tool_door': [901, 798, 276, 427],
 'conductor': [0, 0, 569, 507],
 'crane_tower': [628, 0, 302, 511],
 'surgeon_table': [1040, 77, 490, 420],
 'lung': [22, 514, 521, 478],
 'editor': [564, 515, 527, 483],
 'warden_prime': [1090, 503, 431, 499],
 'conductor_housing': [25, 0, 435, 410],
 'crane_cab': [530, 0, 385, 415],
 'surgeon_hub': [963, 29, 392, 370],
 'arm_link': [14, 539, 447, 120],
 'surgeon_lamp': [515, 410, 391, 352],
 'lung_bellows': [1045, 417, 261, 332],
 'press_roller': [16, 866, 455, 171],
 'paper_web': [494, 861, 440, 172],
 'warden_mast': [1088, 739, 230, 403],
 'operator_downed': [1127, 739, 398, 169],
 'partition': [67, 17, 281, 367],
 'ambulance_side': [432, 39, 398, 317],
 'ambulance_roof': [897, 23, 312, 374],
 'nurse_desk': [31, 450, 375, 325],
 'hospital_bed': [456, 431, 357, 350],
 'ward_seal': [874, 434, 344, 356],
 'crash_cart': [88, 823, 250, 397],
 'pipe': [589, 807, 120, 418],
 'louvre': [884, 892, 315, 250],
 'baton': [21, 204, 483, 220],
 'drone': [529, 63, 478, 349],
 'gauntlet': [1033, 95, 480, 306],
 'jammer': [98, 461, 310, 513],
 'power_core': [636, 495, 246, 458],
 'truth_core': [1085, 556, 372, 367]}

ANCHORS = {'noor': {'lantern': [217, 347]},
 'kiosk': {'screen_tl': [1212, 215], 'screen_tr': [1271, 203], 'screen_bl': [1212, 293]},
 'desk': {'screen_tl': [175, 777], 'screen_tr': [269, 760], 'screen_bl': [181, 837]},
 'news_desk': {'screen_tl': [884, 119], 'screen_tr': [934, 136], 'screen_bl': [874, 174]},
 'teo': {'tablet': [815, 196], 'glasses': [787, 97]},
 'survivor': {'ear': [1218, 81], 'hand': [1288, 300]},
 'wardfolk': {'lantern': [394, 645]},
 'noor_seated': {'lantern': [895, 818]},
 'noor_downed': {'lantern': [1475, 817]},
 'operator_front_idle': {'ear': [229, 156]},
 'operator_front_step1': {'ear': [616, 145]},
 'operator_front_step2': {'ear': [998, 145]},
 'operator_back_idle': {'ear': [1410, 145]},
 'operator_back_step1': {'ear': [239, 634]},
 'operator_back_step2': {'ear': [619, 638]},
 'operator_dodge': {'ear': [1004, 723]},
 'operator_downed': {'ear': [1429, 816]},
 'carry_front_idle': {'ear': [369, 155], 'lantern': [417, 384]},
 'carry_front_step': {'ear': [985, 155], 'lantern': [1040, 383]},
 'carry_back_idle': {'ear': [413, 726], 'lantern': [208, 979]},
 'carry_back_step': {'ear': [1026, 727], 'lantern': [824, 979]},
 'custodian_front': {'lamp': [327, 116]},
 'custodian_back': {'lamp': [271, 146]},
 'clerk_front': {'screen': [787, 134]},
 'clerk_back': {'screen': [748, 156]},
 'lamplighter_front': {'lens': [1270, 81]},
 'lamplighter_back': {'lens': [1273, 80]},
 'warden_front': {'eye': [1356, 578], 'baton': [1101, 515]},
 'warden_back': {'eye': [1298, 575], 'baton': [1408, 548]},
 'surgeon_lamp': {'lens': [701, 655]},
 'conductor_housing': {'lens': [140, 272]},
 'conductor': {'signal_left': [155, 129], 'signal_middle': [291, 121], 'signal_right': [427, 125]},
 'warden_mast': {'lens': [1179, 808]},
 'route_light': {'lens': [191, 87]},
 'lantern_housing': {'lens': [939, 917]},
 'editor': {'screen_tl': [898, 579],
            'screen_tr': [964, 636],
            'screen_br': [942, 692],
            'screen_bl': [870, 634]}}

def build():
    entries = {}
    for sheet in SPECS['sheets']:
        path = ART / (sheet['name'] + '.png')
        im = Image.open(path)
        width, height = im.size
        for i, key in enumerate(sheet['keys']):
            col, row = i % sheet['cols'], i // sheet['cols']
            box = (round(col * width / sheet['cols']), round(row * height / sheet['rows']),
                   round((col + 1) * width / sheet['cols']), round((row + 1) * height / sheet['rows']))
            if sheet['transparent']:
                search_box = sheet.get('search_boxes', {}).get(key, SEARCH_BOXES.get(key))
                if search_box and len(sheet["keys"]) > 1:
                    x, y, w, h = search_box
                    box = (x, y, min(width, x + w), min(height, y + h))
                alpha = im.getchannel('A').crop(box)
                tight = alpha.point(lambda a: 255 if a > 32 else 0).getbbox()
                if tight is None:
                    raise ValueError('Empty painted frame: ' + key)
                x0, y0, x1, y1 = tight
                region = [box[0] + max(0, x0 - 2), box[1] + max(0, y0 - 2),
                          min(box[2] - box[0], x1 + 2) - max(0, x0 - 2),
                          min(box[3] - box[1], y1 + 2) - max(0, y0 - 2)]
            else:
                # One-pixel inset prevents neighbouring atlas cells bleeding into materials.
                inset = 6 if sheet["name"].startswith("materials_") or sheet["name"] == "ground_details" else 1
                region = [box[0] + inset, box[1] + inset, box[2] - box[0] - inset * 2, box[3] - box[1] - inset * 2]
            entries[key] = {'path': 'res://' + path.relative_to(ROOT).as_posix(), 'region': region}
            anchors = sheet.get('anchors', {}).get(key, ANCHORS.get(key))
            if anchors:
                entries[key]['anchors'] = anchors
        # Articulated parts can reuse reviewed subregions of a sheet without rewriting its pixels.
        for key, entry in sheet.get('subframes', {}).items():
            entries[key] = {'path': 'res://' + path.relative_to(ROOT).as_posix(), **entry}
    for key, filename in {'kestrel_lawn': 'lawn', 'kestrel_cobble': 'wet_stone', 'kestrel_paving': 'paving', 'kestrel_wall': 'limestone_wall', 'kestrel_roof': 'slate_roof'}.items():
        im = Image.open(ROOT / 'assets/art/kestrel' / (filename + '.png'))
        entries[key] = {'path': 'res://assets/art/kestrel/' + filename + '.png', 'region': [0, 0, *im.size]}
    for key, filename, region in [
        ('kestrel_hedge', 'hedge', [121, 187, 1115, 829]),
        ('kestrel_planter', 'planter', [253, 224, 626, 934]),
        ('kestrel_railing', 'balcony', [40, 218, 582, 447]),
        ('kestrel_window', 'window_ornament', [56, 20, 1044, 1200]),
        ('kestrel_door', 'door_ornament', [23, 7, 1055, 1199]),
        ('kestrel_balcony', 'balcony', [31, 160, 1200, 665]),
        ('kestrel_lamp', 'lamp_housing', [308, 130, 619, 1180]),
    ]:
        resource = ROOT / 'assets/art/kestrel' / (filename + '.tres')
        if resource.exists() and key != 'kestrel_railing':
            match = re.search(r'region = Rect2\(([^)]+)\)', resource.read_text())
            region = [int(v.strip()) for v in match.group(1).split(',')]
        entries[key] = {'path': 'res://assets/art/kestrel/' + filename + '.png', 'region': region}
    (ART / 'catalog.json').write_text(json.dumps(entries, indent=2) + '\n')
    print(f'{len(entries)} painted frames from {len(SPECS["sheets"])} new sheets and Kestrel originals')

if __name__ == '__main__':
    build()
