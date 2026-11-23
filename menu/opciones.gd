extends Control

signal cerrado

const ESCENA_SELECTOR_CANCHA := preload("res://menu/SeleccionCancha.tscn")
const SCRIPT_FEEDBACK_BOTONES := preload("res://menu/feedback_botones.gd")
const PROGRESO := preload("res://menu/progreso.gd")
const TEXTURA_BOTON_MENU: Texture2D = preload("res://Imagenes/ChatGPT Image 16 sept 2026, 17_38_16.png")
const TEXTURA_BOTON_DIFICULTAD: Texture2D = preload("res://Imagenes/boton_dificultad.png")
const TEXTURA_BOTON_CANCHA: Texture2D = preload("res://Imagenes/boton_elegir_cancha.png")
const TEXTURA_BOTON_MONEDAS: Texture2D = preload("res://Imagenes/boton_monedas.png")
const COLOR_CIAN := Color(0.15, 0.82, 1.0, 1.0)
const COLOR_MAGENTA := Color(0.94, 0.25, 1.0, 1.0)
const COLOR_VERDE := Color(0.15, 1.0, 0.55, 1.0)

var pagina_principal: CenterContainer
var pagina_monedas: CenterContainer
var etiqueta_dificultad: Label
var etiqueta_saldo: Label
var etiqueta_estado_monedas: Label
var selector_cancha: Node
var dificultad_actual := 0
var feedback_botones: Node

const NOMBRES_DIFICULTAD := ["FÁCIL", "NORMAL", "DIFÍCIL"]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	feedback_botones = SCRIPT_FEEDBACK_BOTONES.new()
	add_child(feedback_botones)
	get_tree().set_meta("monedas", PROGRESO.obtener_monedas())
	get_tree().set_meta("cancha_seleccionada", PROGRESO.obtener_cancha_seleccionada())
	if not get_tree().has_meta("dificultad_ia"):
		get_tree().set_meta("dificultad_ia", 0)
	dificultad_actual = clampi(int(get_tree().get_meta("dificultad_ia", 0)), 0, 2)
	_construir_interfaz()

	selector_cancha = ESCENA_SELECTOR_CANCHA.instantiate()
	add_child(selector_cancha)
	selector_cancha.connect("cerrado", Callable(self, "_al_cerrar_selector_cancha"))
	selector_cancha.hide()
	hide()


func mostrar() -> void:
	dificultad_actual = clampi(int(get_tree().get_meta("dificultad_ia", 0)), 0, 2)
	_actualizar_dificultad()
	_actualizar_saldo()
	pagina_monedas.hide()
	pagina_principal.show()
	show()


func _construir_interfaz() -> void:
	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.004, 0.008, 0.028, 0.96)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fondo)

	pagina_principal = CenterContainer.new()
	pagina_principal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pagina_principal.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(pagina_principal)

	var columna := VBoxContainer.new()
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override("separation", 5)
	columna.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pagina_principal.add_child(columna)

	var titulo := TextureRect.new()
	titulo.texture = TEXTURA_BOTON_MENU
	titulo.custom_minimum_size = Vector2(390.0, 130.0)
	titulo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	titulo.stretch_mode = TextureRect.STRETCH_SCALE
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = "AJUSTA TU PARTIDA"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	subtitulo.add_theme_font_size_override("font_size", 16)
	columna.add_child(subtitulo)

	var boton_dificultad_menu := _crear_boton_imagen(TEXTURA_BOTON_DIFICULTAD, _cambiar_dificultad)
	columna.add_child(boton_dificultad_menu)
	etiqueta_dificultad = Label.new()
	etiqueta_dificultad.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_dificultad.add_theme_color_override("font_color", COLOR_CIAN)
	etiqueta_dificultad.add_theme_font_size_override("font_size", 15)
	columna.add_child(etiqueta_dificultad)

	columna.add_child(_crear_boton_imagen(TEXTURA_BOTON_CANCHA, _abrir_selector_cancha))
	columna.add_child(_crear_boton_imagen(TEXTURA_BOTON_MONEDAS, _abrir_pagina_monedas))
	columna.add_child(_crear_boton_volver("VOLVER", _volver, Vector2(190.0, 44.0)))
	_actualizar_dificultad()

	pagina_monedas = CenterContainer.new()
	pagina_monedas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pagina_monedas.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(pagina_monedas)
	var columna_monedas := VBoxContainer.new()
	columna_monedas.alignment = BoxContainer.ALIGNMENT_CENTER
	columna_monedas.add_theme_constant_override("separation", 12)
	columna_monedas.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pagina_monedas.add_child(columna_monedas)

	var titulo_monedas := Label.new()
	titulo_monedas.text = "MONEDAS"
	titulo_monedas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo_monedas.add_theme_color_override("font_color", COLOR_VERDE)
	titulo_monedas.add_theme_font_size_override("font_size", 38)
	columna_monedas.add_child(titulo_monedas)

	var texto_saldo := Label.new()
	texto_saldo.text = "SALDO ACTUAL"
	texto_saldo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_saldo.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0))
	texto_saldo.add_theme_font_size_override("font_size", 17)
	columna_monedas.add_child(texto_saldo)

	etiqueta_saldo = Label.new()
	etiqueta_saldo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_saldo.add_theme_color_override("font_color", Color.WHITE)
	etiqueta_saldo.add_theme_color_override("font_shadow_color", Color(0.15, 1.0, 0.55, 0.8))
	etiqueta_saldo.add_theme_font_size_override("font_size", 54)
	columna_monedas.add_child(etiqueta_saldo)

	var nota_monedas := Label.new()
	nota_monedas.text = "Pulsa para recibir 100 monedas gratis cada vez."
	nota_monedas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nota_monedas.add_theme_color_override("font_color", Color(0.7, 0.78, 0.9))
	nota_monedas.add_theme_font_size_override("font_size", 16)
	columna_monedas.add_child(nota_monedas)

	columna_monedas.add_child(_crear_boton_recargar())
	etiqueta_estado_monedas = Label.new()
	etiqueta_estado_monedas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_estado_monedas.add_theme_color_override("font_color", COLOR_VERDE)
	etiqueta_estado_monedas.add_theme_font_size_override("font_size", 15)
	etiqueta_estado_monedas.custom_minimum_size = Vector2(360, 22)
	columna_monedas.add_child(etiqueta_estado_monedas)

	columna_monedas.add_child(_crear_boton_volver("VOLVER", _volver_de_monedas, Vector2(190.0, 44.0)))
	pagina_monedas.hide()


func _crear_boton_imagen(textura: Texture2D, accion: Callable) -> TextureButton:
	var boton := TextureButton.new()
	boton.custom_minimum_size = Vector2(300.0, 100.0)
	boton.texture_normal = textura
	boton.texture_hover = textura
	boton.texture_pressed = textura
	boton.ignore_texture_size = true
	boton.stretch_mode = TextureButton.STRETCH_SCALE
	boton.focus_mode = Control.FOCUS_NONE
	boton.pressed.connect(accion)
	feedback_botones.call("conectar_boton", boton)
	return boton


func _crear_boton_recargar() -> Button:
	var boton := Button.new()
	boton.text = "RECARGAR GRATIS  ·  +100"
	boton.custom_minimum_size = Vector2(300, 52)
	boton.focus_mode = Control.FOCUS_NONE
	boton.add_theme_font_size_override("font_size", 17)
	boton.add_theme_color_override("font_color", Color.WHITE)
	boton.add_theme_stylebox_override("normal", _crear_estilo_acento(COLOR_VERDE, 0.12))
	boton.add_theme_stylebox_override("hover", _crear_estilo_acento(COLOR_VERDE, 0.32))
	boton.add_theme_stylebox_override("pressed", _crear_estilo_acento(COLOR_VERDE, 0.46))
	boton.pressed.connect(_recargar_monedas)
	feedback_botones.call("conectar_boton", boton)
	return boton


func _crear_boton_volver(texto: String, accion: Callable, tamano: Vector2) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = tamano
	boton.focus_mode = Control.FOCUS_NONE
	boton.add_theme_font_size_override("font_size", 15)
	boton.add_theme_color_override("font_color", Color.WHITE)
	boton.add_theme_stylebox_override("normal", _crear_estilo_volver(0.12))
	boton.add_theme_stylebox_override("hover", _crear_estilo_volver(0.32))
	boton.add_theme_stylebox_override("pressed", _crear_estilo_volver(0.45))
	boton.pressed.connect(accion)
	feedback_botones.call("conectar_boton", boton)
	return boton


func _crear_estilo_acento(acento: Color, intensidad: float) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(acento.r * 0.12, acento.g * 0.12, acento.b * 0.12, 0.96)
	estilo.border_color = acento
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(8)
	estilo.shadow_color = Color(acento.r, acento.g, acento.b, intensidad)
	estilo.shadow_size = 8
	return estilo


func _crear_estilo_volver(intensidad: float) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.06, 0.015, 0.1, 0.96)
	estilo.border_color = COLOR_MAGENTA
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(8)
	estilo.shadow_color = Color(COLOR_MAGENTA.r, COLOR_MAGENTA.g, COLOR_MAGENTA.b, intensidad)
	estilo.shadow_size = 7
	return estilo


func _actualizar_dificultad() -> void:
	if is_instance_valid(etiqueta_dificultad):
		etiqueta_dificultad.text = "NIVEL ACTUAL: " + NOMBRES_DIFICULTAD[dificultad_actual]


func _cambiar_dificultad() -> void:
	dificultad_actual = (dificultad_actual + 1) % NOMBRES_DIFICULTAD.size()
	get_tree().set_meta("dificultad_ia", dificultad_actual)
	_actualizar_dificultad()


func _abrir_selector_cancha() -> void:
	pagina_principal.hide()
	selector_cancha.call("mostrar")


func _al_cerrar_selector_cancha() -> void:
	selector_cancha.hide()
	pagina_principal.show()


func _abrir_pagina_monedas() -> void:
	_actualizar_saldo()
	etiqueta_estado_monedas.text = ""
	pagina_principal.hide()
	pagina_monedas.show()


func _actualizar_saldo() -> void:
	var saldo := PROGRESO.obtener_monedas()
	get_tree().set_meta("monedas", saldo)
	if is_instance_valid(etiqueta_saldo):
		etiqueta_saldo.text = str(saldo)


func _recargar_monedas() -> void:
	var nuevo_saldo := PROGRESO.recargar_gratis(100)
	if nuevo_saldo < 0:
		etiqueta_estado_monedas.text = "No se pudo guardar la recarga."
		etiqueta_estado_monedas.add_theme_color_override("font_color", Color(1.0, 0.38, 0.48))
		return
	get_tree().set_meta("monedas", nuevo_saldo)
	_actualizar_saldo()
	etiqueta_estado_monedas.add_theme_color_override("font_color", COLOR_VERDE)
	etiqueta_estado_monedas.text = "¡Se añadieron 100 monedas!"


func _volver_de_monedas() -> void:
	pagina_monedas.hide()
	pagina_principal.show()


func _volver() -> void:
	hide()
	cerrado.emit()
