// model pentru o intrare in jurnal
// contine starea de spirit si notele

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MoodEntry {
  final DateTime timestamp;
  final int moodLevel; // 1-5 scale
  final String? note;
  final List<String>? tags;
  final String? moodType; // Primary mood type
  final List<String>? secondaryMoods; // Additional mood descriptors

  MoodEntry({
    required this.timestamp,
    required this.moodLevel,
    this.note,
    this.tags,
    this.moodType,
    this.secondaryMoods,
  });

  // Convert MoodEntry to JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'moodLevel': moodLevel,
      'note': note,
      'tags': tags,
      'moodType': moodType,
      'secondaryMoods': secondaryMoods,
    };
  }

  // Create MoodEntry from JSON
  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      moodLevel: json['moodLevel'] as int,
      note: json['note'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
      moodType: json['moodType'] as String?,
      secondaryMoods: json['secondaryMoods'] != null ? List<String>.from(json['secondaryMoods'] as List) : null,
    );
  }

  // Helper method to get mood emoji
  String get moodEmoji => getMoodEmoji(moodLevel);

  // Helper method to get mood description
  String getMoodDescription(BuildContext context) {
    if (moodType != null) {
      return moodType!;
    }
    final l10n = AppLocalizations.of(context)!;
    switch (moodLevel) {
      case 1:
        return l10n.veryLow;
      case 2:
        return l10n.low;
      case 3:
        return l10n.neutral;
      case 4:
        return l10n.good;
      case 5:
        return l10n.veryGood;
      default:
        return l10n.unknown;
    }
  }

  // Get full mood description including secondary moods
  String getFullMoodDescription(BuildContext context) {
    final List<String> parts = [];
    if (moodType != null) {
      parts.add(moodType!);
    }
    if (secondaryMoods != null && secondaryMoods!.isNotEmpty) {
      parts.add(secondaryMoods!.join(', '));
    }
    if (note != null && note!.isNotEmpty) {
      parts.add(note!);
    }
    final l10n = AppLocalizations.of(context)!;
    return parts.isEmpty ? l10n.moodLevel(moodLevel) : parts.join(' - ');
  }

  static String getMoodEmoji(int level) {
    switch (level) {
      case 1:
        return '😢';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😊';
      default:
        return '❓';
    }
  }
} 