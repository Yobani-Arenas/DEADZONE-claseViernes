class_name Sfx
extends Node
## Sonidos y música generados por código (sin archivos externos).

const RATE := 22050

var streams: Dictionary = {}
var pool: Array = []
var pool_idx := 0
var music: AudioStreamPlayer
var sfx_vol := 0.8
var music_vol := 0.5


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(16):
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	music = AudioStreamPlayer.new()
	add_child(music)
	build_sounds()
	music.stream = make_music()
	apply_volumes()
	music.play()


func apply_volumes() -> void:
	if music:
		music.volume_db = linear_to_db(maxf(0.0001, music_vol * 0.6))


func play(sound: String, vol: float = 1.0, pitch: float = 1.0) -> void:
	if not streams.has(sound) or sfx_vol <= 0.0:
		return
	var p: AudioStreamPlayer = pool[pool_idx]
	pool_idx = (pool_idx + 1) % pool.size()
	p.stream = streams[sound]
	p.volume_db = linear_to_db(maxf(0.0001, vol * sfx_vol))
	p.pitch_scale = pitch * randf_range(0.93, 1.07)
	p.play()


func make(samples: PackedFloat32Array) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	s.data = bytes
	return s


func synth(dur: float, f0: float, f1: float, noise: float, decay: float, vol: float, square: bool) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	var lp := 0.0
	for i in range(n):
		var t := float(i) / float(n)
		phase += TAU * lerpf(f0, f1, t) / RATE
		var tone := sin(phase)
		if square:
			tone = 1.0 if tone > 0.0 else -1.0
		lp = lerpf(lp, randf() * 2.0 - 1.0, 0.35)
		var env := exp(-decay * t) * minf(1.0, (1.0 - t) * 25.0)
		out[i] = (tone * (1.0 - noise) + lp * 2.0 * noise) * env * vol
	return out


func silence(dur: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(dur * RATE))
	return out


func build_sounds() -> void:
	streams["pistol"] = make(synth(0.18, 900.0, 200.0, 0.5, 9.0, 0.8, true))
	streams["shotgun"] = make(synth(0.35, 300.0, 60.0, 0.9, 6.0, 1.0, false))
	streams["rifle"] = make(synth(0.12, 700.0, 150.0, 0.6, 12.0, 0.7, true))
	streams["sniper"] = make(synth(0.5, 500.0, 40.0, 0.8, 5.0, 1.0, false))
	streams["flame"] = make(synth(0.15, 150.0, 120.0, 0.95, 4.0, 0.5, false))
	streams["hit"] = make(synth(0.08, 200.0, 100.0, 0.7, 10.0, 0.6, false))
	streams["zdie"] = make(synth(0.35, 220.0, 60.0, 0.4, 5.0, 0.7, true))
	streams["growl"] = make(synth(0.5, 90.0, 70.0, 0.5, 3.0, 0.4, true))
	streams["hurt"] = make(synth(0.25, 300.0, 100.0, 0.3, 6.0, 0.8, true))
	streams["explosion"] = make(synth(0.8, 120.0, 30.0, 0.95, 3.5, 1.0, false))
	streams["pickup"] = make(synth(0.2, 600.0, 1200.0, 0.0, 5.0, 0.5, false))
	streams["wave"] = make(synth(0.6, 220.0, 440.0, 0.0, 2.0, 0.5, true))
	streams["boss"] = make(synth(1.0, 70.0, 40.0, 0.3, 1.5, 0.9, true))
	streams["empty"] = make(synth(0.06, 1200.0, 1000.0, 0.6, 15.0, 0.5, false))
	streams["buy"] = make(synth(0.15, 800.0, 1300.0, 0.0, 4.0, 0.5, false))
	streams["mine"] = make(synth(0.1, 1500.0, 1500.0, 0.0, 6.0, 0.4, false))
	streams["melee"] = make(synth(0.15, 400.0, 150.0, 0.8, 10.0, 0.6, false))
	streams["spit"] = make(synth(0.25, 500.0, 250.0, 0.3, 6.0, 0.5, false))
	var r := synth(0.05, 1400.0, 900.0, 0.6, 15.0, 0.6, false)
	r.append_array(silence(0.12))
	r.append_array(synth(0.07, 900.0, 500.0, 0.6, 15.0, 0.7, false))
	streams["reload"] = make(r)


func make_music() -> AudioStreamWAV:
	var bpm := 96.0
	var beat := 60.0 / bpm
	var notes := [55.0, 55.0, 65.41, 55.0, 49.0, 49.0, 58.27, 49.0, 55.0, 55.0, 65.41, 73.42, 49.0, 49.0, 46.25, 49.0]
	var n_beats := notes.size()
	var total := int(beat * n_beats * RATE)
	var out := PackedFloat32Array()
	out.resize(total)
	var phase := 0.0
	for i in range(total):
		var t := float(i) / RATE
		var b := int(t / beat) % n_beats
		var bt := fmod(t, beat)
		var f: float = notes[b]
		phase += TAU * f / RATE
		var saw := fmod(phase, TAU) / PI - 1.0
		var env := exp(-2.5 * bt / beat)
		var bass := (saw * 0.5 + sin(phase) * 0.5) * env * 0.35
		var kick_phase := TAU * (40.0 * bt + (80.0 / 30.0) * (1.0 - exp(-30.0 * bt)))
		var kick := sin(kick_phase) * exp(-12.0 * bt) * 0.5
		var bt2 := fmod(t + beat * 0.5, beat)
		var hat := (randf() * 2.0 - 1.0) * exp(-60.0 * bt2) * 0.08
		var pad := sin(TAU * 110.0 * t) * 0.025 * (0.5 + 0.5 * sin(TAU * t / (beat * 8.0)))
		out[i] = clampf(bass + kick + hat + pad, -1.0, 1.0)
	var s := make(out)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = total
	return s
