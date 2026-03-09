class AuthEntity {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final UserInfo user;

  const AuthEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });
}

class UserInfo {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;

  const UserInfo({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });
}
