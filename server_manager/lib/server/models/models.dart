class User {
  final String id;
  final String email;
  final String name;
  final String passwordHash;
  final bool isVerified;
  final String? verificationToken;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.passwordHash,
    this.isVerified = false,
    this.verificationToken,
    this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'isVerified': isVerified,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      passwordHash: json['passwordHash'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      verificationToken: json['verificationToken'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJsonWithPassword() {
    return {
      ...toJson(),
      'passwordHash': passwordHash,
      'verificationToken': verificationToken,
    };
  }
}

class Session {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime expiresAt;

  Session({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'token': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : DateTime.now().add(const Duration(days: 7)),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> mediaUrls;
  final int stock;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.mediaUrls = const [],
    this.stock = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'mediaUrls': mediaUrls,
      'stock': stock,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Sin nombre',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num? ?? 0).toDouble(),
      category: json['category'] as String? ?? 'General',
      mediaUrls: (json['mediaUrls'] as List?)?.map((e) => e as String).toList() ?? [],
      stock: json['stock'] as int? ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
    );
  }
}

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      price: (json['price'] as num? ?? 0).toDouble(),
    );
  }
}

class Order {
  final String id;
  final String? userId; // Opcional para invitados
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String shippingAddress;
  final String shippingCity;
  final String shippingZip;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final String? paymentMethod; // 'Transferencia', 'MercadoPago', etc.
  final String? paymentId;
  final DateTime createdAt;

  Order({
    required this.id,
    this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.shippingAddress,
    required this.shippingCity,
    required this.shippingZip,
    required this.items,
    required this.totalAmount,
    this.status = 'pending',
    this.paymentMethod,
    this.paymentId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'shippingAddress': shippingAddress,
      'shippingCity': shippingCity,
      'shippingZip': shippingZip,
      'items': items.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String?,
      customerName: json['customerName'] as String? ?? '',
      customerEmail: json['customerEmail'] as String? ?? json['customerContact'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      shippingAddress: json['shippingAddress'] as String? ?? '',
      shippingCity: json['shippingCity'] as String? ?? '',
      shippingZip: json['shippingZip'] as String? ?? '',
      items: (json['items'] as List?)
          ?.map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList() ?? [],
      totalAmount: (json['totalAmount'] as num? ?? 0).toDouble(),
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['paymentMethod'] as String?,
      paymentId: json['paymentId'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
    );
  }
}

class Favorite {
  final String userId;
  final String productId;
  final DateTime createdAt;

  Favorite({
    required this.userId,
    required this.productId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'productId': productId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      userId: json['userId'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
    );
  }
}
