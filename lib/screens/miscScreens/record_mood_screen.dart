// ecranul pentru inregistrarea starii de spirit
// aici poti spune cum te simti

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/mood_entry.dart';

// ecran pentru inregistrarea starilor
class RecordMoodScreen extends StatefulWidget {
  const RecordMoodScreen({super.key});

  @override
  State<RecordMoodScreen> createState() => _RecordMoodScreenState();
}

class _RecordMoodScreenState extends State<RecordMoodScreen> {
  int _moodLevel = 3;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _notesController = TextEditingController();
  String? _selectedMood;

  // salveaza intrarea
  Future<void> _saveMoodEntry() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList('mood_entries') ?? [];
    
    final entry = {
      'mood': _moodLevel,
      'date': _selectedDate.toIso8601String(),
      'time': '${_selectedTime.hour}:${_selectedTime.minute}',
      'notes': _notesController.text,
    };
    
    entries.add(jsonEncode(entry));
    await prefs.setStringList('mood_entries', entries);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starea a fost salvata!')),
      );
      Navigator.pop(context);
    }
  }

  // alege data
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // alege ora
  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.howAreYouFeelingToday),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // nivel stare
            const Text(
              'Cum te simti?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final level = index + 1;
                IconData moodIcon;
                switch (level) {
                  case 1:
                    moodIcon = Icons.sentiment_very_dissatisfied;
                    break;
                  case 2:
                    moodIcon = Icons.sentiment_dissatisfied;
                    break;
                  case 3:
                    moodIcon = Icons.sentiment_neutral;
                    break;
                  case 4:
                    moodIcon = Icons.sentiment_satisfied;
                    break;
                  case 5:
                    moodIcon = Icons.sentiment_very_satisfied;
                    break;
                  default:
                    moodIcon = Icons.sentiment_neutral;
                }
                
                return IconButton(
                  icon: Icon(
                    moodIcon,
                    size: 40,
                    color: index < _moodLevel
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  onPressed: () {
                    setState(() {
                      _moodLevel = level;
                    });
                  },
                  tooltip: l10n.moodLevel(level),
                );
              }),
            ),
            const SizedBox(height: 20),
            
            // data si ora
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _selectDate,
                  child: const Text('Schimba Data'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _selectTime,
                  child: const Text('Schimba Ora'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // note
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
                hintText: 'Adauga note suplimentare...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            
            // buton salvare
            ElevatedButton(
              onPressed: _saveMoodEntry,
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Salveaza', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}