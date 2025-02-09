import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vizinhos_app/services/auth_provider.dart';
import 'package:vizinhos_app/services/secure_storage.dart';

class DebugStorageScreen extends StatelessWidget {
  const DebugStorageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dados Armazenados'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações básicas do AuthProvider
            Text(
              'Status do Usuário:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Logado: ${authProvider.isLoggedIn ? "Sim" : "Não"}'),
            Text('Tipo: ${authProvider.isSeller ? "Vendedor" : "Cliente"}'),
            if (authProvider.isSeller) ...[
              SizedBox(height: 8),
              FutureBuilder(
                future: _getUpdatedStoreInfo(authProvider),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text(
                        'Erro ao carregar dados do vendedor: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text('Nenhum dado de vendedor disponível.');
                  } else {
                    final storeInfo = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Nome da Loja: ${storeInfo['storeName'] ?? 'N/A'}'),
                        Text(
                            'Categorias: ${storeInfo['categories']?.join(', ') ?? 'Nenhuma'}'),
                      ],
                    );
                  }
                },
              ),
            ],
            SizedBox(height: 16),

            // Tokens armazenados
            Text(
              'Tokens Armazenados:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            FutureBuilder(
              future: SecureStorage().getAllTokens(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Erro ao carregar tokens: ${snapshot.error}');
                } else if (!snapshot.hasData) {
                  return Text('Nenhum token armazenado.');
                } else {
                  final tokens = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Access Token: ${tokens['access_token']?.substring(0, 15)}...'),
                      Text(
                          'ID Token: ${tokens['id_token']?.substring(0, 15)}...'),
                      Text(
                          'Refresh Token: ${tokens['refresh_token']?.substring(0, 15)}...'),
                      Text('Expira em: ${tokens['expires_in']} segundos'),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Método para obter dados atualizados da loja
  Future<Map<String, dynamic>?> _getUpdatedStoreInfo(
      AuthProvider authProvider) async {
    try {
      // Força sincronização com a API
      await authProvider.syncSellerProfile();

      // Busca os dados atualizados do SecureStorage
      final storeInfo = await SecureStorage().getStoreInfo();
      return storeInfo;
    } catch (e) {
      print('Erro ao buscar dados da loja: $e');
      return null;
    }
  }
}
