class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String imageUrl;
  final String category;
  
  // Nuevos campos reales de la base de datos
  final int? idCategory;
  final int? idBrand;
  final String? brandName;
  final double? ivaPercentage;
  final String? state;
  final String? acquisitionType;
  final String? code;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.category,
    this.idCategory,
    this.idBrand,
    this.brandName,
    this.ivaPercentage,
    this.state = 'Activo',
    this.acquisitionType = 'compra_directa',
    this.code,
  });

  // JSON -> Modelo
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json["id_producto"] ?? json["id"] ?? 0,
      name: json["nombre"] ?? json["name"] ?? '',
      description: json["descripcion"] ?? json["description"] ?? '',
      price: (json["precio_neto"] ?? json["price"] ?? 0.0).toDouble(),
      stock: json["stock"] ?? 0,
      imageUrl: json["img"] ?? json["imageUrl"] ?? '',
      category: json["categoria_nombre"] ?? json["category"] ?? 'Sin categoría',
      idCategory: json["id_categoria"],
      idBrand: json["id_marca"],
      brandName: json["marca_nombre"],
      ivaPercentage: (json["iva_porcentaje"] ?? 19.0).toDouble(),
      state: json["estado"] ?? 'Activo',
      acquisitionType: json["tipo_adquisicion"] ?? 'compra_directa',
      code: json["codigo"] ?? json["code"] ?? '',
    );
  }

  // Modelo -> JSON
  Map<String, dynamic> toJson() => {
        "id_producto": id,
        "id": id,
        "nombre": name,
        "name": name,
        "descripcion": description,
        "description": description,
        "precio_neto": price,
        "price": price,
        "stock": stock,
        "img": imageUrl,
        "imageUrl": imageUrl,
        "categoria_nombre": category,
        "category": category,
        "id_categoria": idCategory,
        "id_marca": idBrand,
        "marca_nombre": brandName,
        "iva_porcentaje": ivaPercentage,
        "estado": state,
        "tipo_adquisicion": acquisitionType,
        "codigo": code,
        "code": code,
      };

  // Operador de indexación [] para compatibilidad con código existente que trata a Product como un Map
  dynamic operator [](String key) {
    switch (key) {
      case 'id_producto':
      case 'id':
        return id;
      case 'nombre':
      case 'name':
        return name;
      case 'descripcion':
      case 'description':
        return description;
      case 'precio_neto':
      case 'price':
        return price;
      case 'stock':
        return stock;
      case 'img':
      case 'imageUrl':
        return imageUrl;
      case 'categoria_nombre':
      case 'category':
        return category;
      case 'id_categoria':
        return idCategory;
      case 'id_marca':
        return idBrand;
      case 'marca_nombre':
        return brandName;
      case 'iva_porcentaje':
        return ivaPercentage;
      case 'estado':
        return state;
      case 'tipo_adquisicion':
        return acquisitionType;
      case 'codigo':
      case 'code':
        return code;
      default:
        return null;
    }
  }
}
