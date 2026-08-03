// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// import '../../core/app_theme.dart';
// import '../../core/ui_helpers.dart';
// import '../../mock/mock_appointments.dart'; // solo la lista
// import '../../mock/mock_services.dart';
// import '../../models/service.dart';
// import '../../models/appointment.dart';

// class ManageAppointmentsScreen extends StatefulWidget {
//   const ManageAppointmentsScreen({super.key});

//   @override
//   State<ManageAppointmentsScreen> createState() =>
//       _ManageAppointmentsScreenState();
// }

// class _ManageAppointmentsScreenState extends State<ManageAppointmentsScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppTheme.background,
//       appBar: AppBar(
//         title: const Text("Citas"),
//         backgroundColor: AppTheme.primary,
//         foregroundColor: Colors.white,
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: AppTheme.primary,
//         child: const Icon(Icons.add),
//         onPressed: () => _openForm(),
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: mockAppointments.length,
//         itemBuilder: (_, index) {
//           final appt = mockAppointments[index];
//           return Card(
//             margin: const EdgeInsets.only(bottom: 14),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: ListTile(
//               title: Text(appt.service.name,
//                   style: const TextStyle(fontWeight: FontWeight.bold)),
//               subtitle: Text(
//                   "${DateFormat('dd/MM/yyyy').format(appt.date)} · ${appt.hour}\nBarbero ID: ${appt.barberId} · Cliente ID: ${appt.clientId}"),
//               trailing: Wrap(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.edit, color: Colors.blue),
//                     onPressed: () => _openForm(edit: appt),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.delete, color: Colors.red),
//                     onPressed: () async {
//                       final confirm = await ConfirmationHelper.showDeleteConfirmation(context: context);
//                       if (confirm) {
//                         setState(() {
//                           mockAppointments.removeAt(index);
//                         });
//                       }
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   void _openForm({Appointment? edit}) {
//     DateTime selectedDate = edit?.date ?? DateTime.now();
//     String selectedHour = edit?.hour ?? "09:00 AM";
//     int selectedBarberId = edit?.barberId ?? 1;
//     int selectedClientId = edit?.clientId ?? 1;
//     Service selectedService = edit?.service ?? mockServices.first;

//     showDialog(
//       context: context,
//       builder: (_) => StatefulBuilder(
//         builder: (context, setModal) {
//           return AlertDialog(
//             title: Text(edit == null ? "Nueva cita" : "Editar cita"),
//             content: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Fecha
//                   ListTile(
//                     contentPadding: EdgeInsets.zero,
//                     title: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
//                     leading: const Icon(Icons.calendar_month),
//                     onTap: () async {
//                       final picked = await showDatePicker(
//                         context: context,
//                         initialDate: selectedDate,
//                         firstDate: DateTime.now(),
//                         lastDate: DateTime(2030),
//                       );
//                       if (picked != null) setModal(() => selectedDate = picked);
//                     },
//                   ),
//                   const SizedBox(height: 12),

//                   // Hora
//                   DropdownButtonFormField<String>(
//                     isExpanded: true,
//                     value: selectedHour,
//                     decoration: const InputDecoration(
//                         labelText: "Hora", border: OutlineInputBorder()),
//                     items: [
//                       "09:00 AM",
//                       "10:00 AM",
//                       "11:00 AM",
//                       "02:00 PM",
//                       "03:00 PM",
//                       "04:00 PM",
//                     ]
//                         .map((h) => DropdownMenuItem(
//                               value: h,
//                               child: Text(h),
//                             ))
//                         .toList(),
//                     onChanged: (v) => setModal(() => selectedHour = v!),
//                   ),
//                   const SizedBox(height: 12),

//                   // Barbero ID
//                   DropdownButtonFormField<int>(
//                     isExpanded: true,
//                     value: selectedBarberId,
//                     decoration: const InputDecoration(
//                         labelText: "Barbero ID", border: OutlineInputBorder()),
//                     items: [1, 2, 3]
//                         .map((b) => DropdownMenuItem(
//                               value: b,
//                               child: Text("Barbero $b"),
//                             ))
//                         .toList(),
//                     onChanged: (v) => setModal(() => selectedBarberId = v!),
//                   ),
//                   const SizedBox(height: 12),

//                   // Cliente ID
//                   DropdownButtonFormField<int>(
//                     isExpanded: true,
//                     value: selectedClientId,
//                     decoration: const InputDecoration(
//                         labelText: "Cliente ID", border: OutlineInputBorder()),
//                     items: [1, 2, 3]
//                         .map((c) => DropdownMenuItem(
//                               value: c,
//                               child: Text("Cliente $c"),
//                             ))
//                         .toList(),
//                     onChanged: (v) => setModal(() => selectedClientId = v!),
//                   ),
//                   const SizedBox(height: 12),

//                   // Servicio
//                   DropdownButtonFormField<Service>(
//                     isExpanded: true,
//                     value: selectedService,
//                     decoration: const InputDecoration(
//                         labelText: "Servicio", border: OutlineInputBorder()),
//                     items: mockServices
//                         .map((s) => DropdownMenuItem(
//                               value: s,
//                               child:
//                                   Text(s.name, overflow: TextOverflow.ellipsis),
//                             ))
//                         .toList(),
//                     onChanged: (v) => setModal(() => selectedService = v!),
//                   ),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text("Cancelar")),
//               ElevatedButton(
//                 onPressed: () {
//                   setState(() {
//                     if (edit == null) {
//                       mockAppointments.add(
//                         Appointment(
//                           id: mockAppointments.length + 1,
//                           clientId: selectedClientId,
//                           barberId: selectedBarberId,
//                           date: selectedDate,
//                           hour: selectedHour,
//                           service: selectedService,
//                           status: "pending",
//                         ),
//                       );
//                     } else {
//                       final index =
//                           mockAppointments.indexWhere((a) => a.id == edit.id);

//                       mockAppointments[index] = edit.copyWith(
//                         clientId: selectedClientId,
//                         barberId: selectedBarberId,
//                         date: selectedDate,
//                         hour: selectedHour,
//                         service: selectedService,
//                       );
//                     }
//                   });

//                   Navigator.pop(context);
//                 },
//                 child: const Text("Guardar"),
//               ),

//             ],
//           );
//         },
//       ),
//     );
//   }
// }


import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';

class AppointmentService {
  final Dio _dio = Dio(BaseOptions(baseUrl: Api.baseUrl));

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<List<dynamic>> getAll() async {
    final token = await _getToken();
    final res = await _dio.get('/appointments', options: Options(headers: {"Authorization": "Bearer $token"}));
    return res.data['data'];
  }

  Future<List<dynamic>> getClientes() async {
    final token = await _getToken();
    final res = await _dio.get('/clients', options: Options(headers: {"Authorization": "Bearer $token"}));
    return res.data['data'];
  }

  Future<List<dynamic>> getBarberos() async {
    final token = await _getToken();
    final res = await _dio.get('/employees', options: Options(headers: {"Authorization": "Bearer $token"}));
    return res.data['data'];
  }

  Future<List<dynamic>> getServicios() async {
    final token = await _getToken();
    final res = await _dio.get('/services', options: Options(headers: {"Authorization": "Bearer $token"}));
    return res.data['data'];
  }

  Future<bool> create(Map<String, dynamic> data) async {
    final token = await _getToken();
    final res = await _dio.post('/appointments', data: data, options: Options(headers: {"Authorization": "Bearer $token"}));
    return res.statusCode == 201;
  }

  Future<bool> delete(int id) async {
    final token = await _getToken();
    final res = await _dio.delete('/appointments/$id', options: Options(headers: {"Authorization": "Bearer $token"}));
    return res.statusCode == 200;
  }

  Future<bool> update(int id, Map<String, dynamic> data) async {
    final token = await _getToken();
    final res = await _dio.put('/appointments/$id', data: data, options: Options(headers: {"Authorization": "Bearer $token"}));
    return res.statusCode == 200 || (res.data != null && res.data['success'] == true);
  }

  Future<bool> updateStatus(int id, String status) async {
    final token = await _getToken();
    final res = await _dio.put('/appointments/$id/status', data: {"estado": status}, options: Options(headers: {"Authorization": "Bearer $token"}));
    return res.statusCode == 200 || (res.data != null && res.data['success'] == true);
  }
}