class Category {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}
