📱 Vizinhos App
Vizinhos é um aplicativo que conecta pessoas da mesma comunidade, permitindo que usuários comprem e vendam produtos e serviços locais de forma fácil e segura. Com foco em promover o comércio local, o app oferece uma plataforma intuitiva para vendedores cadastrarem suas lojas e produtos, e para compradores encontrarem ofertas próximas de casa.

🚀 Funcionalidades Principais
Cadastro de Lojas: Vendedores podem criar perfis de lojas, adicionar categorias de produtos e gerenciar informações como endereço e descrição.

Listagem de Produtos: Vendedores podem cadastrar produtos com fotos, preços e descrições.

Busca e Filtros: Compradores podem buscar produtos por categoria, preço ou proximidade.

Avaliações e Comentários: Usuários podem avaliar lojas e produtos, promovendo transparência e confiança.

Integração com Mapas: Visualização de lojas próximas usando geolocalização.

Autenticação Segura: Login e registro com OAuth2 para garantir a segurança dos dados dos usuários.

Notificações: Alertas sobre novas ofertas, pedidos e atualizações de status.

🛠️ Tecnologias Utilizadas
Flutter: Framework para desenvolvimento multiplataforma (iOS e Android).

Dart: Linguagem de programação utilizada no Flutter.

Firebase: Autenticação, banco de dados em tempo real e notificações push.

API RESTful: Integração com backend para gerenciamento de lojas, produtos e pedidos.

Provider: Gerenciamento de estado no Flutter.

Google Maps API: Integração de mapas e geolocalização.

File Picker: Seleção de imagens para upload de fotos de produtos e lojas.

📂 Estrutura do Projeto
Copy
vizinhos_app/
├── lib/
│   ├── screens/
│   │   ├── User/               # Telas do usuário (comprador)
│   │   ├── Vendor/             # Telas do vendedor
│   │   ├── Auth/               # Telas de autenticação (login, registro)
│   │   ├── Orders/             # Telas de pedidos
│   │   └── Search/             # Telas de busca e filtros
│   ├── services/               # Serviços (API, autenticação, etc.)
│   ├── models/                 # Modelos de dados (lojas, produtos, etc.)
│   ├── widgets/                # Componentes reutilizáveis
│   └── main.dart               # Ponto de entrada do app
├── assets/                     # Imagens, ícones e fontes
├── test/                       # Testes unitários e de integração
└── pubspec.yaml                # Dependências e configurações do projeto
🚀 Como Executar o Projeto
Pré-requisitos
Flutter SDK: Instale o Flutter seguindo o guia oficial.

Android Studio / Xcode: Para emular o app em dispositivos Android ou iOS.

Firebase: Configure um projeto no Firebase e adicione os arquivos de configuração (google-services.json para Android e GoogleService-Info.plist para iOS).

Passos para Executar
Clone o repositório:

bash
Copy
git clone https://github.com/seu-usuario/vizinhos-app.git
cd vizinhos-app
Instale as dependências:

bash
Copy
flutter pub get
Execute o app:

bash
Copy
flutter run
Para gerar uma versão de release:

bash
Copy
flutter build apk --release  # Para Android
flutter build ios --release  # Para iOS
