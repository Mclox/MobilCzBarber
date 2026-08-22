import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_provider.dart';
import '../../services/appointment_service.dart';
import '../../core/whatsapp_helper.dart';

/// Pantalla unificada de reserva de citas para Administrador, Barbero y Cliente
class BookingScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const BookingScreen({super.key, this.onBack});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final AppointmentService _appointmentService = AppointmentService();

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  
  int? _selectedClientId;
  Map<String, dynamic>? _selectedServiceMap;
  Map<String, dynamic>? _selectedBarberMap;
  String? _selectedTimeStr;

  List<dynamic> _clients = [];
  List<dynamic> _barbersList = [];
  List<dynamic> _busySlots = [];
  bool _isLoading = false;
  int _currentStep = 0;

  final List<String> _availableTimes = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30', '15:00', '15:30',
    '16:00', '16:30', '17:00', '17:30', '18:00',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = auth.user;
      
      // Cargar servicios
      await Provider.of<ServiceProvider>(context, listen: false).loadServices();
      
      // Obtener clientes, barberos y disponibilidad del backend
      final clientsList = await _appointmentService.getClientes();
      final barbersList = await _appointmentService.getBarberos();
      final busy = await _appointmentService.getPublicBusySlots();
      
      setState(() {
        _clients = clientsList;
        _barbersList = barbersList;
        _busySlots = busy;
        
        final role = currentUser?.role?.toLowerCase() ?? 'client';

        // Si el rol es cliente, buscar su propio cliente en la lista
        if (role == 'client') {
          final myClient = _clients.firstWhere(
            (c) => c['id_usuario'].toString() == currentUser?.id.toString(),
            orElse: () => null,
          );
          if (myClient != null) {
            _selectedClientId = myClient['id_cliente'] as int?;
          } else {
            _selectedClientId = currentUser?.id;
          }
          if (_barbersList.isNotEmpty && _selectedBarberMap == null) {
            _selectedBarberMap = _barbersList.first;
          }
        } else if (role == 'employee' || role == 'barbero' || role == 'empleado') {
          // Si el usuario es un barbero, auto-seleccionar su perfil de barbero
          final myBarber = _barbersList.firstWhere(
            (b) => (b['id_usuario']?.toString() == currentUser?.id.toString()) ||
                   (b['id_barbero']?.toString() == currentUser?.id.toString()) ||
                   (b['nombre']?.toString().toLowerCase() == currentUser?.name?.toLowerCase()),
            orElse: () => _barbersList.isNotEmpty ? _barbersList.first : null,
          );
          if (myBarber != null) {
            _selectedBarberMap = myBarber;
          }
        } else {
          if (_barbersList.isNotEmpty && _selectedBarberMap == null) {
            _selectedBarberMap = _barbersList.first;
          }
        }
      });
    } catch (e) {
      debugPrint("Error loading initial booking data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isSlotAvailable(String timeStr, Map<String, dynamic> barber, DateTime date, Map<String, dynamic> service, List<dynamic> busySlots) {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    if (dateStr.compareTo(todayStr) < 0) {
      return false;
    }
    
    final parts = timeStr.split(':');
    final hh = int.parse(parts[0]);
    final mm = int.parse(parts[1]);
    
    if (dateStr == todayStr) {
      final currentMins = now.hour * 60 + now.minute;
      final slotMins = hh * 60 + mm;
      if (slotMins <= currentMins) {
        return false; 
      }
    }
    
    final barberId = barber['id_barbero'] ?? barber['id_usuario'];
    final duration = service['duracion_minutos'] ?? 30;
    
    final slotStart = hh * 60 + mm;
    final slotEnd = slotStart + duration;
    
    for (final busy in busySlots) {
      if (busy['fecha'] == dateStr && busy['id_barbero'].toString() == barberId.toString()) {
        final bStartParts = busy['hora'].toString().split(':');
        final bEndParts = busy['hora_fin'].toString().split(':');
        if (bStartParts.length < 2 || bEndParts.length < 2) continue;
        
        final bStart = int.parse(bStartParts[0]) * 60 + int.parse(bStartParts[1]);
        final bEnd = int.parse(bEndParts[0]) * 60 + int.parse(bEndParts[1]);
        
        if (slotStart < bEnd && slotEnd > bStart) {
          return false; 
        }
      }
    }
    return true;
  }

  String calculateHoraFin(String horaInicio, int durationMinutes) {
    final parts = horaInicio.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    minute += durationMinutes;
    while (minute >= 60) {
      hour += 1;
      minute -= 60;
    }
    return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?.role ?? 'client';
    final steps = _getSteps(userRole);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservar Cita'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else if (widget.onBack != null) {
              widget.onBack!();
            } else {
              context.go('/client/home');
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: _currentStep,
              onStepContinue: () => _onStepContinue(userRole),
              onStepCancel: _onStepCancel,
              controlsBuilder: (context, details) {
                final isLast = _currentStep == steps.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLast ? _confirmBooking : details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLast ? Colors.green : AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(isLast ? 'Confirmar Reserva' : 'Continuar'),
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: details.onStepCancel,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Atrás'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: steps,
            ),
    );
  }

  List<Step> _getSteps(String role) {
    final List<Step> steps = [];
    
    if (role != 'client') {
      steps.add(
        Step(
          title: const Text('Seleccionar Cliente'),
          content: _buildClientSelection(),
          isActive: _currentStep >= 0,
          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        ),
      );
    }
    
    final offset = role == 'client' ? 0 : 1;
    
    steps.addAll([
      Step(
        title: const Text('Seleccionar Servicio'),
        content: _buildServiceSelection(),
        isActive: _currentStep >= (0 + offset),
        state: _currentStep > (0 + offset) ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Seleccionar Fecha'),
        content: _buildDateSelection(),
        isActive: _currentStep >= (1 + offset),
        state: _currentStep > (1 + offset) ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Hora y Barbero'),
        content: _buildTimeAndBarberSelection(),
        isActive: _currentStep >= (2 + offset),
        state: _currentStep > (2 + offset) ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Confirmar'),
        content: _buildConfirmation(),
        isActive: _currentStep >= (3 + offset),
        state: StepState.indexed,
      ),
    ]);
    
    return steps;
  }

  Widget _buildClientSelection() {
    final clientIds = _clients.map((c) => (c['id_cliente'] ?? 0) as int).toSet();
    final effectiveSelectedId = (clientIds.contains(_selectedClientId)) ? _selectedClientId : (clientIds.isNotEmpty ? clientIds.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona el cliente para la cita:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
          ),
          value: effectiveSelectedId,
          hint: const Text('Selecciona un cliente'),
          items: _clients.map((c) {
            final String name = c['nombre_final'] ?? c['nombre'] ?? c['nombre_invitado'] ?? c['name'] ?? c['nombre_completo'] ?? 'Cliente General';
            final int id = (c['id_cliente'] ?? 0) as int;
            return DropdownMenuItem<int>(
              value: id,
              child: Text(name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedClientId = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildServiceSelection() {
    final services = Provider.of<ServiceProvider>(context).services;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Elige el servicio que deseas:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ...services.map((service) {
          final double price = double.tryParse(service['precio_neto']?.toString() ?? '0') ?? 0.0;
          final isSelected = _selectedServiceMap?['id_servicio'] == service['id_servicio'];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: isSelected ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedServiceMap = service;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.content_cut,
                        color: AppTheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service['nombre'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service['descripcion'] ?? 'Servicio profesional',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${service['duracion_minutos']} min',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    if (isSelected)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.check_circle,
                          color: AppTheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona la fecha de tu cita:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedTimeStr = null; // Reset time when date changes
              });
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(color: Colors.white),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Fecha seleccionada: ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeAndBarberSelection() {
    // 1. Filtrar los horarios de disponibilidad del barbero seleccionado
    final List<String> filteredTimes = _selectedBarberMap != null && _selectedServiceMap != null
        ? _availableTimes.where((time) => _isSlotAvailable(time, _selectedBarberMap!, _selectedDay, _selectedServiceMap!, _busySlots)).toList()
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selección de barbero
        const Text(
          'Selecciona tu barbero preferido:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ..._barbersList.map((barber) {
          final selectedId = (_selectedBarberMap?['id_barbero'] ?? _selectedBarberMap?['id_empleado'] ?? _selectedBarberMap?['id_usuario'] ?? _selectedBarberMap?['id'])?.toString();
          final bId = (barber['id_barbero'] ?? barber['id_empleado'] ?? barber['id_usuario'] ?? barber['id'])?.toString();
          final isSelected = selectedId != null && selectedId == bId;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: isSelected ? 3 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primary.withOpacity(0.2),
                child: Text(
                  (barber['nombre'] ?? 'B')[0],
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                barber['nombre'] ?? 'Sin nombre',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: const Text('Barbero profesional'),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppTheme.primary)
                  : null,
              onTap: () {
                setState(() {
                  _selectedBarberMap = barber;
                  _selectedTimeStr = null; // Reset time when barber changes
                });
              },
            ),
          );
        }).toList(),

        const SizedBox(height: 24),

        // Selección de hora
        const Text(
          'Selecciona la hora disponible:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _selectedBarberMap == null 
            ? const Text('Por favor, selecciona un barbero primero.', style: TextStyle(color: Colors.grey))
            : filteredTimes.isEmpty
                ? const Text('No hay horarios disponibles para este barbero en la fecha seleccionada.', style: TextStyle(color: Colors.redAccent))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filteredTimes.map((time) {
                      final isSelected = _selectedTimeStr == time;
                      return ChoiceChip(
                        label: Text(time),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedTimeStr = time;
                            });
                          }
                        },
                        selectedColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
      ],
    );
  }

  Widget _buildConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen de tu reserva:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        _buildSummaryItem(
          icon: Icons.person,
          title: 'Cliente',
          value: (() {
            final selectedClient = _clients.firstWhere((c) => c['id_cliente'] == _selectedClientId, orElse: () => null);
            return selectedClient?['nombre_final'] ?? selectedClient?['nombre_completo'] ?? 'Cliente General';
          })(),
        ),

        _buildSummaryItem(
          icon: Icons.content_cut,
          title: 'Servicio',
          value: _selectedServiceMap?['nombre'] ?? '',
        ),

        _buildSummaryItem(
          icon: Icons.calendar_today,
          title: 'Fecha',
          value: '${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
        ),

        _buildSummaryItem(
          icon: Icons.access_time,
          title: 'Hora',
          value: _selectedTimeStr ?? '',
        ),

        _buildSummaryItem(
          icon: Icons.person_outline,
          title: 'Barbero',
          value: _selectedBarberMap?['nombre'] ?? '',
        ),

        _buildSummaryItem(
          icon: Icons.attach_money,
          title: 'Precio',
          value: '\$${_selectedServiceMap?['precio_neto'] ?? 0}',
          isLast: true,
        ),

      ],
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String value,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) const Divider(height: 32),
      ],
    );
  }

  void _onStepContinue(String role) {
    final maxSteps = role == 'client' ? 3 : 4;
    
    if (role != 'client') {
      if (_currentStep == 0 && _selectedClientId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona un cliente')),
        );
        return;
      }
      if (_currentStep == 1 && _selectedServiceMap == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona un servicio')),
        );
        return;
      }
      if (_currentStep == 3 && (_selectedTimeStr == null || _selectedBarberMap == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona hora y barbero')),
        );
        return;
      }
    } else {
      if (_currentStep == 0 && _selectedServiceMap == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona un servicio')),
        );
        return;
      }
      if (_currentStep == 2 && (_selectedTimeStr == null || _selectedBarberMap == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor selecciona hora y barbero')),
        );
        return;
      }
    }
    
    if (_currentStep < maxSteps) {
      setState(() {
        _currentStep += 1;
      });
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  void _confirmBooking() async {
    if (_selectedClientId == null || _selectedServiceMap == null || _selectedBarberMap == null || _selectedTimeStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos de la reserva')),
      );
      return;
    }
    
    final isAvailable = _isSlotAvailable(
      _selectedTimeStr!,
      _selectedBarberMap!,
      _selectedDay,
      _selectedServiceMap!,
      _busySlots,
    );
    
    if (!isAvailable) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Reserva no válida"),
          content: const Text("El horario seleccionado ya no está disponible o ha pasado. Por favor elige otro horario."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Entendido"),
            )
          ],
        ),
      );
      return;
    }
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.user;

    final selectedClient = _clients.firstWhere(
      (c) => (c['id_cliente']?.toString() == _selectedClientId?.toString()) || (c['id_usuario']?.toString() == _selectedClientId?.toString()),
      orElse: () => {
        'id_cliente': _selectedClientId ?? currentUser?.id ?? 1,
        'nombre_final': currentUser?.name ?? 'Cliente',
        'nombre': currentUser?.name ?? 'Cliente'
      },
    );

    setState(() => _isLoading = true);
    
    final int clientId = (selectedClient['id_cliente'] ?? _selectedClientId ?? 1) as int;
    final int barberId = (_selectedBarberMap!['id_barbero'] ?? _selectedBarberMap!['id_usuario']) as int;
    final int serviceId = _selectedServiceMap!['id_servicio'] as int;
    
    final dateStr = "${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}";
    final duration = _selectedServiceMap!['duracion_minutos'] ?? 30;
    final endTimeStr = calculateHoraFin(_selectedTimeStr!, duration);
    
    final payload = {
      'id_cliente': clientId,
      'id_barbero': barberId,
      'id_servicio': serviceId,
      'fecha': dateStr,
      'hora_inicio': _selectedTimeStr,
      'hora_fin': endTimeStr,
      'detalles_json': {
        'servicios': [serviceId],
        'productos': []
      }
    };
    
    try {
      final success = await _appointmentService.create(payload);
      if (success && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Text('¡Reserva Confirmada!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tu cita ha sido reservada exitosamente en el sistema.'),
                const SizedBox(height: 16),
                Text(
                  'Detalles:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Cliente: ${selectedClient['nombre_final'] ?? selectedClient['nombre'] ?? 'Cliente'}'),
                Text('Servicio: ${_selectedServiceMap!['nombre']}'),
                Text('Fecha: $dateStr'),
                Text('Hora: $_selectedTimeStr'),
                Text('Barbero: ${_selectedBarberMap!['nombre']}'),
              ],
            ),
            actions: [
              ElevatedButton.icon(
                icon: const Icon(Icons.chat, color: Colors.white),
                label: const Text('Enviar por WhatsApp al Barbero'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final String barberPhone = (_selectedBarberMap!['telefono'] ?? _selectedBarberMap!['phone'] ?? '').toString();
                  final String barberName = (_selectedBarberMap!['nombre'] ?? 'Barbero').toString();
                  final String clientName = (selectedClient['nombre_final'] ?? selectedClient['nombre'] ?? 'Cliente').toString();
                  final String clientPhone = (selectedClient['telefono_final'] ?? selectedClient['telefono'] ?? 'N/A').toString();
                  final String serviceName = (_selectedServiceMap!['nombre'] ?? 'Servicio').toString();

                  final message = WhatsAppHelper.buildNewAppointmentBarberMessage(
                    barberName: barberName,
                    clientName: clientName,
                    clientPhone: clientPhone,
                    serviceName: serviceName,
                    dateStr: dateStr,
                    timeStr: _selectedTimeStr!,
                    endTimeStr: endTimeStr,
                  );

                  await WhatsAppHelper.openWhatsApp(
                    phone: barberPhone,
                    message: message,
                    context: context,
                  );
                },
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cerrar diálogo
                  
                  // Reset wizard steps
                  setState(() {
                    _currentStep = 0;
                    _selectedServiceMap = null;
                    _selectedBarberMap = null;
                    _selectedTimeStr = null;
                  });

                  if (Navigator.canPop(context)) {
                    Navigator.pop(context); // Regresar
                  } else {
                    context.go('/client/home');
                  }
                },
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al procesar la reserva. Inténtalo de nuevo.')),
        );
      }
    } catch (e) {
      debugPrint("Error making booking: $e");
      String errorMessage = 'No se pudo completar la reserva. Verifica que la fecha y el horario no hayan pasado y que el barbero esté disponible.';
      if (e is DioException && e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          errorMessage = data['message'].toString();
        } else if (data is Map && data['error'] != null) {
          errorMessage = data['error'].toString();
        }
      }
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reserva no completada'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
