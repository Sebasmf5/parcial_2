/// Modelo que representa un Establecimiento de parqueadero.
///
/// Se mapea desde/hacia la API REST de parking.visiontic.com.co.
class Establecimiento {
  final int? id;
  final String nombre;
  final String nit;
  final String direccion;
  final String telefono;
  final String? logo;
  final String? estado;

  const Establecimiento({
    this.id,
    required this.nombre,
    required this.nit,
    required this.direccion,
    required this.telefono,
    this.logo,
    this.estado,
  });

  /// Crea una instancia de [Establecimiento] desde un mapa JSON.
  factory Establecimiento.fromJson(Map<String, dynamic> json) {
    return Establecimiento(
      id: json['id'] as int?,
      nombre: json['nombre'] as String? ?? '',
      nit: json['nit'] as String? ?? '',
      direccion: json['direccion'] as String? ?? '',
      telefono: json['telefono'] as String? ?? '',
      logo: json['logo'] as String?,
      estado: json['estado'] as String?,
    );
  }

  /// Convierte el establecimiento a un mapa para enviar a la API.
  ///
  /// No incluye [id] ni [logo] ya que el logo se envía como archivo
  /// en multipart/form-data.
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'nit': nit,
      'direccion': direccion,
      'telefono': telefono,
    };
  }

  /// Crea una copia del establecimiento con campos modificados.
  Establecimiento copyWith({
    int? id,
    String? nombre,
    String? nit,
    String? direccion,
    String? telefono,
    String? logo,
    String? estado,
  }) {
    return Establecimiento(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      nit: nit ?? this.nit,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      logo: logo ?? this.logo,
      estado: estado ?? this.estado,
    );
  }
}
