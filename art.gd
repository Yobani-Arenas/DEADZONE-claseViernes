class_name Art
extends RefCounted
## Carga y cachea las imágenes de res://assets/.
## Si una imagen no existe devuelve null y cada script dibuja entonces su
## versión de respaldo con formas simples (círculos), así el juego nunca se rompe.
## Para usar tu propio arte reemplaza el PNG de assets/ con el mismo nombre.

static var cache: Dictionary = {}


static func tex(tex_name: String) -> Texture2D:
	if cache.has(tex_name):
		return cache[tex_name]
	var t: Texture2D = null
	var path := "res://assets/%s.png" % tex_name
	if ResourceLoader.exists(path):
		t = load(path) as Texture2D
	else:
		# Respaldo: cargar el PNG directamente si Godot aún no lo ha importado.
		var img := Image.new()
		if img.load(ProjectSettings.globalize_path(path)) == OK:
			t = ImageTexture.create_from_image(img)
	cache[tex_name] = t
	return t


## Dibuja la imagen centrada en `center`. Devuelve false si no existe.
static func draw(ci: CanvasItem, tex_name: String, center: Vector2, size: Vector2, mod: Color = Color.WHITE) -> bool:
	var t := tex(tex_name)
	if t == null:
		return false
	ci.draw_texture_rect(t, Rect2(center - size * 0.5, size), false, mod)
	return true


## Igual que draw() pero rotada `rot` radianes alrededor de `center`.
static func draw_rot(ci: CanvasItem, tex_name: String, center: Vector2, rot: float, size: Vector2, mod: Color = Color.WHITE) -> bool:
	var t := tex(tex_name)
	if t == null:
		return false
	ci.draw_set_transform(center, rot, Vector2.ONE)
	ci.draw_texture_rect(t, Rect2(-size * 0.5, size), false, mod)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true
