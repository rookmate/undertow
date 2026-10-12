#!/usr/bin/env python3
"""Draws data/levels/the_spire.txt's grid (the header with the legend, ids and hints is kept by hand).
    python3 -I tools/maps/spire_gen.py   # prints the grid rows

The Spire, the Core: the Steward's own house, all of it on the Lattice. Black glass, cold blue-white
light, and nothing that attacks you. From the landing off the skiff, up through the atrium's panes, into
the cooling halls (rows of racks, coolant channels) and the core room at the top, where the last
Reliquary is. At set places along the way the Steward says what it did ('c'). Off the path, behind the
last row of racks, a maintenance crawl (grating, never indexed) and a technician's note.

This map's own characters (declared in its '%' legend lines):
    a  black glass floor (on the Lattice)    r  a server rack (tall)    e  a glass pane (you see past it)
    c  where the Steward says what it did    k  the maintenance crawl's grating (off the Lattice)
"""
W, H = 30, 36
g = [[' '] * W for _ in range(H)]


def put(x, y, ch):
    if 0 <= y < H and 0 <= x < W:
        g[y][x] = ch


def rect(x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(x, y, ch)


# The back walls: black glass, the ring burned into it (nothing walkable stands behind them).
rect(0, 0, W - 1, 0, '#')
rect(0, 0, 0, H - 1, '#')
# The core room at the top, the last Reliquary at its heart.
rect(1, 1, 10, 7, 'a')
put(5, 3, 'R')
for (x, y) in [(1, 1), (10, 1), (1, 7), (10, 7)]:
    put(x, y, 'L')
put(6, 6, 'c')
# Down from it into the cooling halls.
rect(4, 8, 7, 9, 'a')
rect(1, 10, 20, 21, 'a')
# Rows of racks with aisles between them; cross-aisles at x 6-7 and 13-14.
for y in (12, 15, 18):
    for x in list(range(2, 6)) + list(range(8, 13)) + list(range(15, 19)):
        put(x, y, 'r')
put(10, 13, 'c')
put(5, 10, 'c')
for (x, y) in [(1, 10), (20, 10), (1, 21), (20, 21)]:
    put(x, y, 'L')
# Coolant along the halls' front edge, west of the atrium.
rect(1, 21, 7, 21, '~')
put(1, 20, 'L')
# The maintenance crawl behind the last rack column (racked off from the aisles, its way in at the
# bottom): off the Lattice, the technician's note at its end.
for y in range(11, 18):
    put(18, y, 'r')
rect(19, 11, 20, 17, 'k')
put(19, 10, 'r')
put(20, 11, 'U')
# The atrium: wide, panes standing in it.
rect(8, 22, 28, 29, 'a')
for x in (11, 14, 17, 20, 23, 26):
    put(x, 24, 'e')
    put(x, 27, 'e')
put(18, 25, 'c')
for (x, y) in [(8, 22), (28, 22), (8, 29), (28, 29), (16, 26)]:
    put(x, y, 'L')
# The landing off the skiff.
rect(20, 30, 28, 34, 'a')
put(24, 33, 'P')
put(23, 30, 'c')
for (x, y) in [(20, 34), (28, 34)]:
    put(x, y, 'L')

for row in g:
    print(''.join(row))
