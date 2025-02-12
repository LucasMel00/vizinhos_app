import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  static const routeName = '/terms';

  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final headlineStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: primaryColor,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos e Políticas'),
        backgroundColor: primaryColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Termos de Uso',
                style: headlineStyle,
              ),
              const SizedBox(height: 16),
              const Text(
                'Política de Privacidade - [Vizinhos]\n'
                'Data de Vigência: [2025]\n\n'
                'Esta Política de Privacidade descreve como [Nome da Empresa ou Site] (“nós”, “nosso” ou “empresa”) coleta, armazena, utiliza, compartilha e protege as informações dos usuários (“você” ou “usuário”) que acessam ou utilizam nossos serviços, produtos e/ou nosso site. Nosso compromisso é assegurar a transparência no tratamento dos dados pessoais e adotar medidas técnicas e administrativas para protegê-los.\n\n'
                '1. Introdução\n'
                'Sua privacidade é fundamental para nós. Esta política tem como objetivo informar, de maneira clara e detalhada, quais dados são coletados, por que são coletados, como são utilizados e quais medidas de segurança adotamos para proteger suas informações. Ao acessar ou utilizar nossos serviços, você concorda com as práticas descritas neste documento.\n\n'
                '2. Quais Dados Coletamos\n'
                '2.1. Dados Pessoais Fornecidos Diretamente\n'
                'Coletamos informações que você nos fornece de forma direta, tais como:\n'
                '- Informações de Identificação: Nome, sobrenome, CPF/CNPJ, data de nascimento.\n'
                '- Informações de Contato: Endereço, e-mail, telefone.\n'
                '- Dados de Acesso: Informações de login, como nome de usuário e senha (armazenados de forma criptografada).\n'
                '- Outros Dados: Informações adicionais que você possa fornecer ao preencher formulários, cadastrar-se em nosso site, solicitar suporte ou participar de pesquisas.\n\n'
                '2.2. Dados Coletados Automaticamente\n'
                'Durante a utilização de nossos serviços, podemos coletar automaticamente dados técnicos e comportamentais, incluindo:\n'
                '- Dados de Navegação: Endereço IP, tipo e versão do navegador, sistema operacional, páginas acessadas, data e hora do acesso.\n'
                '- Cookies e Tecnologias Similares: Utilizamos cookies, pixels e outras tecnologias para melhorar sua experiência, personalizar conteúdo e analisar o tráfego do site. Você pode gerenciar as configurações de cookies por meio das opções do seu navegador.\n\n'
                '2.3. Dados de Terceiros\n'
                'Em alguns casos, poderemos receber informações de terceiros (como parceiros, redes sociais ou provedores de pagamento) que integrem seus serviços aos nossos, sempre respeitando os limites e finalidades previstos nesta política.\n\n'
                '3. Finalidades do Tratamento de Dados\n'
                'Utilizamos os dados coletados para diversas finalidades, tais como:\n\n'
                '3.1. Prestação de Serviços e Suporte\n'
                '- Cadastro e Autenticação: Garantir o acesso seguro e personalizado à sua conta.\n'
                '- Atendimento ao Cliente: Responder dúvidas, fornecer suporte e processar solicitações.\n'
                '- Melhoria de Produtos e Serviços: Analisar padrões de uso para aprimorar funcionalidades e corrigir eventuais problemas.\n\n'
                '3.2. Marketing e Comunicação\n'
                '- Envio de Informações: Comunicar novidades, atualizações, ofertas e promoções, sempre com a possibilidade de cancelamento da inscrição.\n'
                '- Pesquisa de Satisfação: Conduzir pesquisas para melhorar a experiência do usuário e a qualidade dos nossos serviços.\n\n'
                '3.3. Análise e Melhoria Interna\n'
                '- Estatísticas e Métricas: Realizar análises e gerar relatórios para otimizar nossos processos internos e a eficiência do site.\n'
                '- Segurança e Prevenção: Monitorar e prevenir fraudes, acessos não autorizados e outras atividades que possam comprometer a segurança da plataforma.\n\n'
                '3.4. Cumprimento Legal e Contratual\n'
                '- Obrigações Legais: Atender a exigências legais, investigações judiciais ou solicitações de autoridades competentes.\n'
                '- Contratos e Acordos: Cumprir obrigações decorrentes de contratos firmados com usuários e parceiros.\n\n'
                '4. Armazenamento e Proteção dos Dados\n'
                '4.1. Infraestrutura Segura\n'
                '- Criptografia: Utilizamos criptografia para proteger dados sensíveis durante a transmissão (SSL/TLS) e, quando necessário, no armazenamento.\n'
                '- Ambientes Segregados: Os dados são armazenados em servidores seguros, com acesso restrito e segregação de ambientes de produção e testes.\n'
                '- Backups: Realizamos backups periódicos para garantir a integridade e disponibilidade das informações.\n\n'
                '4.2. Medidas Técnicas e Administrativas\n'
                '- Controle de Acesso: Implementamos mecanismos rigorosos de controle de acesso, garantindo que apenas pessoas autorizadas tenham acesso aos dados pessoais.\n'
                '- Monitoramento e Auditoria: Realizamos monitoramento contínuo e auditorias de segurança para identificar e mitigar riscos.\n'
                '- Treinamento de Equipe: Nossa equipe é regularmente treinada em boas práticas de segurança da informação e privacidade.\n\n'
                '5. Compartilhamento e Transferência de Dados\n'
                '5.1. Compartilhamento com Terceiros\n'
                'Podemos compartilhar seus dados com:\n'
                '- Prestadores de Serviço: Empresas terceirizadas que auxiliam na operação, manutenção e segurança do site (como hospedagem, processamento de pagamentos, análise de dados), sempre sob obrigações contratuais de confidencialidade e segurança.\n'
                '- Autoridades Competentes: Quando exigido por lei ou em cumprimento de ordem judicial.\n'
                '- Parcerias Comerciais: Em casos específicos, com parceiros estratégicos, desde que tais compartilhamentos estejam em conformidade com as finalidades descritas nesta política e mediante consentimento, quando necessário.\n\n'
                '5.2. Transferência Internacional\n'
                'Caso ocorra a transferência de dados para fora do território nacional, adotaremos as salvaguardas exigidas pela legislação aplicável, garantindo um nível adequado de proteção, como cláusulas contratuais padrão e outras medidas recomendadas pelos órgãos reguladores.\n\n'
                '6. Direitos dos Usuários\n'
                'Em conformidade com as normas de proteção de dados, você possui os seguintes direitos:\n'
                '- Acesso: Solicitar o acesso aos seus dados pessoais armazenados.\n'
                '- Correção: Solicitar a correção de dados incompletos, inexatos ou desatualizados.\n'
                '- Exclusão: Requerer a exclusão de dados pessoais, salvo em situações em que a manutenção seja necessária para cumprimento de obrigações legais ou contratuais.\n'
                '- Portabilidade: Solicitar a portabilidade dos dados para outro fornecedor de serviço ou produto.\n'
                '- Limitação e Oposição: Solicitar a limitação do tratamento ou se opor ao tratamento de seus dados, quando aplicável.\n'
                '- Revogação do Consentimento: Revogar o consentimento para o tratamento dos dados, sem prejuízo da legalidade do tratamento realizado com base no consentimento anteriormente dado.\n\n'
                'Para exercer esses direitos, entre em contato conosco por meio dos canais indicados na seção de Contato.\n\n'
                '7. Cookies e Tecnologias de Rastreamento\n'
                'Utilizamos cookies e tecnologias similares para:\n'
                '- Personalizar a Experiência: Adaptar conteúdos e ofertas com base no comportamento do usuário.\n'
                '- Análise de Dados: Monitorar o desempenho e o tráfego do site.\n'
                '- Publicidade: Exibir anúncios relevantes.\n\n'
                'Você pode gerenciar ou desativar os cookies diretamente pelas configurações do seu navegador. Note que a desativação pode afetar a funcionalidade de alguns recursos do site.\n\n'
                '8. Retenção de Dados\n'
                'Os dados pessoais serão mantidos pelo tempo necessário para cumprir as finalidades para as quais foram coletados, bem como para atender a obrigações legais, regulatórias ou contratuais. Após esse período, os dados serão eliminados de forma segura, de acordo com as melhores práticas do mercado.\n\n'
                '9. Alterações nesta Política\n'
                'Esta Política de Privacidade pode ser revisada e atualizada periodicamente para refletir mudanças em nossas práticas ou na legislação aplicável. Caso ocorram alterações significativas, comunicaremos os usuários por meio de aviso em destaque no site ou por e-mail, quando aplicável. Recomendamos a revisão periódica deste documento.\n\n'
                '10. Segurança da Informação\n'
                'Além das medidas já descritas, adotamos políticas internas e tecnologias avançadas para proteger os dados dos usuários contra acesso não autorizado, perda, alteração, divulgação ou qualquer forma de tratamento inadequado. Em caso de incidentes de segurança, contamos com um plano de resposta que inclui a notificação aos usuários e às autoridades competentes, conforme exigido pela legislação.\n\n'
                '11. Base Legal para o Tratamento dos Dados\n'
                'O tratamento dos seus dados pessoais se fundamenta em bases legais previstas na legislação vigente, tais como:\n'
                '- Consentimento: Quando expressamente solicitado e autorizado pelo usuário.\n'
                '- Execução de Contrato: Para a prestação dos serviços solicitados.\n'
                '- Obrigação Legal: Para o cumprimento de obrigações legais e regulatórias.\n'
                '- Interesses Legítimos: Quando necessário para a execução de atividades legítimas, desde que não prejudiquem os direitos e liberdades fundamentais do titular.\n\n'
                '12. Contato\n'
                'Em caso de dúvidas, solicitações ou reclamações referentes a esta Política de Privacidade ou ao tratamento dos seus dados pessoais, entre em contato conosco através dos seguintes canais:\n'
                '- E-mail: [inserir e-mail de contato]\n'
                '- Telefone: [inserir telefone]\n'
                '- Endereço: [inserir endereço físico, se aplicável]\n\n'
                'Nossa equipe está disponível para atender suas solicitações e prestar esclarecimentos adicionais.\n\n'
                '13. Disposições Finais\n'
                'Esta Política de Privacidade é regida pelas leis [inserir país ou região, ex.: "da República Federativa do Brasil"] e quaisquer controvérsias decorrentes serão submetidas ao foro da comarca [inserir comarca], com exclusão de qualquer outro, por mais privilegiado que seja.\n\n'
                'Ao utilizar nossos serviços, você declara ter lido, compreendido e aceitado os termos desta política, concordando com o tratamento de seus dados conforme aqui descrito.\n\n'
                'Observação: Este documento é um modelo e deve ser adaptado às necessidades e especificidades do seu negócio. Recomenda-se a consulta a um profissional jurídico especializado em proteção de dados para garantir a conformidade completa com as normas legais vigentes e a adequação às particularidades de suas operações.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              Text(
                'Política de Privacidade',
                style: headlineStyle,
              ),
              const SizedBox(height: 16),
              const Text(
                'Política de Privacidade - [Vizinhos]\n'
                'Data de Vigência: [2025]\n\n'
                'Esta Política de Privacidade descreve como [Nome da Empresa ou Site] (“nós”, “nosso” ou “empresa”) coleta, armazena, utiliza, compartilha e protege as informações dos usuários (“você” ou “usuário”) que acessam ou utilizam nossos serviços, produtos e/ou nosso site. Nosso compromisso é assegurar a transparência no tratamento dos dados pessoais e adotar medidas técnicas e administrativas para protegê-los.\n\n'
                '1. Introdução\n'
                'Sua privacidade é fundamental para nós. Esta política tem como objetivo informar, de maneira clara e detalhada, quais dados são coletados, por que são coletados, como são utilizados e quais medidas de segurança adotamos para proteger suas informações. Ao acessar ou utilizar nossos serviços, você concorda com as práticas descritas neste documento.\n\n'
                '2. Quais Dados Coletamos\n'
                '2.1. Dados Pessoais Fornecidos Diretamente\n'
                'Coletamos informações que você nos fornece de forma direta, tais como:\n'
                '- Informações de Identificação: Nome, sobrenome, CPF/CNPJ, data de nascimento.\n'
                '- Informações de Contato: Endereço, e-mail, telefone.\n'
                '- Dados de Acesso: Informações de login, como nome de usuário e senha (armazenados de forma criptografada).\n'
                '- Outros Dados: Informações adicionais que você possa fornecer ao preencher formulários, cadastrar-se em nosso site, solicitar suporte ou participar de pesquisas.\n\n'
                '2.2. Dados Coletados Automaticamente\n'
                'Durante a utilização de nossos serviços, podemos coletar automaticamente dados técnicos e comportamentais, incluindo:\n'
                '- Dados de Navegação: Endereço IP, tipo e versão do navegador, sistema operacional, páginas acessadas, data e hora do acesso.\n'
                '- Cookies e Tecnologias Similares: Utilizamos cookies, pixels e outras tecnologias para melhorar sua experiência, personalizar conteúdo e analisar o tráfego do site. Você pode gerenciar as configurações de cookies por meio das opções do seu navegador.\n\n'
                '2.3. Dados de Terceiros\n'
                'Em alguns casos, poderemos receber informações de terceiros (como parceiros, redes sociais ou provedores de pagamento) que integrem seus serviços aos nossos, sempre respeitando os limites e finalidades previstos nesta política.\n\n'
                '3. Finalidades do Tratamento de Dados\n'
                'Utilizamos os dados coletados para diversas finalidades, tais como:\n\n'
                '3.1. Prestação de Serviços e Suporte\n'
                '- Cadastro e Autenticação: Garantir o acesso seguro e personalizado à sua conta.\n'
                '- Atendimento ao Cliente: Responder dúvidas, fornecer suporte e processar solicitações.\n'
                '- Melhoria de Produtos e Serviços: Analisar padrões de uso para aprimorar funcionalidades e corrigir eventuais problemas.\n\n'
                '3.2. Marketing e Comunicação\n'
                '- Envio de Informações: Comunicar novidades, atualizações, ofertas e promoções, sempre com a possibilidade de cancelamento da inscrição.\n'
                '- Pesquisa de Satisfação: Conduzir pesquisas para melhorar a experiência do usuário e a qualidade dos nossos serviços.\n\n'
                '3.3. Análise e Melhoria Interna\n'
                '- Estatísticas e Métricas: Realizar análises e gerar relatórios para otimizar nossos processos internos e a eficiência do site.\n'
                '- Segurança e Prevenção: Monitorar e prevenir fraudes, acessos não autorizados e outras atividades que possam comprometer a segurança da plataforma.\n\n'
                '3.4. Cumprimento Legal e Contratual\n'
                '- Obrigações Legais: Atender a exigências legais, investigações judiciais ou solicitações de autoridades competentes.\n'
                '- Contratos e Acordos: Cumprir obrigações decorrentes de contratos firmados com usuários e parceiros.\n\n'
                '4. Armazenamento e Proteção dos Dados\n'
                '4.1. Infraestrutura Segura\n'
                '- Criptografia: Utilizamos criptografia para proteger dados sensíveis durante a transmissão (SSL/TLS) e, quando necessário, no armazenamento.\n'
                '- Ambientes Segregados: Os dados são armazenados em servidores seguros, com acesso restrito e segregação de ambientes de produção e testes.\n'
                '- Backups: Realizamos backups periódicos para garantir a integridade e disponibilidade das informações.\n\n'
                '4.2. Medidas Técnicas e Administrativas\n'
                '- Controle de Acesso: Implementamos mecanismos rigorosos de controle de acesso, garantindo que apenas pessoas autorizadas tenham acesso aos dados pessoais.\n'
                '- Monitoramento e Auditoria: Realizamos monitoramento contínuo e auditorias de segurança para identificar e mitigar riscos.\n'
                '- Treinamento de Equipe: Nossa equipe é regularmente treinada em boas práticas de segurança da informação e privacidade.\n\n'
                '5. Compartilhamento e Transferência de Dados\n'
                '5.1. Compartilhamento com Terceiros\n'
                'Podemos compartilhar seus dados com:\n'
                '- Prestadores de Serviço: Empresas terceirizadas que auxiliam na operação, manutenção e segurança do site (como hospedagem, processamento de pagamentos, análise de dados), sempre sob obrigações contratuais de confidencialidade e segurança.\n'
                '- Autoridades Competentes: Quando exigido por lei ou em cumprimento de ordem judicial.\n'
                '- Parcerias Comerciais: Em casos específicos, com parceiros estratégicos, desde que tais compartilhamentos estejam em conformidade com as finalidades descritas nesta política e mediante consentimento, quando necessário.\n\n'
                '5.2. Transferência Internacional\n'
                'Caso ocorra a transferência de dados para fora do território nacional, adotaremos as salvaguardas exigidas pela legislação aplicável, garantindo um nível adequado de proteção, como cláusulas contratuais padrão e outras medidas recomendadas pelos órgãos reguladores.\n\n'
                '6. Direitos dos Usuários\n'
                'Em conformidade com as normas de proteção de dados, você possui os seguintes direitos:\n'
                '- Acesso: Solicitar o acesso aos seus dados pessoais armazenados.\n'
                '- Correção: Solicitar a correção de dados incompletos, inexatos ou desatualizados.\n'
                '- Exclusão: Requerer a exclusão de dados pessoais, salvo em situações em que a manutenção seja necessária para cumprimento de obrigações legais ou contratuais.\n'
                '- Portabilidade: Solicitar a portabilidade dos dados para outro fornecedor de serviço ou produto.\n'
                '- Limitação e Oposição: Solicitar a limitação do tratamento ou se opor ao tratamento de seus dados, quando aplicável.\n'
                '- Revogação do Consentimento: Revogar o consentimento para o tratamento dos dados, sem prejuízo da legalidade do tratamento realizado com base no consentimento anteriormente dado.\n\n'
                'Para exercer esses direitos, entre em contato conosco por meio dos canais indicados na seção de Contato.\n\n'
                '7. Cookies e Tecnologias de Rastreamento\n'
                'Utilizamos cookies e tecnologias similares para:\n'
                '- Personalizar a Experiência: Adaptar conteúdos e ofertas com base no comportamento do usuário.\n'
                '- Análise de Dados: Monitorar o desempenho e o tráfego do site.\n'
                '- Publicidade: Exibir anúncios relevantes.\n\n'
                'Você pode gerenciar ou desativar os cookies diretamente pelas configurações do seu navegador. Note que a desativação pode afetar a funcionalidade de alguns recursos do site.\n\n'
                '8. Retenção de Dados\n'
                'Os dados pessoais serão mantidos pelo tempo necessário para cumprir as finalidades para as quais foram coletados, bem como para atender a obrigações legais, regulatórias ou contratuais. Após esse período, os dados serão eliminados de forma segura, de acordo com as melhores práticas do mercado.\n\n'
                '9. Alterações nesta Política\n'
                'Esta Política de Privacidade pode ser revisada e atualizada periodicamente para refletir mudanças em nossas práticas ou na legislação aplicável. Caso ocorram alterações significativas, comunicaremos os usuários por meio de aviso em destaque no site ou por e-mail, quando aplicável. Recomendamos a revisão periódica deste documento.\n\n'
                '10. Segurança da Informação\n'
                'Além das medidas já descritas, adotamos políticas internas e tecnologias avançadas para proteger os dados dos usuários contra acesso não autorizado, perda, alteração, divulgação ou qualquer forma de tratamento inadequado. Em caso de incidentes de segurança, contamos com um plano de resposta que inclui a notificação aos usuários e às autoridades competentes, conforme exigido pela legislação.\n\n'
                '11. Base Legal para o Tratamento dos Dados\n'
                'O tratamento dos seus dados pessoais se fundamenta em bases legais previstas na legislação vigente, tais como:\n'
                '- Consentimento: Quando expressamente solicitado e autorizado pelo usuário.\n'
                '- Execução de Contrato: Para a prestação dos serviços solicitados.\n'
                '- Obrigação Legal: Para o cumprimento de obrigações legais e regulatórias.\n'
                '- Interesses Legítimos: Quando necessário para a execução de atividades legítimas, desde que não prejudiquem os direitos e liberdades fundamentais do titular.\n\n'
                '12. Contato\n'
                'Em caso de dúvidas, solicitações ou reclamações referentes a esta Política de Privacidade ou ao tratamento dos seus dados pessoais, entre em contato conosco através dos seguintes canais:\n'
                '- E-mail: [inserir e-mail de contato]\n'
                '- Telefone: [inserir telefone]\n'
                '- Endereço: [inserir endereço físico, se aplicável]\n\n'
                'Nossa equipe está disponível para atender suas solicitações e prestar esclarecimentos adicionais.\n\n'
                '13. Disposições Finais\n'
                'Esta Política de Privacidade é regida pelas leis [inserir país ou região, ex.: "da República Federativa do Brasil"] e quaisquer controvérsias decorrentes serão submetidas ao foro da comarca [inserir comarca], com exclusão de qualquer outro, por mais privilegiado que seja.\n\n'
                'Ao utilizar nossos serviços, você declara ter lido, compreendido e aceitado os termos desta política, concordando com o tratamento de seus dados conforme aqui descrito.\n\n'
                'Observação: Este documento é um modelo e deve ser adaptado às necessidades e especificidades do seu negócio. Recomenda-se a consulta a um profissional jurídico especializado em proteção de dados para garantir a conformidade completa com as normas legais vigentes e a adequação às particularidades de suas operações.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
