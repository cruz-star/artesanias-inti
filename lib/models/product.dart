import 'dart:typed_data';

class Product {
  final String id;
  String name;
  String description;
  double price;
  Uint8List? imageBytes; // Para uso local temporal antes de subir
  String? imageFileName;
  String? imageUrl;     // URL pública del servidor
  String category;
  bool isAvailable;
  String? contacto;
  String? email;
  String? telefono;

  Product({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.imageBytes,
    this.imageFileName,
    this.imageUrl,
    this.category = 'General',
    this.isAvailable = true,
    this.contacto,
    this.email,
    this.telefono,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'isAvailable': isAvailable,
      'contacto': contacto,
      'email': email,
      'telefono': telefono,
      'imageFileName': imageFileName,
      'imageUrl': imageUrl,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? 'General',
      isAvailable: map['isAvailable'] ?? true,
      contacto: map['contacto'],
      email: map['email'],
      telefono: map['telefono'],
      imageFileName: map['imageFileName'],
      imageUrl: map['imageUrl'],
    );
  }

  Product copyWith({
    String? name,
    String? description,
    double? price,
    Uint8List? imageBytes,
    String? imageFileName,
    String? imageUrl,
    String? category,
    bool? isAvailable,
    String? contacto,
    String? email,
    String? telefono,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageBytes: imageBytes ?? this.imageBytes,
      imageFileName: imageFileName ?? this.imageFileName,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      contacto: contacto ?? this.contacto,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
    );
  }
}
