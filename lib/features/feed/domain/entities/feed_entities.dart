/// Reacciones disponibles (el orden es el que se muestra en el selector).
const List<String> reactionOrder = [
  'me_encanta',
  'me_gusta',
  'jaja',
  'wow',
  'triste',
  'fuego',
];

const Map<String, String> reactionEmojis = {
  'me_gusta': '👍',
  'me_encanta': '❤️',
  'jaja': '😂',
  'wow': '😮',
  'triste': '😢',
  'fuego': '🔥',
};

DateTime _parseUtc(String value) {
  final hasZone = value.endsWith('Z') || RegExp(r'[+-]\d\d:\d\d$').hasMatch(value);
  return DateTime.parse(hasZone ? value : '${value}Z').toLocal();
}

class AuthorEntity {
  final int id;
  final String name;
  final String? photoUrl;

  AuthorEntity({required this.id, required this.name, this.photoUrl});

  factory AuthorEntity.fromJson(Map<String, dynamic> json) => AuthorEntity(
        id: json['id'],
        name: json['nombre'] ?? '',
        photoUrl: json['fotoUrl'],
      );
}

class PostMediaEntity {
  final int id;
  final String url;
  final bool isVideo;
  final int order;

  PostMediaEntity({
    required this.id,
    required this.url,
    required this.isVideo,
    required this.order,
  });

  factory PostMediaEntity.fromJson(Map<String, dynamic> json) => PostMediaEntity(
        id: json['id'],
        url: json['url'],
        isVideo: (json['tipo'] ?? '').toString().toLowerCase() == 'video',
        order: json['orden'] ?? 0,
      );
}

class CommunityBrief {
  final int id;
  final String name;
  final String? imageUrl;

  CommunityBrief({required this.id, required this.name, this.imageUrl});

  factory CommunityBrief.fromJson(Map<String, dynamic> json) =>
      CommunityBrief(id: json['id'], name: json['nombre'] ?? '', imageUrl: json['imagenUrl']);
}

class PostEntity {
  final int id;
  final AuthorEntity author;
  final String? text;
  final DateTime createdAt;
  final List<PostMediaEntity> media;
  final int totalReactions;
  final Map<String, int> reactions;
  final String? myReaction;
  final int totalComments;
  final bool isMine;
  final bool canDelete; // autor, o admin/moderador de la comunidad
  final CommunityBrief? community;

  PostEntity({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
    required this.media,
    required this.totalReactions,
    required this.reactions,
    required this.myReaction,
    required this.totalComments,
    required this.isMine,
    this.canDelete = false,
    this.community,
  });

  factory PostEntity.fromJson(Map<String, dynamic> json) => PostEntity(
        id: json['id'],
        author: AuthorEntity.fromJson(json['autor']),
        text: json['texto'],
        createdAt: _parseUtc(json['creadoEn']),
        media: (json['media'] as List<dynamic>? ?? [])
            .map((e) => PostMediaEntity.fromJson(e))
            .toList(),
        totalReactions: json['totalReacciones'] ?? 0,
        reactions: (json['reacciones'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as int)),
        myReaction: json['miReaccion'],
        totalComments: json['totalComentarios'] ?? 0,
        isMine: json['esMio'] ?? false,
        canDelete: json['puedeEliminar'] ?? (json['esMio'] ?? false),
        community: json['comunidad'] != null ? CommunityBrief.fromJson(json['comunidad']) : null,
      );
}

class CommentEntity {
  final int id;
  final int postId;
  final int? parentId;
  final AuthorEntity author;
  final String text;
  final DateTime createdAt;
  final bool isMine;

  CommentEntity({
    required this.id,
    required this.postId,
    required this.parentId,
    required this.author,
    required this.text,
    required this.createdAt,
    required this.isMine,
  });

  factory CommentEntity.fromJson(Map<String, dynamic> json) => CommentEntity(
        id: json['id'],
        postId: json['postId'],
        parentId: json['parentId'],
        author: AuthorEntity.fromJson(json['autor']),
        text: json['texto'] ?? '',
        createdAt: _parseUtc(json['creadoEn']),
        isMine: json['esMio'] ?? false,
      );
}

class CursorPage<T> {
  final List<T> items;
  final int? nextCursor;

  CursorPage({required this.items, required this.nextCursor});
}
