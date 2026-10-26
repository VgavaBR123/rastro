// Modelos da conta no NOSSO backend (`backend/`, contrato em backend/README.md).
library;

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final int createdAtMs;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAtMs,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'].toString(),
        email: j['email'] as String,
        displayName: j['displayName'] as String,
        createdAtMs: (j['createdAt'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'createdAt': createdAtMs,
      };

  AppUser copyWith({String? displayName}) => AppUser(
        id: id,
        email: email,
        displayName: displayName ?? this.displayName,
        createdAtMs: createdAtMs,
      );
}

/// Sessao autenticada: token opaco + usuario. O usuario fica guardado junto
/// para o app abrir logado mesmo sem rede (offline-first).
class AuthSession {
  final String token;
  final AppUser user;
  const AuthSession({required this.token, required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> j) => AuthSession(
        token: j['token'] as String,
        user: AppUser.fromJson(j['user'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {'token': token, 'user': user.toJson()};
}

/// Totais do usuario no servidor (o que ja foi sincronizado).
class ProfileStats {
  final int activityCount;
  final double totalDistanceMeters;
  const ProfileStats({required this.activityCount, required this.totalDistanceMeters});

  factory ProfileStats.fromJson(Map<String, dynamic> j) => ProfileStats(
        activityCount: (j['activityCount'] as num).toInt(),
        totalDistanceMeters: (j['totalDistanceMeters'] as num).toDouble(),
      );
}

class Profile {
  final AppUser user;
  final ProfileStats stats;
  const Profile(this.user, this.stats);
}

/// Erro de autenticacao com mensagem pronta para a UI. [statusCode] e null
/// quando a falha foi de transporte (sem rede, servidor fora).
class AuthException implements Exception {
  final String message;
  final int? statusCode;
  const AuthException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'AuthException($statusCode): $message';
}
