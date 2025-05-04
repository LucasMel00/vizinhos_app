import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/services/auth_provider.dart';
import 'package:vizinhos_app/screens/splash/splash_screen.dart';
import 'package:vizinhos_app/screens/provider/cart_provider.dart'; // Import CartProvider
import 'package:vizinhos_app/screens/cart/cart_screen.dart'; // Import CartScreen

void main() {
  // Garante que o binding Flutter esteja inicializado
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider(), // Adiciona o CartProvider
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vizinhos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFFbbc2c),
        scaffoldBackgroundColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Opcional: Definir a cor de destaque para combinar com a primária
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFFFbbc2c), // Cor de acento
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFbbc2c), // Cor padrão da AppBar
          foregroundColor: Colors.white, // Cor padrão do texto/ícones da AppBar
        ),
      ),
      home: const SplashScreen(),
      // Adiciona as rotas
      routes: {
        CartScreen.routeName: (ctx) => const CartScreen(), // Rota para a tela do carrinho
        // Adicione outras rotas nomeadas aqui, se houver
      },
    );
  }
}

