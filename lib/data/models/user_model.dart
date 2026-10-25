class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final DateTime createdAt;
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.createdAt,
    this.photoUrl,
  });

  // من Firestore إلى Model
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      createdAt: (map['createdAt'] != null)
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      photoUrl: map['photoUrl'],
    );
  }

  // من Model إلى Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'createdAt': createdAt.toIso8601String(),
      'photoUrl': photoUrl,
    };
  }

  // نسخة معدّلة
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    DateTime? createdAt,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}