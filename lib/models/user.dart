class User {
  final int? id;
  final String username;
  final String password;

  const User({this.id, required this.username, required this.password});

  const User.sansId({required this.username, required this.password})
    : id = null;

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'password': password,
    };
  }
}
