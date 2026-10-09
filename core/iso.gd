class_name Iso
extends RefCounted
## Isometric grid maths. Cell (x, y) covers grid square [x, x+1] × [y, y+1]; grid point (gx, gy) is drawn
## at screen ((gx - gy) · W/2, (gx + gy) · H/2). +x runs down-right on screen, +y runs down-left.
## Tile size 128×72 (Tunables): a ground square seen from about 56° off vertical.

const W := float(Tunables.TILE_W)
const H := float(Tunables.TILE_H)
const HALF_W := W * 0.5
const HALF_H := H * 0.5
## Vertical squash of the ground plane on screen (H / W).
const SQUASH := H / W


static func grid_to_world(g: Vector2) -> Vector2:
	return Vector2((g.x - g.y) * HALF_W, (g.x + g.y) * HALF_H)


static func world_to_grid(p: Vector2) -> Vector2:
	return Vector2((p.x / HALF_W + p.y / HALF_H) * 0.5, (p.y / HALF_H - p.x / HALF_W) * 0.5)


## Screen position of a cell's centre.
static func cell_center(cell: Vector2i) -> Vector2:
	return grid_to_world(Vector2(cell.x + 0.5, cell.y + 0.5))


static func world_to_cell(p: Vector2) -> Vector2i:
	var g := world_to_grid(p)
	return Vector2i(floori(g.x), floori(g.y))


## The four screen-space corners of a cell: top, right, bottom, left.
static func cell_diamond(cell: Vector2i) -> PackedVector2Array:
	return PackedVector2Array([
		grid_to_world(Vector2(cell.x, cell.y)),
		grid_to_world(Vector2(cell.x + 1, cell.y)),
		grid_to_world(Vector2(cell.x + 1, cell.y + 1)),
		grid_to_world(Vector2(cell.x, cell.y + 1)),
	])


## Distance across the ground, in tiles, between two screen positions.
static func ground_distance(a: Vector2, b: Vector2) -> float:
	return world_to_grid(a).distance_to(world_to_grid(b))


## Ground direction (grid space) for a stick or WASD input. The input square maps onto the ground
## diamond, as in Bastion: up-right walks along the street (grid -y), right walks across the screen.
## Magnitude is kept (analog sticks), capped at 1.
static func input_to_ground(input: Vector2) -> Vector2:
	if input.length_squared() < 0.0001:
		return Vector2.ZERO
	var strength := minf(input.length(), 1.0)
	var ground := Vector2(input.x + input.y, input.y - input.x)
	return ground.normalized() * strength


## Screen velocity for moving across the ground at `tiles_per_second` in grid direction `ground`.
static func ground_velocity(ground: Vector2, tiles_per_second: float) -> Vector2:
	return grid_to_world(ground * tiles_per_second)


## Screen-space input straight to a screen velocity (see input_to_ground).
static func input_to_velocity(input: Vector2, tiles_per_second: float) -> Vector2:
	return ground_velocity(input_to_ground(input), tiles_per_second)


## Ground direction (unit, grid space) from one screen position toward another: aiming at the mouse.
static func ground_dir_between(from: Vector2, to: Vector2) -> Vector2:
	var d := world_to_grid(to) - world_to_grid(from)
	return d.normalized() if d.length_squared() > 0.000001 else Vector2.ZERO


## Unit screen vector pointing along the ground from `from` to `to` (for facing and aim).
static func screen_dir_between(from: Vector2, to: Vector2) -> Vector2:
	var d := to - from
	return d.normalized() if d.length_squared() > 0.0001 else Vector2.ZERO
