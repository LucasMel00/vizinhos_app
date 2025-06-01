import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/screens/provider/notification_provider.dart'; // Importar NotificationProvider
import 'package:vizinhos_app/notifications_screen.dart'; // Importar NotificationsScreen
import 'package:vizinhos_app/screens/splash/splash_screen.dart';
import 'package:vizinhos_app/screens/cart/cart_screen.dart';
import 'package:vizinhos_app/screens/provider/cart_provider.dart';
import 'package:vizinhos_app/screens/provider/orders_provider.dart';
import 'package:vizinhos_app/screens/provider/favorites_provider.dart';
import 'package:vizinhos_app/services/auth_provider.dart';

// Plugin para notificações locais
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Handler para notificações em segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 Notificação recebida em segundo plano: ${message.messageId}');
  // NOTA: Adicionar notificações ao SharedPreferences aqui para serem carregadas pelo Provider depois
  // Esta parte requer uma implementação cuidadosa para comunicação entre isolates ou acesso direto ao SharedPreferences.
  // Por simplicidade e foco no pedido principal, esta parte não será completamente implementada aqui.
  // O ideal seria ter uma forma de o NotificationProvider ser notificado ou recarregar.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    await _messaging.requestPermission();

    final token = await _messaging.getToken();
    print('📲 FCM Token: $token');
    final secureStorage = FlutterSecureStorage();
    await secureStorage.write(key: 'fcmToken', value: token);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final fcmToken = await secureStorage.read(key: 'fcmToken');
    if (fcmToken != null) {
      authProvider.setFcmToken(fcmToken);
    }
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print(
          '📩 Mensagem recebida em foreground: ${message.notification?.title}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        if (mounted) {
          Provider.of<NotificationProvider>(context, listen: false)
              .addNotification(notification.title ?? 'Sem Título',
                  notification.body ?? 'Sem Conteúdo');
        }

        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
          'default_channel_id',
          'Notificações padrão',
          channelDescription: 'Este canal é usado para notificações padrão.',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

        const NotificationDetails platformDetails =
            NotificationDetails(android: androidDetails);

        await flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          platformDetails,
          payload: message.data['screen'],
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📬 Notificação clicada: ${message.notification?.title}');
      final notification = message.notification;
      if (notification != null) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vizinhos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFFbbc2c),
        scaffoldBackgroundColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFFFbbc2c),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFbbc2c),
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        CartScreen.routeName: (ctx) => const CartScreen(),
        NotificationsScreen.routeName: (ctx) => const NotificationsScreen(),
      },
    );
  }
}
