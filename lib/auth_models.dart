class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.username,
    this.name,
  });

  final String id;
  final String username;
  final String? name;

  factory PlayerProfile.fromMap(Map<String, dynamic> map) {
    return PlayerProfile(
      id: (map['player_id'] ?? map['id'] ?? '').toString(),
      username: (map['username'] ?? map['player_username'] ?? map['name'] ?? '').toString(),
      name: map['player_name']?.toString(),
    );
  }
}
