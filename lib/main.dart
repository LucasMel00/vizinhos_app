import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import 'package:vizinhos_app/screens/splash/splash_screen.dart';
import 'package:vizinhos_app/screens/cart/cart_screen.dart';
import 'package:vizinhos_app/screens/provider/cart_provider.dart';
import 'package:vizinhos_app/screens/provider/orders_provider.dart';
import 'package:vizinhos_app/services/auth_provider.dart';

// Plugin para notificações locais
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Handler para notificações em segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 Notificação recebida em segundo plano: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Inicialização do flutter_local_notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Configura o handler para mensagens em background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
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
    // Solicita permissões no iOS
    await _messaging.requestPermission();

    // Obtém e imprime o token do dispositivo
    final token = await _messaging.getToken();
    print('📲 FCM Token: $token');

    // Quando o app está em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('📩 Mensagem recebida em foreground: ${message.notification?.title}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'default_channel_id', // id do canal
          'Notificações padrão', // nome do canal
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
          payload: 'item x', // opcional: payload para ação na notificação
        );
      }
    });

    // Quando o usuário clica em uma notificação (app aberto pelo clique)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📬 Notificação clicada: ${message.notification?.title}');
      // Navegue para a tela desejada aqui se quiser
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
      },
    );
  }
}
