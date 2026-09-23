import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'employee_main_screen.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/custom_button.dart';
import '../../providers/barber_availability_provider.dart';
import '../../core/app_theme.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BarberAvailabilityProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Disponibilidad"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Días Disponibles",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  ...provider.availability.keys.map((day) {
                    return SwitchListTile(
                      title: Text(day),
                      value: provider.availability[day]!,
                      onChanged: (value) => provider.toggleDay(day, value),
                    );
                  }).toList(),
                  const SizedBox(height: 25),
                  const Text(
                    "Horario",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text("Hora de inicio"),
                    subtitle: Text("${provider.startTime.hour}:${provider.startTime.minute.toString().padLeft(2, '0')}"),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: provider.startTime,
                      );
                      if (picked != null) provider.setStartTime(picked);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time_filled),
                    title: const Text("Hora de finalización"),
                    subtitle: Text("${provider.endTime.hour}:${provider.endTime.minute.toString().padLeft(2, '0')}"),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: provider.endTime,
                      );
                      if (picked != null) provider.setEndTime(picked);
                    },
                  ),
                  const SizedBox(height: 30),
                  CustomButton(
                    text: "Guardar Disponibilidad",
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      await provider.saveAvailability();
                      if (mounted) {
                        setState(() => _isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Disponibilidad guardada correctamente"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        
                        // Redirigir al inicio de forma fluida
                        final mainScreen = context.findAncestorStateOfType<EmployeeMainScreenState>();
                        if (mainScreen != null) {
                          mainScreen.selectTab(0);
                        } else if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          context.go("/employee/home");
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
