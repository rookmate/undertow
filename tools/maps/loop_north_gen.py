#!/usr/bin/env python3
"""Draws data/levels/loop_north.txt's grid (the header with the legend and ids is kept by hand).
    python3 -I tools/maps/loop_north_gen.py   # prints the grid rows
"""
W, H = 47, 37
g = [[' '] * W for _ in range(H)]
def put(x, y, ch):
    if 0 <= x < W and 0 <= y < H: g[y][x] = ch
def rect(x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1): put(x, y, ch)
# Platform A (the start): a stub of the elevated ring, fog all round.
rect(1, 14, 7, 19, ',')
put(3, 17, 'P')
for x in (2, 6): put(x, 14, '*'); put(x, 19, '*')
put(1, 16, 'L')
# Train 1: carriages from the platform out over the drop, the driver's cab at the front.
rect(8, 15, 26, 19, 'r')
rect(8, 16, 23, 18, 'h')
rect(24, 16, 25, 18, 'x')            # the cab: the Lattice was never let in
put(25, 16, 'J')                     # the welded control desk
put(24, 18, 'T')
put(12, 18, 'W'); put(17, 18, 'W')   # the Waiting, in their seats along the window
put(15, 16, 'c')
put(10, 17, 'C')
# Side door, and a maintenance gantry north over the gap.
put(20, 15, 'h'); put(21, 15, 'h')
rect(20, 11, 21, 14, 'u')
# Platform B: Custodians, a checkpoint, the Lattice's lamps.
rect(14, 7, 28, 10, ',')
put(16, 9, 'C')
put(18, 8, 'c'); put(25, 9, 'c')
for x in (15, 22, 27): put(x, 7, 'L')
for x in (17, 24, 27): put(x, 10, '*')
# Train 2: the Waiting in rows, then out of its front onto the gantry to the junction.
rect(29, 7, 40, 11, 'r')
rect(29, 8, 40, 10, 'h')
put(32, 10, 'W'); put(36, 10, 'W')
put(34, 9, 'c')
put(38, 8, 'C')                     # last checkpoint before the junction
rect(39, 4, 40, 7, 'u'); put(39, 7, 'h'); put(40, 7, 'h')
# The north junction: three lanes, the Conductor at their east end, the signal box in a nook, the
# buffer stops before the junction station and its Reliquary.
rect(28, 2, 42, 2, '1'); rect(28, 3, 42, 3, '2'); rect(28, 4, 42, 4, '3')
rect(39, 4, 40, 4, '3')
put(43, 3, 'B'); put(43, 2, 'r'); put(43, 4, 'r')
put(34, 5, 'Z')
# Platform B's points lever (the hold) and the service hatch beside it, interlocked with the points; the
# Steward's Custodians come off the platform's ends to stop you.
put(23, 8, 'n')
put(14, 10, 's'); put(28, 7, 's')
put(26, 9, 'l')
# The service tunnels inside the viaduct (a descent, off the Lattice): the landing under the hatch, a
# tunnel east, a drop south, the crew's gallery, and the end room where they left their log.
rect(9, 25, 14, 28, 'v'); put(10, 26, 'l')
rect(15, 26, 29, 27, 'v')
rect(22, 28, 23, 31, 'v')
rect(16, 32, 29, 35, 'v')
rect(30, 29, 36, 35, 'v')
put(19, 34, 'c'); put(27, 33, 'c')
put(17, 34, 'w')
put(35, 30, 'T')
rect(27, 2, 27, 4, 'y')
rect(23, 1, 26, 5, ',')
put(24, 3, 'R')
put(25, 1, 'L'); put(25, 5, 'L')
put(26, 3, 'C')
for row in g: print(''.join(row).rstrip())
