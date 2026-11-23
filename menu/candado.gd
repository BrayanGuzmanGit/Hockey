extends Control

@export var color_acento: Color = Color(0.9, 0.95, 1.0, 1.0)


func _draw() -> void:
	var centro_x := size.x * 0.5
	var radio := minf(size.x * 0.28, size.y * 0.25)
	var centro_arco := Vector2(centro_x, size.y * 0.56)
	draw_arc(centro_arco, radio, PI, TAU, 18, color_acento, 2.2, true)

	var cuerpo := Rect2(
		Vector2(size.x * 0.2, size.y * 0.5),
		Vector2(size.x * 0.6, size.y * 0.42)
	)
	draw_rect(cuerpo, Color(0.025, 0.035, 0.07, 1.0))
	draw_rect(cuerpo, color_acento, false, 2.0, true)
	draw_circle(Vector2(centro_x, size.y * 0.68), maxf(1.2, size.x * 0.045), color_acento)


func set_color_acento(color: Color) -> void:
	color_acento = color
	queue_redraw()
