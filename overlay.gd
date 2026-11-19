class_name Overlay
extends Control
## Capa de interfaz (texto nítido a resolución completa). Delega el dibujo en main.gd.

var main = null


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if main != null:
		main.draw_overlay(self)
