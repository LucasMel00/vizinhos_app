import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onFinish;
  const OnboardingScreen({Key? key, this.onFinish}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      icon: Icons.store_mall_directory,
      title: 'Bem-vindo ao Vizinhos App',
      description: 'Encontre produtos caseiros e serviços próximos de você.',
      features: [
        'Compre de vizinhos',
        'Apoie o comércio local',
        'Descubra lojas próximas',
      ],
    ),
    _OnboardingPageData(
      icon: Icons.search,
      title: 'Explore Lojas e Produtos',
      description: 'Navegue por categorias e encontre o que precisa.',
      features: [
        'Categorias como Doces, Salgados e Bebidas',
        'Detalhes e avaliações',
        'Busca fácil',
      ],
    ),
    _OnboardingPageData(
      icon: Icons.shopping_cart,
      title: 'Pedidos Simplificados',
      description: 'Adicione ao carrinho e finalize rapidamente.',
      features: [
        'Carrinho fácil',
        'Entrega ou retirada',
        'Acompanhe seus pedidos',
      ],
    ),
    _OnboardingPageData(
      icon: Icons.store,
      title: 'Seja um Vendedor',
      description: 'Crie sua loja e venda para a comunidade.',
      features: [
        'Cadastro rápido',
        'Gerencie produtos',
        'Receba pedidos',
      ],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

Future<void> _finishOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboardingComplete', true);
  widget.onFinish?.call();
}


  List<Widget> _buildPageIndicators() {
    return List.generate(_pages.length, (i) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: i == _currentPage ? 18.0 : 10.0,
        height: 10.0,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: i == _currentPage ? Color(0xFFFbbc2c) : Colors.grey[300],
          borderRadius: BorderRadius.circular(12.0),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botão pular
            Padding(
              padding: const EdgeInsets.only(top: 16.0, right: 16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: const Text(
                    'Pular',
                    style: TextStyle(
                      color: Color(0xFFFbbc2c),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Color(0xFFFbbc2c).withOpacity(0.15),
                          child: Icon(page.icon, size: 70, color: Color(0xFFFbbc2c)),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ...page.features.map((feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFFFbbc2c), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Indicadores
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildPageIndicators(),
              ),
            ),
            // Botão próximo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFbbc2c),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                ),
                onPressed: _nextPage,
                child: Text(
                  _currentPage == _pages.length - 1 ? 'Começar' : 'Próximo',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;

  _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
  });
}
