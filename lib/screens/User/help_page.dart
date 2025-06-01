import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  // Método para enviar email
  Future<void> _sendEmail(BuildContext context) async {
    const String email = 'melo.goncalves@aluno.ifsp.edu.br';
    const String subject = 'Ajuda - Vizinhos App';
    
    try {
      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: email,
        query: 'subject=${Uri.encodeComponent(subject)}',
      );
      
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        // Fallback: copiar email para clipboard
        await _copyEmailToClipboard(context, email);
      }
    } catch (e) {
      await _copyEmailToClipboard(context, email);
    }
  }

  // Método para copiar email para clipboard
  Future<void> _copyEmailToClipboard(BuildContext context, String email) async {
    await Clipboard.setData(ClipboardData(text: email));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email copiado: $email'),
          backgroundColor: const Color(0xFFFbbc2c),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  // Método para abrir WhatsApp
  Future<void> _openWhatsApp(BuildContext context) async {
    const String phoneNumber = '5511912922258'; // Substitua pelo número real
    const String message = 'Olá! Preciso de ajuda com o Vizinhos App.';
    
    try {
      final Uri whatsappUri = Uri.parse(
        'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}'
      );
      
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp não está disponível neste dispositivo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao abrir WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFFbbc2c);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajuda',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.help_center,
                    size: 60,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Como podemos ajudar?',
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Estamos aqui para resolver suas dúvidas e problemas',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Seção de contato
            const Text(
              'Entre em contato',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),
            
            // Botão de Email
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.email, color: Colors.white),
                label: const Text(
                  'Enviar Email',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: () => _sendEmail(context),
              ),
            ),
            
            // Botão de WhatsApp
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat, color: Colors.white),
                label: const Text(
                  'WhatsApp',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // Cor do WhatsApp
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: () => _openWhatsApp(context),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // FAQ Section
            const Text(
              'Perguntas Frequentes',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildFAQItem(
              'Como me cadastrar como vendedor?',
              'Acesse sua conta, vá em "Conta" e toque em "Sua Loja". Siga as instruções para completar seu cadastro de vendedor.',
            ),
            
            _buildFAQItem(
              'Como fazer um pedido?',
              'Navegue pelos produtos, adicione ao carrinho e finalize a compra. Você receberá confirmação por email.',
            ),

            _buildFAQItem(
              'Como alterar meu endereço?',
              'Acesse "Minha Conta", vá em "Endereços" e edite seu endereço de entrega.',
            ),
            
            _buildFAQItem(
              'Problemas com pagamento?',
              'Entre em contato conosco pelo email ou WhatsApp com os detalhes do problema.',
            ),
            
            const SizedBox(height: 32),
            
            // Informação de contato
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 40,
                    color: Color(0xFF666666),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Horário de Atendimento',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Segunda a Sexta: 8h às 18h\nSábado: 8h às 12h',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Email: melo.goncalves@aluno.ifsp.edu.br',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFAQItem(String question, String answer) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
