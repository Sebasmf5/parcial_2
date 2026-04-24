/// Modelo que representa un accidente de tránsito del dataset de Tuluá.
///
/// Se mapea directamente desde el JSON de Datos Abiertos Colombia.
/// Solo se conservan los campos relevantes para el cálculo estadístico.
class Accidente {
  final String? claseAccidente;
  final String? gravedad;
  final String? barrioHecho;
  final String? dia;
  final String? hora;
  final String? area;
  final String? claseVehiculo;

  const Accidente({
    this.claseAccidente,
    this.gravedad,
    this.barrioHecho,
    this.dia,
    this.hora,
    this.area,
    this.claseVehiculo,
  });

  /// Crea una instancia de [Accidente] a partir de un mapa JSON.
  ///
  /// Los campos pueden ser nulos si no vienen en el registro.
  factory Accidente.fromJson(Map<String, dynamic> json) {
    return Accidente(
      claseAccidente: json['clase_de_accidente'] as String?,
      gravedad: json['gravedad_del_accidente'] as String?,
      barrioHecho: json['barrio_hecho'] as String?,
      dia: json['dia'] as String?,
      hora: json['hora'] as String?,
      area: json['area'] as String?,
      claseVehiculo: json['clase_de_vehiculo'] as String?,
    );
  }
}
