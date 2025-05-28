// serviciu pentru notificari
// trimite notificari catre utilizator

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // initializeaza serviciul
  Future<void> initialize() async {
    if (_initialized) return;

    print('Initializare serviciu notificari...');
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    print('Plugin notificari initializat');

    // cere permisiuni pentru Android
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      print('Permisiune notificari Android: $granted');
    }

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notificare apasata: ${response.payload}');
  }

  // cere permisiuni
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    bool? androidGranted;

    if (android != null) {
      androidGranted = await android.requestNotificationsPermission();
      print('Permisiune notificari Android ceruta: $androidGranted');
    }

    return androidGranted ?? false;
  }

  // programeaza o notificare de test
  Future<void> scheduleTestNotification() async {
    print('Programare notificare test...');
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Notificari Test',
      channelDescription: 'Canal pentru testarea notificarilor',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    try {
      // incearca o notificare imediata
      print('Afisare notificare imediata...');
      await _notifications.show(
        998,
        'Test Imediat',
        'Aceasta este o notificare de test imediata',
        details,
      );
      print('Notificare imediata afisata');

      // programeaza una pentru peste 5 secunde
      final now = DateTime.now();
      final scheduledTime = now.add(const Duration(seconds: 5));
      print('Programare notificare pentru: $scheduledTime');

      await _notifications.zonedSchedule(
        999,
        'Test Programat',
        'Aceasta este o notificare de test programata',
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('Notificare test programata cu succes');
    } catch (e) {
      print('Eroare cu notificarile: $e');
    }
  }

  // programeaza o notificare pentru stare
  Future<void> scheduleMoodReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required bool repeats,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'mood_reminders',
      'Notificari Stare',
      channelDescription: 'Notificari pentru inregistrarea starilor',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      category: AndroidNotificationCategory.reminder,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    if (repeats) {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // anuleaza o notificare
  Future<void> cancelReminder(int id) async {
    if (!_initialized) await initialize();
    await _notifications.cancel(id);
  }

  // anuleaza toate notificarile
  Future<void> cancelAllReminders() async {
    if (!_initialized) await initialize();
    await _notifications.cancelAll();
  }

  // ia toate notificarile programate
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) await initialize();
    return await _notifications.pendingNotificationRequests();
  }
} 