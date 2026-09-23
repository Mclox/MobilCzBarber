import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/appointment_provider.dart';
import '../../providers/barber_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';

import '../../models/appointment.dart';
import '../../models/service.dart';
import '../../mock/mock_services.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  int? selectedBarberId;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  Service? selectedService;

  @override
  void initState() {
    super.initState();
    Provider.of<BarberProvider>(context, listen: false).fetchBarbers();
  }

  @override
  Widget build(BuildContext context) {
    final barberProvider = Provider.of<BarberProvider>(context);
    final appointmentProvider = Provider.of<AppointmentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reservar Cita"),
        backgroundColor: Colors.black87,
      ),
      body: barberProvider.isLoading
          ? const LoadingWidget()
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // -------- BARBERO --------
                  const Text(
                    "Selecciona un barbero",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<int>(
                    value: barberProvider.barbers.any((b) => b.id == selectedBarberId) ? selectedBarberId : null,
                    hint: const Text("Barbero disponible"),
                    items: () {
                      final seenIds = <int>{};
                      final list = <DropdownMenuItem<int>>[];
                      for (final barber in barberProvider.barbers) {
                        if (!seenIds.contains(barber.id)) {
                          seenIds.add(barber.id);
                          list.add(DropdownMenuItem(
                            value: barber.id,
                            child: Text(barber.name),
                          ));
                        }
                      }
                      return list;
                    }(),
                    onChanged: (value) {
                      setState(() => selectedBarberId = value);
                    },
                  ),

                  const SizedBox(height: 25),

                  // -------- SERVICIO --------
                  const Text(
                    "Selecciona el servicio",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<Service>(
                    value: selectedService,
                    hint: const Text("Servicio"),
                    items: mockServices.map((service) {
                      return DropdownMenuItem<Service>(
                        value: service,
                        child: Text(service.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedService = value);
                    },
                  ),

                  const SizedBox(height: 25),

                  // -------- FECHA --------
                  const Text(
                    "Selecciona la fecha",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  CustomButton(
                    text: selectedDate == null
                        ? "Elegir fecha"
                        : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                    onPressed: pickDate,
                  ),

                  const SizedBox(height: 25),

                  // -------- HORA --------
                  const Text(
                    "Selecciona la hora",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  CustomButton(
                    text: selectedTime == null
                        ? "Elegir hora"
                        : "${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}",
                    onPressed: pickTime,
                  ),

                  const Spacer(),

                  // -------- BOTÓN --------
                  CustomButton(
                    text: "Reservar Cita",
                    onPressed: () async {
                      if (selectedBarberId == null ||
                          selectedDate == null ||
                          selectedTime == null ||
                          selectedService == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Completa todos los campos"),
                          ),
                        );
                        return;
                      }

                      final fullDate = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                      );

                      final appointment = Appointment(
                        id: 0,
                        clientId: 999, // luego vendrá del login
                        barberId: selectedBarberId!,
                        date: fullDate,
                        hour:
                            "${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}",
                        service: selectedService!,
                        status: "pending",
                      );

                      final ok = await appointmentProvider
                          .createAppointment(appointment);

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? "Cita registrada exitosamente"
                              : "Error al registrar la cita"),
                        ),
                      );

                      if (ok) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  // -------- HELPERS --------

  Future<void> pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> pickTime() async {
    final time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());

    if (time != null) {
      setState(() => selectedTime = time);
    }
  }
}
