class User {
  final int? id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final DateTime? createdAt;

  User({
    this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    this.createdAt,
  });

  String get fullName => '$prenom $nom';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      telephone: json['telephone'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}