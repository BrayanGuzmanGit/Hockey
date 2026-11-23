extends RefCounted

const ARCHIVO := "user://progreso.cfg"
const CANCHA_PRINCIPAL := 0
const MAX_CANCHAS := 2
const RESULTADO_COMPRA_OK := "ok"
const RESULTADO_YA_DESBLOQUEADA := "desbloqueada"
const RESULTADO_SALDO_INSUFICIENTE := "saldo_insuficiente"
const RESULTADO_COMPRA_INVALIDA := "compra_invalida"
const RESULTADO_ERROR_GUARDADO := "error_guardado"


static func _cargar_configuracion() -> ConfigFile:
	var configuracion := ConfigFile.new()
	var error := configuracion.load(ARCHIVO)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_warning("No se pudo leer el progreso guardado: %s" % error)
	return configuracion


static func _leer_canchas_desbloqueadas(configuracion: ConfigFile) -> Array[int]:
	var guardadas: Variant = configuracion.get_value("progreso", "canchas_desbloqueadas", [])
	var canchas: Array[int] = [CANCHA_PRINCIPAL]
	if guardadas is Array:
		for valor in guardadas:
			var indice := int(valor)
			if indice >= CANCHA_PRINCIPAL and indice <= MAX_CANCHAS and not canchas.has(indice):
				canchas.append(indice)
	return canchas


static func obtener_monedas() -> int:
	var configuracion := _cargar_configuracion()
	return maxi(0, int(configuracion.get_value("progreso", "monedas", 0)))


static func recargar_gratis(cantidad: int = 100) -> int:
	var configuracion := _cargar_configuracion()
	var saldo := maxi(0, int(configuracion.get_value("progreso", "monedas", 0)))
	var nuevo_saldo := saldo + maxi(0, cantidad)
	configuracion.set_value("progreso", "monedas", nuevo_saldo)
	if configuracion.save(ARCHIVO) != OK:
		return -1
	return nuevo_saldo


static func precio_cancha(indice: int) -> int:
	match indice:
		0:
			return 0
		1:
			return 100
		2:
			return 200
		_:
			return -1


static func obtener_canchas_desbloqueadas() -> Array[int]:
	var configuracion := _cargar_configuracion()
	return _leer_canchas_desbloqueadas(configuracion)


static func comprar_cancha(indice: int) -> String:
	var precio := precio_cancha(indice)
	if precio < 0:
		return RESULTADO_COMPRA_INVALIDA

	var configuracion := _cargar_configuracion()
	var canchas := _leer_canchas_desbloqueadas(configuracion)
	if canchas.has(indice):
		return RESULTADO_YA_DESBLOQUEADA

	var saldo := maxi(0, int(configuracion.get_value("progreso", "monedas", 0)))
	if saldo < precio:
		return RESULTADO_SALDO_INSUFICIENTE

	canchas.append(indice)
	configuracion.set_value("progreso", "monedas", saldo - precio)
	configuracion.set_value("progreso", "canchas_desbloqueadas", canchas)
	if configuracion.save(ARCHIVO) != OK:
		return RESULTADO_ERROR_GUARDADO
	return RESULTADO_COMPRA_OK


static func obtener_cancha_seleccionada() -> int:
	var configuracion := _cargar_configuracion()
	var seleccion := int(configuracion.get_value("progreso", "cancha_seleccionada", CANCHA_PRINCIPAL))
	if not _leer_canchas_desbloqueadas(configuracion).has(seleccion):
		return CANCHA_PRINCIPAL
	return seleccion


static func guardar_cancha_seleccionada(indice: int) -> bool:
	if precio_cancha(indice) < 0 or not obtener_canchas_desbloqueadas().has(indice):
		return false
	var configuracion := _cargar_configuracion()
	configuracion.set_value("progreso", "cancha_seleccionada", indice)
	return configuracion.save(ARCHIVO) == OK
