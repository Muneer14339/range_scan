// models/user.dart

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String? location;
  final DateTime? createdAt;
  final int role;
  final String? registeredFrom;
  final String? currentlyLogin;
  final String? password;

  const UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    this.location,
    required this.role,
    this.createdAt,
    this.registeredFrom,
    this.currentlyLogin,
    this.password,
  });

  // fromJson
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      location: json['location'] as String?,
      role: json['role'] as int,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      registeredFrom: json['registeredFrom'] as String?,
      currentlyLogin: json['currentlyLogin'] as String?,
    );
  }

  // toJson
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'location': location,
      'role': role,
      'createdAt':DateTime.now(),
      'registeredFrom': registeredFrom,
      'currentlyLogin': currentlyLogin,
      "password": password,
    };
  }
}
