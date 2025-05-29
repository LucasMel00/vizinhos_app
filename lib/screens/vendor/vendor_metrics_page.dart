import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vizinhos_app/services/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:vizinhos_app/screens/vendor/vendor_orders_page.dart';

class VendorMetricsPage extends StatefulWidget {
  final String idLoja;
  const VendorMetricsPage({super.key, required this.idLoja});

  @override
  State<VendorMetricsPage> createState() => _VendorMetricsPageState();
}

class _VendorMetricsPageState extends State<VendorMetricsPage> {
  bool _isLoading = true;
  int _totalPedidos = 0;
  int _pedidosEntregues = 0;
  int _pedidosCancelados = 0;
  double _totalVendas = 0;
  double _ticketMedio = 0;
  // Pré-processados para gráficos
  List<FlSpot> _vendasSpots = [];
  List<BarChartGroupData> _pedidosBarGroups = [];
  List<PieChartSectionData> _statusSections = [];
  List<dynamic> _recentOrders = [];
  List<String> _diasVendas = [];
  List<String> _diasPedidos = [];
  Map<String, int> _statusData = {}; // Dados para a legenda

  @override
  void initState() {
    super.initState();
    _fetchMetrics();
  }

  Future<void> _fetchMetrics() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse(
          'https://gav0yq3rk7.execute-api.us-east-2.amazonaws.com/GetOrdersByStore?id_Loja=${widget.idLoja}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final orders = data['pedidos'] ?? [];
        int entregues = 0;
        int cancelados = 0;
        Map<String, double> vendasPorDia = {};
        Map<String, int> pedidosPorDia = {};
        Map<String, int> statusCount = {};
        for (final pedido in orders) {
          final status =
              (pedido['status_pedido'] ?? '').toString().toLowerCase();
          final valor =
              double.tryParse(pedido['valor_total']?.toString() ?? '0') ?? 0;
          final dataPedido =
              (pedido['data_pedido'] ?? '').toString().split(' ').first;
          // Contagem de status
          statusCount[status] = (statusCount[status] ?? 0) + 1;
          // Evolução diária
          vendasPorDia[dataPedido] = (vendasPorDia[dataPedido] ?? 0) + valor;
          pedidosPorDia[dataPedido] = (pedidosPorDia[dataPedido] ?? 0) + 1;
          if (status == 'completo') entregues++;
          if (status == 'cancelado' || status == 'reembolsado') cancelados++;
        }
        // Pré-processamento para gráficos
        final diasVendas = vendasPorDia.keys.toList()..sort();
        final vendasSpots = <FlSpot>[];
        for (var i = 0; i < diasVendas.length; i++) {
          vendasSpots.add(FlSpot(i.toDouble(), vendasPorDia[diasVendas[i]]!));
        }
        final diasPedidos = pedidosPorDia.keys.toList()..sort();
        final pedidosBarGroups = <BarChartGroupData>[];
        for (var i = 0; i < diasPedidos.length; i++) {
          pedidosBarGroups.add(BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: pedidosPorDia[diasPedidos[i]]!.toDouble(),
                color: AppTheme.primaryColor,
              ),
            ],
          ));
        }
        final statusSectionsList = statusCount.entries.map((e) {
          final color = e.key == 'completo'
              ? Colors.green
              : (e.key == 'cancelado' || e.key == 'reembolsado')
                  ? Colors.red
                  : AppTheme.primaryColor;
          return PieChartSectionData(
            value: e.value.toDouble(),
            color: color,
            title: '${e.value}',
            radius: 50,
            titleStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            titlePositionPercentageOffset: 0.55,
          );
        }).toList();
        double totalVendasCalc = vendasPorDia.values.fold(0, (a, b) => a + b);
        setState(() {
          _totalPedidos = orders.length;
          _pedidosEntregues = entregues;
          _pedidosCancelados = cancelados;
          _totalVendas = totalVendasCalc;
          _ticketMedio =
              orders.isNotEmpty ? totalVendasCalc / orders.length : 0;
          _vendasSpots = vendasSpots;
          _pedidosBarGroups = pedidosBarGroups;
          _statusSections = statusSectionsList;
          _recentOrders = orders.take(5).toList();
          _diasVendas = diasVendas;
          _diasPedidos = diasPedidos;
          _statusData = statusCount; // Salvar dados para a legenda
          _isLoading = false;
        });
      } else {
        throw Exception('Erro ao buscar pedidos: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao buscar métricas: $e'),
            backgroundColor: AppTheme.errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Desempenho da Loja'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchMetrics,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Resumo',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor)),
                            const SizedBox(height: 16),
                            _buildMetricRow('Total de Pedidos',
                                _totalPedidos.toString(), Icons.shopping_cart),
                            _buildMetricRow(
                                'Pedidos Entregues',
                                _pedidosEntregues.toString(),
                                Icons.check_circle,
                                color: Colors.green),
                            _buildMetricRow('Pedidos Cancelados',
                                _pedidosCancelados.toString(), Icons.cancel,
                                color: Colors.red),
                            _buildMetricRow(
                                'Total em Vendas',
                                'R\$ ${_totalVendas.toStringAsFixed(2)}',
                                Icons.attach_money),
                            _buildMetricRow(
                                'Ticket Médio',
                                'R\$ ${_ticketMedio.toStringAsFixed(2)}',
                                Icons.receipt_long),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_vendasSpots.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Evolução de Vendas (R\$)',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor)),
                          SizedBox(
                            height: 220,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 16, bottom: 20, left: 8, right: 16),
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    drawHorizontalLine: true,
                                    horizontalInterval:
                                        null, // Deixar automático
                                    verticalInterval: null, // Deixar automático
                                  ),
                                  borderData: FlBorderData(show: true),
                                  minY:
                                      0, // Garantir que o gráfico comece do zero
                                  maxY: null, // Deixar automático
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 60,
                                        interval:
                                            null, // Deixar o gráfico calcular automaticamente
                                        getTitlesWidget: (value, meta) {
                                          // Formatar valores monetários no eixo Y
                                          if (value >= 1000) {
                                            return Text(
                                              'R\$${(value / 1000).toStringAsFixed(1)}k',
                                              style:
                                                  const TextStyle(fontSize: 10),
                                            );
                                          } else {
                                            return Text(
                                              'R\$${value.toInt()}',
                                              style:
                                                  const TextStyle(fontSize: 10),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final idx = value.toInt();
                                          if (idx < 0 ||
                                              idx >= _diasVendas.length)
                                            return const SizedBox.shrink();

                                          // Mostrar apenas algumas datas para evitar sobreposição
                                          if (_diasVendas.length > 7 &&
                                              idx % 2 != 0) {
                                            return const SizedBox.shrink();
                                          }
                                          if (_diasVendas.length > 14 &&
                                              idx % 3 != 0) {
                                            return const SizedBox.shrink();
                                          }

                                          // Formatar data mais compacta (dd/mm)
                                          final data = _diasVendas[idx];
                                          final partes = data.split('-');
                                          final dataFormatada =
                                              partes.length >= 3
                                                  ? '${partes[2]}/${partes[1]}'
                                                  : data;

                                          return Transform.rotate(
                                            angle: -0.5, // Rotacionar 45 graus
                                            child: Text(
                                              dataFormatada,
                                              style:
                                                  const TextStyle(fontSize: 9),
                                            ),
                                          );
                                        },
                                        reservedSize: 40,
                                      ),
                                      axisNameWidget: const Text('Período'),
                                      axisNameSize: 24,
                                    ),
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _vendasSpots,
                                      isCurved: true,
                                      color: AppTheme.primaryColor,
                                      barWidth: 3,
                                      dotData: const FlDotData(show: false),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    if (_pedidosBarGroups.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Evolução de Pedidos',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor)),
                          SizedBox(
                            height: 220,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 16, bottom: 20, left: 8, right: 16),
                              child: BarChart(
                                BarChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    drawHorizontalLine: true,
                                    horizontalInterval:
                                        null, // Deixar automático
                                    verticalInterval: null, // Deixar automático
                                  ),
                                  borderData: FlBorderData(show: true),
                                  minY:
                                      0, // Garantir que o gráfico comece do zero
                                  maxY: null, // Deixar automático
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        interval:
                                            null, // Deixar o gráfico calcular automaticamente
                                        getTitlesWidget: (value, meta) {
                                          // Mostrar apenas números inteiros para pedidos
                                          return Text(
                                            value.toInt().toString(),
                                            style:
                                                const TextStyle(fontSize: 10),
                                          );
                                        },
                                      ),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final idx = value.toInt();
                                          if (idx < 0 ||
                                              idx >= _diasPedidos.length)
                                            return const SizedBox.shrink();

                                          // Mostrar apenas algumas datas para evitar sobreposição
                                          if (_diasPedidos.length > 7 &&
                                              idx % 2 != 0) {
                                            return const SizedBox.shrink();
                                          }
                                          if (_diasPedidos.length > 14 &&
                                              idx % 3 != 0) {
                                            return const SizedBox.shrink();
                                          }

                                          // Formatar data mais compacta (dd/mm)
                                          final data = _diasPedidos[idx];
                                          final partes = data.split('-');
                                          final dataFormatada =
                                              partes.length >= 3
                                                  ? '${partes[2]}/${partes[1]}'
                                                  : data;

                                          return Transform.rotate(
                                            angle: -0.5, // Rotacionar 45 graus
                                            child: Text(
                                              dataFormatada,
                                              style:
                                                  const TextStyle(fontSize: 9),
                                            ),
                                          );
                                        },
                                        reservedSize: 40,
                                      ),
                                      axisNameWidget: const Text('Período'),
                                      axisNameSize: 24,
                                    ),
                                  ),
                                  barGroups: _pedidosBarGroups,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    if (_statusSections.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Distribuição de Status dos Pedidos',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor)),
                          Row(
                            children: [
                              // Gráfico de pizza
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 180,
                                  child: PieChart(
                                    PieChartData(
                                      sections: _statusSections,
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 30,
                                    ),
                                  ),
                                ),
                              ),
                              // Legenda
                              Expanded(
                                flex: 1,
                                child: _buildLegenda(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    const Text('Pedidos Recentes',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 320,
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentOrders.length,
                        itemBuilder: (context, idx) =>
                            _buildOrderTile(_recentOrders[idx]),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrdersVendorPage(
                                deliveryType: 'Delivery', // Adjust as needed
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Ver Mais Pedidos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color ?? AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOrderTile(dynamic pedido) {
    final status = pedido['status_pedido']?.toString() ?? '';
    final valor =
        double.tryParse(pedido['valor_total']?.toString() ?? '0') ?? 0;
    final data = pedido['data_pedido'] ?? '';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(Icons.receipt, color: AppTheme.primaryColor),
        title: Text('Pedido #${pedido['id_Pedido'] ?? ''}'),
        subtitle: Text('Status: $status\nData: $data'),
        trailing: Text('R\$ ${valor.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLegenda() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: _statusData.entries.map((entry) {
        final color = entry.key == 'completo'
            ? Colors.green
            : (entry.key == 'cancelado' || entry.key == 'reembolsado')
                ? Colors.red
                : AppTheme.primaryColor;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${entry.key}\n(${entry.value})',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
