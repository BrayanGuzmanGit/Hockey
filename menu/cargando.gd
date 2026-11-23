extends Control

const ESCENA_PARTIDA := "res://Niveles/partida.tscn"
const DURACION_MINIMA_CARGA := 7.0

@onready var texto: Label = $CenterContainer/VBoxContainer/Porcentaje
@onready var barra: ProgressBar = $CenterContainer/VBoxContainer/Barra
@onready var logo: TextureRect = $CenterContainer/VBoxContainer/Logo
@onready var fondo_oscuro: ColorRect = $FondoOscuro
@onready var fondo_animado: VideoStreamPlayer = $FondoAnimado

var cambiando_escena := false
var tiempo_cargando := 0.0
var progreso_real := 0.0


func _ready() -> void:
	fondo_animado.finished.connect(_repetir_fondo_sin_audio)
	logo.pivot_offset = logo.custom_minimum_size * 0.5
	fondo_oscuro.color = Color(0.005, 0.012, 0.04, 0.0)
	var fundido := create_tween()
	fundido.tween_property(fondo_oscuro, "color", Color(0.005, 0.012, 0.04, 0.62), 0.4)

	var pulso := create_tween().set_loops()
	pulso.tween_property(logo, "scale", Vector2(1.025, 1.025), 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulso.tween_property(logo, "scale", Vector2.ONE, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var error := ResourceLoader.load_threaded_request(ESCENA_PARTIDA)
	if error != OK:
		set_process(false)
		texto.text = "No se pudo iniciar la carga"
		push_error("No se pudo solicitar la escena: " + ESCENA_PARTIDA)


func _repetir_fondo_sin_audio() -> void:
	# Conserva la animación del menú, pero reproduce su sonido solo una vez.
	fondo_animado.volume_db = -80.0
	fondo_animado.play()


func _process(_delta: float) -> void:
	if cambiando_escena:
		return

	tiempo_cargando += _delta

	var progreso: Array = []
	var estado := ResourceLoader.load_threaded_get_status(ESCENA_PARTIDA, progreso)

	if not progreso.is_empty():
		progreso_real = maxf(progreso_real, progreso[0])

	if estado == ResourceLoader.THREAD_LOAD_LOADED:
		progreso_real = 1.0

	# La barra refleja la carga real, pero también tarda al menos siete segundos.
	var progreso_por_tiempo := clampf(tiempo_cargando / DURACION_MINIMA_CARGA, 0.0, 1.0)
	var progreso_mostrado := minf(progreso_real, progreso_por_tiempo)
	var porcentaje := clampi(roundi(progreso_mostrado * 100.0), 1, 99)
	barra.value = porcentaje
	texto.text = "Cargando %d%%" % porcentaje

	if estado == ResourceLoader.THREAD_LOAD_LOADED and tiempo_cargando >= DURACION_MINIMA_CARGA:
		cambiando_escena = true
		barra.value = 100
		texto.text = "Cargando 100%"
		await get_tree().create_timer(0.2).timeout

		var partida := ResourceLoader.load_threaded_get(ESCENA_PARTIDA) as PackedScene
		if partida == null:
			texto.text = "No se pudo abrir la partida"
			push_error("El recurso cargado no es una escena: " + ESCENA_PARTIDA)
			return

		get_tree().change_scene_to_packed(partida)
	elif estado == ResourceLoader.THREAD_LOAD_FAILED or estado == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		cambiando_escena = true
		texto.text = "Error al cargar la partida"
		push_error("Falló la carga de: " + ESCENA_PARTIDA)
