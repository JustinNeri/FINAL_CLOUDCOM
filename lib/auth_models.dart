class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.username,
    this.name,
  });

  final String id;
  final String username;
  final String? name;

  /// Name to greet the player with: their player name, else their username.
  String get displayName => name?.isNotEmpty == true ? name! : username;

  factory PlayerProfile.fromMap(Map<String, dynamic> map) {
    return PlayerProfile(
      id: (map['player_id'] ?? map['id'] ?? '').toString(),
      username: (map['username'] ?? map['player_username'] ?? map['name'] ?? '').toString(),
      name: map['player_name']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'player_id': id,
        'username': username,
        if (name != null) 'player_name': name,
      };
}
