class_name BossEncounter
extends Node
## A district's boss fight from start to finish (DECISIONS 177, 179, 190): the boss on its 'B' cell, its
## weak point on 'Z' and what its fight works (lanes, rollers, Wardens it calls: group "boss_parts"),
## its barriers ('y'), and starting the whole fight over when you go down in it. Whether the fight was
## lost is settled as you go down, not by what happens while you're down: from then nothing can hurt the
## boss (what you had in the air is gone with you), and when you're back on your feet, at the checkpoint
## by its arena's door, a fresh one stands where it was built.

var level: Level
## You went down in this fight: it starts over when you're back on your feet.
var lost: bool = false


func setup(owner_level: Level) -> void:
	level = owner_level


## Its barriers and the boss. On a revisit it stays beaten, and its barriers stay open.
func build() -> void:
	if level.revisit:
		return
	for c: Vector2i in level.grid.cells_with("y"):
		var barrier := BossBarrier.new()
		barrier.setup(c)
		level.world.add_child(barrier)
	_make_boss()


## You went down. If it was during the fight, the fight's lost: from now nothing can hurt the boss, and
## your shots still in the air are gone.
func player_went_down() -> void:
	var b := level.boss
	if b == null or not is_instance_valid(b) or not b.is_alive() or not b.is_engaged:
		return
	lost = true
	b.hold_off()
	for n: Node in level.world.get_children():
		if n is Projectile and (n as Projectile).team == Projectile.Team.PLAYER:
			n.queue_free()


## Back on your feet: a fight you lost starts over, and you're at the checkpoint by its arena's door (on
## your side of its barrier). Returns whether it did.
func start_over_if_lost() -> bool:
	if not lost:
		return false
	lost = false
	restart()
	var door := level.grid.arena_checkpoint()
	if door.x >= 0:
		level.checkpoint_cell = door
	return true


## The boss you were fighting, its weak point, what its fight works and whatever it had in the air are
## gone, and a fresh one stands where it was built, at full strength and its first stage. It doesn't
## introduce itself again, and gives you a moment at the checkpoint before it engages. Its barriers stay
## shut.
func restart() -> void:
	var parts: Array[Node] = []
	var b := level.boss
	if b != null and is_instance_valid(b):
		parts.append(b)
		if b.weak_point != null and is_instance_valid(b.weak_point):
			parts.append(b.weak_point)
	parts.append_array(get_tree().get_nodes_in_group(&"boss_parts").filter(func(n: Node) -> bool: return level.is_ancestor_of(n)))
	for n: Node in level.world.get_children():
		if n is Projectile and (n as Projectile).team == Projectile.Team.ENEMY:
			parts.append(n)
	for n: Node in parts:
		if n is Enemy:
			level.forget_enemy(n as Enemy)
		else:
			n.queue_free()
	_make_boss()
	if level.boss != null:
		level.boss.retrying = true


## The district's boss on its 'B' cell, its weak point on 'Z', and what its fight works (lanes, rollers:
## group "boss_parts").
func _make_boss() -> void:
	var grid := level.grid
	var b := grid.first("B")
	if b.x < 0:
		return
	match level.boss_id():
		"conductor":
			var conductor := Conductor.new()
			level.add_enemy(conductor, b, Conductor.MAX_INTEGRITY)
			level.boss = conductor
			var lanes: Array[ShuntLane] = []
			for digit: String in ["1", "2", "3"]:
				var cells := grid.cells_with(digit)
				if cells.is_empty():
					continue
				# The carriage runs away from the Conductor down its lane.
				cells.sort_custom(func(p: Vector2i, q: Vector2i) -> bool: return p.distance_squared_to(b) < q.distance_squared_to(b))
				var lane := ShuntLane.new()
				lanes.append(lane)
				lane.cells = cells
			# As the Operator sees them: the lane furthest down-left on screen is the left track.
			lanes.sort_custom(func(p: ShuntLane, q: ShuntLane) -> bool: return p.cells[0].y > q.cells[0].y)
			var sides := ["left", "middle", "right"]
			for i: int in lanes.size():
				lanes[i].setup(level, lanes[i].cells, sides[mini(i, 2)])
				lanes[i].add_to_group(&"boss_parts")
				level.fx_ground.add_child(lanes[i])
			conductor.lanes = lanes
			_add_weak_point(conductor, SignalBox.new())
		"crane":
			var crane := Crane.new()
			level.add_enemy(crane, b, Crane.MAX_INTEGRITY)
			level.boss = crane
			_add_weak_point(crane, HoistBrake.new())
		"surgeon":
			var surgeon := Surgeon.new()
			level.add_enemy(surgeon, b, Surgeon.MAX_INTEGRITY)
			level.boss = surgeon
			_add_weak_point(surgeon, TheatreSwitch.new())
		"lung":
			var lung := Lung.new()
			level.add_enemy(lung, b, Lung.MAX_INTEGRITY)
			level.boss = lung
			_add_weak_point(lung, HandValve.new())
		"warden_prime":
			var prime := WardenPrime.new()
			level.add_enemy(prime, b, WardenPrime.MAX_INTEGRITY)
			level.boss = prime
			_add_weak_point(prime, RelayMast.new())
		"editor":
			var editor := Editor.new()
			level.add_enemy(editor, b, Editor.MAX_INTEGRITY)
			level.boss = editor
			_add_weak_point(editor, BaleStack.new())
			var rollers := PressRollers.new()
			rollers.editor = editor
			rollers.add_to_group(&"boss_parts")
			level.fx_ground.add_child(rollers)


func _add_weak_point(owner_boss: Boss, point: WeakPoint) -> void:
	var z := level.grid.first("Z")
	if z.x < 0:
		return
	level.add_enemy(point, z, 1.0)
	point.boss = owner_boss
	owner_boss.weak_point = point
