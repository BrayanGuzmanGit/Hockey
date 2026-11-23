extends CharacterBody2D

@export var control_ia: bool = false
@export var control_teclado_local: bool = false
@export_range(1, 2, 1) var jugador_local: int = 1
@export_range(200.0, 3000.0, 50.0) var velocidad_maxima: float = 2200.0
@export_range(1.0, 80.0, 1.0) var distancia_para_impulso_maximo: float = 30.0
@export_range(0.0, 1500.0, 25.0) var impulso_minimo_golpe: float = 120.0
@export_range(100.0, 2000.0, 25.0) var impulso_maximo_golpe: float = 1000.0

# Límites del golpeador; se ajustan por instancia en Partida.tscn.
@export var limite_minimo: Vector2 = Vector2(157.0, 136.0)
@export var limite_maximo: Vector2 = Vector2(528.0, 509.0)

# Parámetros de la IA. Son deliberadamente moderados.
@export_range(200.0, 1200.0, 20.0) var velocidad_ia: float = 520.0
@export_range(0.0, 500.0, 10.0) var impulso_minimo_golpe_ia: float = 50.0
@export_range(100.0, 800.0, 10.0) var impulso_maximo_golpe_ia: float = 360.0
@export var centro_cancha_ia: float = 580.0
@export var linea_defensa_ia: float = 925.0
@export_range(0.05, 0.5, 0.01) var demora_reaccion_ia: float = 0.12

var _contactos_anteriores: Dictionary = {}
var _disco: RigidBody2D
var _temporizador_ia: float = 0.0
var _objetivo_ia: Vector2 = Vector2.ZERO


func _ready() -> void:
	if control_ia:
		_disco = get_parent().get_node_or_null("Disco") as RigidBody2D
		_objetivo_ia = global_position


func _physics_process(delta: float) -> void:
	var objetivo := _obtener_objetivo(delta)
	var distancia := global_position.distance_to(objetivo)
	var rapidez_maxima_actual := velocidad_ia if control_ia else velocidad_maxima

	if distancia <= 1.0:
		velocity = Vector2.ZERO
	else:
		var rapidez := minf(rapidez_maxima_actual, distancia / delta)
		velocity = global_position.direction_to(objetivo) * rapidez

	# Conservamos la velocidad antes de que move_and_slide la ajuste al chocar.
	var velocidad_de_golpe := velocity
	move_and_slide()
	_aplicar_golpe_a_discos(velocidad_de_golpe, delta)


func reiniciar_en(posicion: Vector2) -> void:
	global_position = posicion
	velocity = Vector2.ZERO
	_contactos_anteriores.clear()
	if control_ia:
		_objetivo_ia = posicion
		_temporizador_ia = 0.0


func _obtener_objetivo(delta: float) -> Vector2:
	if not control_ia:
		if control_teclado_local:
			return _obtener_objetivo_teclado(delta)
		return _limitar_a_zona(get_global_mouse_position())

	if _disco == null:
		return _limitar_a_zona(_objetivo_ia)

	_temporizador_ia -= delta
	if _temporizador_ia <= 0.0:
		_temporizador_ia = demora_reaccion_ia
		var posicion_disco := _disco.global_position
		var velocidad_disco := _disco.linear_velocity
		var x_objetivo := linea_defensa_ia
		var y_objetivo := _predecir_y_en_x(
			linea_defensa_ia - 74.0,
			posicion_disco,
			velocidad_disco
		)

		if posicion_disco.x > centro_cancha_ia:
			# Se coloca a la derecha del disco para devolverlo hacia el jugador.
			var x_ataque := clampf(posicion_disco.x + 80.0, limite_minimo.x, limite_maximo.x)
			if global_position.x < posicion_disco.x + 75.0:
				# Si el disco le queda detrás, primero lo rodea por arriba o por abajo.
				var y_rodeo := _elegir_carril_para_rodear(posicion_disco.y)
				if absf(global_position.y - posicion_disco.y) < 90.0:
					x_objetivo = global_position.x
					y_objetivo = y_rodeo
				elif global_position.x < x_ataque - 15.0:
					x_objetivo = x_ataque
					y_objetivo = y_rodeo
				else:
					x_objetivo = x_ataque
					y_objetivo = _predecir_y_en_x(x_ataque - 74.0, posicion_disco, velocidad_disco)
			else:
				x_objetivo = clampf(posicion_disco.x + 60.0, limite_minimo.x, limite_maximo.x)
				y_objetivo = _predecir_y_en_x(x_objetivo - 74.0, posicion_disco, velocidad_disco)

		_objetivo_ia = _limitar_a_zona(Vector2(x_objetivo, y_objetivo))

	return _objetivo_ia


func _obtener_objetivo_teclado(delta: float) -> Vector2:
	var direccion := Vector2.ZERO
	if jugador_local == 1:
		if Input.is_key_pressed(KEY_A):
			direccion.x -= 1.0
		if Input.is_key_pressed(KEY_D):
			direccion.x += 1.0
		if Input.is_key_pressed(KEY_W):
			direccion.y -= 1.0
		if Input.is_key_pressed(KEY_S):
			direccion.y += 1.0
	else:
		if Input.is_key_pressed(KEY_LEFT):
			direccion.x -= 1.0
		if Input.is_key_pressed(KEY_RIGHT):
			direccion.x += 1.0
		if Input.is_key_pressed(KEY_UP):
			direccion.y -= 1.0
		if Input.is_key_pressed(KEY_DOWN):
			direccion.y += 1.0

	if direccion.length_squared() > 1.0:
		direccion = direccion.normalized()

	return _limitar_a_zona(
		global_position + direccion * velocidad_maxima * delta
	)


func _elegir_carril_para_rodear(y_disco: float) -> float:
	var y_arriba := clampf(y_disco - 110.0, limite_minimo.y, limite_maximo.y)
	var y_abajo := clampf(y_disco + 110.0, limite_minimo.y, limite_maximo.y)
	if absf(y_arriba - y_disco) < 90.0:
		return y_abajo
	if absf(y_abajo - y_disco) < 90.0:
		return y_arriba
	if absf(global_position.y - y_arriba) <= absf(global_position.y - y_abajo):
		return y_arriba
	return y_abajo


func _predecir_y_en_x(x_objetivo: float, posicion_disco: Vector2, velocidad_disco: Vector2) -> float:
	if velocidad_disco.x <= 30.0 or x_objetivo <= posicion_disco.x:
		return clampf(posicion_disco.y, limite_minimo.y, limite_maximo.y)

	var tiempo_hasta_x := (x_objetivo - posicion_disco.x) / velocidad_disco.x
	var y_futura := posicion_disco.y + velocidad_disco.y * tiempo_hasta_x
	const Y_MIN_DISCO := 106.0
	const Y_MAX_DISCO := 539.0
	var alto_campo := Y_MAX_DISCO - Y_MIN_DISCO
	var recorrido := fposmod(y_futura - Y_MIN_DISCO, alto_campo * 2.0)
	if recorrido > alto_campo:
		y_futura = Y_MAX_DISCO - (recorrido - alto_campo)
	else:
		y_futura = Y_MIN_DISCO + recorrido
	return clampf(y_futura, limite_minimo.y, limite_maximo.y)


func _limitar_a_zona(posicion: Vector2) -> Vector2:
	return Vector2(
		clampf(posicion.x, limite_minimo.x, limite_maximo.x),
		clampf(posicion.y, limite_minimo.y, limite_maximo.y)
	)


func _aplicar_golpe_a_discos(velocidad_de_golpe: Vector2, delta: float) -> void:
	var contactos_actuales: Dictionary = {}
	var impulso_minimo := impulso_minimo_golpe_ia if control_ia else impulso_minimo_golpe
	var impulso_maximo := impulso_maximo_golpe_ia if control_ia else impulso_maximo_golpe

	for i in range(get_slide_collision_count()):
		var colision := get_slide_collision(i)
		var cuerpo := colision.get_collider()
		if not cuerpo is RigidBody2D:
			continue

		var id_cuerpo: RID = cuerpo.get_rid()
		contactos_actuales[id_cuerpo] = true
		if _contactos_anteriores.has(id_cuerpo):
			continue

		var direccion_del_golpe := -colision.get_normal()
		var rapidez_de_impacto := maxf(0.0, velocidad_de_golpe.dot(direccion_del_golpe))
		if rapidez_de_impacto <= 0.0:
			continue

		var distancia_del_golpe := rapidez_de_impacto * delta
		var intensidad := clampf(distancia_del_golpe / distancia_para_impulso_maximo, 0.0, 1.0)
		var impulso := lerpf(impulso_minimo, impulso_maximo, intensidad)
		cuerpo.apply_central_impulse(direccion_del_golpe * impulso)

	_contactos_anteriores = contactos_actuales