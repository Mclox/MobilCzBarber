// import 'package:flutter/material.dart';

// class KpisScreen extends StatelessWidget {
//   const KpisScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Indicadores (KPIs)'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ListView(
//           children: [
//             _buildKpiCard(
//               title: 'Citas Totales Hoy',
//               value: '32',
//               icon: Icons.calendar_today,
//               color: Colors.blue,
//             ),
//             _buildKpiCard(
//               title: 'Ingresos del Día',
//               value: '\$856.000',
//               icon: Icons.monetization_on,
//               color: Colors.green,
//             ),
//             _buildKpiCard(
//               title: 'Servicios Más Solicitados',
//               value: 'Corte + Barba',
//               icon: Icons.content_cut,
//               color: Colors.orange,
//             ),
//             _buildKpiCard(
//               title: 'Barbero del Día',
//               value: 'Juan Pablo',
//               icon: Icons.star,
//               color: Colors.purple,
//             ),
//             _buildKpiCard(
//               title: 'Clientes Nuevos Esta Semana',
//               value: '14',
//               icon: Icons.person_add,
//               color: Colors.teal,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildKpiCard({
//     required String title,
//     required String value,
//     required IconData icon,
//     required Color color,
//   }) {
//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 28,
//               backgroundColor: color.withOpacity(0.15),
//               child: Icon(icon, size: 32, color: color),
//             ),
//             const SizedBox(width: 20),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     value,
//                     style: TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                       color: color,
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';

class KpisScreen extends StatefulWidget {
  const KpisScreen({super.key});

  @override
  State<KpisScreen> createState() => _KpisScreenState();
}

class _KpisScreenState extends State<KpisScreen> {
  @override
  void initState() {
    super.initState();
    // Invocamos la carga de datos al entrar a la pantalla
    Future.microtask(() => 
      Provider.of<DashboardProvider>(context, listen: false).fetchKpis()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Indicadores (KPIs)'),
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          // Indicador de carga mientras el backend consulta a SQL Server
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final kpis = provider.kpis;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildKpiCard(
                  title: 'Citas Totales',
                  value: '${kpis['citasHoy'] ?? 0}',
                  icon: Icons.calendar_today,
                  color: Colors.blue,
                ),
                _buildKpiCard(
                  title: 'Ingresos del Periodo',
                  value: '\$${(kpis['ingresosDia'] ?? 0).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
                _buildKpiCard(
                  title: 'Servicio Top',
                  value: kpis['topServicio'] ?? 'N/A',
                  icon: Icons.content_cut,
                  color: Colors.orange,
                ),
                _buildKpiCard(
                  title: 'Barbero del Día',
                  value: kpis['barberoTop'] ?? 'N/A',
                  icon: Icons.star,
                  color: Colors.purple,
                ),
                _buildKpiCard(
                  title: 'Clientes Nuevos',
                  value: '${kpis['clientesNuevos'] ?? 0}',
                  icon: Icons.person_add,
                  color: Colors.teal,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}