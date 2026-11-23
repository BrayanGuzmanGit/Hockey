extends Control

signal cerrado

const TEXTURA_CLASICA: Texture2D = preload("res://Imagenes/cancha.png")
const TEXTURA_NEON: Texture2D = preload("res://Imagenes/cancha_neon.svg")
const VIDEO_CANCHA_NEON: VideoStream = preload("res://Cancha/cancha2.ogv")
const SCRIPT_FEEDBACK_BOTONES := preload("res://menu/feedback_botones.gd")
const SCRIPT_CANDADO := preload("res://menu/candado.gd")
const PROGRESO := preload("res://menu/progreso.gd")
const COLORES := [
	Color(0.05, 0.84, 1.0, 1.0),
	Color(0.92, 0.2, 1.0, 1.0),
	Color(0.1, 1.0, 0.58, 1.0),
]
const NOMBRES := ["ARENA CLÁSICA", "ARENA NEÓN", "ARENA NEÓN ANIMADA"]

var etiqueta_saldo: Label
var etiqueta_mensaje: Label
var detalles: Array[Label] = []
var candados: Array[Control] = []
var botones_compra: Array[Button] = []
var tarjetas: Array[PanelContainer] = []
var previsualizacion_animada: VideoStreamPlayer
var feedback_botones: Node


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	feedback_botones = SCRIPT_FEEDBACK_BOTONES.new()
	add_child(feedback_botones)
	_construir_interfaz()
	_actualizar_tienda()
	hide()


func mostrar() -> void:
	_actualizar_tienda()
	if is_instance_valid(previsualizacion_animada):
		previsualizacion_animada.play()
	show()


func _construir_interfaz() -> void:
	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.004, 0.008, 0.028, 0.98)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fondo)

	var centrador := CenterContainer.new()
	centrador.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centrador.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(centrador)

	var columna := VBoxContainer.new()
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override("separation", 8)
	columna.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	centrador.add_child(columna)

	var titulo := Label.new()
	titulo.text = "TIENDA DE CANCHAS"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_color_override("font_color", Color(0.15, 1.0, 0.55, 1.0))
	titulo.add_theme_font_size_override("font_size", 38)
	columna.add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = "Desbloquea nuevas arenas con tus monedas"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.add_theme_color_override("font_color", Color(0.82, 0.91, 1.0))
	subtitulo.add_theme_font_size_override("font_size", 17)
	columna.add_child(subtitulo)

	etiqueta_saldo = Label.new()
	etiqueta_saldo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_saldo.add_theme_color_override("font_color", Color(0.1, 1.0, 0.58, 1.0))
	etiqueta_saldo.add_theme_font_size_override("font_size", 18)
	columna.add_child(etiqueta_saldo)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	columna.add_child(fila)
	fila.add_child(_crear_tarjeta_textura(TEXTURA_CLASICA, 0))
	fila.add_child(_crear_tarjeta_textura(TEXTURA_NEON, 1))
	fila.add_child(_crear_tarjeta_video(VIDEO_CANCHA_NEON, 2))

	etiqueta_mensaje = Label.new()
	etiqueta_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta_mensaje.custom_minimum_size = Vector2(800, 34)
	etiqueta_mensaje.add_theme_color_override("font_color", Color(0.78, 0.86, 1.0))
	etiqueta_mensaje.add_theme_font_size_override("font_size", 15)
	columna.add_child(etiqueta_mensaje)

	var acciones := HBoxContainer.new()
	acciones.alignment = BoxContainer.ALIGNMENT_CENTER
	acciones.add_theme_constant_override("separation", 18)
	columna.add_child(acciones)
	acciones.add_child(_crear_boton("VOLVER", Color(0.92, 0.2, 1.0, 1.0), _volver))


func _crear_tarjeta_textura(textura: Texture2D, indice: int) -> PanelContainer:
	var vista := TextureRect.new()
	vista.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vista.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	vista.texture = textura
	return _crear_tarjeta(vista, indice)


func _crear_tarjeta_video(video: VideoStream, indice: int) -> PanelContainer:
	previsualizacion_animada = VideoStreamPlayer.new()
	previsualizacion_animada.stream = video
	previsualizacion_animada.autoplay = false
	previsualizacion_animada.loop = true
	previsualizacion_animada.volume_db = -80.0
	previsualizacion_animada.expand = true
	return _crear_tarjeta(previsualizacion_animada, indice)


func _crear_tarjeta(vista: Control, indice: int) -> PanelContainer:
	var acento: Color = COLORES[indice]
	var tarjeta := PanelContainer.new()
	tarjeta.custom_minimum_size = Vector2(340, 314)
	tarjeta.add_theme_stylebox_override("panel", _crear_estilo_tarjeta(acento, false))
	tarjetas.append(tarjeta)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 7)
	tarjeta.add_child(columna)

	var titulo := Label.new()
	titulo.text = NOMBRES[indice]
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_color_override("font_color", acento)
	titulo.add_theme_font_size_override("font_size", 19)
	columna.add_child(titulo)

	vista.custom_minimum_size = Vector2(312, 174)
	vista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(vista)

	var fila_estado := HBoxContainer.new()
	fila_estado.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_estado.custom_minimum_size = Vector2(0, 22)
	fila_estado.add_theme_constant_override("separation", 6)
	columna.add_child(fila_estado)

	var icono_candado: Control = SCRIPT_CANDADO.new()
	icono_candado.custom_minimum_size = Vector2(20, 20)
	icono_candado.call("set_color_acento", acento)
	fila_estado.add_child(icono_candado)
	candados.append(icono_candado)

	var detalle := Label.new()
	detalle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detalle.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0))
	detalle.add_theme_font_size_override("font_size", 14)
	fila_estado.add_child(detalle)
	detalles.append(detalle)

	var boton := _crear_boton("COMPRAR", acento, _comprar_cancha.bind(indice))
	boton.custom_minimum_size = Vector2(312, 40)
	columna.add_child(boton)
	botones_compra.append(boton)
	return tarjeta


func _crear_boton(texto: String, acento: Color, accion: Callable) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(190, 44)
	boton.focus_mode = Control.FOCUS_NONE
	boton.add_theme_font_size_override("font_size", 16)
	boton.add_theme_color_override("font_color", Color.WHITE)
	boton.add_theme_color_override("font_hover_color", Color.WHITE)
	boton.add_theme_stylebox_override("normal", _crear_estilo_boton(acento, 0.12))
	boton.add_theme_stylebox_override("hover", _crear_estilo_boton(acento, 0.28))
	boton.add_theme_stylebox_override("pressed", _crear_estilo_boton(acento, 0.42))
	boton.add_theme_stylebox_override("disabled", _crear_estilo_boton(acento, 0.05))
	boton.pressed.connect(accion)
	feedback_botones.call("conectar_boton", boton)
	return boton


func _crear_estilo_boton(acento: Color, intensidad: float) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(acento.r * 0.16, acento.g * 0.16, acento.b * 0.16, 0.95)
	estilo.border_color = Color(acento.r, acento.g, acento.b, maxf(0.3, 1.0 - intensidad))
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(8)
	estilo.shadow_color = Color(acento.r, acento.g, acento.b, intensidad)
	estilo.shadow_size = 7
	return estilo


func _crear_estilo_tarjeta(acento: Color, seleccionada: bool) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.025, 0.04, 0.09, 0.97)
	estilo.border_color = acento if seleccionada else Color(acento.r, acento.g, acento.b, 0.52)
	estilo.set_border_width_all(3 if seleccionada else 2)
	estilo.set_corner_radius_all(12)
	estilo.shadow_color = Color(acento.r, acento.g, acento.b, 0.28 if seleccionada else 0.12)
	estilo.shadow_size = 12 if seleccionada else 5
	return estilo


func _actualizar_tienda() -> void:
	var saldo := PROGRESO.obtener_monedas()
	var desbloqueadas := PROGRESO.obtener_canchas_desbloqueadas()
	etiqueta_saldo.text = "MONEDAS: %d" % saldo
	get_tree().set_meta("monedas", saldo)

	for indice in range(botones_compra.size()):
		var desbloqueada := desbloqueadas.has(indice)
		candados[indice].visible = not desbloqueada
		tarjetas[indice].add_theme_stylebox_override(
			"panel",
			_crear_estilo_tarjeta(COLORES[indice], false)
		)
		if indice == 0:
			detalles[indice].text = "SIEMPRE DISPONIBLE · GRATIS"
			botones_compra[indice].text = "CANCHA PRINCIPAL"
			botones_compra[indice].disabled = true
		elif desbloqueada:
			detalles[indice].text = "DESBLOQUEADA"
			botones_compra[indice].text = "COMPRADA"
			botones_compra[indice].disabled = true
		else:
			var precio := PROGRESO.precio_cancha(indice)
			detalles[indice].text = "BLOQUEADA · %d MONEDAS" % precio
			botones_compra[indice].text = "COMPRAR · %d" % precio
			botones_compra[indice].disabled = false

	if etiqueta_mensaje.text.is_empty():
		etiqueta_mensaje.text = "Las canchas compradas se podrán elegir desde Opciones → Elegir cancha."


func _comprar_cancha(indice: int) -> void:
	var resultado := PROGRESO.comprar_cancha(indice)
	match resultado:
		PROGRESO.RESULTADO_COMPRA_OK:
			etiqueta_mensaje.add_theme_color_override("font_color", Color(0.1, 1.0, 0.58, 1.0))
			etiqueta_mensaje.text = "%s desbloqueada. Ahora puedes elegirla desde Opciones → Elegir cancha." % NOMBRES[indice]
			_actualizar_tienda()
		PROGRESO.RESULTADO_SALDO_INSUFICIENTE:
			var faltante := PROGRESO.precio_cancha(indice) - PROGRESO.obtener_monedas()
			etiqueta_mensaje.add_theme_color_override("font_color", Color(1.0, 0.48, 0.62, 1.0))
			etiqueta_mensaje.text = "Te faltan %d monedas. Recarga gratis desde Opciones → Monedas." % faltante
		PROGRESO.RESULTADO_YA_DESBLOQUEADA:
			etiqueta_mensaje.add_theme_color_override("font_color", Color(0.78, 0.86, 1.0))
			etiqueta_mensaje.text = "Ya está desbloqueada. Puedes elegirla desde Opciones → Elegir cancha."
		_:
			etiqueta_mensaje.add_theme_color_override("font_color", Color(1.0, 0.48, 0.62, 1.0))
			etiqueta_mensaje.text = "No se pudo completar la compra. Inténtalo de nuevo."
	_actualizar_tienda()


func _volver() -> void:
	if is_instance_valid(previsualizacion_animada):
		previsualizacion_animada.stop()
	cerrado.emit()
