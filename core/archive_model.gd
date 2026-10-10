class_name ArchiveModel
extends RefCounted
## The Archive (brief, "The Ark"): read and replay recovered memories. Lists every log of the slice:
## the Steward's own comforting records, the truth it buried, what it never indexed, and the entries
## you left behind (unrecovered). Replaying a log for the first time is when Noor and Teo react, and
## when their trust moves.

enum State { UNLOCKED, UNRECOVERED }

const KIND_ORDER: Array[String] = ["comforting", "truth", "unindexed"]

class Entry:
	var log_id: String
	var title: String
	var kind: String
	var state: State
	var replayed: bool


class Replay:
	var first_time: bool = false
	var noor_delta: int = 0
	var teo_delta: int = 0
	var error: String = ""


static func entries(run: RunState) -> Array[Entry]:
	var unlocked: Array[Entry] = []
	var unrecovered: Array[Entry] = []
	for id: String in ContentDb.log_ids():
		var def := ContentDb.memory_log(id)
		var e := Entry.new()
		e.log_id = id
		e.title = str(def.get("title", id))
		e.kind = str(def.get("kind", "comforting"))
		e.state = State.UNLOCKED if run.logs_unlocked.has(id) else State.UNRECOVERED
		e.replayed = run.logs_replayed.has(id)
		if e.state == State.UNLOCKED:
			unlocked.append(e)
		else:
			unrecovered.append(e)
	unlocked.sort_custom(func(a: Entry, b: Entry) -> bool: return KIND_ORDER.find(a.kind) < KIND_ORDER.find(b.kind))
	unlocked.append_array(unrecovered)
	return unlocked


## Replays a log. Trust moves only the first time, and only for companions who are here (joined and
## still with you).
static func replay(log_id: String) -> Replay:
	var r := Replay.new()
	if not GameState.run.logs_unlocked.has(log_id):
		r.error = "That memory wasn't recovered."
		return r
	r.first_time = GameState.mark_log_replayed(log_id)
	if not r.first_time:
		return r
	var def := ContentDb.memory_log(log_id)
	if GameState.run.companion_here(RunState.WHO_NOOR):
		r.noor_delta = int(def.get("noor", {}).get("trust", 0))
		GameState.change_trust(RunState.WHO_NOOR, r.noor_delta)
	if GameState.run.companion_here(RunState.WHO_TEO):
		r.teo_delta = int(def.get("teo", {}).get("trust", 0))
		GameState.change_trust(RunState.WHO_TEO, r.teo_delta)
	return r
