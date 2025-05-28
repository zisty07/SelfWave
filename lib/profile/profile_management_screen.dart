import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'profile_manager.dart';

// ecran pentru gestionarea profilurilor
class ProfileManagementScreen extends StatefulWidget {
  final VoidCallback? onProfileChanged;

  const ProfileManagementScreen({
    super.key,
    this.onProfileChanged,
  });

  @override
  State<ProfileManagementScreen> createState() => _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  List<UserProfile> _profiles = [];
  String? _currentProfileId;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // incarca profilurile
  Future<void> _load() async {
    try {
      final profiles = await ProfileManager.getProfiles();
      final current = await ProfileManager.getCurrentProfile();
      
      if (mounted) {
        setState(() {
          _profiles = profiles;
          _currentProfileId = current?.id;
        });
      }
    } catch (e) {
      print('Error loading profiles: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profiles: $e')),
        );
      }
    }
  }

  // alege o imagine
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    
    if (picked != null) {
      setState(() {
        _avatarPath = picked.path;
      });
    }
  }

  // adauga sau editeaza un profil
  Future<void> _addOrEditProfile({UserProfile? profile}) async {
    final nameController = TextEditingController(text: profile?.name);
    String? avatarPath = profile?.avatarPath ?? _avatarPath;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(profile == null ? 'Profil Nou' : 'Editeaza Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // imagine profil
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 40,
                backgroundImage: avatarPath != null
                    ? FileImage(File(avatarPath))
                    : null,
                child: avatarPath == null
                    ? const Icon(Icons.add_a_photo, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            // nume profil
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nume',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuleaza'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Numele nu poate fi gol')),
                );
                return;
              }
              
              try {
                if (profile == null) {
                  final newProfile = await ProfileManager.createProfile(name, avatarPath: avatarPath);
                  if (newProfile == null) {
                    throw Exception('Nu s-a putut crea profilul');
                  }
                } else {
                  final updated = UserProfile(
                    id: profile.id,
                    name: name,
                    avatarPath: avatarPath,
                    email: profile.email,
                    firebaseUid: profile.firebaseUid,
                  );
                  await ProfileManager.updateProfile(updated);
                }
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Eroare: ${e.toString()}')),
                );
              }
            },
            child: Text(profile == null ? 'Adauga' : 'Salveaza'),
          ),
        ],
      ),
    );
    await _load();
    widget.onProfileChanged?.call();
  }

  // sterge un profil
  Future<void> _deleteProfile(UserProfile profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sterge Profil'),
        content: Text('Esti sigur ca vrei sa stergi profilul "${profile.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuleaza'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sterge', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await ProfileManager.deleteProfile(profile.id);
      await _load();
      widget.onProfileChanged?.call();
    }
  }

  // schimba profilul curent
  Future<void> _switchProfile(UserProfile profile) async {
    try {
      await ProfileManager.setCurrentProfile(profile.id);
      if (mounted) {
        setState(() {
          _currentProfileId = profile.id;
        });
        widget.onProfileChanged?.call();
        Navigator.of(context).pop(true); // Return true to indicate profile was changed
      }
    } catch (e) {
      print('Error switching profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error switching profile: $e')),
        );
      }
    }
  }

  // exporta datele
  Future<void> _exportData() async {
    try {
      final filePath = await ProfileManager.exportAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Date exportate in: $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la export: $e')),
        );
      }
    }
  }

  // importa datele
  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result != null) {
        final filePath = result.files.single.path!;
        await ProfileManager.importData(filePath);
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Date importate cu succes')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare la import: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(false); // Return false to indicate no changes
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestioneaza Profiluri'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.file_upload),
              onPressed: _exportData,
              tooltip: 'Exporta Date',
            ),
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: _importData,
              tooltip: 'Importa Date',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addOrEditProfile(),
              tooltip: 'Adauga Profil',
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: _profiles.length,
          itemBuilder: (context, index) {
            final profile = _profiles[index];
            final isCurrent = profile.id == _currentProfileId;
            
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: profile.avatarPath != null
                    ? FileImage(File(profile.avatarPath!))
                    : null,
                child: profile.avatarPath == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(
                profile.name,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: isCurrent ? const Text('Profil curent') : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCurrent)
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: () => _switchProfile(profile),
                      tooltip: 'Selecteaza profilul',
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _addOrEditProfile(profile: profile),
                    tooltip: 'Editeaza profilul',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteProfile(profile),
                    tooltip: 'Sterge profilul',
                  ),
                ],
              ),
              tileColor: isCurrent
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isCurrent
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: isCurrent ? 2 : 1,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            );
          },
          padding: const EdgeInsets.all(16),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addOrEditProfile(),
          child: const Icon(Icons.add),
          tooltip: 'Adauga profil nou',
        ),
      ),
    );
  }
} 