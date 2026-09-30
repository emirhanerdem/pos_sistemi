class AppUser {
  final int? id;
  final String businessType;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String passwordHash;
  final DateTime createdAt;

  const AppUser({
    this.id,
    required this.businessType,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.passwordHash,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'business_type': businessType,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'password_hash': passwordHash,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory AppUser.fromMap(Map<String, Object?> map) {
    return AppUser(
      id: map['id'] as int?,
      businessType: map['business_type'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      passwordHash: map['password_hash'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
