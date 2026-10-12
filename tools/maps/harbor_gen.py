#!/usr/bin/env python3
"""Draws data/levels/harbor_ward.txt's grid (the header with the legend, ids and hints is kept by hand).
    python3 -I tools/maps/harbor_gen.py   # prints the grid rows

Harbor Ward: the old fishing quarter that voted against the Compact and got nothing, hand-wired by its
own people. No Lattice at all inside it: only the city's ferry slip (one lamp) and the border plaza past
the fence. From the slip, the south boardwalk; three piers north to Net Lane; boat-houses along the
lane's north side with the water behind them, Noor's at the west end; the gate in the border fence at
the lane's east end; the border plaza (the Lattice again), the Warden depot behind it and the Harbor
Bridge's severed end beyond.

This map's own characters (declared in its '%' legend lines):
    s  the Ward's stone lanes    p  pier planks    h  a boat-house    o  a boat-house's door
    f  a piling                  n  a Wardfolk lantern                b  the bridge stub
    w  a Warden, posted (the curfew patrol)
"""
W, H = 46, 39
g = [['~'] * W for _ in range(H)]


def put(x, y, ch):
    if 0 <= y < H and 0 <= x < W:
        g[y][x] = ch


def rect(x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(x, y, ch)


# Noor's boat-house at the lane's west end, its door on the lane.
rect(0, 17, 3, 22, 'h')
put(3, 19, 'o')
# Net Lane, and the boat-houses along its north side, the water behind them.
rect(4, 18, 33, 21, 's')
for x0 in (5, 11, 17, 23, 29):
    rect(x0, 14, x0 + 4 if x0 < 29 else 32, 17, 'h')
for x in (8, 14, 20, 26, 32):
    put(x, 21, 'n')
# Three piers south to the boardwalk; pilings in the water beside them.
for x0 in (6, 17, 27):
    rect(x0, 22, x0 + 2, 30, 'p')
for (x, y) in [(5, 24), (5, 28), (9, 26), (16, 25), (20, 27), (26, 24), (30, 26), (12, 32), (24, 35)]:
    put(x, y, 'f')
for (x, y) in [(8, 25), (17, 29), (29, 23)]:
    put(x, y, 'n')
# The south boardwalk, and the city's ferry slip off it: the Ark's landing, one lamp, on the Lattice.
rect(4, 31, 33, 33, 'p')
rect(4, 34, 8, 37, '.')
put(4, 34, 'L')
put(6, 36, 'P')
# The border: the fence, its one gate at the lane's end, and the plaza beyond on the Lattice.
rect(34, 10, 34, 37, '-')
rect(34, 19, 34, 20, '.')
rect(35, 10, 45, 26, '.')
for (x, y) in [(35, 11), (45, 11), (35, 25), (45, 25), (38, 18), (43, 18)]:
    put(x, y, 'L')
# The Warden depot behind the plaza, and the bridge's severed end beyond it.
rect(35, 6, 45, 9, '#')
put(40, 9, 'd')
rect(37, 1, 43, 5, 'b')
# The depot's Reliquary; checkpoints on the lane and in the plaza.
put(40, 12, 'R')
put(16, 19, 'C')
put(37, 22, 'C')
# The curfew patrol: Wardens on the lane, by the gate, and on the middle pier.
for (x, y) in [(24, 20), (32, 19), (18, 26)]:
    put(x, y, 'w')
# Off the path, all of it: the dashcam at Noor's door, the Wardfolk's radio log by the gate.
put(4, 18, 'T')
put(31, 18, 'U')

for row in g:
    print(''.join(row).rstrip())
