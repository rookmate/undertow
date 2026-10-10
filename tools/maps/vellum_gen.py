#!/usr/bin/env python3
"""Draws data/levels/vellum_street.txt's grid (the header with the legend, ids and hints is kept by hand).
    python3 -I tools/maps/vellum_gen.py   # prints the grid rows

The slice's street, plaza and stacks are drawn by hand (SLICE, unchanged, so every coordinate the game
and its tests know stays put); Act 2 adds the east bank across the canal: a footbridge from the plaza,
the newsroom where the Feed was written, the press hall where the Editor prints and pulps the same page,
the Reliquary beyond it, and down the newsroom's stair, the deep stacks and Prem Vashti's office.

The Vellum's own characters (declared in the map's '%' legend lines):
    n  the newsroom's floor (on the Lattice)       D  a newsroom desk, its screen dead
"""
SLICE = [
    '#################',
    '#################',
    '#################',
    '####d###g###m####',
    '#,,,,,,,,,,,,,,,=~~~~~~~',
    '#,L...L....L...,=~~~~~~~',
    '#,.............,=~~~~~~~',
    '#,.............,=~~~~~~~',
    '#,.R...........,=~~~~~~~',
    '#,.....k.......,=~~~~~~~',
    '#,L............,=~~~~~~~',
    '#,.............,=~~~~~~~',
    '#========......L=~~~~~~~',
    ' ~~~~~~~=,.....,=~~~~~~~',
    ' ~~~~~~~=L.....,=~~~~~~~',
    ' ~~~~~~~=,.....,=~~~~~~~',
    '      ###,.....L=~~~~~~~',
    '      ###,...K.,=~~~~~~~',
    '      ###L.....,=~~~~~~~',
    '      ##m,.....,=~~~~~~~',
    '      ###,..c..L=~~~~~~~',
    '      ###,.....,=~~~~~~~',
    '      ###L.....,=:~~~~~~',
    '      ###,.....,=:___~~~',
    '      ###,..C..,=:__T~~~',
    '      ##dW.....,S:_|_~~~',
    '      ###,c....,S:_|_~~~',
    '      ###,.....,=:U__~~~',
    '      ###,.tt..L=:___~~~',
    '      ###,.tt..,=:_|_~~~',
    '      ###L.tt..,=:_|_~~~',
    '      ##g,.tt..,=:w__~~~',
    '      ###,.....L=:__|~~~',
    '      ###,.....,=:___~~~',
    '      ###L.....,=:~~~~~~',
    '      ###,...c.,=~~~~~~~',
    '      ##m,.....L=~~~~~~~',
    '      ###,.....,=~~~~~~~',
    '      ###L.....,=~~~~~~~',
    '      ###,..P..,=~~~~~~~',
    '      ###,.....,=~~~~~~~',
    '      ###--------~~~~~~~',
]
W = 45
g = [list(r.ljust(W)) for r in SLICE]


def put(x, y, ch):
    if 0 <= y < len(g) and 0 <= x < W:
        g[y][x] = ch


def rect(x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(x, y, ch)


# The plaza's Reliquary moves east, past the press hall (its cell is plaza cobble now).
put(3, 8, '.')
# Back edges across the canal and the east bank: the newspaper's old building, neon on the corner.
rect(17, 0, 44, 3, '#')
put(30, 3, 'm'); put(40, 3, 'g'); put(26, 3, 'd')
# The river beyond the east bank.
rect(24, 21, 44, len(g) - 1, '~')
# The footbridge from the plaza over the canal.
rect(16, 6, 24, 7, ',')
# The east bank's edge on the canal.
rect(24, 4, 24, 5, '=')
rect(24, 8, 24, 20, '=')
# The newsroom: desks in rows, their screens dead, the ring burned into each.
rect(25, 4, 34, 13, 'n')
for y in (5, 7, 10, 12):
    for x in range(26, 34, 2):
        put(x, y, 'D')
put(29, 9, 'k'); put(33, 6, 'k')
put(25, 8, 'L'); put(34, 4, 'L')
put(28, 13, 'C')
# The wall between the newsroom and the press hall, its door.
rect(35, 4, 35, 13, '-')
rect(35, 8, 35, 9, 'n')
# The press hall: the Editor at the back, the pulper by it with a bale stack over it; the barrier that
# opens when it falls, then the Reliquary.
rect(36, 4, 44, 13, '.')
put(44, 4, 'L'); put(36, 12, 'L')
put(40, 5, 'B'); put(37, 5, 'Z')
rect(35, 14, 44, 20, '.')
rect(35, 14, 35, 20, '-')
rect(36, 14, 44, 14, 'y')
put(40, 17, 'R'); put(38, 15, 'C'); put(44, 20, 'L')
# Down the newsroom's stair: the deep stacks, pitch dark, and Prem Vashti's office at the far end.
rect(25, 14, 34, 20, '_')
rect(25, 14, 34, 14, '-')
put(27, 14, 'S')
for x in (26, 29, 32):
    rect(x, 16, x, 18, '|')
put(33, 19, 'T')
put(30, 20, 'U')
put(27, 19, 'w')
rect(34, 15, 34, 20, '-')

for row in g:
    print(''.join(row).rstrip())
