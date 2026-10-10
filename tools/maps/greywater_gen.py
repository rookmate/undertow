#!/usr/bin/env python3
"""Draws data/levels/greywater.txt's grid (the header with the legend, ids and hints is kept by hand).
    python3 -I tools/maps/greywater_gen.py   # prints the grid rows

Greywater's own characters (declared in the map's '%' legend lines):
    ,  the seawall's concrete (high ground, on the Lattice)
    .  a low street (on the Lattice; floods at high tide)
    k  kelp on a low street (slows you; floods too)
    m  the thick Marrow over a low street (on the Lattice, but the Steward can't see through it)
    :  iron grating (the old manual pump room: off the Lattice)
    #  a pumping station's wall     d  its door      ~  the sea, the channel
    t  a tidal turbine              g  a tide gauge (read the tide by hand)
"""
W, H = 44, 26
g = [[' '] * W for _ in range(H)]


def put(x, y, ch):
    if 0 <= x < W and 0 <= y < H:
        g[y][x] = ch


def rect(x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(x, y, ch)


# Back edges: the pumping stations along the top and the left.
rect(0, 0, 43, 1, '#')
rect(0, 0, 1, 25, '#')
for x in (7, 19, 27):
    put(x, 1, 'd')

# The seawall promenade along the bottom (the start), the sea beyond it.
rect(2, 20, 30, 22, ',')
rect(2, 23, 43, 25, '~')
put(4, 21, 'P')
for x in (8, 15, 22, 29):
    put(x, 22, 'L')
put(12, 21, 'c')

# The low streets between the seawall and the stations: they flood at high tide. Kelp in the lowest.
rect(2, 7, 30, 19, '.')
rect(6, 13, 12, 17, 'k')
rect(19, 9, 24, 12, 'k')
# The one way over high ground: the causeway north from the seawall to the station apron.
rect(16, 7, 17, 19, ',')
for (x, y) in [(16, 9), (17, 15)]:
    put(x, y, 'L')
# Tide gauges where the water comes up, for reading the tide by hand.
for (x, y) in [(5, 18), (14, 8), (27, 16)]:
    put(x, y, 'g')
put(9, 10, 'c'); put(23, 17, 'O')
# The thick Marrow over the east end of the low streets: the Steward can't see through it.
rect(25, 7, 30, 13, 'm')
put(28, 10, 'W')

# The station apron (high ground) under the pumping stations.
rect(2, 2, 30, 6, ',')
put(5, 5, 'C')
for (x, y) in [(3, 3), (15, 3), (24, 3)]:
    put(x, y, 'L')
# The Waiting: pump-station hands still at their posts.
put(18, 3, 'W'); put(26, 4, 'W')
# The old manual pump room (off the Lattice), behind a low wall: the plaque, the shift roster.
rect(8, 2, 13, 3, ':')
rect(8, 4, 13, 4, '-')
put(11, 4, ':')
put(12, 2, 'T')
put(9, 2, 'w')

# The channel, its tidal turbines; the bridge to the east island; the Reliquary at its far end.
rect(31, 2, 33, 22, '~')
for y in (9, 14, 19):
    put(32, y, 't')
rect(31, 4, 33, 6, ',')
rect(34, 2, 42, 20, ',')
put(38, 11, 'C')
put(40, 17, 'R')
for (x, y) in [(34, 2), (42, 2), (34, 20), (42, 20)]:
    put(x, y, 'L')

for row in g:
    print(''.join(row).rstrip())
