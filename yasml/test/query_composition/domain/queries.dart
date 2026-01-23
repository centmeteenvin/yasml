/// Query definitions for the gaming scoreboard system
library;

import 'package:flutter/foundation.dart';
import 'package:yasml/yasml.dart';

import 'models.dart';

/// Returns the current player's stats immediately.
base class PlayerStatsQuery extends SynchronousQuery<PlayerStats> {
  @override
  String get key => 'PlayerStats';

  @override
  PlayerStats query(World world) {
    return PlayerStats(
      playerId: 'player_123',
      kills: 42,
      wins: 15,
      level: 5,
    );
  }
}

/// Emits live leaderboard rankings.
/// KEY INSIGHT: This query will be used by BOTH views!
base class RankingsStreamQuery extends StreamQuery<List<RankEntry>> {
  @override
  String get key => 'Rankings';

  @override
  Stream<List<RankEntry>> query(World world, VoidCallback setSettled) {
    // Create a simple async stream that emits rankings
    return _emitRankings(setSettled);
  }

  static Stream<List<RankEntry>> _emitRankings(VoidCallback setSettled) async* {
    setSettled();
    yield [
      RankEntry(playerId: 'player_456', playerName: 'Alice', rank: 1, wins: 50),
      RankEntry(playerId: 'player_123', playerName: 'Bob', rank: 2, wins: 15),
      RankEntry(playerId: 'player_789', playerName: 'Charlie', rank: 3, wins: 10),
    ];
  }
}

/// Asynchronously loads player achievements.
base class AchievementsQuery extends FutureQuery<List<Achievement>> {
  @override
  String get key => 'Achievements';

  @override
  Future<List<Achievement>> query(World world) async {
    await Future.delayed(const Duration(milliseconds: 10));

    return [
      Achievement(id: 'first_kill', title: 'First Blood', unlocked: true),
      Achievement(id: 'triple_kill', title: 'Triple Kill', unlocked: true),
      Achievement(id: 'pentakill', title: 'Pentakill', unlocked: false),
      Achievement(id: 'level_10', title: 'Reach Level 10', unlocked: false),
    ];
  }
}
