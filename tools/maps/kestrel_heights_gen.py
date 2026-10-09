#!/usr/bin/env python3
"""Draws data/levels/kestrel_heights.txt's grid (the header with the legend and ids is kept by hand).
    python3 -I tools/maps/kestrel_heights_gen.py   # prints the grid rows
"""
W, H = 36, 30
g = [[' '] * W for _ in range(H)]
def put(x, y, ch):
    if 0 <= x < W and 0 <= y < H: g[y][x] = ch
def rect(x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1): put(x, y, ch)
# Back edges: terrace houses (pale stone), laundry balconies, doors.
rect(0, 0, W - 5, 1, '#'); rect(0, 0, 1, H - 3, '#')
for x in range(3, W - 5, 4): put(x, 1, 'l')
for x in (7, 15, 23): put(x, 1, 'd')
for y in (6, 20, 25): put(1, y, 'l')
put(1, 9, 'd')
# Terrace 3 (top): lawns, the walkway, the civic garden with the Reliquary.
rect(2, 2, W - 6, 9, 'v')
rect(4, 5, 30, 6, '.')
rect(24, 2, 30, 4, ',')             # the little civic garden
put(28, 3, 'R')
for x in (24, 30): put(x, 2, 'F')
for x in range(6, 24, 4): put(x, 4, 'H'); put(x + 1, 4, 'H')
for x in range(5, 30, 5): put(x, 7, 'L')
put(18, 4, 'W')                    # the gardener, still pruning
rect(17, 3, 19, 3, 'H')
put(12, 5, 'c'); put(22, 6, 'X')
put(26, 5, 'C')
for x in (9, 15, 21): put(x, 8, 'j')
rect(10, 7, 11, 9, '.')             # from the top steps up to the walk
put(9, 7, 'L')
# Retaining wall, steps up to the top terrace.
rect(2, 10, W - 6, 10, '-'); rect(10, 10, 11, 10, 'E')
# Terrace 2: lawns, the walkway west, and beyond a hedge at its far end, the child's room.
rect(2, 11, W - 6, 17, 'v')
rect(9, 14, 30, 15, '.')
rect(10, 11, 11, 13, '.')           # up to the steps
rect(28, 16, 29, 17, '.')           # down to the lower steps
put(28, 16, 'Q'); put(29, 16, 'Q')  # the smart gate: open while it listens
for x in range(13, 28, 4): put(x, 13, 'H'); put(x, 16, 'H'); put(x + 1, 16, 'H')
for x in range(12, 28, 5): put(x, 16, 'L')
put(18, 13, 'L')
put(16, 14, 'X'); put(24, 15, 'X')
put(20, 15, 'C')
for x in (15, 23): put(x, 12, 'j')
rect(8, 14, 8, 15, 'H'); put(8, 15, 'q')   # the hedge gap
rect(4, 14, 7, 15, 'q')                     # a garden walk the Lattice never lit
rect(2, 11, 6, 12, 'i')                     # the child's room, its front open
rect(7, 11, 7, 12, '-'); rect(2, 13, 7, 13, '-'); put(5, 13, 'q')
put(3, 11, 'T')
put(5, 11, 'b')                    # her bed, the nightlight still on
# Retaining wall, steps at the east end.
rect(2, 18, W - 6, 18, '-'); rect(28, 18, 29, 18, 'E')
# Terrace 1 (bottom): the funicular stop, the promenade east, the sea beyond the railing.
rect(2, 19, W - 6, 27, 'v')
rect(5, 22, 31, 24, '.')
rect(28, 19, 29, 21, '.')
rect(5, 21, 8, 25, ',')             # the funicular stop
put(6, 23, 'P')
for x in range(10, 30, 4): put(x, 21, 'H'); put(x + 1, 21, 'H')
for x in range(9, 32, 5): put(x, 25, 'L')
put(11, 21, 'L'); put(19, 21, 'L')
for x in (14, 18): put(x, 22, 'F')
put(17, 23, 'c'); put(26, 23, 'c')
put(24, 22, 'C')
rect(2, 26, W - 6, 27, 'v')
for x in (12, 20, 27): put(x, 26, 'j')
rect(2, 28, W - 5, 28, '=')
rect(W - 5, 2, W - 5, 28, '=')
for row in g: print(''.join(row).rstrip())
