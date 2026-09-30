class LoginAttempt {
  final int? id;
  final String email;
  final bool success;
  final DateTime date;

  const LoginAttempt({
    this.id,
    required this.email,
    required this.success,
    required this.date,
  });

  factory LoginAttempt.fromMap(Map<String, Object?> map) {
    return LoginAttempt(
      id: map['id'] as int?,
      email: map['email'] as String,
      success: (map['success'] as int) == 1,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    );
  }
}
