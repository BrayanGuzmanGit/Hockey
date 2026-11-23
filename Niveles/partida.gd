extends Node2D

const POSICION_INICIAL_DISCO := Vector2(581.0, 316.0)
const POSICION_INICIAL_JUGADOR := Vector2(168.0, 313.0)
const POSICION_INICIAL_IA := Vector2(950.0, 325.0)
const TEXTURA_CANCHA_NEON := preload("res://Imagenes/cancha_neon.svg")
const VIDEO_CANCHA_NEON: VideoStream = preload("res://Cancha/cancha2.ogv")
const META_PREGUNTAS := "res://Niveles/preguntas.json"
const SCRIPT_FEEDBACK_BOTONES := preload("res://menu/feedback_botones.gd")
const DURACION_PODER := 10.0
const DURACION_TRIVIA := 15.0

enum EstadoPartida { JUGANDO, GOL, TRIVIA, RESULTADO_TRIVIA, FINALIZADA }
enum TipoPoder { NINGUNO, VELOCIDAD, BARRERA, MAZO_GRANDE, FRENAR_RIVAL }

@onready var disco: RigidBody2D = $Disco
@onready var jugador: CharacterBody2D = $Personaje
@onready var oponente: CharacterBody2D = $OponenteIA
@onready var cancha: StaticBody2D = $Cancha
@onready var porteria_jugador: Area2D = $Cancha/PorteríaJugador
@onready var porteria_ia: Area2D = $Cancha/PorteríaIA

var reinicio_en_curso := false
var posicion_disco_anterior := Vector2.ZERO
var video_fondo: VideoStreamPlayer
var puntos_jugador := 0
var puntos_oponente := 0
var marcador_jugador: Label
var marcador_oponente: Label
var marcador_vs: Label
var feedback_botones: Node
var estado_partida := EstadoPartida.JUGANDO
var modo_multijugador_local := false
var velocidades_base: Array[float] = [2200.0, 520.0]
var escalas_base: Array[Vector2] = [Vector2.ONE, Vector2.ONE]
var poderes_disponibles: Array[int] = [TipoPoder.NINGUNO, TipoPoder.NINGUNO]
var poderes_activos: Array[int] = [TipoPoder.NINGUNO, TipoPoder.NINGUNO]
var tiempos_poder: Array[float] = [0.0, 0.0]
var barreras: Array[StaticBody2D] = [null, null]
var etiquetas_poder: Array[Label] = []
var botones_poder: Array[Button] = []
var preguntas_catalogo: Array[Dictionary] = []
var preguntas_disponibles: Array[Dictionary] = []
var preguntas_trivia: Array[Dictionary] = []
var respuestas_trivia: Array = [null, null]
var jugador_trivia_activo := 0
var tiempos_trivia: Array[float] = [DURACION_TRIVIA, DURACION_TRIVIA]
var etiquetas_tiempo_trivia: Array[Label] = []
var etiquetas_estado_trivia: Array[Label] = []
var botones_trivia: Array = []
var tarjetas_trivia: Array[Control] = []
var panel_trivia: CanvasLayer
var temporizador_ia_trivia := 0.0
var tiempo_resultado_trivia := 0.0
var rng := RandomNumberGenerator.new()
var etiquetas_estado_poder: Array[Label] = []


func _ready() -> void:
	modo_multijugador_local = bool(get_tree().get_meta("modo_multijugador_local", false))
	feedback_botones = SCRIPT_FEEDBACK_BOTONES.new()
	add_child(feedback_botones)
	if modo_multijugador_local:
		jugador.set("control_ia", false)
		jugador.set("control_teclado_local", true)
		jugador.set("jugador_local", 1)
		oponente.set("control_ia", false)
		oponente.set("control_teclado_local", true)
		oponente.set("jugador_local", 2)
	_aplicar_dificultad_ia()
	_crear_marcador(modo_multijugador_local)
	_crear_interfaz_poderes()
	randomize()
	rng.randomize()
	_cargar_preguntas()
	velocidades_base[0] = _leer_velocidad(jugador)
	velocidades_base[1] = _leer_velocidad(oponente)
	escalas_base[0] = jugador.scale
	escalas_base[1] = oponente.scale

	var cancha_seleccionada := int(get_tree().get_meta("cancha_seleccionada", 0))
	if cancha_seleccionada == 1:
		cancha.get_node("Sprite2D").texture = TEXTURA_CANCHA_NEON
	elif cancha_seleccionada == 2:
		_iniciar_fondo_animado()

	posicion_disco_anterior = disco.global_position


func _process(delta: float) -> void:
	match estado_partida:
		EstadoPartida.JUGANDO:
			_actualizar_poderes(delta)
			_gestionar_poder_ia()
		EstadoPartida.TRIVIA:
			_actualizar_trivia(delta)
		EstadoPartida.RESULTADO_TRIVIA:
			tiempo_resultado_trivia -= delta
			if tiempo_resultado_trivia <= 0.0:
				_cerrar_trivia_y_reanudar()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var tecla_evento := event as InputEventKey
	if not tecla_evento.pressed or tecla_evento.echo:
		return
	var tecla := tecla_evento.keycode
	if estado_partida == EstadoPartida.TRIVIA:
		match tecla:
			KEY_1:
				_responder_trivia(0, 0)
			KEY_2:
				_responder_trivia(0, 1)
			KEY_3:
				_responder_trivia(0, 2)
			KEY_4:
				_responder_trivia(0, 3)
			KEY_7:
				_responder_trivia(1, 0)
			KEY_8:
				_responder_trivia(1, 1)
			KEY_9:
				_responder_trivia(1, 2)
			KEY_0:
				_responder_trivia(1, 3)
		get_viewport().set_input_as_handled()
		return
	if estado_partida != EstadoPartida.JUGANDO:
		return
	if (modo_multijugador_local and tecla == KEY_E) or (not modo_multijugador_local and tecla == KEY_SPACE):
		_activar_poder(0)
	elif tecla == KEY_ENTER or tecla == KEY_KP_ENTER:
		if modo_multijugador_local:
			_activar_poder(1)


func _aplicar_dificultad_ia() -> void:
	if modo_multijugador_local:
		return
	var dificultad := clampi(int(get_tree().get_meta("dificultad_ia", 0)), 0, 2)
	match dificultad:
		0:
			oponente.set("velocidad_ia", 350.0)
			oponente.set("demora_reaccion_ia", 0.24)
			oponente.set("impulso_minimo_golpe_ia", 20.0)
			oponente.set("impulso_maximo_golpe_ia", 190.0)
		1:
			oponente.set("velocidad_ia", 520.0)
			oponente.set("demora_reaccion_ia", 0.14)
			oponente.set("impulso_minimo_golpe_ia", 45.0)
			oponente.set("impulso_maximo_golpe_ia", 340.0)
		2:
			oponente.set("velocidad_ia", 760.0)
			oponente.set("demora_reaccion_ia", 0.07)
			oponente.set("impulso_minimo_golpe_ia", 80.0)
			oponente.set("impulso_maximo_golpe_ia", 560.0)


func _iniciar_fondo_animado() -> void:
	cancha.get_node("Sprite2D").hide()

	var capa_fondo := CanvasLayer.new()
	capa_fondo.layer = -1
	add_child(capa_fondo)

	var contenedor := Control.new()
	contenedor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contenedor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_fondo.add_child(contenedor)

	video_fondo = VideoStreamPlayer.new()
	video_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	video_fondo.stream = VIDEO_CANCHA_NEON
	video_fondo.expand = true
	video_fondo.loop = true
	video_fondo.volume_db = -80.0
	video_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenedor.add_child(video_fondo)
	video_fondo.play()


func _physics_process(_delta: float) -> void:
	if estado_partida != EstadoPartida.JUGANDO or reinicio_en_curso:
		return

	var posicion_actual := disco.global_position
	var gol_jugador := _cruzo_arco(posicion_disco_anterior, posicion_actual, porteria_ia, false)
	var gol_ia := _cruzo_arco(posicion_disco_anterior, posicion_actual, porteria_jugador, true)
	posicion_disco_anterior = posicion_actual

	if gol_jugador or gol_ia:
		estado_partida = EstadoPartida.GOL
		reinicio_en_curso = true
		disco.freeze = true
		disco.linear_velocity = Vector2.ZERO
		disco.angular_velocity = 0.0
		jugador.set_physics_process(false)
		oponente.set_physics_process(false)
		if gol_jugador:
			puntos_jugador += 1
			marcador_jugador.text = str(puntos_jugador)
			_animar_punto(marcador_jugador)
		else:
			puntos_oponente += 1
			marcador_oponente.text = str(puntos_oponente)
			_animar_punto(marcador_oponente)
		_mostrar_gol()
		call_deferred("_continuar_despues_del_gol", 0 if gol_jugador else 1)


func _crear_marcador(multijugador_local: bool) -> void:
	var capa := CanvasLayer.new()
	capa.name = "Marcador"
	capa.layer = 10
	add_child(capa)

	var interfaz := Control.new()
	interfaz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	interfaz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(interfaz)

	var placa := PanelContainer.new()
	placa.name = "PlacaMarcador"
	placa.anchor_left = 0.5
	placa.anchor_right = 0.5
	placa.anchor_top = 0.0
	placa.anchor_bottom = 0.0
	placa.offset_left = -216.0
	placa.offset_right = 216.0
	placa.offset_top = 1.0
	placa.offset_bottom = 37.0
	placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placa.add_theme_stylebox_override(
		"panel",
		_estilo_marcador(Color(0.012, 0.027, 0.06, 0.98), Color(0.12, 0.72, 1.0), 13, 2, 4)
	)
	interfaz.add_child(placa)

	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_theme_constant_override("separation", 8)
	placa.add_child(fila)

	var nombre_izquierdo := "JUGADOR 1" if multijugador_local else "TÚ"
	var dificultad := clampi(int(get_tree().get_meta("dificultad_ia", 0)), 0, 2)
	var nombres_dificultad := ["FÁCIL", "NORMAL", "DIFÍCIL"]
	var nombre_derecho: String
	if multijugador_local:
		nombre_derecho = "JUGADOR 2"
	else:
		nombre_derecho = "IA · %s" % nombres_dificultad[dificultad]
	var equipo_izquierdo := _crear_equipo_marcador(
		nombre_izquierdo,
		Color(0.28, 0.91, 1.0),
		Color(0.015, 0.13, 0.2, 0.96),
		false
	)
	var equipo_derecho := _crear_equipo_marcador(
		nombre_derecho,
		Color(1.0, 0.28, 0.69),
		Color(0.17, 0.025, 0.105, 0.97),
		true
	)
	marcador_jugador = equipo_izquierdo["puntos"] as Label
	marcador_oponente = equipo_derecho["puntos"] as Label
	fila.add_child(equipo_izquierdo["panel"] as PanelContainer)

	var placa_vs := PanelContainer.new()
	placa_vs.custom_minimum_size = Vector2(42.0, 28.0)
	placa_vs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placa_vs.add_theme_stylebox_override(
		"panel",
		_estilo_marcador(Color(0.035, 0.055, 0.09, 1.0), Color(0.39, 0.69, 0.91), 15, 1, 2)
	)
	var etiqueta_vs := Label.new()
	etiqueta_vs.text = "VS"
	etiqueta_vs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiqueta_vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_vs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta_vs.add_theme_font_size_override("font_size", 13)
	etiqueta_vs.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0))
	placa_vs.add_child(etiqueta_vs)
	marcador_vs = etiqueta_vs
	fila.add_child(placa_vs)
	fila.add_child(equipo_derecho["panel"] as PanelContainer)


func _crear_equipo_marcador(
	nombre: String,
	color: Color,
	fondo: Color,
	puntuacion_primero: bool
) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(164.0, 32.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override(
		"panel",
		_estilo_marcador(fondo, color, 10, 2, 3)
	)
	var contenido := HBoxContainer.new()
	contenido.alignment = BoxContainer.ALIGNMENT_CENTER
	contenido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenido.add_theme_constant_override("separation", 6)
	panel.add_child(contenido)

	var etiqueta_nombre := Label.new()
	etiqueta_nombre.text = nombre
	etiqueta_nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiqueta_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_nombre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	etiqueta_nombre.add_theme_font_size_override("font_size", 13)
	etiqueta_nombre.add_theme_color_override("font_color", color)

	var etiqueta_puntos := Label.new()
	etiqueta_puntos.name = "Puntos"
	etiqueta_puntos.text = "0"
	etiqueta_puntos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiqueta_puntos.custom_minimum_size = Vector2(30.0, 28.0)
	etiqueta_puntos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_puntos.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta_puntos.add_theme_font_size_override("font_size", 23)
	etiqueta_puntos.add_theme_color_override("font_color", Color(0.96, 0.99, 1.0))
	etiqueta_puntos.add_theme_color_override(
		"font_shadow_color",
		Color(color.r, color.g, color.b, 0.76)
	)
	etiqueta_puntos.add_theme_constant_override("shadow_offset_x", 0)
	etiqueta_puntos.add_theme_constant_override("shadow_offset_y", 2)
	if puntuacion_primero:
		contenido.add_child(etiqueta_puntos)
		contenido.add_child(etiqueta_nombre)
	else:
		contenido.add_child(etiqueta_nombre)
		contenido.add_child(etiqueta_puntos)
	return {"panel": panel, "puntos": etiqueta_puntos}


func _estilo_marcador(
	fondo: Color,
	borde: Color,
	radio: int,
	grosor_borde: int,
	tamano_sombra: int
) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = fondo
	estilo.border_color = borde
	estilo.set_border_width_all(grosor_borde)
	estilo.set_corner_radius_all(radio)
	estilo.shadow_color = Color(borde.r, borde.g, borde.b, 0.34)
	estilo.shadow_size = tamano_sombra
	estilo.shadow_offset = Vector2(0.0, -1.0)
	estilo.content_margin_left = 10.0
	estilo.content_margin_top = 1.0
	estilo.content_margin_right = 10.0
	estilo.content_margin_bottom = 1.0
	return estilo


func _animar_punto(etiqueta: Label) -> void:
	etiqueta.pivot_offset = etiqueta.size * 0.5
	var animacion := create_tween()
	animacion.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animacion.tween_property(etiqueta, "scale", Vector2(1.3, 1.3), 0.14)
	animacion.tween_property(etiqueta, "scale", Vector2.ONE, 0.24)


func _mostrar_gol() -> void:
	marcador_vs.text = "¡GOL!"
	marcador_vs.add_theme_color_override("font_color", Color(1.0, 0.84, 0.34))
	marcador_vs.pivot_offset = marcador_vs.size * 0.5
	var animacion := create_tween()
	animacion.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animacion.tween_property(marcador_vs, "scale", Vector2(1.18, 1.18), 0.12)
	animacion.tween_property(marcador_vs, "scale", Vector2.ONE, 0.2)
	get_tree().create_timer(0.85).timeout.connect(_restaurar_vs, CONNECT_ONE_SHOT)


func _restaurar_vs() -> void:
	marcador_vs.text = "VS"
	marcador_vs.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0))


func _cruzo_arco(anterior: Vector2, actual: Vector2, arco: Area2D, hacia_izquierda: bool) -> bool:
	var colision_arco := arco.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var colision_disco := disco.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if colision_arco == null or colision_disco == null:
		return false

	var forma_arco := colision_arco.shape as RectangleShape2D
	var forma_disco := colision_disco.shape as CircleShape2D
	if forma_arco == null or forma_disco == null:
		return false

	var centro_arco := colision_arco.global_position
	var escala_arco := Vector2(
		absf(colision_arco.global_scale.x),
		absf(colision_arco.global_scale.y)
	)
	var mitad_arco := forma_arco.size * escala_arco * 0.5
	var radio_disco := forma_disco.radius * maxf(
		absf(colision_disco.global_scale.x),
		absf(colision_disco.global_scale.y)
	)
	var x_umbral: float
	if hacia_izquierda:
		x_umbral = centro_arco.x + mitad_arco.x - radio_disco
		if not (anterior.x > x_umbral and actual.x <= x_umbral):
			return false
	else:
		x_umbral = centro_arco.x - mitad_arco.x + radio_disco
		if not (anterior.x < x_umbral and actual.x >= x_umbral):
			return false

	var desplazamiento_x := actual.x - anterior.x
	if is_zero_approx(desplazamiento_x):
		return false
	var proporcion := (x_umbral - anterior.x) / desplazamiento_x
	var y_al_cruzar := lerpf(anterior.y, actual.y, proporcion)

	# El centro debe cruzar la línea y el círculo completo debe caber en la boca.
	return (
		y_al_cruzar - radio_disco >= centro_arco.y - mitad_arco.y
		and y_al_cruzar + radio_disco <= centro_arco.y + mitad_arco.y
	)


func _continuar_despues_del_gol(lado_goleador: int) -> void:
	await get_tree().create_timer(0.85).timeout
	_restaurar_vs()
	_reubicar_jugadores_y_disco()
	if puntos_jugador >= 7 or puntos_oponente >= 7:
		_mostrar_victoria()
		return
	if (puntos_jugador + puntos_oponente) % 3 == 0:
		if _iniciar_trivia():
			return
	_reanudar_partida()


func _reubicar_jugadores_y_disco() -> void:
	disco.freeze = true
	disco.global_position = POSICION_INICIAL_DISCO
	posicion_disco_anterior = POSICION_INICIAL_DISCO
	disco.linear_velocity = Vector2.ZERO
	disco.angular_velocity = 0.0
	disco.sleeping = false
	jugador.reiniciar_en(POSICION_INICIAL_JUGADOR)
	oponente.reiniciar_en(POSICION_INICIAL_IA)


func _reanudar_partida() -> void:
	if estado_partida == EstadoPartida.FINALIZADA:
		return
	jugador.set_physics_process(true)
	oponente.set_physics_process(true)
	disco.freeze = false
	disco.sleeping = false
	reinicio_en_curso = false
	estado_partida = EstadoPartida.JUGANDO


func _mostrar_victoria() -> void:
	estado_partida = EstadoPartida.FINALIZADA
	reinicio_en_curso = true
	var ganador := 0 if puntos_jugador >= 7 else 1
	var nombre_ganador := "TÚ" if ganador == 0 else "IA"
	if modo_multijugador_local:
		nombre_ganador = "JUGADOR 1" if ganador == 0 else "JUGADOR 2"
	var capa := CanvasLayer.new()
	capa.name = "PantallaVictoria"
	capa.layer = 40
	add_child(capa)
	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.004, 0.008, 0.028, 0.9)
	capa.add_child(fondo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa.add_child(centro)
	var tarjeta := PanelContainer.new()
	tarjeta.custom_minimum_size = Vector2(520.0, 290.0)
	tarjeta.add_theme_stylebox_override("panel", _estilo_marcador(Color(0.015, 0.025, 0.07, 0.99), Color(0.16, 0.82, 1.0), 22, 2, 18))
	centro.add_child(tarjeta)
	var columna := VBoxContainer.new()
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override("separation", 17)
	tarjeta.add_child(columna)
	var titulo := Label.new()
	titulo.text = "¡VICTORIA!"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 38)
	titulo.add_theme_color_override("font_color", Color(0.28, 0.91, 1.0))
	columna.add_child(titulo)
	var ganador_label := Label.new()
	ganador_label.text = "%s GANA" % nombre_ganador
	ganador_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ganador_label.add_theme_font_size_override("font_size", 25)
	ganador_label.add_theme_color_override("font_color", Color.WHITE)
	columna.add_child(ganador_label)
	var resultado := Label.new()
	resultado.text = "%d  —  %d" % [puntos_jugador, puntos_oponente]
	resultado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resultado.add_theme_font_size_override("font_size", 24)
	resultado.add_theme_color_override("font_color", Color(1.0, 0.35, 0.75))
	columna.add_child(resultado)
	var volver := Button.new()
	volver.text = "VOLVER AL MENÚ"
	volver.custom_minimum_size = Vector2(250.0, 52.0)
	volver.add_theme_font_size_override("font_size", 17)
	volver.add_theme_color_override("font_color", Color.WHITE)
	volver.add_theme_stylebox_override("normal", _estilo_marcador(Color(0.12, 0.025, 0.12, 1.0), Color(1.0, 0.25, 0.72), 10, 2, 7))
	volver.add_theme_stylebox_override("hover", _estilo_marcador(Color(0.2, 0.035, 0.18, 1.0), Color(1.0, 0.45, 0.82), 10, 2, 10))
	volver.pressed.connect(_volver_al_menu)
	feedback_botones.call("conectar_boton", volver)
	columna.add_child(volver)


func _volver_al_menu() -> void:
	get_tree().change_scene_to_file("res://menu/MENU.tscn")


func _cargar_preguntas() -> void:
	if not FileAccess.file_exists(META_PREGUNTAS):
		push_error("No se encontró el archivo de preguntas: " + META_PREGUNTAS)
		return
	var contenido := FileAccess.get_file_as_string(META_PREGUNTAS)
	var datos: Variant = JSON.parse_string(contenido)
	if not (datos is Array):
		push_error("El archivo de preguntas debe contener una lista JSON.")
		return
	for entrada in datos:
		if not (entrada is Dictionary):
			continue
		if not entrada.has("pregunta") or not entrada.has("materia"):
			continue
		if not entrada.has("opciones") or not (entrada.opciones is Array) or entrada.opciones.size() != 4:
			continue
		if not entrada.has("respuesta_correcta") or not entrada.opciones.has(entrada.respuesta_correcta):
			continue
		preguntas_catalogo.append(entrada)
	preguntas_disponibles.clear()
	for pregunta in preguntas_catalogo:
		preguntas_disponibles.append(pregunta.duplicate(true))
	preguntas_disponibles.shuffle()
	if preguntas_catalogo.is_empty():
		push_error("No hay preguntas válidas para iniciar la trivia.")


func _sacar_dos_preguntas() -> Array[Dictionary]:
	if preguntas_disponibles.size() < 2:
		if preguntas_catalogo.size() < 2:
			return []
		preguntas_disponibles.clear()
		for pregunta in preguntas_catalogo:
			preguntas_disponibles.append(pregunta.duplicate(true))
		preguntas_disponibles.shuffle()
	var elegidas: Array[Dictionary] = []
	for _i in range(2):
		if preguntas_disponibles.is_empty():
			break
		elegidas.append(preguntas_disponibles.pop_back())
	return elegidas


func _iniciar_trivia() -> bool:
	preguntas_trivia = _sacar_dos_preguntas()
	if preguntas_trivia.size() != 2:
		push_error("No se pudo cargar una pregunta para cada participante; la partida continuará.")
		return false
	estado_partida = EstadoPartida.TRIVIA
	reinicio_en_curso = true
	respuestas_trivia = [null, null]
	jugador_trivia_activo = 0
	tiempos_trivia = [DURACION_TRIVIA, DURACION_TRIVIA]
	var demora_ia := _obtener_demora_trivia_ia()
	temporizador_ia_trivia = rng.randf_range(demora_ia.x, demora_ia.y)
	_construir_interfaz_trivia()
	return true


func _obtener_demora_trivia_ia() -> Vector2:
	var dificultad := clampi(int(get_tree().get_meta("dificultad_ia", 0)), 0, 2)
	match dificultad:
		0:
			return Vector2(5.0, 8.0)
		1:
			return Vector2(3.0, 5.5)
		_:
			return Vector2(1.0, 3.0)


func _construir_interfaz_trivia() -> void:
	panel_trivia = CanvasLayer.new()
	panel_trivia.name = "Trivia"
	panel_trivia.layer = 30
	add_child(panel_trivia)
	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.005, 0.008, 0.025, 0.93)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	panel_trivia.add_child(fondo)
	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 26)
	margen.add_theme_constant_override("margin_right", 26)
	margen.add_theme_constant_override("margin_top", 62)
	margen.add_theme_constant_override("margin_bottom", 38)
	panel_trivia.add_child(margen)
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 16)
	margen.add_child(columna)
	var titulo := Label.new()
	titulo.text = "RONDA DE TRIVIA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 30)
	titulo.add_theme_color_override("font_color", Color(0.31, 0.91, 1.0))
	columna.add_child(titulo)
	var subtitulo := Label.new()
	subtitulo.text = "RESPONDE ANTES DE 15 SEGUNDOS PARA GANAR UN PODER"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.add_theme_font_size_override("font_size", 13)
	subtitulo.add_theme_color_override("font_color", Color(0.76, 0.84, 0.96))
	columna.add_child(subtitulo)
	var tarjetas := HBoxContainer.new()
	tarjetas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tarjetas.add_theme_constant_override("separation", 18)
	columna.add_child(tarjetas)
	etiquetas_tiempo_trivia.clear()
	etiquetas_estado_trivia.clear()
	botones_trivia.clear()
	tarjetas_trivia.clear()
	for lado in range(2):
		var color_jugador := Color(0.15, 0.84, 1.0) if lado == 0 else Color(1.0, 0.27, 0.72)
		var tarjeta := PanelContainer.new()
		tarjeta.visible = not modo_multijugador_local or lado == 0
		tarjeta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tarjeta.add_theme_stylebox_override("panel", _estilo_marcador(Color(0.014, 0.022, 0.055, 0.99), color_jugador, 16, 2, 12))
		tarjetas.add_child(tarjeta)
		tarjetas_trivia.append(tarjeta)
		var contenido := VBoxContainer.new()
		contenido.add_theme_constant_override("separation", 8)
		tarjeta.add_child(contenido)
		var cabecera := HBoxContainer.new()
		contenido.add_child(cabecera)
		var nombre := Label.new()
		if modo_multijugador_local:
			nombre.text = "JUGADOR 1 · TECLAS 1–4" if lado == 0 else "JUGADOR 2 · TECLAS 7–0"
		else:
			nombre.text = "TÚ · TECLAS 1–4" if lado == 0 else "IA · RESPONDE AUTOMÁTICAMENTE"
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nombre.add_theme_font_size_override("font_size", 15)
		nombre.add_theme_color_override("font_color", color_jugador)
		cabecera.add_child(nombre)
		var reloj := Label.new()
		reloj.text = "15 s"
		reloj.add_theme_font_size_override("font_size", 18)
		reloj.add_theme_color_override("font_color", Color.WHITE)
		cabecera.add_child(reloj)
		etiquetas_tiempo_trivia.append(reloj)
		var materia := Label.new()
		materia.text = str(preguntas_trivia[lado].get("materia", "General")).to_upper()
		materia.add_theme_font_size_override("font_size", 12)
		materia.add_theme_color_override("font_color", color_jugador)
		contenido.add_child(materia)
		var pregunta := Label.new()
		pregunta.text = str(preguntas_trivia[lado].get("pregunta", ""))
		pregunta.custom_minimum_size = Vector2(0.0, 68.0)
		pregunta.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pregunta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pregunta.add_theme_font_size_override("font_size", 17)
		pregunta.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
		contenido.add_child(pregunta)
		var botones_lado: Array[Button] = []
		var opciones: Array = preguntas_trivia[lado].get("opciones", [])
		for indice in range(4):
			var boton := _crear_boton_opcion(lado, indice, str(opciones[indice]), color_jugador)
			contenido.add_child(boton)
			botones_lado.append(boton)
		botones_trivia.append(botones_lado)
		var estado := Label.new()
		if lado == 1 and not modo_multijugador_local:
			estado.text = "La IA está pensando…"
		else:
			estado.text = "Elige una respuesta"
		estado.custom_minimum_size = Vector2(0.0, 24.0)
		estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		estado.add_theme_font_size_override("font_size", 13)
		estado.add_theme_color_override("font_color", Color(0.72, 0.8, 0.92))
		contenido.add_child(estado)
		etiquetas_estado_trivia.append(estado)


func _crear_boton_opcion(lado: int, indice: int, texto: String, acento: Color) -> Button:
	var boton := Button.new()
	boton.custom_minimum_size = Vector2(0.0, 47.0)
	boton.focus_mode = Control.FOCUS_NONE
	boton.text = ""
	boton.add_theme_stylebox_override("normal", _estilo_marcador(Color(0.035, 0.055, 0.095, 1.0), Color(acento.r, acento.g, acento.b, 0.56), 8, 1, 2))
	boton.add_theme_stylebox_override("hover", _estilo_marcador(Color(0.07, 0.1, 0.16, 1.0), acento, 8, 2, 5))
	boton.add_theme_stylebox_override("pressed", _estilo_marcador(Color(0.1, 0.12, 0.2, 1.0), acento, 8, 2, 3))
	var etiqueta := Label.new()
	etiqueta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	etiqueta.offset_left = 12.0
	etiqueta.offset_right = -12.0
	etiqueta.offset_top = 3.0
	etiqueta.offset_bottom = -3.0
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tecla_opcion := str(indice + 1)
	if lado == 1 and modo_multijugador_local:
		tecla_opcion = ["7", "8", "9", "0"][indice]
	etiqueta.text = "%s. %s" % [tecla_opcion, texto]
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_size_override("font_size", 13)
	etiqueta.add_theme_color_override("font_color", Color(0.91, 0.95, 1.0))
	boton.add_child(etiqueta)
	if lado == 1 and not modo_multijugador_local:
		boton.disabled = true
	boton.pressed.connect(_responder_trivia.bind(lado, indice))
	feedback_botones.call("conectar_boton", boton)
	return boton


func _actualizar_trivia(delta: float) -> void:
	if modo_multijugador_local:
		_actualizar_trivia_multijugador_local(delta)
		return
	if respuestas_trivia[1] == null:
		temporizador_ia_trivia -= delta
		if temporizador_ia_trivia <= 0.0:
			_respuesta_ia_trivia()
	for lado in range(2):
		if respuestas_trivia[lado] != null:
			continue
		tiempos_trivia[lado] = maxf(0.0, tiempos_trivia[lado] - delta)
		etiquetas_tiempo_trivia[lado].text = "%d s" % ceili(tiempos_trivia[lado])
		if tiempos_trivia[lado] <= 0.0:
			_registrar_respuesta_trivia(lado, -1)
	if respuestas_trivia[0] != null and respuestas_trivia[1] != null:
		_estado_resultado_trivia()


func _actualizar_trivia_multijugador_local(delta: float) -> void:
	var lado := jugador_trivia_activo
	if lado < 0 or lado >= respuestas_trivia.size() or respuestas_trivia[lado] != null:
		return
	tiempos_trivia[lado] = maxf(0.0, tiempos_trivia[lado] - delta)
	etiquetas_tiempo_trivia[lado].text = "%d s" % ceili(tiempos_trivia[lado])
	if tiempos_trivia[lado] <= 0.0:
		_registrar_respuesta_trivia(lado, -1)


func _estado_resultado_trivia() -> void:
	estado_partida = EstadoPartida.RESULTADO_TRIVIA
	tiempo_resultado_trivia = 1.5


func _respuesta_ia_trivia() -> void:
	if respuestas_trivia[1] != null:
		return
	var dificultad := clampi(int(get_tree().get_meta("dificultad_ia", 0)), 0, 2)
	var probabilidades: Array[float] = [0.42, 0.68, 0.9]
	var probabilidad: float = probabilidades[dificultad]
	var opciones: Array = preguntas_trivia[1].get("opciones", [])
	var correcta := opciones.find(preguntas_trivia[1].get("respuesta_correcta", ""))
	var elegida := correcta
	if rng.randf() > probabilidad:
		var incorrectas: Array[int] = []
		for i in range(opciones.size()):
			if i != correcta:
				incorrectas.append(i)
		elegida = incorrectas[rng.randi_range(0, incorrectas.size() - 1)]
	_registrar_respuesta_trivia(1, elegida)


func _responder_trivia(lado: int, indice: int) -> void:
	if estado_partida != EstadoPartida.TRIVIA or respuestas_trivia[lado] != null:
		return
	if lado == 1 and not modo_multijugador_local:
		return
	if modo_multijugador_local and lado != jugador_trivia_activo:
		return
	_registrar_respuesta_trivia(lado, indice)


func _registrar_respuesta_trivia(lado: int, indice: int) -> void:
	var opciones: Array = preguntas_trivia[lado].get("opciones", [])
	var correcta := opciones.find(preguntas_trivia[lado].get("respuesta_correcta", ""))
	var acertada := indice >= 0 and indice == correcta
	respuestas_trivia[lado] = acertada
	etiquetas_tiempo_trivia[lado].text = "LISTO"
	var estado := etiquetas_estado_trivia[lado]
	if indice < 0:
		estado.text = "Tiempo agotado · sin poder"
	elif acertada:
		estado.text = "¡Correcto! Poder al terminar la ronda"
	else:
		if poderes_disponibles[lado] != TipoPoder.NINGUNO or poderes_activos[lado] != TipoPoder.NINGUNO:
			estado.text = "Incorrecto · conservas tu poder anterior"
		else:
			estado.text = "Incorrecto · no recibes poder"
	for i in range(botones_trivia[lado].size()):
		var boton := botones_trivia[lado][i] as Button
		boton.disabled = true
		if i == correcta:
			boton.modulate = Color(0.62, 1.0, 0.74)
		elif i == indice:
			boton.modulate = Color(1.0, 0.48, 0.48)
	if indice < 0:
		estado.add_theme_color_override("font_color", Color(1.0, 0.72, 0.38))
	elif acertada:
		estado.add_theme_color_override("font_color", Color(0.48, 1.0, 0.66))
	else:
		estado.add_theme_color_override("font_color", Color(1.0, 0.54, 0.54))

	if modo_multijugador_local:
		if lado == 0:
			jugador_trivia_activo = 1
			tiempos_trivia[1] = DURACION_TRIVIA
			etiquetas_tiempo_trivia[1].text = "%d s" % ceili(tiempos_trivia[1])
			etiquetas_estado_trivia[1].text = "Turno del jugador 2 · responde ahora"
			tarjetas_trivia[0].hide()
			tarjetas_trivia[1].show()
		else:
			for tarjeta in tarjetas_trivia:
				tarjeta.show()
			_estado_resultado_trivia()


func _cerrar_trivia_y_reanudar() -> void:
	if is_instance_valid(panel_trivia):
		panel_trivia.queue_free()
	panel_trivia = null
	for lado in range(2):
		if bool(respuestas_trivia[lado]):
			_otorgar_poder(lado)
	_reanudar_partida()


func _otorgar_poder(lado: int) -> void:
	if not bool(respuestas_trivia[lado]):
		return
	if poderes_disponibles[lado] != TipoPoder.NINGUNO or poderes_activos[lado] != TipoPoder.NINGUNO:
		if etiquetas_estado_poder.size() == 2:
			etiquetas_estado_poder[lado].text = "PODER OCUPADO · no se acumula"
		return
	poderes_disponibles[lado] = rng.randi_range(TipoPoder.VELOCIDAD, TipoPoder.FRENAR_RIVAL)
	_actualizar_hud_poderes()
	if etiquetas_estado_poder.size() == 2:
		etiquetas_estado_poder[lado].text = "¡Respuesta correcta! Poder obtenido"


func _crear_interfaz_poderes() -> void:
	var capa := CanvasLayer.new()
	capa.name = "HudPoderes"
	capa.layer = 11
	add_child(capa)
	var raiz := Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(raiz)
	etiquetas_poder.clear()
	botones_poder.clear()
	etiquetas_estado_poder.clear()
	for lado in range(2):
		var acento := Color(0.15, 0.84, 1.0) if lado == 0 else Color(1.0, 0.27, 0.72)
		var panel := PanelContainer.new()
		panel.anchor_left = 0.0 if lado == 0 else 1.0
		panel.anchor_right = 0.0 if lado == 0 else 1.0
		panel.anchor_top = 1.0
		panel.anchor_bottom = 1.0
		panel.offset_left = 16.0 if lado == 0 else -326.0
		panel.offset_right = 326.0 if lado == 0 else -16.0
		panel.offset_top = -78.0
		panel.offset_bottom = -12.0
		panel.add_theme_stylebox_override("panel", _estilo_marcador(Color(0.01, 0.025, 0.055, 0.94), acento, 10, 2, 5))
		raiz.add_child(panel)
		var columna := VBoxContainer.new()
		columna.add_theme_constant_override("separation", 3)
		panel.add_child(columna)
		var fila := HBoxContainer.new()
		columna.add_child(fila)
		var etiqueta := Label.new()
		etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		etiqueta.add_theme_font_size_override("font_size", 12)
		etiqueta.add_theme_color_override("font_color", Color.WHITE)
		fila.add_child(etiqueta)
		etiquetas_poder.append(etiqueta)
		var boton := Button.new()
		boton.custom_minimum_size = Vector2(94.0, 29.0)
		boton.focus_mode = Control.FOCUS_NONE
		boton.add_theme_font_size_override("font_size", 11)
		boton.add_theme_color_override("font_color", Color.WHITE)
		boton.add_theme_stylebox_override("normal", _estilo_marcador(Color(0.055, 0.07, 0.12, 1.0), acento, 7, 1, 2))
		boton.add_theme_stylebox_override("hover", _estilo_marcador(Color(0.1, 0.14, 0.2, 1.0), acento, 7, 2, 4))
		boton.pressed.connect(_activar_poder.bind(lado))
		feedback_botones.call("conectar_boton", boton)
		fila.add_child(boton)
		botones_poder.append(boton)
		var estado := Label.new()
		if lado == 0:
			estado.text = "TÚ · BARRA ESPACIADORA" if not modo_multijugador_local else "EQUIPO IZQUIERDO"
		elif modo_multijugador_local:
			estado.text = "EQUIPO DERECHO"
		else:
			estado.text = "IA · ADMINISTRA SUS PODERES"
		estado.add_theme_font_size_override("font_size", 10)
		estado.add_theme_color_override("font_color", Color(0.65, 0.75, 0.89))
		columna.add_child(estado)
		etiquetas_estado_poder.append(estado)
	_actualizar_hud_poderes()


func _actualizar_hud_poderes() -> void:
	if etiquetas_poder.size() != 2:
		return
	for lado in range(2):
		var tipo := poderes_disponibles[lado]
		var boton := botones_poder[lado]
		if poderes_activos[lado] != TipoPoder.NINGUNO:
			etiquetas_poder[lado].text = "%s · %.1f s" % [_nombre_poder(poderes_activos[lado]), tiempos_poder[lado]]
			boton.text = "EN USO"
			boton.disabled = true
		elif tipo != TipoPoder.NINGUNO:
			etiquetas_poder[lado].text = "LISTO: " + _nombre_poder(tipo)
			if lado == 1 and not modo_multijugador_local:
				boton.text = "IA DECIDE"
				boton.disabled = true
			else:
				boton.text = "USAR [ESPACIO]" if not modo_multijugador_local else ("USAR [E]" if lado == 0 else "USAR [ENTER]")
				boton.disabled = false
		else:
			etiquetas_poder[lado].text = "SIN PODER DISPONIBLE"
			boton.text = "SIN PODER"
			boton.disabled = true


func _nombre_poder(tipo: int) -> String:
	match tipo:
		TipoPoder.VELOCIDAD:
			return "+30% VELOCIDAD"
		TipoPoder.BARRERA:
			return "BARRERA DE ARCO"
		TipoPoder.MAZO_GRANDE:
			return "MAZO GRANDE"
		TipoPoder.FRENAR_RIVAL:
			return "FRENAR RIVAL"
	return "SIN PODER"


func _activar_poder(lado: int) -> void:
	if estado_partida != EstadoPartida.JUGANDO or poderes_disponibles[lado] == TipoPoder.NINGUNO:
		return
	poderes_activos[lado] = poderes_disponibles[lado]
	poderes_disponibles[lado] = TipoPoder.NINGUNO
	tiempos_poder[lado] = DURACION_PODER
	if poderes_activos[lado] == TipoPoder.BARRERA:
		_crear_barrera(lado)
	_actualizar_modificadores()
	_actualizar_hud_poderes()
	if etiquetas_estado_poder.size() == 2:
		etiquetas_estado_poder[lado].text = "Poder activo durante 10 segundos"


func _actualizar_poderes(delta: float) -> void:
	var cambio := false
	for lado in range(2):
		if poderes_activos[lado] == TipoPoder.NINGUNO:
			continue
		tiempos_poder[lado] = maxf(0.0, tiempos_poder[lado] - delta)
		if tiempos_poder[lado] <= 0.0:
			if poderes_activos[lado] == TipoPoder.BARRERA:
				_eliminar_barrera(lado)
			poderes_activos[lado] = TipoPoder.NINGUNO
			cambio = true
	if cambio:
		_actualizar_modificadores()
	_actualizar_hud_poderes()


func _crear_barrera(lado: int) -> void:
	_eliminar_barrera(lado)
	var barrera := StaticBody2D.new()
	barrera.name = "BarreraProteccionJugador" if lado == 0 else "BarreraProteccionRival"
	barrera.global_position = Vector2(89.0, 317.0) if lado == 0 else Vector2(1074.0, 317.0)
	barrera.z_index = 5
	add_child(barrera)
	var forma := CollisionShape2D.new()
	var rectangulo := RectangleShape2D.new()
	rectangulo.size = Vector2(14.0, 190.0)
	forma.shape = rectangulo
	barrera.add_child(forma)
	var acento := Color(0.18, 0.86, 1.0) if lado == 0 else Color(1.0, 0.28, 0.72)
	var resplandor := Polygon2D.new()
	resplandor.polygon = PackedVector2Array([Vector2(-11, -96), Vector2(11, -96), Vector2(11, 96), Vector2(-11, 96)])
	resplandor.color = Color(acento.r, acento.g, acento.b, 0.2)
	barrera.add_child(resplandor)
	var nucleo := Polygon2D.new()
	nucleo.polygon = PackedVector2Array([Vector2(-4, -94), Vector2(4, -94), Vector2(4, 94), Vector2(-4, 94)])
	nucleo.color = Color(acento.r, acento.g, acento.b, 0.84)
	barrera.add_child(nucleo)
	barreras[lado] = barrera


func _eliminar_barrera(lado: int) -> void:
	if is_instance_valid(barreras[lado]):
		barreras[lado].queue_free()
	barreras[lado] = null


func _leer_velocidad(personaje: CharacterBody2D) -> float:
	var usa_ia := bool(personaje.get("control_ia"))
	return float(personaje.get("velocidad_ia" if usa_ia else "velocidad_maxima"))


func _actualizar_modificadores() -> void:
	for lado in range(2):
		var factor := 1.0
		if poderes_activos[lado] == TipoPoder.VELOCIDAD:
			factor *= 1.3
		var rival := 1 - lado
		if poderes_activos[rival] == TipoPoder.FRENAR_RIVAL:
			factor *= 0.5
		var personaje: CharacterBody2D = jugador if lado == 0 else oponente
		var propiedad := "velocidad_ia" if bool(personaje.get("control_ia")) else "velocidad_maxima"
		personaje.set(propiedad, velocidades_base[lado] * factor)
		personaje.scale = escalas_base[lado] * (1.28 if poderes_activos[lado] == TipoPoder.MAZO_GRANDE else 1.0)


func _gestionar_poder_ia() -> void:
	if not bool(oponente.get("control_ia")) or poderes_disponibles[1] == TipoPoder.NINGUNO:
		return
	var posicion_disco := disco.global_position
	var cerca_de_porteria := posicion_disco.x >= 835.0
	var en_mitad_ia := posicion_disco.x >= 580.0
	var cerca_del_juego := oponente.global_position.distance_to(posicion_disco) < 330.0
	var debe_usar := false
	match poderes_disponibles[1]:
		TipoPoder.BARRERA:
			debe_usar = cerca_de_porteria
		TipoPoder.FRENAR_RIVAL:
			debe_usar = posicion_disco.x < 720.0 and cerca_del_juego
		TipoPoder.VELOCIDAD, TipoPoder.MAZO_GRANDE:
			debe_usar = en_mitad_ia and cerca_del_juego
	if debe_usar:
		_activar_poder(1)


