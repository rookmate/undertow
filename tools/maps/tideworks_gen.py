#!/usr/bin/env python3
"""Draws data/levels/tideworks.txt's grid (the header with the legend and ids is kept by hand).
    python3 -I tools/maps/tideworks_gen.py   # prints the grid rows
"""
W, H = 45, 22
g = [[' '] * W for _ in range(H)]
def put(x, y, ch):
    if 0 <= x < W and 0 <= y < H: g[y][x] = ch
def rect(x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1): put(x, y, ch)
# Back edges: the old warehouses.
rect(0, 0, 34, 1, '#'); rect(0, 0, 1, 19, '#')
for x in (6, 14, 22, 30): put(x, 1, 'd')
# The side yard: the union hall (pre-Compact, its door open) and the Warden depot built to watch it.
rect(2, 2, 15, 8, ',')
rect(2, 2, 6, 6, 'i'); rect(7, 2, 7, 6, '-'); rect(2, 7, 7, 7, '-'); put(7, 4, ':'); put(5, 7, ':')
put(3, 3, 'T')
rect(9, 2, 13, 5, ':'); rect(14, 2, 14, 5, '-'); rect(9, 6, 14, 6, '-'); put(11, 6, ':')
put(11, 3, 'V')
put(8, 4, 'W')
rect(10, 7, 11, 8, ',')
# The quay: between the container stacks, under the gantries, containers hanging mid-lift overhead.
rect(2, 9, 30, 14, '.')
put(3, 12, 'P')
put(8, 11, 'C')
for x in range(13, 30, 2): put(x, 8, '[')
rect(2, 15, 30, 15, '[')
for x in (6, 17, 25): put(x, 15, '.')
put(18, 15, '^'); put(26, 15, '^'); put(18, 8, '^'); put(26, 8, '^')
put(15, 12, '['); put(16, 12, '['); put(22, 10, '['); put(22, 11, '[')
for x in (12, 20, 27): put(x, 11, ']')
for x in (5, 11, 24): put(x, 9, 'L')
for x in (9, 21, 29): put(x, 14, 'L')
put(14, 10, 'c'); put(19, 13, 'O'); put(26, 12, 'O')
put(24, 13, 'C')
rect(2, 17, 44, 21, '~'); rect(32, 6, 44, 16, '~'); rect(31, 9, 34, 14, '~')
rect(3, 16, 30, 16, '=')
# The pier, out over black water to the last crane.
rect(31, 10, 34, 13, ',')
rect(31, 9, 34, 9, '='); rect(31, 14, 34, 14, '=')
rect(35, 6, 43, 16, ',')
put(39, 11, 'B')
for p in [(36, 7), (42, 7), (36, 15), (42, 15)]: put(p[0], p[1], '^')
put(37, 8, 'Z')
rect(35, 17, 43, 17, '='); rect(44, 6, 44, 17, '=')
# Past the crane's buffer stops: the Tideworks Reliquary on the pier head.
rect(38, 5, 41, 5, 'y')
rect(37, 1, 42, 4, ',')
put(40, 2, 'R'); put(38, 3, 'C')
put(37, 1, 'L'); put(42, 4, 'L')
for row in g: print(''.join(row).rstrip())
