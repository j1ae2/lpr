class Bus {
  final String id;
  final String nombre;

  Bus({required this.id, required this.nombre});

  // Método para convertir de un JSON a un objeto Bus
  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'],
      nombre: json['nombre'].toString(), // Convierte a String si es necesario
    );
  }

  // Método para convertir de un objeto Bus a un JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }

  // Método para convertir una lista de JSON a una lista de objetos Bus
  static List<Bus> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) => Bus.fromJson(json)).toList();
  }
}
