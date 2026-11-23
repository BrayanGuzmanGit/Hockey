extends Control

const ESCENA_OPCIONES := preload("res://menu/Opciones.tscn")
const SCRIPT_TIENDA_CANCHAS := preload("res://menu/tienda_canchas.gd")
const SCRIPT_FEEDBACK_BOTONES := preload("res://menu/feedback_botones.gd")
const PROGRESO := preload("res://menu/progreso.gd")

var iniciando_juego := false
var opciones: Node
var tienda_canchas: Node
var feedback_botones: Node


func _ready() -> void:
	get_tree().set_meta("monedas", PROGRESO.obtener_monedas())
	get_tree().set_meta("cancha_seleccionada", PROGRESO.obtener_cancha_seleccionada())
	feedback_botones = SCRIPT_FEEDBACK_BOTONES.new()
	add_child(feedback_botones)
	for boton in [
		$CenterContainer/VBoxContainer/TextureButton,
		$CenterContainer/VBoxContainer/TextureButton2,
		$CenterContainer/VBoxContainer/TextureButton3,
		$CenterContainer/VBoxContainer/TextureButton4,
	]:
		feedback_botones.call("conectar_boton", boton)

	$CenterContainer/VBoxContainer/TextureButton3.pressed.connect(_abrir_tienda_canchas)

	opciones = ESCENA_OPCIONES.instantiate()
	add_child(opciones)
	opciones.connect("cerrado", Callable(self, "_cerrar_opciones"))

	tienda_canchas = SCRIPT_TIENDA_CANCHAS.new()
	add_child(tienda_canchas)
	tienda_canchas.connect("cerrado", Callable(self, "_cerrar_tienda_canchas"))
	tienda_canchas.hide()


# Jugar solo y multijugador local comparten la pantalla animada de carga.
func _on_texture_button_pressed() -> void:
	_iniciar_partida(false)


func _on_texture_button_2_pressed() -> void:
	_iniciar_partida(true)


func _iniciar_partida(es_multijugador_local: bool) -> void:
	if iniciando_juego:
		return

	iniciando_juego = true
	get_tree().set_meta("modo_multijugador_local", es_multijugador_local)
	await get_tree().create_timer(0.14).timeout
	$CenterContainer/VBoxContainer/TextureButton.disabled = true
	$CenterContainer/VBoxContainer/TextureButton2.disabled = true
	_abrir_pantalla_de_carga()


func _abrir_pantalla_de_carga() -> void:
	get_tree().change_scene_to_file("res://menu/Cargando.tscn")


func _abrir_tienda_canchas() -> void:
	if iniciando_juego:
		return
	$CenterContainer.hide()
	tienda_canchas.call("mostrar")


func _cerrar_tienda_canchas() -> void:
	tienda_canchas.hide()
	if not iniciando_juego:
		$CenterContainer.show()


func _on_texture_button_4_pressed() -> void:
	if iniciando_juego:
		return

	$CenterContainer.hide()
	opciones.call("mostrar")


func _cerrar_opciones() -> void:
	opciones.hide()
	$CenterContainer.show()


# Se activa al PONER el ratón encima
func _on_texture_button_mouse_entered() -> void:
	if iniciando_juego:
		return
	$CenterContainer/VBoxContainer/TextureButton.modulate = Color(4.5, 4.5, 4.5)


# Se activa al QUITAR el ratón de encima
func _on_texture_button_mouse_exited() -> void:
	if iniciando_juego:
		return
	$CenterContainer/VBoxContainer/TextureButton.modulate = Color(1.0, 1.0, 1.0)


func _on_texture_button_2_mouse_entered() -> void:
	$CenterContainer/VBoxContainer/TextureButton2.modulate = Color(4.5, 4.5, 4.5)


func _on_texture_button_2_mouse_exited() -> void:
	$CenterContainer/VBoxContainer/TextureButton2.modulate = Color(1.0, 1.0, 1.0)


func _on_texture_button_3_mouse_entered() -> void:
	$CenterContainer/VBoxContainer/TextureButton3.modulate = Color(4.5, 4.5, 4.5)


func _on_texture_button_3_mouse_exited() -> void:
	$CenterContainer/VBoxContainer/TextureButton3.modulate = Color(1.0, 1.0, 1.0)


func _on_texture_button_4_mouse_entered() -> void:
	$CenterContainer/VBoxContainer/TextureButton4.modulate = Color(4.5, 4.5, 4.5)


func _on_texture_button_4_mouse_exited() -> void:
	$CenterContainer/VBoxContainer/TextureButton4.modulate = Color(1.0, 1.0, 1.0)
