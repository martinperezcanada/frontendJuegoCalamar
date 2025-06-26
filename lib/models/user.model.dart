class User {
  String? id;
  String name;
  String lastName;
  String email;
  String? token;

  User({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['_id'] ?? json['id'],
    name: json['name'] ?? '',
    lastName: json['lastName'] ?? '',
    email: json['email'] ?? '',
    token: json['token'],
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'lastName': lastName,
    'email': email,
    'token': token,
  };
}
