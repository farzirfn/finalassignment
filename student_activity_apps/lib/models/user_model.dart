class Usermodel {
  int? id;
  String? name;
  String? email;
  String? phone;
  String? role;
  String? profileImage;
  String? createdAt;

  Usermodel({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.role,
    this.profileImage,
    this.createdAt,
  });

  Usermodel.fromJson(Map<String, dynamic> json) {
    id = int.tryParse(json['id'].toString());

    name = json['name']?.toString();
    email = json['email']?.toString();
    phone = json['phone']?.toString();
    role = json['role']?.toString();

    profileImage = json['profile_image']?.toString() ?? "";

    createdAt = json['created_at']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "phone": phone,
      "role": role,
      "profile_image": profileImage,
      "created_at": createdAt,
    };
  }
}
