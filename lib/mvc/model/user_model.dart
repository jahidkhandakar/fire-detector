class UserModel {
  final int id;
  final String email;
  final String phoneNumber;
  final String role;

  UserModel({
    required this.id,
    required this.email,
    required this.phoneNumber,
    required this.role,
  });

  //* Factory constructor to create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      role: json['role'] ?? '',
    );
  }

  //* Convert UserModel to JSON (useful for requests/storage)
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "email": email,
      "phone_number": phoneNumber,
      "role": role,
    };
  }
}
