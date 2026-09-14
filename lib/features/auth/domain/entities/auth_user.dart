enum UserRole {
  guest,
  user,
  admin,
}

/// Represents an authenticated or guest user in the application.
class AuthUser {
  final String id;
  final String? email;
  final String displayName;
  final UserRole role;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final String avatarEmoji;
  final List<String> permissions;

  const AuthUser({
    required this.id,
    this.email,
    required this.displayName,
    this.role = UserRole.user,
    this.isAnonymous = false,
    required this.createdAt,
    required this.lastLoginAt,
    this.avatarEmoji = '🦉',
    this.permissions = const ['read_public', 'sync_cloud', 'create_bookmarks'],
  });

  bool get isGuest => role == UserRole.guest || isAnonymous;
  bool get isUser => role == UserRole.user && !isAnonymous;
  bool get isAdmin => role == UserRole.admin;

  bool get canManageCatalog => isAdmin || permissions.contains('manage_catalog');
  bool get canEditShelves => isAdmin || permissions.contains('manage_shelves');
  bool get canUploadPublicBooks => isAdmin || permissions.contains('upload_public_books');

  String get roleLabel {
    switch (role) {
      case UserRole.admin:
        return 'Admin / Curator';
      case UserRole.user:
        return 'Verified Reader';
      case UserRole.guest:
        return 'Guest Reader';
    }
  }

  String get roleBadge {
    switch (role) {
      case UserRole.admin:
        return '👑 ADMIN';
      case UserRole.user:
        return '✨ MEMBER';
      case UserRole.guest:
        return '🌱 GUEST';
    }
  }

  AuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    UserRole? role,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? avatarEmoji,
    List<String>? permissions,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      permissions: permissions ?? this.permissions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'isAnonymous': isAnonymous,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'avatarEmoji': avatarEmoji,
      'permissions': permissions,
    };
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? 'usr_default',
      email: json['email'] as String?,
      displayName: json['displayName'] as String? ?? 'Reader',
      role: UserRole.values.firstWhere(
        (r) => r.name == (json['role'] as String?),
        orElse: () => UserRole.user,
      ),
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.tryParse(json['lastLoginAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      avatarEmoji: json['avatarEmoji'] as String? ?? '🦉',
      permissions: (json['permissions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          (json['role'] == 'admin'
              ? const ['read_public', 'sync_cloud', 'create_bookmarks', 'manage_catalog', 'manage_shelves', 'upload_public_books']
              : const ['read_public', 'sync_cloud', 'create_bookmarks']),
    );
  }

  factory AuthUser.guest() {
    return AuthUser(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      email: null,
      displayName: 'Guest Explorer',
      role: UserRole.guest,
      isAnonymous: true,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      avatarEmoji: '🌱',
      permissions: const ['read_public', 'local_storage'],
    );
  }

  factory AuthUser.admin({String? name, String? email}) {
    return AuthUser(
      id: 'admin_master',
      email: email ?? 'admin@scribbleverse.io',
      displayName: name ?? 'Scribble Curator (Admin)',
      role: UserRole.admin,
      isAnonymous: false,
      createdAt: DateTime(2025, 1, 1),
      lastLoginAt: DateTime.now(),
      avatarEmoji: '👑',
      permissions: const [
        'read_public',
        'sync_cloud',
        'create_bookmarks',
        'manage_catalog',
        'manage_shelves',
        'upload_public_books',
        'admin_dashboard',
      ],
    );
  }
}
