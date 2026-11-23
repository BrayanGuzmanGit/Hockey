extends Node

const META_CONECTADO: StringName = &"feedback_boton_conectado"
const META_ESCALA_BASE: StringName = &"feedback_boton_escala_base"
const ESCALA_HOVER := 1.045
const ESCALA_PRESION := 0.94
const DURACION_HOVER := 0.12
const DURACION_PRESION := 0.07

var animaciones: Dictionary = {}
var botones_presionados: Dictionary = {}


func conectar_boton(boton: BaseButton) -> void:
	if not is_instance_valid(boton) or boton.has_meta(META_CONECTADO):
		return

	boton.set_meta(META_CONECTADO, true)
	boton.set_meta(META_ESCALA_BASE, boton.scale)
	boton.mouse_entered.connect(_al_entrar.bind(boton))
	boton.mouse_exited.connect(_al_salir.bind(boton))
	boton.button_down.connect(_al_presionar.bind(boton))
	boton.button_up.connect(_al_soltar.bind(boton))


func _al_entrar(boton: BaseButton) -> void:
	if not boton.disabled:
		_animar(boton, ESCALA_HOVER, DURACION_HOVER)


func _al_salir(boton: BaseButton) -> void:
	if not botones_presionados.has(boton.get_instance_id()):
		_animar(boton, 1.0, DURACION_HOVER)


func _al_presionar(boton: BaseButton) -> void:
	botones_presionados[boton.get_instance_id()] = true
	_animar(boton, ESCALA_PRESION, DURACION_PRESION)


func _al_soltar(boton: BaseButton) -> void:
	botones_presionados.erase(boton.get_instance_id())
	_animar(boton, ESCALA_HOVER if boton.is_hovered() else 1.0, DURACION_HOVER)


func _animar(boton: BaseButton, factor: float, duracion: float) -> void:
	if not is_instance_valid(boton):
		return

	var id := boton.get_instance_id()
	var anterior := animaciones.get(id) as Tween
	if anterior != null and anterior.is_running():
		anterior.kill()

	var escala_base: Vector2 = boton.get_meta(META_ESCALA_BASE, Vector2.ONE)
	boton.pivot_offset = boton.size * 0.5
	var animacion := create_tween()
	animaciones[id] = animacion
	animacion.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animacion.tween_property(boton, "scale", escala_base * factor, duracion)
	animacion.finished.connect(_limpiar_animacion.bind(id, animacion))


func _limpiar_animacion(id: int, animacion: Tween) -> void:
	if animaciones.get(id) == animacion:
		animaciones.erase(id)
