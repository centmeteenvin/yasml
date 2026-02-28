/// Domain models for the gaming scoreboard system
library;

/// Represents a player's statistics
class PlayerStats {
  PlayerStats({
    required this.playerId,
    required this.kills,
    required this.wins,
    required this.level,
  });
  final String playerId;
  final int kills;
  final int wins;
  final int level;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerStats &&
          runtimeType == other.runtimeType &&
          playerId == other.playerId &&
          kills == other.kills &&
          wins == other.wins &&
          level == other.level;

  @override
  int get hashCode => playerId.hashCode ^ kills.hashCode ^ wins.hashCode ^ level.hashCode;
}

/// Represents a single entry in the rankings leaderboard
class RankEntry {
  RankEntry({
    required this.playerId,
    required this.playerName,
    required this.rank,
    required this.wins,
  });
  final String playerId;
  final String playerName;
  final int rank;
  final int wins;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RankEntry &&
          runtimeType == other.runtimeType &&
          playerId == other.playerId &&
          playerName == other.playerName &&
          rank == other.rank &&
          wins == other.wins;

  @override
  int get hashCode => playerId.hashCode ^ playerName.hashCode ^ rank.hashCode ^ wins.hashCode;
}

/// Represents a player achievement
class Achievement {
  Achievement({
    required this.id,
    required this.title,
    required this.unlocked,
  });
  final String id;
  final String title;
  final bool unlocked;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Achievement &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          unlocked == other.unlocked;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ unlocked.hashCode;
}
