extends Control

signal cerrado

const TEXTURA_CLASICA: Texture2D = preload("res://Imagenes/cancha.png")
const TEXTURA_NEON: Texture2D = preload("res://Imagenes/cancha_neon.svg")
const VIDEO_CANCHA_NEON: VideoStream = preload("res://Cancha/cancha2.ogv")
const SCRIPT_FEEDBACK_BOTONES := preload("res://menu/feedback_botones.gd")
const SCRIPT_CANDADO := preload("res://menu/candado.gd")
const PROGRESO := preload("res://menu/progreso.gd")
const COLOR_CIAN := Color(0.05, 0.84, 1.0, 1.0)
const COLOR_MAGENTA := Color(0.92, 0.2, 1.0, 1.0)
const COLOR_VERDE := Color(0.1, 1.0, 0.58, 1.0)

var cancha_elegida := 0
var etiqueta_seleccion: Label
var etiqueta_saldo: Label
var tarjetas: Array[PanelContainer] = []
var etiquetas_detalle: Array[Label] = []
var iconos_candado: Array[Control] = []
var botones_tarjeta: Array[Button] = []
var previsualizacion_animada: VideoStreamPlayer
var feedback_botones: Node

const NOMBRES := ["ARENA CLÁSICA", "ARENA NEÓN", "ARENA NEÓN ANIMADA"]
const ACENTOS := [COLOR_CIAN, COLOR_MAGENTA, COLOR_VERDE]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	feedback_botones = SCRIPT_FEEDBACK_BOTONES.new()
	add_child(feedback_botones)
	get_tree().set_meta("monedas", PROGRESO.obtener_monedas())
	get_tree().set_meta("cancha_seleccionada", PROGRESO.obtener_cancha_seleccionada())
	_construir_interfaz()
	_actualizar_seleccion()
	hide()


func mostrar() -> void:
	cancha_elegida = PROGRESO.obtener_cancha_seleccionada()
	get_tree().set_meta("cancha_seleccionada", cancha_elegida)
	_actualizar_seleccion()
	if is_instance_valid(previsualizacion_animada):
		previsualizacion_animada.play()
	show()


func _construir_interfaz() -> void:
	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.005, 0.009, 0.035, 0.93)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fondo)

	var centrador := CenterContainer.new()
	centrador.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centrador.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(centrador)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 10)
	columna.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	centrador.add_child(columna)

	var titulo := Label.new()
	titulo.text = "ELIGE TU CANCHA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_color_override("font_color", COLOR_CIAN)
	titulo.add_theme_font_size_override("font_size", 38)
	columna.add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = "Selecciona una cancha desbloqueada para tu próxima partida"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.add_theme_color_override("font_color", Color(0.82, 0.91, 1.0))
	subtitulo.add_theme_font_size_override("font_size", 17)
	columna.add_child(subtitulo)

	etiqueta_saldo = Label.new()
	etiqueta_saldo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_saldo.add_theme_color_override("font_color", COLOR_VERDE)
	etiqueta_saldo.add_theme_font_size_override("font_size", 17)
	columna.add_child(etiqueta_saldo)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	columna.add_child(fila)

	fila.add_child(_crear_tarjeta_textura("ARENA CLÁSICA", "Cancha principal", TEXTURA_CLASICA, 0, COLOR_CIAN))
	fila.add_child(_crear_tarjeta_textura("ARENA NEÓN", "Versión estática", TEXTURA_NEON, 1, COLOR_MAGENTA))
	fila.add_child(_crear_tarjeta_video("ARENA NEÓN ANIMADA", "Video Ogg Theora", VIDEO_CANCHA_NEON, 2, COLOR_VERDE))

	etiqueta_seleccion = Label.new()
	etiqueta_seleccion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_seleccion.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	etiqueta_seleccion.add_theme_font_size_override("font_size", 17)
	etiqueta_seleccion.custom_minimum_size = Vector2(760, 42)
	columna.add_child(etiqueta_seleccion)

	var acciones := HBoxContainer.new()
	acciones.alignment = BoxContainer.ALIGNMENT_CENTER
	acciones.add_theme_constant_override("separation", 18)
	columna.add_child(acciones)

	acciones.add_child(_crear_boton("VOLVER", COLOR_MAGENTA, _volver))
	acciones.add_child(_crear_boton("USAR CANCHA", COLOR_CIAN, _confirmar))


func _crear_tarjeta_textura(
	nombre: String,
	descripcion: String,
	textura: Texture2D,
	indice: int,
	acento: Color
) -> PanelContainer:
	var vista_previa := TextureRect.new()
	vista_previa.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vista_previa.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	vista_previa.texture = textura
	return _crear_tarjeta(nombre, descripcion, vista_previa, indice, acento)


func _crear_tarjeta_video(
	nombre: String,
	descripcion: String,
	video: VideoStream,
	indice: int,
	acento: Color
) -> PanelContainer:
	previsualizacion_animada = VideoStreamPlayer.new()
	previsualizacion_animada.stream = video
	previsualizacion_animada.autoplay = false
	previsualizacion_animada.loop = true
	previsualizacion_animada.volume_db = -80.0
	previsualizacion_animada.expand = true
	return _crear_tarjeta(nombre, descripcion, previsualizacion_animada, indice, acento)


func _crear_tarjeta(
	nombre: String,
	descripcion: String,
	vista_previa: Control,
	indice: int,
	acento: Color
) -> PanelContainer:
	var tarjeta := PanelContainer.new()
	tarjeta.custom_minimum_size = Vector2(340, 314)
	tarjeta.add_theme_stylebox_override("panel", _crear_estilo_tarjeta(acento, false))
	tarjetas.append(tarjeta)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 7)
	tarjeta.add_child(columna)

	var titulo := Label.new()
	titulo.text = nombre
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_color_override("font_color", acento)
	titulo.add_theme_font_size_override("font_size", 19)
	columna.add_child(titulo)

	vista_previa.custom_minimum_size = Vector2(312, 174)
	vista_previa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vista_previa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(vista_previa)

	var fila_estado := HBoxContainer.new()
	fila_estado.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_estado.custom_minimum_size = Vector2(0, 22)
	fila_estado.add_theme_constant_override("separation", 5)
	columna.add_child(fila_estado)

	var candado: Control = SCRIPT_CANDADO.new()
	candado.custom_minimum_size = Vector2(20, 20)
	candado.call("set_color_acento", acento)
	fila_estado.add_child(candado)
	iconos_candado.append(candado)

	var detalle := Label.new()
	detalle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detalle.add_theme_color_override("font_color", Color(0.78, 0.86, 1.0))
	detalle.add_theme_font_size_override("font_size", 14)
	fila_estado.add_child(detalle)
	etiquetas_detalle.append(detalle)

	var boton := _crear_boton("SELECCIONAR", acento, _seleccionar.bind(indice))
	boton.custom_minimum_size = Vector2(0, 40)
	columna.add_child(boton)
	botones_tarjeta.append(boton)
	return tarjeta


func _crear_boton(texto: String, acento: Color, accion: Callable) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(190, 44)
	boton.add_theme_font_size_override("font_size", 16)
	boton.add_theme_color_override("font_color", Color.WHITE)
	boton.add_theme_color_override("font_hover_color", Color.WHITE)
	boton.add_theme_stylebox_override("normal", _crear_estilo_boton(acento, 0.12))
	boton.add_theme_stylebox_override("hover", _crear_estilo_boton(acento, 0.28))
	boton.add_theme_stylebox_override("pressed", _crear_estilo_boton(acento, 0.42))
	boton.add_theme_stylebox_override("focus", _crear_estilo_boton(acento, 0.2))
	boton.pressed.connect(accion)
	feedback_botones.call("conectar_boton", boton)
	return boton


func _crear_estilo_boton(acento: Color, intensidad: float) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(acento.r * 0.16, acento.g * 0.16, acento.b * 0.16, 0.95)
	estilo.border_color = acento
	_establecer_bordes(estilo, 2)
	_establecer_esquinas(estilo, 8)
	estilo.shadow_color = Color(acento.r, acento.g, acento.b, intensidad)
	estilo.shadow_size = 8
	return estilo


func _crear_estilo_tarjeta(acento: Color, seleccionada: bool) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.025, 0.04, 0.09, 0.97)
	estilo.border_color = acento if seleccionada else Color(acento.r, acento.g, acento.b, 0.45)
	_establecer_bordes(estilo, 4 if seleccionada else 2)
	_establecer_esquinas(estilo, 12)
	estilo.shadow_color = Color(acento.r, acento.g, acento.b, 0.38 if seleccionada else 0.12)
	estilo.shadow_size = 14 if seleccionada else 5
	return estilo


func _establecer_bordes(estilo: StyleBoxFlat, grosor: int) -> void:
	estilo.border_width_left = grosor
	estilo.border_width_top = grosor
	estilo.border_width_right = grosor
	estilo.border_width_bottom = grosor


func _establecer_esquinas(estilo: StyleBoxFlat, radio: int) -> void:
	estilo.corner_radius_top_left = radio
	estilo.corner_radius_top_right = radio
	estilo.corner_radius_bottom_right = radio
	estilo.corner_radius_bottom_left = radio


func _seleccionar(indice: int) -> void:
	if not PROGRESO.obtener_canchas_desbloqueadas().has(indice):
		_actualizar_seleccion("Esta cancha está bloqueada. Cómprala en la tienda verde del menú principal.")
		return
	cancha_elegida = indice
	_actualizar_seleccion("Lista para usar.")


func _actualizar_seleccion(mensaje: String = "") -> void:
	if is_instance_valid(etiqueta_saldo):
		var saldo := PROGRESO.obtener_monedas()
		etiqueta_saldo.text = "MONEDAS: %d" % saldo
		get_tree().set_meta("monedas", saldo)

	if not is_instance_valid(etiqueta_seleccion):
		_actualizar_tarjetas()
		return

	var indice_seguro := clampi(cancha_elegida, 0, NOMBRES.size() - 1)
	var texto: String = "SELECCIÓN ACTUAL: " + str(NOMBRES[indice_seguro])
	if not mensaje.is_empty():
		texto += "\n" + mensaje
	etiqueta_seleccion.text = texto
	_actualizar_tarjetas()


func _actualizar_tarjetas() -> void:
	var desbloqueadas := PROGRESO.obtener_canchas_desbloqueadas()
	for indice in range(tarjetas.size()):
		var desbloqueada := desbloqueadas.has(indice)
		iconos_candado[indice].visible = not desbloqueada
		if desbloqueada:
			if indice == 0:
				etiquetas_detalle[indice].text = "GRATIS · SIEMPRE DISPONIBLE"
			else:
				etiquetas_detalle[indice].text = "DESBLOQUEADA · COMPRADA"
			botones_tarjeta[indice].text = "SELECCIONADA" if indice == cancha_elegida else "SELECCIONAR"
		else:
			etiquetas_detalle[indice].text = "BLOQUEADA · VE A TIENDA"
			botones_tarjeta[indice].text = "CERRADA"

		tarjetas[indice].add_theme_stylebox_override(
			"panel",
			_crear_estilo_tarjeta(ACENTOS[indice], indice == cancha_elegida)
		)


func _detener_previsualizacion() -> void:
	if is_instance_valid(previsualizacion_animada):
		previsualizacion_animada.stop()


func _confirmar() -> void:
	if not PROGRESO.guardar_cancha_seleccionada(cancha_elegida):
		_actualizar_seleccion("No se pudo guardar la cancha seleccionada.")
		return
	get_tree().set_meta("cancha_seleccionada", cancha_elegida)
	get_tree().set_meta("monedas", PROGRESO.obtener_monedas())
	_detener_previsualizacion()
	cerrado.emit()


func _volver() -> void:
	_detener_previsualizacion()
	cerrado.emit()
