class Contact {
  final int? id;
  final int? userId;
  final String nom;
  final String prenom;
  final String? email;
  final String telephone;
  final String? adresse;
  final String? photoPath;
  final bool isFavorite;
  final DateTime? createdAt;

  Contact({
    this.id,
    this.userId,
    required this.nom,
    required this.prenom,
    this.email,
    required this.telephone,
    this.adresse,
    this.photoPath,
    this.isFavorite = false,
    this.createdAt,
  });

  String get fullName => '$prenom $nom';

  String get initials {
    String prenomInitial = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    String nomInitial = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return prenomInitial + nomInitial;
  }

  String get firstLetter => nom.isNotEmpty ? nom[0].toUpperCase() : '#';

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      userId: json['user_id'],
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      telephone: json['telephone'],
      adresse: json['adresse'],
      photoPath: json['photo_path'],
      isFavorite: json['is_favorite'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'adresse': adresse,
      'photo_path': photoPath,
      'is_favorite': isFavorite,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Contact copyWith({
    int? id,
    int? userId,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? adresse,
    String? photoPath,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return Contact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      photoPath: photoPath ?? this.photoPath,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}