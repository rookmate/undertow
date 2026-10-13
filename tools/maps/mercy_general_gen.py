#!/usr/bin/env python3
"""Draws data/levels/mercy_general.txt's grid (the header with the legend, ids and hints is kept by hand).
    python3 -I tools/maps/mercy_general_gen.py   # prints the grid rows

Mercy General's own characters (declared in the map's '%' legend lines):
    .  hospital tile (corridors, wards, the theatre; on the Lattice)
    ,  the ambulance yard's asphalt (on the Lattice)
    :  staff floor (the night nurses' station: off the Lattice)
    =  a glass partition (cut away to waist height so the wards can be seen into)
    s  a sealed ward door        a  an ambulance        j  the night nurses' desk
    x  a Sterilizer      #  the hospital's walls   d  a locked door   b  a ward bed
    n  the emergency generator's crank (a hold)    h  where the Steward's machines come out
    l  a ladder (the morgue lift's shaft, and back up)    u  the morgue (a descent, off the Lattice)
"""
W, H = 42, 41
g = [[' '] * W for _ in range(H)]


def put(x, y, ch):
    if 0 <= x < W and 0 <= y < H:
        g[y][x] = ch


def rect(x0, y0, x1, y1, ch):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            put(x, y, ch)


# Back edges: the hospital's outer walls, doors to wings that stay locked.
rect(0, 0, 40, 1, '#')
rect(0, 0, 1, 26, '#')
for x in (9, 17, 25):
    put(x, 1, 'd')
for y in (8, 15):
    put(1, y, 'd')

# The ambulance yard (start): asphalt, ambulances parked nose to tail, the Lattice lamps.
rect(2, 19, 16, 26, ',')
put(5, 24, 'P')
for x in (9, 10, 11):
    put(x, 21, 'a')
for x in (12, 13, 14):
    put(x, 24, 'a')
put(3, 20, 'L'); put(15, 20, 'L'); put(8, 26, 'L')
put(13, 22, 'c')

# The main corridor north from the yard: three tiles wide, every third light working.
rect(6, 4, 8, 18, '.')
put(7, 12, 'C')
for y in (6, 17):
    put(5, y, 'L')
# The resus bay off the corridor's west side, open to it: the Defib Gauntlet on its trolley.
rect(2, 10, 5, 14, '.')
put(3, 12, 'V')
rect(2, 9, 5, 9, '=')
rect(2, 15, 5, 15, '=')
put(5, 13, '.')

# The wards east of the corridor behind glass, each sealed at the Quiet: beds, and the Waiting in them.
rect(9, 7, 21, 17, '=')
rect(10, 8, 20, 11, '.')          # ward A
rect(10, 13, 20, 16, '.')         # ward B
rect(10, 12, 20, 12, '=')
put(9, 9, 's')                    # ward A's door
put(9, 14, 's')                   # ward B's door
for x in (11, 13, 15, 17, 19):
    put(x, 8, 'b')
    put(x, 16, 'b')
put(13, 9, 'W'); put(17, 9, 'W'); put(15, 15, 'W')
put(12, 10, 'x'); put(18, 14, 'x')
# Ward B's far door to the night nurses' station (off the Lattice: they kept paper).
put(21, 15, 's')
rect(22, 13, 27, 17, ':')
rect(22, 12, 28, 12, '=')
rect(28, 13, 28, 17, '=')
rect(22, 18, 28, 18, '=')
put(25, 14, 'j')
put(24, 15, 'T')
put(26, 16, 'w')

# The upper corridor east to the surgical theatre.
rect(9, 2, 29, 6, '.')
rect(9, 2, 29, 2, '=')
put(14, 5, 'x'); put(22, 4, 'c')
put(18, 3, 'L'); put(27, 3, 'L')

# The surgical theatre: the Surgeon at its table, the lamp's switch panel by the door.
rect(30, 2, 40, 12, '.')
put(35, 7, 'B')
put(31, 9, 'Z')
for p in [(30, 2), (40, 2)]:
    put(p[0], p[1], 'L')
rect(30, 13, 40, 13, '=')
# Past the barrier (it opens when the Surgeon falls): the records vault, the Mercy Reliquary.
rect(34, 13, 36, 13, 'y')
rect(31, 14, 39, 19, '.')
put(35, 17, 'R'); put(32, 15, 'C')
put(31, 19, 'L'); put(39, 14, 'L')
rect(30, 14, 30, 20, '=')
rect(40, 14, 40, 20, '=')
rect(30, 20, 40, 20, '=')

# The checkpoint at the boss arena's door, your side of its barrier: a boss fight you die in starts
# over from here (DECISIONS 177).
put(26, 5, 'C')

# The ambulance yard's emergency generator (the hold): crank it by hand and the morgue lift runs, while
# the Steward's Custodians come out of the yard's corners to stop you.
put(12, 20, 'n')
put(16, 19, 'h'); put(2, 25, 'h')
put(9, 25, 'l')
# The morgue under the hospital (a descent, off the Lattice): the lift's landing, the corridor, the
# ramp down to the cold hall, the drawer room off it and the attendant's office at its end.
rect(3, 29, 8, 32, 'u'); put(4, 30, 'l')
rect(9, 30, 24, 31, 'u')
rect(18, 32, 19, 35, 'u')
rect(10, 36, 24, 40, 'u')
rect(5, 37, 9, 39, 'u')
rect(25, 33, 31, 40, 'u')
put(13, 38, 'c'); put(21, 37, 'c')
put(6, 38, 'w')
put(30, 34, 'T')

for row in g:
    print(''.join(row).rstrip())
