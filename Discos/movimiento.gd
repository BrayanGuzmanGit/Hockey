extends RigidBody2D

# Límites interiores de seguridad: las aberturas de los arcos siguen disponibles.
const LIMITE_IZQUIERDO := 67.0
const LIMITE_DERECHO := 1093.0
const LIMITE_SUPERIOR := 106.0
const LIMITE_INFERIOR := 539.0
const REBOTE_SEGURIDAD := 0.82

@export_range(200.0, 2500.0, 50.0) var velocidad_maxima: float = 2000.0


func _integrate_forces(estado: PhysicsDirectBodyState2D) -> void:
	var rapidez := estado.linear_velocity.length()
	if rapidez > velocidad_maxima:
		estado.linear_velocity = estado.linear_velocity * (velocidad_maxima / rapidez)

	# Respaldo para uniones o contactos que la geometría de la cancha no alcance.
	# Las porterías quedan dentro de estos límites y el detector de gol puede actuar.
	var posicion := estado.transform.origin
	var velocidad := estado.linear_velocity
	var corregir_posicion := false

	if posicion.x < LIMITE_IZQUIERDO:
		posicion.x = LIMITE_IZQUIERDO
		if velocidad.x < 0.0:
			velocidad.x = absf(velocidad.x) * REBOTE_SEGURIDAD
		corregir_posicion = true
	elif posicion.x > LIMITE_DERECHO:
		posicion.x = LIMITE_DERECHO
		if velocidad.x > 0.0:
			velocidad.x = -absf(velocidad.x) * REBOTE_SEGURIDAD
		corregir_posicion = true

	if posicion.y < LIMITE_SUPERIOR:
		posicion.y = LIMITE_SUPERIOR
		if velocidad.y < 0.0:
			velocidad.y = absf(velocidad.y) * REBOTE_SEGURIDAD
		corregir_posicion = true
	elif posicion.y > LIMITE_INFERIOR:
		posicion.y = LIMITE_INFERIOR
		if velocidad.y > 0.0:
			velocidad.y = -absf(velocidad.y) * REBOTE_SEGURIDAD
		corregir_posicion = true

	if corregir_posicion:
		var transformacion := estado.transform
		transformacion.origin = posicion
		estado.transform = transformacion
		estado.linear_velocity = velocidad
