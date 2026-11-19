extends Node2D
## INFESTACIÓN - aventura 2D por salas al estilo The Legend of Zelda (1986).
## Todo se dibuja en coordenadas "NES" (256x240) y la escena se amplía x3.

const TS := 16
const COLS := 16
const ROWS := 11
const FW := 256.0
const FH := 176.0
const ORIGIN := Vector2(0, 64)
const S := 3.0

const WORLDS := [
	{"name": "CIUDAD", "w": 3, "h": 2, "boss": "LA ABOMINACIÓN", "hp": 16,
		"tip": "Prevenir es mejor que curar: la mejor batalla es la que se evita a tiempo."},
	{"name": "BOSQUE", "w": 3, "h": 3, "boss": "LA MATRIARCA", "hp": 22,
		"tip": "Cuidarte no es debilidad: descansar y recuperarte te permite ayudar a los demás."},
	{"name": "LABORATORIO", "w": 4, "h": 3, "boss": "PACIENTE CERO", "hp": 28,
		"tip": "Ningún héroe vence solo: la ciencia y la solidaridad curan lo que la fuerza no puede."},
]

const EN := {
	"walker": {"hp": 2, "speed": 26.0, "dmg": 1, "tex": "z_walker", "chase": 0.6},
	"runner": {"hp": 2, "speed": 50.0, "dmg": 1, "tex": "z_runner", "chase": 0.8},
	"shooter": {"hp": 2, "speed": 18.0, "dmg": 1, "tex": "z_shooter", "chase": 0.15},
	"tank": {"hp": 6, "speed": 20.0, "dmg": 2, "tex": "z_tank", "chase": 0.7},
}

const COVER_REVIEW := "Un brote biológico convirtió la ciudad, el bosque y el laboratorio en zonas infestadas. Como último superviviente, deberás abrirte paso con tu pistola, explorar cada sector, encontrar suministros y derrotar a los jefes para recuperar los fragmentos de la cura."
const COVER_LESSON := "Sobrevivir exige mantener la calma, pensar antes de actuar y cuidar los recursos. La valentía no consiste en no tener miedo, sino en seguir adelante, aprender y proteger a quienes nos rodean."
const FINAL_LESSON := "La infestación no se detiene con miedo ni con prisa, sino con prevención, cuidado y cooperación. Hoy tú fuiste la cura: recuerda que la salud de uno es la salud de todos."

var sfx: Sfx
var overlay: Overlay

var state := "cover"  # cover, play, scroll, dead, clear, win
var paused := false
var state_t := 0.0
var message := ""
var message_t := 0.0
var score := 0

# Mundo
var world_i := 0
var gw := 3
var gh := 2
var rooms: Array = []
var cur_room: Dictionary = {}
var room_pos := Vector2i.ZERO
var next_pos := Vector2i.ZERO
var boss_pos := Vector2i.ZERO
var boss_unlocked := false
var boss_closed := false
var visited: Dictionary = {}

# Jugador
var pos := Vector2(128, 120)
var face := Vector2i(0, -1)
var hp := 6
var max_hp := 6
var lives := 3
var keys := 0
var anim_t := 0.0
var moving := false
var atk_t := 0.0
var atk_id := 0
var inv_t := 0.0
var kb := Vector2.ZERO
var last_x := true

# Sala actual
var enemies: Array = []
var pending: Array = []
var shots: Array = []
var items: Array = []
var puffs: Array = []
var beam: Dictionary = {}

# Transición
var scroll_t := 0.0
var scroll_dir := Vector2i.ZERO
var scroll_from := Vector2.ZERO
var scroll_to := Vector2.ZERO


func _ready() -> void:
	scale = Vector2(S, S)
	randomize()
	sfx = Sfx.new()
	add_child(sfx)
	sfx.music_vol = 0.35
	sfx.apply_volumes()
	var layer := CanvasLayer.new()
	add_child(layer)
	overlay = Overlay.new()
	overlay.main = self
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


# ------------------------------------------------------------ Entrada

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if state == "dead":
			if event.keycode != KEY_ESCAPE:
				retry_level()
			return
		match event.keycode:
			KEY_LEFT, KEY_A, KEY_RIGHT, KEY_D:
				last_x = true
			KEY_UP, KEY_W, KEY_DOWN, KEY_S:
				last_x = false
			KEY_ENTER, KEY_KP_ENTER:
				confirm()
			KEY_R:
				if state == "dead":
					retry_level()
			KEY_SPACE, KEY_Z, KEY_J:
				if state == "dead":
					retry_level()
				else:
					press_attack()
			KEY_P, KEY_ESCAPE:
				if state == "play":
					paused = not paused
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_A, JOY_BUTTON_X:
				press_attack()
			JOY_BUTTON_START:
				if state == "play":
					paused = not paused
				else:
					confirm()


func press_attack() -> void:
	if state == "play":
		if paused or atk_t > 0.0:
			return
		atk_t = 0.22
		atk_id += 1
		sfx.play("pistol", 0.75)
		if beam.is_empty():
			beam = {"pos": pos + Vector2(face) * 12.0, "vel": Vector2(face) * 230.0, "dir": face}
	else:
		confirm()


func confirm() -> void:
	match state:
		"cover":
			start_game()
		"dead":
			retry_level()
		"clear":
			load_world(world_i + 1)
		"win":
			go_state("cover")


func go_state(s: String) -> void:
	state = s
	state_t = 0.0


func retry_level() -> void:
	# Una derrota definitiva permite comenzar una campaña nueva.
	paused = false
	start_game()


func read_dir() -> Vector2i:
	var dx := 0
	var dy := 0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT):
		dx -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT):
		dx += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP):
		dy -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S) or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN):
		dy += 1
	var ax := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var ay := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if absf(ax) > 0.5 or absf(ay) > 0.5:
		if absf(ax) > absf(ay):
			dx = 1 if ax > 0.0 else -1
		else:
			dy = 1 if ay > 0.0 else -1
	if dx != 0 and dy != 0:
		if last_x:
			dy = 0
		else:
			dx = 0
	return Vector2i(dx, dy)


# ------------------------------------------------------------ Mundo

func idx(p: Vector2i) -> int:
	return p.y * gw + p.x


func start_game() -> void:
	max_hp = 6
	hp = max_hp
	lives = 3
	score = 0
	load_world(0)


func load_world(i: int) -> void:
	world_i = i
	var cfg: Dictionary = WORLDS[i]
	gw = cfg["w"]
	gh = cfg["h"]
	rooms.clear()
	for y in range(gh):
		for x in range(gw):
			rooms.append(make_room(x, y))
	room_pos = Vector2i(0, gh - 1)
	boss_pos = Vector2i(gw - 1, 0)
	boss_unlocked = false
	boss_closed = false
	visited.clear()
	enemies.clear()
	pending.clear()
	shots.clear()
	items.clear()
	puffs.clear()
	beam.clear()
	keys = 0
	hp = max_hp
	inv_t = 0.0
	kb = Vector2.ZERO
	atk_t = 0.0
	paused = false
	var cand: Array = []
	for y in range(gh):
		for x in range(gw):
			var p := Vector2i(x, y)
			if p != room_pos and p != boss_pos:
				cand.append(p)
	cand.shuffle()
	var key_room: Vector2i = cand[0]
	rooms[idx(key_room)]["has_key"] = true
	if cand.size() > 2:
		var heart_room: Vector2i = cand[1]
		rooms[idx(heart_room)]["items"].append({"kind": "heart", "pos": Vector2(128, 88)})
	for p in cand:
		var r: Dictionary = rooms[idx(p)]
		var n := mini(6, 2 + i + randi() % 3)
		for k in range(n):
			r["kinds"].append(pick_kind())
	rooms[idx(boss_pos)]["kinds"] = ["boss"]
	# La sala inicial también debe tener enemigos: dos amenazas garantizadas.
	var start_room: Dictionary = rooms[idx(room_pos)]
	start_room["kinds"] = ["walker", "runner"] if i == 0 else ["walker", "shooter"]
	start_room["cleared"] = false
	pos = Vector2(128, 118)
	face = Vector2i(0, -1)
	go_state("play")
	enter_room()
	show_message("NIVEL %d: %s" % [i + 1, cfg["name"]], 3.0)
	sfx.play("wave", 0.6)


func pick_kind() -> String:
	var r := randf()
	match world_i:
		0:
			return "walker" if r < 0.55 else "runner"
		1:
			if r < 0.4:
				return "walker"
			return "runner" if r < 0.7 else "shooter"
		_:
			if r < 0.3:
				return "walker"
			if r < 0.55:
				return "runner"
			return "shooter" if r < 0.8 else "tank"


func make_room(x: int, y: int) -> Dictionary:
	var t := PackedByteArray()
	t.resize(COLS * ROWS)
	for ty in range(ROWS):
		for tx in range(COLS):
			if tx == 0 or tx == COLS - 1 or ty == 0 or ty == ROWS - 1:
				t[ty * COLS + tx] = 1
	if y > 0:
		t[7] = 6
		t[8] = 6
	if y < gh - 1:
		t[(ROWS - 1) * COLS + 7] = 6
		t[(ROWS - 1) * COLS + 8] = 6
	if x > 0:
		for ty in [4, 5, 6]:
			t[ty * COLS] = 6
	if x < gw - 1:
		for ty in [4, 5, 6]:
			t[ty * COLS + COLS - 1] = 6
	for q in range(4):
		var qx0 := 1 if q % 2 == 0 else 10
		var qy0 := 1 if q < 2 else 7
		if randf() < 0.8:
			for i in range(randi_range(1, 5)):
				var tx := qx0 + randi() % 5
				var ty := qy0 + randi() % 3
				t[ty * COLS + tx] = 2 if randf() < 0.7 else 3
	# Mantiene libre el punto de reaparición para evitar quedar dentro de un obstáculo.
	t[7 * COLS + 8] = 0
	t[6 * COLS + 8] = 0
	return {"tiles": t, "kinds": [], "cleared": false, "items": [], "has_key": false}


func eff_tile(r: Dictionary, rp: Vector2i, tx: int, ty: int) -> int:
	var tl: PackedByteArray = r["tiles"]
	var v: int = tl[ty * COLS + tx]
	if v != 6:
		return v
	var nb := rp
	if ty == 0:
		nb += Vector2i(0, -1)
	elif ty == ROWS - 1:
		nb += Vector2i(0, 1)
	elif tx == 0:
		nb += Vector2i(-1, 0)
	else:
		nb += Vector2i(1, 0)
	if rp == boss_pos or nb == boss_pos:
		if not boss_unlocked:
			return 4
		if boss_closed:
			return 5
	return 0


func out_ok(tx: int, ty: int) -> bool:
	var tl: PackedByteArray = cur_room["tiles"]
	if tx < 0 and ty >= 0 and ty < ROWS:
		return tl[ty * COLS] == 6
	if tx >= COLS and ty >= 0 and ty < ROWS:
		return tl[ty * COLS + COLS - 1] == 6
	if ty < 0 and tx >= 0 and tx < COLS:
		return tl[tx] == 6
	if ty >= ROWS and tx >= 0 and tx < COLS:
		return tl[(ROWS - 1) * COLS + tx] == 6
	return false


func solid_px(p: Vector2) -> bool:
	var tx := floori(p.x / TS)
	var ty := floori(p.y / TS)
	if tx < 0 or tx >= COLS or ty < 0 or ty >= ROWS:
		return not out_ok(tx, ty)
	return eff_tile(cur_room, room_pos, tx, ty) != 0


func box_hits(c: Vector2, h: float) -> bool:
	return solid_px(c + Vector2(-h, -h)) or solid_px(c + Vector2(h, -h)) or solid_px(c + Vector2(-h, h)) or solid_px(c + Vector2(h, h))


func move_box(p: Vector2, d: Vector2, half: float) -> Vector2:
	var nx := Vector2(p.x + d.x, p.y)
	if box_hits(nx, half):
		nx = p
	var ny := Vector2(nx.x, nx.y + d.y)
	if box_hits(ny, half):
		ny = nx
	return ny


func enter_room() -> void:
	visited[room_pos] = true
	cur_room = rooms[idx(room_pos)]
	enemies.clear()
	pending.clear()
	shots.clear()
	puffs.clear()
	beam = {}
	items = cur_room["items"].duplicate()
	if not cur_room["cleared"]:
		var kinds: Array = cur_room["kinds"]
		for k in kinds:
			var kind: String = k
			if kind == "boss":
				enemies.append(make_enemy("boss", Vector2(128, 50)))
				boss_closed = true
				sfx.play("boss", 0.8)
				show_message("¡%s!" % str(WORLDS[world_i]["boss"]), 2.5)
				continue
			var p := Vector2(128, 88)
			for i in range(40):
				var c := Vector2(randi_range(2, 13) * TS + 8, randi_range(2, 8) * TS + 8)
				if eff_tile(cur_room, room_pos, int(c.x / TS), int(c.y / TS)) == 0 and c.distance_to(pos) > 60.0:
					p = c
					break
			enemies.append(make_enemy(kind, p))


func save_room_items() -> void:
	cur_room["items"] = items.duplicate()


func make_enemy(kind: String, p: Vector2) -> Dictionary:
	var ehp := 2
	if kind == "boss":
		ehp = int(WORLDS[world_i]["hp"])
	else:
		ehp = int(EN[kind]["hp"])
	return {"kind": kind, "pos": p, "hp": ehp, "dir": Vector2.DOWN, "t": randf_range(0.2, 1.0),
		"st": randf_range(1.0, 2.5), "sp": 5.0, "kb": Vector2.ZERO, "flash": 0.0, "inv": 0.0,
		"anim": randf() * 3.0, "mode": "walk", "bi": world_i, "atk": -1}


func room_cleared() -> void:
	cur_room["cleared"] = true
	if cur_room["has_key"]:
		items.append({"kind": "key", "pos": Vector2(128, 88)})
		show_message("¡Aparece una llave!", 2.0)
		sfx.play("wave", 0.6)


func show_message(s: String, secs: float) -> void:
	message = s
	message_t = secs


# ------------------------------------------------------------ Bucle

func _process(delta: float) -> void:
	state_t += delta
	if message_t > 0.0:
		message_t -= delta
	match state:
		"play":
			if not paused:
				update_play(delta)
		"scroll":
			update_scroll(delta)
	queue_redraw()


func update_play(dt: float) -> void:
	inv_t = maxf(0.0, inv_t - dt)
	var dir := read_dir()
	moving = false
	if atk_t > 0.0:
		atk_t -= dt
	elif dir != Vector2i.ZERO:
		face = dir
		moving = true
		anim_t += dt
		pos = move_box(pos, Vector2(dir) * 62.0 * dt, 6.0)
		var probe := pos + Vector2(face) * 9.0
		var ptx := floori(probe.x / TS)
		var pty := floori(probe.y / TS)
		if ptx >= 0 and ptx < COLS and pty >= 0 and pty < ROWS:
			if eff_tile(cur_room, room_pos, ptx, pty) == 4 and keys > 0:
				keys -= 1
				boss_unlocked = true
				sfx.play("buy", 0.8)
				show_message("¡Puerta del jefe abierta!", 2.0)
	if kb.length() > 1.0:
		pos = move_box(pos, kb * dt, 6.0)
		kb = kb.move_toward(Vector2.ZERO, 600.0 * dt)
	update_beam(dt)
	update_enemies(dt)
	# Si el jugador muere durante la actualización de enemigos, no ejecutar
	# más lógica de la partida en este mismo frame.
	if state != "play":
		return
	update_shots(dt)
	if state != "play":
		return
	update_items()
	var puff_keep: Array = []
	for pf in puffs:
		pf["t"] += dt
		if pf["t"] < 0.3:
			puff_keep.append(pf)
	puffs = puff_keep
	if enemies.is_empty() and not cur_room["cleared"] and state == "play":
		boss_closed = false
		room_cleared()
	if state != "play":
		return
	if pos.x < 0.0:
		begin_scroll(Vector2i(-1, 0))
	elif pos.x > FW:
		begin_scroll(Vector2i(1, 0))
	elif pos.y < 0.0:
		begin_scroll(Vector2i(0, -1))
	elif pos.y > FH:
		begin_scroll(Vector2i(0, 1))


func begin_scroll(d: Vector2i) -> void:
	save_room_items()
	next_pos = room_pos + d
	scroll_dir = d
	scroll_t = 0.0
	scroll_from = pos
	if d.x < 0:
		scroll_to = Vector2(FW - 24.0, pos.y)
	elif d.x > 0:
		scroll_to = Vector2(24.0, pos.y)
	elif d.y < 0:
		scroll_to = Vector2(pos.x, FH - 24.0)
	else:
		scroll_to = Vector2(pos.x, 24.0)
	enemies.clear()
	shots.clear()
	beam = {}
	go_state("scroll")


func update_scroll(dt: float) -> void:
	scroll_t += dt / 0.65
	anim_t += dt
	if scroll_t >= 1.0:
		room_pos = next_pos
		pos = scroll_to
		go_state("play")
		enter_room()


func sword_hits() -> void:
	var sz := Vector2(18, 10) if face.x != 0 else Vector2(10, 18)
	var c := pos + Vector2(face) * 13.0
	var rect := Rect2(c - sz * 0.5, sz)
	for e in enemies:
		if e["hp"] <= 0 or e["atk"] == atk_id:
			continue
		var half := 13.0 if e["kind"] == "boss" else 7.0
		var ep: Vector2 = e["pos"]
		var er := Rect2(ep - Vector2(half, half), Vector2(half, half) * 2.0)
		if rect.intersects(er):
			e["atk"] = atk_id
			hit_enemy(e, 2, Vector2(face))


func hit_enemy(e: Dictionary, dmg: int, dir: Vector2) -> void:
	if e["inv"] > 0.0:
		return
	e["hp"] -= dmg
	e["flash"] = 0.2
	e["inv"] = 0.3
	sfx.play("hit", 0.7)
	if e["kind"] != "boss":
		e["kb"] = dir * 190.0
	if e["hp"] <= 0:
		kill_enemy(e)


func kill_enemy(e: Dictionary) -> void:
	var ep: Vector2 = e["pos"]
	puffs.append({"pos": ep, "t": 0.0})
	score += 100 if e["kind"] != "boss" else 1000
	if e["kind"] == "boss":
		sfx.play("explosion", 0.9)
		for o in enemies:
			if o["hp"] > 0:
				o["hp"] = 0
				puffs.append({"pos": o["pos"], "t": 0.0})
		for o in pending:
			o["hp"] = 0
		items.append({"kind": "container", "pos": Vector2(108, 88)})
		items.append({"kind": "fragment", "pos": Vector2(148, 88)})
		boss_closed = false
		show_message("¡Jefe derrotado!", 2.5)
	else:
		sfx.play("zdie", 0.6)
		if randf() < 0.18:
			items.append({"kind": "heart", "pos": ep})


func update_beam(dt: float) -> void:
	if beam.is_empty():
		return
	var bp: Vector2 = beam["pos"]
	var bv: Vector2 = beam["vel"]
	bp += bv * dt
	beam["pos"] = bp
	if solid_px(bp) or bp.x < -8.0 or bp.x > FW + 8.0 or bp.y < -8.0 or bp.y > FH + 8.0:
		beam = {}
		return
	for e in enemies:
		if e["hp"] <= 0:
			continue
		var half := 13.0 if e["kind"] == "boss" else 8.0
		var ep: Vector2 = e["pos"]
		if absf(ep.x - bp.x) < half + 3.0 and absf(ep.y - bp.y) < half + 3.0:
			hit_enemy(e, 2, bv.normalized())
			beam = {}
			return


func update_enemies(dt: float) -> void:
	var alive: Array = []
	for e in enemies:
		if e["hp"] <= 0:
			continue
		e["flash"] = maxf(0.0, e["flash"] - dt)
		e["inv"] = maxf(0.0, e["inv"] - dt)
		e["anim"] += dt
		var kind: String = e["kind"]
		var is_boss := kind == "boss"
		var half := 13.0 if is_boss else 6.0
		var ep: Vector2 = e["pos"]
		var kbv: Vector2 = e["kb"]
		if kbv.length() > 1.0:
			ep = move_box(ep, kbv * dt, half)
			e["kb"] = kbv.move_toward(Vector2.ZERO, 700.0 * dt)
		elif is_boss:
			ep = boss_ai(e, ep, dt)
		else:
			ep = basic_ai(e, ep, dt, kind)
		ep.x = clampf(ep.x, half + 2.0, FW - half - 2.0)
		ep.y = clampf(ep.y, half + 2.0, FH - half - 2.0)
		e["pos"] = ep
		var dmg := 2 if is_boss else int(EN[kind]["dmg"])
		if inv_t <= 0.0 and absf(ep.x - pos.x) < half + 4.0 and absf(ep.y - pos.y) < half + 4.0:
			hurt_player(dmg, ep)
			if state != "play":
				enemies.clear()
				pending.clear()
				return
		alive.append(e)
	enemies = alive + pending
	pending.clear()


func basic_ai(e: Dictionary, ep: Vector2, dt: float, kind: String) -> Vector2:
	var st: Dictionary = EN[kind]
	e["t"] -= dt
	var d: Vector2 = e["dir"]
	if e["t"] <= 0.0:
		e["t"] = randf_range(0.5, 1.4)
		var chase: float = st["chase"]
		if randf() < chase:
			var to := pos - ep
			if absf(to.x) > absf(to.y):
				d = Vector2(signf(to.x), 0.0)
			else:
				d = Vector2(0.0, signf(to.y))
		else:
			var opts: Array = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
			d = opts[randi() % 4]
		e["dir"] = d
	var np := move_box(ep, d * float(st["speed"]) * dt, 6.0)
	if np.is_equal_approx(ep):
		e["t"] = 0.0
	if kind == "shooter":
		e["st"] -= dt
		if e["st"] <= 0.0:
			e["st"] = randf_range(1.6, 2.6)
			var to2 := pos - ep
			var sd := Vector2(signf(to2.x), 0.0) if absf(to2.x) > absf(to2.y) else Vector2(0.0, signf(to2.y))
			shots.append({"pos": ep, "vel": sd * 85.0})
			sfx.play("spit", 0.4)
	return np


func chase_step(ep: Vector2, speed: float, dt: float) -> Vector2:
	var to := pos - ep
	if to.length() < 1.0:
		return ep
	return move_box(ep, to.normalized() * speed * dt, 13.0)


func boss_ai(e: Dictionary, ep: Vector2, dt: float) -> Vector2:
	var bi: int = e["bi"]
	e["t"] -= dt
	if bi == 0:
		# La Abominación: camina, se prepara y embiste
		var mode: String = e["mode"]
		if mode == "walk":
			ep = chase_step(ep, 28.0, dt)
			if e["t"] <= 0.0:
				e["mode"] = "wind"
				e["t"] = 0.6
		elif mode == "wind":
			if e["t"] <= 0.0:
				e["mode"] = "charge"
				e["t"] = 0.9
				e["dir"] = (pos - ep).normalized()
		else:
			var cd: Vector2 = e["dir"]
			var np := move_box(ep, cd * 120.0 * dt, 13.0)
			if np.is_equal_approx(ep):
				e["t"] = 0.0
			ep = np
			if e["t"] <= 0.0:
				e["mode"] = "walk"
				e["t"] = randf_range(1.5, 2.5)
	elif bi == 1:
		# La Matriarca: abanico de esporas e invoca corredores
		ep = chase_step(ep, 22.0, dt)
		e["st"] -= dt
		if e["st"] <= 0.0:
			e["st"] = 1.8
			var base := (pos - ep).angle()
			for a in [-0.35, 0.0, 0.35]:
				shots.append({"pos": ep, "vel": Vector2.from_angle(base + float(a)) * 80.0})
			sfx.play("spit", 0.5)
		e["sp"] -= dt
		if e["sp"] <= 0.0:
			e["sp"] = 6.0
			if enemies.size() + pending.size() < 6:
				pending.append(make_enemy("runner", ep + Vector2(0, 24)))
	else:
		# Paciente Cero: deriva y lanza anillos de esporas
		if e["t"] <= 0.0:
			e["t"] = randf_range(0.8, 1.6)
			var opts: Array = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
			e["dir"] = opts[randi() % 4]
		var wd: Vector2 = e["dir"]
		ep = move_box(ep, wd * 16.0 * dt, 13.0)
		e["st"] -= dt
		if e["st"] <= 0.0:
			e["st"] = 1.6
			var off := 0.39 if int(e["anim"]) % 2 == 0 else 0.0
			for k in range(8):
				shots.append({"pos": ep, "vel": Vector2.from_angle(off + float(k) * TAU / 8.0) * 70.0})
			sfx.play("spit", 0.5)
	return ep


func update_shots(dt: float) -> void:
	var keep: Array = []
	for s in shots:
		var sp: Vector2 = s["pos"]
		var sv: Vector2 = s["vel"]
		sp += sv * dt
		s["pos"] = sp
		if solid_px(sp) or sp.x < -4.0 or sp.x > FW + 4.0 or sp.y < -4.0 or sp.y > FH + 4.0:
			continue
		if inv_t <= 0.0 and sp.distance_to(pos) < 8.0:
			hurt_player(1, sp)
			if state != "play":
				return
			continue
		keep.append(s)
	shots = keep


func update_items() -> void:
	for it in items.duplicate():
		var ip: Vector2 = it["pos"]
		if pos.distance_to(ip) > 11.0:
			continue
		var kind: String = it["kind"]
		items.erase(it)
		match kind:
			"heart":
				hp = mini(max_hp, hp + 2)
				sfx.play("pickup", 0.6)
			"key":
				keys += 1
				sfx.play("buy", 0.8)
				show_message("¡Llave conseguida! Busca la sala del jefe", 2.5)
			"container":
				max_hp += 2
				hp = max_hp
				sfx.play("buy", 0.9)
				show_message("¡Un corazón más!", 2.0)
			"fragment":
				score += 500
				sfx.play("wave", 0.8)
				if world_i >= WORLDS.size() - 1:
					go_state("win")
				else:
					go_state("clear")
				return


func hurt_player(dmg: int, from: Vector2) -> void:
	hp -= dmg
	inv_t = 1.0
	kb = (pos - from).normalized() * 170.0
	sfx.play("hurt", 0.8)
	if hp <= 0:
		hp = 0
		lives -= 1
		paused = false
		atk_t = 0.0
		beam.clear()
		shots.clear()
		pending.clear()
		kb = Vector2.ZERO
		moving = false
		puffs.clear()
		if lives > 0:
			# Reaparece en el centro de la sala, con salud completa y breve invulnerabilidad.
			hp = max_hp
			pos = Vector2(128, 120)
			face = Vector2i(0, -1)
			inv_t = 2.2
			enter_room()
			show_message("REAPARICIÓN: %d VIDAS RESTANTES" % lives, 2.5)
			sfx.play("wave", 0.75)
		else:
			inv_t = 0.0
			enemies.clear()
			items.clear()
			go_state("dead")
			sfx.play("boss", 0.8)


# ------------------------------------------------------------ Dibujo del juego

func spr(tex_name: String, center: Vector2, flip: bool = false, mod: Color = Color.WHITE, size: Vector2 = Vector2(16, 16), rot: float = 0.0) -> void:
	var t: Texture2D = Art.tex(tex_name)
	if t == null:
		return
	draw_set_transform(center.round(), rot, Vector2(-1.0 if flip else 1.0, 1.0))
	draw_texture_rect(t, Rect2(-size * 0.5, size), false, mod)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func rot_of(d: Vector2i) -> float:
	if d.y < 0:
		return 0.0
	if d.x > 0:
		return PI * 0.5
	if d.y > 0:
		return PI
	return -PI * 0.5


func draw_room(rp: Vector2i, off: Vector2) -> void:
	var r: Dictionary = rooms[idx(rp)]
	for ty in range(ROWS):
		for tx in range(COLS):
			var v := eff_tile(r, rp, tx, ty)
			var c := ORIGIN + off + Vector2(tx * TS + 8, ty * TS + 8)
			var gv := 1 if (tx * 31 + ty * 17) % 7 == 0 else 0
			match v:
				0:
					spr("tile_ground_%d_%d" % [world_i, gv], c)
					# Marcas viales desgastadas para que la ciudad se lea como una calle,
					# no como una cuadrícula vacía. Son solo decoración: no alteran colisiones.
					if world_i == 0 and ty == 5 and tx in [2, 6, 10, 13]:
						draw_rect(Rect2(c + Vector2(-5, -1), Vector2(10, 2)), Color(0.66, 0.64, 0.57, 0.48))
					if world_i == 0 and ty == 6 and tx in [3, 11] and (rp.x + rp.y) % 2 == 0:
						draw_rect(Rect2(c + Vector2(-2, 5), Vector2(4, 1)), Color(0.50, 0.48, 0.44, 0.55))
				1:
					spr("tile_wall_%d" % world_i, c)
				2:
					spr("tile_obs_%d" % world_i, c)
				3:
					spr("tile_liq_%d" % world_i, c)
				4:
					spr("tile_lock", c)
				5:
					spr("tile_shut", c)
	draw_environment_decor(rp, off)


func draw_environment_decor(rp: Vector2i, off: Vector2) -> void:
	# Elementos decorativos situados sobre el suelo; no modifican colisiones ni rutas.
	if world_i == 0:
		# Vehículos dañados, barricadas y señales de evacuación en la ciudad.
		var seed := rp.x * 37 + rp.y * 19
		var car := ORIGIN + off + Vector2(48 if seed % 2 == 0 else 208, 52 if seed % 3 == 0 else 140)
		draw_rect(Rect2(car + Vector2(-13, -7), Vector2(26, 14)), Color(0.12, 0.16, 0.18))
		draw_rect(Rect2(car + Vector2(-9, -5), Vector2(18, 10)), Color(0.38, 0.20, 0.16))
		draw_rect(Rect2(car + Vector2(-5, -4), Vector2(10, 8)), Color(0.20, 0.30, 0.32))
		for wx in [-8, 8]:
			draw_rect(Rect2(car + Vector2(wx - 2, -9), Vector2(5, 3)), Color(0.035, 0.04, 0.045))
			draw_rect(Rect2(car + Vector2(wx - 2, 6), Vector2(5, 3)), Color(0.035, 0.04, 0.045))
		var barricade := ORIGIN + off + Vector2(128, 42 if seed % 2 == 0 else 150)
		draw_rect(Rect2(barricade + Vector2(-13, -3), Vector2(26, 6)), Color(0.12, 0.13, 0.13))
		for bx in [-9, 0, 9]:
			draw_line(barricade + Vector2(bx - 3, 2), barricade + Vector2(bx + 2, -2), Color(0.95, 0.55, 0.12), 2.0)
		# Señal de peligro y pequeños fragmentos de concreto.
		var sign_pos := ORIGIN + off + Vector2(218, 28)
		draw_rect(Rect2(sign_pos + Vector2(-5, -5), Vector2(10, 10)), Color(0.72, 0.13, 0.08))
		draw_line(sign_pos + Vector2(0, -3), sign_pos + Vector2(0, 2), Color(1.0, 0.9, 0.65), 2.0)
		draw_circle(sign_pos + Vector2(0, 4), 1.0, Color(1.0, 0.9, 0.65))
		for j in range(5):
			var debris := ORIGIN + off + Vector2(28 + float((seed + j * 23) % 195), 30 + float((seed + j * 31) % 112))
			draw_rect(Rect2(debris, Vector2(3 + j % 3, 2 + j % 2)), Color(0.42, 0.40, 0.36, 0.8))
	elif world_i == 1:
		# Maleza, ramas y hongos bioluminiscentes en el bosque.
		for j in range(7):
			var q := ORIGIN + off + Vector2(20 + float((rp.x * 29 + j * 31) % 215), 25 + float((rp.y * 17 + j * 23) % 125))
			draw_line(q, q + Vector2(0, -5), Color(0.18, 0.34, 0.20), 2.0)
			draw_circle(q + Vector2(0, -6), 2.0, Color(0.35, 0.68, 0.28, 0.8))
	else:
		# Laboratorio: balizas, paneles averiados y reflejos químicos.
		for j in range(4):
			var q := ORIGIN + off + Vector2(34 + j * 58, 30 if (rp.x + j) % 2 == 0 else 145)
			draw_rect(Rect2(q, Vector2(18, 3)), Color(0.12, 0.32, 0.34, 0.75))
			draw_circle(q + Vector2(9, 1), 2.0, Color(0.25, 0.95, 0.75, 0.8))


func draw_player(sp: Vector2) -> void:
	if inv_t > 0.0 and int(inv_t * 20.0) % 2 == 0:
		return
	var frame := int(anim_t * 8.0) % 2
	var tex := "hero_down"
	var flip := false
	if face.y > 0:
		flip = frame == 1
	elif face.y < 0:
		tex = "hero_up"
		flip = frame == 1
	else:
		tex = "hero_side_a" if frame == 0 else "hero_side_b"
		flip = face.x < 0
	# El personaje se representa únicamente con su sprite original; no se superponen
	# formas geométricas que oculten el diseño del arte.
	draw_circle(sp + Vector2(0, 4), 4.8, Color(0.0, 0.0, 0.0, 0.38))
	spr(tex, sp, flip, Color.WHITE, Vector2(18, 23))
	# Pistola compacta dibujada por código y orientada hacia la dirección de avance.
	draw_pistol(sp + Vector2(face) * 5.0, face)


func draw_pistol(center: Vector2, direction: Vector2i) -> void:
	var angle := 0.0
	if direction.y < 0:
		angle = -PI * 0.5
	elif direction.y > 0:
		angle = PI * 0.5
	elif direction.x < 0:
		angle = PI
	draw_set_transform(center.round(), angle, Vector2.ONE)
	# Pistola compacta: corredera, empuñadura y cañón corto.
	draw_rect(Rect2(-2, -2, 10, 4), Color(0.10, 0.12, 0.14))
	draw_rect(Rect2(1, -3, 8, 3), Color(0.43, 0.47, 0.49))
	draw_rect(Rect2(6, -2, 5, 2), Color(0.72, 0.75, 0.72))
	draw_rect(Rect2(-2, 1, 4, 5), Color(0.25, 0.18, 0.14))
	draw_rect(Rect2(2, -4, 3, 1), Color(0.13, 0.15, 0.16))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw() -> void:
	if state == "cover":
		return
	if state == "scroll":
		var d := Vector2(scroll_dir)
		var sz := Vector2(FW, FH)
		draw_room(room_pos, -d * sz * scroll_t)
		draw_room(next_pos, d * sz * (1.0 - scroll_t))
		var pp := scroll_from.lerp(scroll_to + d * sz, scroll_t) - d * sz * scroll_t
		draw_player(ORIGIN + pp)
		return
	draw_room(room_pos, Vector2.ZERO)
	for it in items:
		var ip: Vector2 = ORIGIN + it["pos"]
		match str(it["kind"]):
			"heart":
				spr("heart", ip, false, Color.WHITE, Vector2(8, 8))
			"key":
				spr("key", ip)
			"container":
				spr("container", ip)
			"fragment":
				var pulse := 1.0 + 0.12 * sin(state_t * 6.0)
				spr("fragment_%d" % world_i, ip, false, Color.WHITE, Vector2(16, 16) * pulse)
	for e in enemies:
		var kind: String = e["kind"]
		var ep: Vector2 = ORIGIN + Vector2(e["pos"])
		var mod := Color.WHITE
		if e["flash"] > 0.0 or (e["mode"] == "wind" and int(state_t * 16.0) % 2 == 0):
			mod = Color(1.0, 0.45, 0.45)
		var flip := int(e["anim"] * 6.0) % 2 == 1
		draw_circle(ep + Vector2(0, 3), 4.8 if kind != "boss" else 8.5, Color(0.0, 0.0, 0.0, 0.42))
		if kind == "boss":
			spr("boss_%d" % int(e["bi"]), ep, flip, mod, Vector2(26, 26))
		else:
			var esize := Vector2(18, 20) if kind != "tank" else Vector2(19, 21)
			spr(str(EN[kind]["tex"]), ep, flip, mod, esize)
	for s in shots:
		spr("spore", ORIGIN + Vector2(s["pos"]), false, Color.WHITE, Vector2(8, 8))
	if not beam.is_empty():
		var bp: Vector2 = ORIGIN + Vector2(beam["pos"])
		var bv: Vector2 = Vector2(beam["dir"])
		draw_set_transform(bp, rot_of(Vector2i(int(bv.x), int(bv.y))) - PI * 0.5, Vector2.ONE)
		draw_rect(Rect2(-2, -1, 13, 2), Color(1.0, 0.78, 0.25))
		draw_rect(Rect2(5, -2, 8, 4), Color(1.0, 0.96, 0.68))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for pf in puffs:
		var k: float = float(pf["t"]) / 0.3
		spr("poof", ORIGIN + Vector2(pf["pos"]), false, Color(1, 1, 1, 1.0 - k), Vector2(16, 16) * (0.6 + k * 1.6))
	if state == "play" or state == "dead":
		if state == "play" or int(state_t * 10.0) % 2 == 0:
			draw_player(ORIGIN + pos)


# ------------------------------------------------------------ Interfaz

func txt(c: Control, s: String, p: Vector2, size: int, col: Color = Color.WHITE, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, w: float = -1.0) -> void:
	var f: Font = ThemeDB.fallback_font
	c.draw_string(f, p + Vector2(2, 2), s, align, w, size, Color(0, 0, 0, 0.8))
	c.draw_string(f, p, s, align, w, size, col)


func panel(c: Control, y: float, title: String, body: String, col: Color, fs: int) -> float:
	var f: Font = ThemeDB.fallback_font
	var sz: Vector2 = f.get_multiline_string_size(body, HORIZONTAL_ALIGNMENT_LEFT, 600.0, fs)
	var h := sz.y + 70.0
	var r := Rect2(48, y, 672, h)
	c.draw_rect(r, Color(0, 0, 0, 0.84))
	c.draw_rect(r, Color.WHITE, false, 3.0)
	txt(c, title, Vector2(72, y + 36), 24, col)
	c.draw_multiline_string(f, Vector2(72, y + 70), body, HORIZONTAL_ALIGNMENT_LEFT, 600.0, fs, -1, Color.WHITE)
	return y + h


func draw_overlay(c: Control) -> void:
	if state == "cover":
		draw_cover(c)
		return
	draw_hud(c)
	if message_t > 0.0 and (state == "play" or state == "scroll"):
		c.draw_rect(Rect2(0, 540, 768, 56), Color(0, 0, 0, 0.7))
		txt(c, message, Vector2(0, 578), 28, Color(1, 0.95, 0.5), HORIZONTAL_ALIGNMENT_CENTER, 768.0)
	match state:
		"play":
			if paused:
				c.draw_rect(Rect2(0, 192, 768, 528), Color(0, 0, 0, 0.6))
				txt(c, "PAUSA", Vector2(0, 420), 56, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 768.0)
				txt(c, "P: continuar", Vector2(0, 470), 22, Color(0.8, 0.8, 0.8), HORIZONTAL_ALIGNMENT_CENTER, 768.0)
		"dead":
			c.draw_rect(Rect2(0, 192, 768, 528), Color(0, 0, 0, 0.7))
			txt(c, "DERROTA", Vector2(0, 400), 60, Color(0.95, 0.2, 0.15), HORIZONTAL_ALIGNMENT_CENTER, 768.0)
			txt(c, "HAS PERDIDO TUS 3 VIDAS", Vector2(0, 462), 28, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 768.0)
			txt(c, "PULSA CUALQUIER TECLA PARA INICIAR DE NUEVO", Vector2(0, 510), 22, Color(0.9, 0.82, 0.65), HORIZONTAL_ALIGNMENT_CENTER, 768.0)
			txt(c, "También puedes usar A / X en el mando.", Vector2(0, 552), 16, Color(0.75, 0.8, 0.85), HORIZONTAL_ALIGNMENT_CENTER, 768.0)
		"clear":
			draw_end_screen(c, false)
		"win":
			draw_end_screen(c, true)


func draw_end_screen(c: Control, is_final: bool) -> void:
	c.draw_rect(Rect2(0, 0, 768, 720), Color.BLACK)
	var ft: Texture2D = Art.tex("fragment_%d" % world_i)
	if ft:
		c.draw_texture_rect(ft, Rect2(336, 70, 96, 96), false)
	var head := "¡LA CURA ESTÁ COMPLETA!" if is_final else "¡FRAGMENTO %d RECUPERADO!" % (world_i + 1)
	txt(c, head, Vector2(0, 230), 40, Color(1, 0.9, 0.3), HORIZONTAL_ALIGNMENT_CENTER, 768.0)
	var body: String = FINAL_LESSON if is_final else str(WORLDS[world_i]["tip"])
	panel(c, 280, "ENSEÑANZA", body, Color(0.5, 1, 0.6), 22)
	txt(c, "Puntos: %05d" % score, Vector2(0, 560), 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 768.0)
	if int(state_t * 2.0) % 2 == 0 and state_t > 0.6:
		var nxt := "ENTER: volver a la portada" if is_final else "ENTER: siguiente mundo"
		txt(c, nxt, Vector2(0, 640), 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 768.0)


func draw_hud(c: Control) -> void:
	c.draw_rect(Rect2(0, 0, 768, 192), Color.BLACK)
	c.draw_rect(Rect2(0, 188, 768, 4), Color(0.25, 0.25, 0.3))
	var cfg: Dictionary = WORLDS[world_i]
	txt(c, "NIVEL %d  %s" % [world_i + 1, cfg["name"]], Vector2(36, 40), 22, Color(0.9, 0.9, 0.9))
	for y in range(gh):
		for x in range(gw):
			var p := Vector2i(x, y)
			var col := Color(0.18, 0.18, 0.24)
			if visited.has(p):
				col = Color(0.5, 0.5, 0.62)
			if p == boss_pos:
				col = Color(0.6, 0.1, 0.1) if visited.has(p) else Color(0.32, 0.06, 0.06)
			if p == room_pos:
				col = Color.WHITE
			c.draw_rect(Rect2(36 + x * 40, 60 + y * 24, 36, 20), col)
	var kt: Texture2D = Art.tex("key")
	if kt:
		c.draw_texture_rect(kt, Rect2(300, 56, 48, 48), false)
	txt(c, "x %d" % keys, Vector2(356, 94), 30)
	txt(c, "PUNTOS %05d" % score, Vector2(300, 150), 22)
	txt(c, "VIDAS", Vector2(630, 40), 20, Color(1.0, 0.78, 0.28))
	for life_i in range(3):
		var life_col := Color(0.95, 0.20, 0.16) if life_i < lives else Color(0.22, 0.22, 0.25)
		c.draw_circle(Vector2(642 + life_i * 34, 76), 11, life_col)
		c.draw_circle(Vector2(652 + life_i * 34, 76), 11, life_col)
		c.draw_colored_polygon(PackedVector2Array([Vector2(631 + life_i * 34, 78), Vector2(663 + life_i * 34, 78), Vector2(647 + life_i * 34, 94)]), life_col)
	txt(c, "SALUD", Vector2(470, 44), 24, Color(0.95, 0.25, 0.15))
	var ht: Texture2D = Art.tex("heart")
	var he: Texture2D = Art.tex("heart_empty")
	for i in range(max_hp >> 1):
		var hx := 470.0 + float(i % 8) * 34.0
		var hy := 62.0 + floorf(float(i) / 8.0) * 34.0
		if he:
			c.draw_texture_rect(he, Rect2(hx, hy, 28, 28), false)
		#if ht:
			#if hp >= (i + 1) * 2:
				#c.draw_texture_rect(ht, Rect2(hx, hy, 28, 28), false)
			#elif hp == i * 2 + 1:
				#c.draw_texture_region(ht, Rect2(hx, hy, 14, 28), Rect2(0, 0, 4, 8))


func draw_cover(c: Control) -> void:
	# Portada cinematográfica: arte original de apocalipsis como fondo y textos nítidos.
	c.draw_rect(Rect2(0, 0, 768, 720), Color(0.015, 0.02, 0.035))
	var bg: Texture2D = Art.tex("menu_bg")
	if bg:
		c.draw_texture_rect(bg, Rect2(0, 0, 768, 675), false)
	# Viñeta y paneles inferiores para que la reseña y la enseñanza sean legibles.
	c.draw_rect(Rect2(0, 0, 768, 675), Color(0.015, 0.02, 0.035, 0.12))
	c.draw_rect(Rect2(0, 438, 768, 282), Color(0.015, 0.025, 0.04, 0.94))
	c.draw_rect(Rect2(18, 452, 354, 168), Color(0.08, 0.11, 0.15, 0.98))
	c.draw_rect(Rect2(18, 452, 354, 5), Color(0.85, 0.16, 0.14))
	c.draw_rect(Rect2(390, 452, 360, 168), Color(0.06, 0.13, 0.10, 0.98))
	c.draw_rect(Rect2(390, 452, 360, 5), Color(0.20, 0.88, 0.40))
	txt(c, "RESEÑA", Vector2(38, 485), 22, Color(1.0, 0.35, 0.28))
	var review := "Un brote biológico arrasó la ciudad. Explora calles destruidas, vehículos abandonados y zonas infestadas; enfréntate a hordas y busca los fragmentos de la cura."
	c.draw_multiline_string(ThemeDB.fallback_font, Vector2(38, 516), review, HORIZONTAL_ALIGNMENT_LEFT, 315, 16, -1, Color(0.88, 0.92, 0.96))
	txt(c, "ENSEÑANZA", Vector2(410, 485), 22, Color(0.35, 1.0, 0.55))
	var lesson := "Mantén la calma, piensa antes de actuar y administra tus recursos. La perseverancia y la cooperación ayudan a superar incluso los momentos más difíciles."
	c.draw_multiline_string(ThemeDB.fallback_font, Vector2(410, 516), lesson, HORIZONTAL_ALIGNMENT_LEFT, 320, 16, -1, Color(0.88, 0.95, 0.90))
	txt(c, "3 VIDAS  ·  REAPARICIÓN CON SALUD COMPLETA  ·  CIUDAD EN RUINAS  ·  BOSQUE INFESTADO  ·  LABORATORIO", Vector2(0, 642), 14, Color(0.45, 0.95, 0.65), HORIZONTAL_ALIGNMENT_CENTER, 768)
	txt(c, "CONTROLES: WASD / FLECHAS  ·  DISPARAR: Z / J / ESPACIO  ·  PAUSA: P / ESC", Vector2(0, 670), 14, Color(0.78, 0.84, 0.90), HORIZONTAL_ALIGNMENT_CENTER, 768)
	if int(state_t * 2.0) % 2 == 0:
		txt(c, "PRESIONA ENTER PARA COMENZAR", Vector2(0, 706), 22, Color(1.0, 0.82, 0.28), HORIZONTAL_ALIGNMENT_CENTER, 768)
