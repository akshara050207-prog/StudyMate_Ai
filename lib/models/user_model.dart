class ProjectItem {
  final String id;
  final String title;
  final String description;
  final String link;

  ProjectItem({
    required this.id,
    required this.title,
    required this.description,
    required this.link,
  });

  factory ProjectItem.fromJson(Map<String, dynamic> json) {
    return ProjectItem(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      link: json['link'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'link': link,
      };
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final String avatar;
  final String bio;
  final bool isVerifiedGmail;
  final String? phone;
  final List<ProjectItem> projects;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.avatar,
    required this.bio,
    required this.isVerifiedGmail,
    required this.projects,
    this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
      bio: json['bio'] ?? '',
      phone: json['phone'] ?? '',
      isVerifiedGmail: json['isVerifiedGmail'] ?? true,
      projects: (json['projects'] as List<dynamic>?)
              ?.map((p) => ProjectItem.fromJson(p))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'bio': bio,
      'phone': phone,
      'isVerifiedGmail': isVerifiedGmail,
      'projects': projects.map((p) => p.toJson()).toList(),
    };
  }
}
