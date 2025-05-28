import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

// clasa pentru profilul utilizatorului
class UserProfile {
  final String id;
  final String name;
  final String? avatarPath;
  String? email;
  String? firebaseUid;

  UserProfile({
    required this.id,
    required this.name,
    this.avatarPath,
    this.email,
    this.firebaseUid,
  });

  // converteste profilul in JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarPath': avatarPath,
      'email': email,
      'firebaseUid': firebaseUid,
    };
  }

  // creeaza un profil din JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarPath: json['avatarPath'] as String?,
      email: json['email'] as String?,
      firebaseUid: json['firebaseUid'] as String?,
    );
  }
}

// manager pentru profiluri
// gestioneaza profilurile utilizatorilor
class ProfileManager {
  static const String _profilesKey = 'profiles';
  static const String _currentProfileKey = 'current_profile';
  static const _uuid = Uuid();

  // ia toate profilurile
  static Future<List<UserProfile>> getProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getStringList(_profilesKey) ?? [];
      
      return profilesJson
          .map((json) => UserProfile.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('Eroare la incarcarea profilurilor: $e');
      return [];
    }
  }

  // ia profilul curent
  static Future<UserProfile?> getCurrentProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final currentId = prefs.getString(_currentProfileKey);
    
    if (currentId == null) return null;
    
    final profiles = await getProfiles();
    return profiles.firstWhere(
      (profile) => profile.id == currentId,
      orElse: () => profiles.first,
    );
  }

  // seteaza profilul curent
  static Future<void> setCurrentProfile(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentProfileKey, profileId);
  }

  // creeaza un profil nou
  static Future<UserProfile?> createProfile(String name, {String? avatarPath}) async {
    try {
      print('Incepe crearea profilului: $name');
      final profiles = await getProfiles();
      
      final newProfile = UserProfile(
        id: _uuid.v4(),
        name: name,
        avatarPath: avatarPath,
      );
      
      print('Profil nou creat cu ID: ${newProfile.id}');
      profiles.add(newProfile);
      
      await _saveProfiles(profiles);
      print('Profil salvat in SharedPreferences');
      
      // daca e primul profil, il seteaza ca curent
      if (profiles.length == 1) {
        await setCurrentProfile(newProfile.id);
        print('Profil setat ca curent');
      }
      
      return newProfile;
    } catch (e) {
      print('Eroare la crearea profilului: $e');
      return null;
    }
  }

  // actualizeaza un profil
  static Future<void> updateProfile(UserProfile profile) async {
    final profiles = await getProfiles();
    final index = profiles.indexWhere((p) => p.id == profile.id);
    
    if (index != -1) {
      profiles[index] = profile;
      await _saveProfiles(profiles);
    }
  }

  // sterge un profil
  static Future<void> deleteProfile(String profileId) async {
    final profiles = await getProfiles();
    profiles.removeWhere((profile) => profile.id == profileId);
    await _saveProfiles(profiles);
    
    // daca profilul sters era cel curent, seteaza primul profil ca curent
    final currentProfile = await getCurrentProfile();
    if (currentProfile?.id == profileId && profiles.isNotEmpty) {
      await setCurrentProfile(profiles.first.id);
    }
  }

  // salveaza toate profilurile
  static Future<void> _saveProfiles(List<UserProfile> profiles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = profiles
          .map((profile) => jsonEncode(profile.toJson()))
          .toList();
      await prefs.setStringList(_profilesKey, profilesJson);
      print('Profiluri salvate cu succes: ${profiles.length}');
    } catch (e) {
      print('Eroare la salvarea profilurilor: $e');
      rethrow;
    }
  }

  // For Firebase linking
  static Future<void> linkProfileToFirebase(String id, String email, String firebaseUid) async {
    final profiles = await getProfiles();
    final idx = profiles.indexWhere((p) => p.id == id);
    if (idx != -1) {
      profiles[idx].email = email;
      profiles[idx].firebaseUid = firebaseUid;
      await _saveProfiles(profiles);
    }
  }

  // exporta toate datele
  static Future<String> exportAllData() async {
    try {
      print('Incepe exportul datelor...');
      
      // ia toate profilurile
      final profiles = await getProfiles();
      final profilesData = profiles.map((p) => p.toJson()).toList();
      
      // ia toate intrarile de stare
      final prefs = await SharedPreferences.getInstance();
      final moodEntriesJson = prefs.getStringList('mood_entries') ?? [];
      final moodEntries = moodEntriesJson.map((e) {
        final decoded = jsonDecode(e);
        if (decoded is Map || decoded is List) {
          return decoded;
        } else {
          // Optionally log or handle the invalid entry
          return null;
        }
      }).where((e) => e != null).toList();
      
      // creeaza obiectul cu toate datele
      final exportData = {
        'profiles': profilesData,
        'mood_entries': moodEntries,
        'export_date': DateTime.now().toIso8601String(),
      };
      
      // converteste in JSON
      final jsonString = jsonEncode(exportData);
      
      // salveaza in fisier
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/selfwave_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);
      
      print('Date exportate cu succes in: ${file.path}');
      return file.path;
    } catch (e) {
      print('Eroare la exportul datelor: $e');
      rethrow;
    }
  }

  // importa date din fisier
  static Future<void> importData(String filePath) async {
    try {
      print('Incepe importul datelor din: $filePath');
      
      // citeste fisierul
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final importData = jsonDecode(jsonString);
      
      // importa profilurile
      final profiles = (importData['profiles'] as List)
          .map((p) => UserProfile.fromJson(p))
          .toList();
      await _saveProfiles(profiles);
      
      // importa intrarile de stare
      final prefs = await SharedPreferences.getInstance();
      final moodEntries = (importData['mood_entries'] as List)
          .map((e) => jsonEncode(e))
          .toList();
      await prefs.setStringList('mood_entries', moodEntries);
      
      print('Date importate cu succes');
    } catch (e) {
      print('Eroare la importul datelor: $e');
      rethrow;
    }
  }

  // incarca profilul curent
  static Future<UserProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_currentProfileKey);
    if (json == null) {
      return UserProfile(id: _uuid.v4(), name: 'Utilizator');
    }
    return UserProfile.fromJson(Map<String, dynamic>.from(
      const JsonDecoder().convert(json),
    ));
  }

  // salveaza profilul
  static Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentProfileKey, const JsonEncoder().convert(profile.toJson()));
  }

  // arata ecranul de gestionare a profilurilor
  static Future<void> showProfileManagement(BuildContext context) async {
    // TODO: implementeaza ecranul de gestionare
  }
} 