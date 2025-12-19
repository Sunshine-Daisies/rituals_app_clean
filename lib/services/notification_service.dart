import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

// Background message handler (top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 Background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  // Notification channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'rituals_notifications',
    'Rituals Notifications',
    description: 'Rituals App notifications',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  // Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Firebase'i başlat
      await Firebase.initializeApp();
      
      // Background handler'ı kaydet
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // İzinleri iste
      await _requestPermissions();

      // Local notifications'ı başlat
      await _initLocalNotifications();

      // FCM token'ı al ve backend'e gönder
      await _getFcmToken();

      // Token refresh listener
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _sendTokenToBackend(newToken);
      });

      // Foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Background/terminated message opened handler
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check if app was opened from notification
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      _initialized = true;
      print('✅ NotificationService initialized');
    } catch (e) {
      print('❌ NotificationService initialization error: $e');
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('🔔 Notification permission: ${settings.authorizationStatus}');
  }

  // Initialize local notifications
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android notification channel oluştur
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
  }

  // Get FCM token
  Future<void> _getFcmToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('🔑 FCM Token: $_fcmToken');
      
      if (_fcmToken != null) {
        await _sendTokenToBackend(_fcmToken!);
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  // Send FCM token to backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      
      if (authToken == null) {
        print('⚠️ No auth token, skipping FCM token registration');
        return;
      }

      final response = await ApiService.post(
        '/notifications/fcm-token',
        {'fcm_token': token},
        authToken: authToken,
      );

      if (response != null) {
        print('✅ FCM token sent to backend');
      }
    } catch (e) {
      print('❌ Error sending FCM token to backend: $e');
    }
  }

  // Handle foreground message
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('🔔 Foreground message: ${message.notification?.title}');
    
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  // Handle message opened app (when user taps notification)
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('🔔 Message opened app: ${message.data}');
    
    final type = message.data['type'];
    
    // Bildirim tipine göre navigasyon yapılabilir
    switch (type) {
      case 'streak_warning':
        // Rituals sayfasına yönlendir
        break;
      case 'partner_completed':
        // Ritual detay sayfasına yönlendir
        break;
      case 'friend_request':
        // Arkadaşlar sayfasına yönlendir
        break;
      case 'badge_earned':
        // Badge sayfasına yönlendir
        break;
      case 'level_up':
        // Profil sayfasına yönlendir
        break;
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        final type = data['type'] as String?;
        // Navigasyon logic'i buraya - type'a göre yönlendirme yapılacak
        print('Notification type: $type');
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  // Remove FCM token (logout sırasında çağır)
  Future<void> removeToken() async {
    try {
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        final authToken = prefs.getString('auth_token');
        
        if (authToken != null) {
          await ApiService.delete(
            '/notifications/fcm-token',
            body: {'fcm_token': _fcmToken},
            authToken: authToken,
          );
        }
      }
      
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      print('✅ FCM token removed');
    } catch (e) {
      print('❌ Error removing FCM token: $e');
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('✅ Subscribed to topic: $topic');
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('✅ Unsubscribed from topic: $topic');
  }
}
