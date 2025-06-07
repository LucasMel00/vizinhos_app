# 📱 Vizinhos : A comida do vizinho é sempre melhor que a sua!

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) <!-- Adicionar badges relevantes, como build status -->

O Vizinhos App é uma plataforma móvel desenvolvida em Flutter, projetada para fortalecer os laços comunitários, facilitando a descoberta e a compra de produtos e serviços oferecidos por vizinhos. Ele permite que usuários explorem o comércio local ou criem suas próprias lojas virtuais, promovendo a economia de bairro de maneira simples, segura e intuitiva.

## Funcionalidades Principais

O aplicativo oferece um conjunto robusto de funcionalidades para compradores e vendedores:

*   **Cadastro e Gestão de Lojas:** Vendedores podem facilmente criar e gerenciar suas lojas virtuais, adicionando informações essenciais como nome, categorias de produtos, endereço (integrado com geolocalização) e descrições detalhadas. A gestão de produtos permite adicionar itens com fotos, preços, descrições e controle de estoque.
*   **Descoberta Inteligente:** Compradores podem encontrar produtos e lojas de forma eficiente utilizando filtros por nome, categoria ou proximidade geográfica. A integração com mapas permite visualizar as lojas disponíveis na vizinhança.
*   **Interação e Avaliação:** O sistema de avaliações permite que usuários compartilhem suas experiências sobre lojas e produtos, contribuindo para a confiança e a transparência na comunidade.
*   **Autenticação Segura:** O processo de login e cadastro garante a segurança dos dados do usuário. A gestão de perfil permite que os usuários atualizem suas informações pessoais e de loja.
*   **Notificações:** Mantenha-se atualizado sobre pedidos, novas lojas ou promoções através de notificações push e locais.

<!-- Sugestão: Adicionar screenshots ou um GIF demonstrando o app -->

## Tecnologias Utilizadas

O Vizinhos App foi construído utilizando um conjunto moderno de tecnologias para garantir uma experiência multiplataforma fluida, segura e escalável:

*   **Frontend & UI:**
    *   **Flutter:** Framework principal para desenvolvimento multiplataforma (Android, iOS, Web, Desktop) com uma única base de código Dart.
    *   **Provider:** Gerenciamento de estado declarativo e eficiente.
    *   **Cupertino Icons:** Ícones no estilo iOS.
    *   **Flutter SVG:** Renderização de imagens vetoriais SVG.
    *   **Lottie:** Animações vetoriais de alta qualidade.
    *   **Shimmer:** Efeito de carregamento para melhor feedback visual.
    *   **Flutter Rating Stars:** Componente para exibição de avaliações.
    *   **Flutter Masked Text2 & Mask Text Input Formatter:** Formatação de campos de entrada (ex: telefone, moeda).
    *   **IM Stepper:** Componente visual para indicar progresso em etapas.
    *   **FL Chart:** Criação de gráficos e visualizações de dados.
*   **Backend & Cloud:**
    *   **Firebase:**
        *   **Firebase Messaging:** Envio e recebimento de notificações push.
        *   **Flutter Local Notifications:** Exibição de notificações no dispositivo.
    *   **AWS:**
      *   **DynamoDB:** Banco de dados NoSQL gerenciado pela AWS, utilizado para armazenamento de dados da aplicação (via `aws_dynamodb_api`).
      *   **Lambda: ** API REST para criação dos ENDPOINTS da aplicação.
*   **Armazenamento Local:**
    *   **Shared Preferences:** Armazenamento simples de pares chave-valor.
    *   **Flutter Secure Storage:** Armazenamento seguro de dados sensíveis (tokens, senhas).
*   **APIs & Integrações:**
    *   **HTTP:** Realização de requisições a APIs RESTful.
    *   **Permission Handler:** Gerenciamento de permissões do dispositivo (câmera, localização, etc.).
    *   **Image Picker & File Picker:** Seleção de imagens e arquivos da galeria ou câmera.
    *   **URL Launcher:** Abertura de URLs externas no navegador ou outros aplicativos.
*   **Utilitários:**
    *   **Intl Phone Number Input:** Campo de entrada formatado para números de telefone internacionais.
    *   **Dart JSON Web Token:** Manipulação de JSON Web Tokens (JWT), possivelmente para autenticação ou comunicação segura.
    *   **Flutter Launcher Icons:** Geração automática de ícones do aplicativo para diferentes plataformas.

## Pré-requisitos

Antes de começar, certifique-se de ter instalado em seu ambiente de desenvolvimento:

*   **Flutter SDK:** Versão 3.x ou superior. Siga o [guia oficial de instalação](https://flutter.dev/docs/get-started/install).
*   **IDE:** Android Studio ou Visual Studio Code com as extensões Flutter e Dart.
*   **Emulador/Dispositivo:** Um emulador Android/iOS configurado ou um dispositivo físico.
*   **Git:** Para clonar o repositório.
*   **Contas e Chaves de API:**
    *   **Firebase:** Uma conta no Firebase e um projeto configurado para usar Firebase Messaging.
## Instalação e Configuração

Siga os passos abaixo para configurar e executar o projeto localmente:

1.  **Clone o Repositório:**
    ```bash
    git clone https://github.com/LucasMel00/vizinhos_app.git
    cd vizinhos_app
    ```

2.  **Instale as Dependências:**
    ```bash
    flutter pub get
    ```

3.  **Configure as Chaves de API e Variáveis de Ambiente:**
    *   **Firebase:** Adicione os arquivos de configuração do Firebase (`google-services.json` para Android e `GoogleService-Info.plist` para iOS) nos diretórios apropriados (`android/app/` e `ios/Runner/`).
    *   **Google Maps API Key:** Configure a chave da API do Google Maps nos arquivos de manifesto nativos (AndroidManifest.xml para Android e AppDelegate.swift/m para iOS).
    *   **AWS Credentials:** Configure as credenciais da AWS. Isso pode envolver a configuração de variáveis de ambiente ou um arquivo de configuração específico, dependendo de como a biblioteca `aws_dynamodb_api` está sendo utilizada no projeto. Consulte a documentação da biblioteca ou o código-fonte para obter detalhes.
    *   _(Verifique se há outros arquivos de configuração ou variáveis de ambiente necessárias, como um arquivo `.env`)_

4.  **Gere os Ícones do Aplicativo (se necessário):**
    ```bash
    flutter pub run flutter_launcher_icons:main
    ```

5.  **Execute o Aplicativo:**
    ```bash
    flutter run
    ```
    Selecione o emulador ou dispositivo desejado quando solicitado.

## Estrutura do Projeto

O projeto segue uma estrutura padrão do Flutter, com as principais pastas sendo:

*   `lib/`: Contém todo o código Dart da aplicação (telas, widgets, lógica de negócios, modelos, etc.).
*   `assets/`: Armazena ativos estáticos como imagens, fontes e arquivos de animação (Lottie).
*   `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/`: Contêm os códigos e configurações específicas de cada plataforma.
*   `pubspec.yaml`: Arquivo de manifesto do projeto, onde as dependências e metadados são definidos.

## Contribuições

Contribuições são bem-vindas! Se você deseja contribuir com o projeto, por favor, siga estas etapas:

1.  Faça um fork do repositório.
2.  Crie uma nova branch para sua feature ou correção (`git checkout -b minha-feature`).
3.  Implemente suas alterações.
4.  Faça commit das suas alterações (`git commit -m 'Adiciona nova feature'`).
5.  Faça push para a branch (`git push origin minha-feature`).
6.  Abra um Pull Request.

## Licença

Este projeto está licenciado sob a Licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes (Nota: Adicionar um arquivo LICENSE ao repositório se ainda não existir).

## Contato

Lucas Melo - melo.goncalves@aluno.ifsp.edu.br

Link do Projeto: [https://github.com/LucasMel00/vizinhos_app](https://github.com/LucasMel00/vizinhos_app)


   git clone https://github.com/seu-usuario/vizinhos-app.git
   cd vizinhos-app
