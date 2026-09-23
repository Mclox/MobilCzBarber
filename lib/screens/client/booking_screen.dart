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
import '../../providers/barber_availability_provider.dart';
import '../../providers/barber_appointment_provider.dart';
import '../../widgets/booking_confirmation_dialog.dart';

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
  bool _isLoading = true;
  int _currentStep = 0;

  final List<String> _availableTimes = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30', '15:00', '15:30',
    '16:00', '16:30', '17:00', '17:30', '18:00', '18:30', '19:00', '19:30',
    '20:00', '20:30', '21:00', '21:30', '22:00'
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
    final slotStart = hh * 60 + mm;
    
    if (dateStr == todayStr) {
      final currentMins = now.hour * 60 + now.minute;
      if (slotStart <= currentMins) {
        return false; 
      }
    }
    
    // --- VALIDACIÓN DE DISPONIBILIDAD REAL ---
    final provider = Provider.of<BarberAvailabilityProvider>(context, listen: false);
    final barberId = barber['id_barbero'] ?? barber['id_usuario'] ?? barber['id'];
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    if (barberId.toString() == auth.user?.id.toString()) {
      // Validar día
      String getDayName(DateTime d) {
        switch (d.weekday) {
          case DateTime.monday: return "Lunes";
          case DateTime.tuesday: return "Martes";
          case DateTime.wednesday: return "Miércoles";
          case DateTime.thursday: return "Jueves";
          case DateTime.friday: return "Viernes";
          case DateTime.saturday: return "Sábado";
          case DateTime.sunday: return "Domingo";
          default: return "";
        }
      }
      final dayName = getDayName(date);
      if (provider.availability[dayName] == false) {
        return false;
      }
      
      // Validar horario
      final startMins = provider.startTime.hour * 60 + provider.startTime.minute;
      final endMins = provider.endTime.hour * 60 + provider.endTime.minute;
      if (slotStart < startMins || slotStart >= endMins) {
        return false;
      }
    } else {
      final startStr = barber['hora_inicio']?.toString();
      final endStr = barber['hora_fin']?.toString();
      
      if (startStr != null && startStr.isNotEmpty && endStr != null && endStr.isNotEmpty) {
        try {
          final startParts = startStr.split(':');
          final endParts = endStr.split(':');
          final startMins = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
          final endMins = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
          
          if (slotStart < startMins || slotStart >= endMins) {
            return false;
          }
        } catch (_) {}
      } else {
        if (slotStart < 8 * 60 || slotStart >= 18 * 60) {
          return false;
        }
      }
      
      if (date.weekday == DateTime.sunday) {
        return false;
      }
    }
    // --- FIN VALIDACIÓN ---
    
    final duration = service['duracion_minutos'] ?? 30;
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

  String _getBarberDisplayName(Map<String, dynamic>? barber) {
    if (barber == null) return 'Barbero no seleccionado';

    final nameCandidates = [
      barber['nombre'],
      barber['name'],
      barber['nombre_completo'],
      barber['nombre_final'],
      barber['usuario_nombre'],
      barber['barbero_nombre'],
      barber['empleado_nombre'],
      if (barber['usuario'] is Map) ...[
        barber['usuario']['nombre'],
        barber['usuario']['name'],
        barber['usuario']['nombre_completo'],
      ],
    ];

    for (final cand in nameCandidates) {
      if (cand != null && cand.toString().trim().isNotEmpty && cand.toString().trim().toLowerCase() != 'null') {
        return cand.toString().trim();
      }
    }

    final selId = (barber['id_barbero'] ??
            barber['id_empleado'] ??
            barber['id_usuario'] ??
            barber['id'])
        ?.toString();
    if (selId != null && _barbersList.isNotEmpty) {
      final found = _barbersList.firstWhere(
        (b) =>
            (b['id_barbero']?.toString() == selId) ||
            (b['id_empleado']?.toString() == selId) ||
            (b['id_usuario']?.toString() == selId) ||
            (b['id']?.toString() == selId),
        orElse: () => null,
      );
      if (found != null && found is Map) {
        final listCandidates = [
          found['nombre'],
          found['name'],
          found['nombre_completo'],
          found['nombre_final'],
          found['usuario_nombre'],
          if (found['usuario'] is Map) ...[
            found['usuario']['nombre'],
            found['usuario']['name'],
          ]
        ];
        for (final cand in listCandidates) {
          if (cand != null && cand.toString().trim().isNotEmpty && cand.toString().trim().toLowerCase() != 'null') {
            return cand.toString().trim();
          }
        }
      }
    }

    return 'Barbero profesional';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Reservar Cita'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/client/home');
              }
            },
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Cargando datos de reserva...',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context);
      final rawRole = (authProvider.user?.role ?? 'client').toLowerCase();
      final steps = _getSteps(rawRole);
      final safeStep = _currentStep.clamp(0, steps.isEmpty ? 0 : steps.length - 1);

      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Reservar Cita'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/client/home');
              }
            },
          ),
        ),
        body: Stepper(
          currentStep: safeStep,
          physics: const BouncingScrollPhysics(),
          type: StepperType.vertical,
          onStepContinue: () => _onStepContinue(rawRole),
          onStepCancel: _onStepCancel,
          onStepTapped: (step) {
            if (step <= safeStep) {
              setState(() => _currentStep = step);
            }
          },
          controlsBuilder: (context, details) {
            final isLast = safeStep == steps.length - 1;
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLast ? _confirmBooking : details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLast ? const Color(0xFF2E7D32) : AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Center(
                        child: Text(
                          isLast ? 'Confirmar Reserva' : 'Continuar',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (safeStep > 0) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.darkText,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        child: const Center(
                          child: Text(
                            'Atrás',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
    } catch (e, stack) {
      debugPrint("Error in BookingScreen.build: $e\n$stack");
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Reservar Cita'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Ocurrió un problema al abrir el formulario de agendamiento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _loadInitialData(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }
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
    final clientItems = <DropdownMenuItem<int>>[];
    final seenClientIds = <int>{};
    for (final c in _clients) {
      final int id = int.tryParse((c['id_cliente'] ?? c['id_usuario'] ?? 0).toString()) ?? 0;
      if (id != 0 && !seenClientIds.contains(id)) {
        seenClientIds.add(id);
        final String displayName = (c['nombre_final'] ?? c['nombre'] ?? c['name'] ?? c['nombre_completo'] ?? 'Cliente #$id').toString();
        clientItems.add(DropdownMenuItem(value: id, child: Text(displayName)));
      }
    }

    final effectiveSelectedId = seenClientIds.contains(_selectedClientId)
        ? _selectedClientId
        : (seenClientIds.isNotEmpty ? seenClientIds.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona el cliente para la cita:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (clientItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Cargando lista de clientes...', style: TextStyle(color: Colors.grey)),
          )
        else
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
            items: clientItems,
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
        if (services.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('No hay servicios disponibles actualmente.', style: TextStyle(color: Colors.grey))),
          )
        else
          ...services.map((service) {
            final double price = double.tryParse(service['precio_neto']?.toString() ?? '0') ?? 0.0;
            final duration = int.tryParse(service['duracion_minutos']?.toString() ?? '30') ?? 30;
            final isSelected = _selectedServiceMap?['id_servicio']?.toString() == service['id_servicio']?.toString();
            final serviceName = (service['nombre'] ?? 'Servicio').toString();
            final serviceDesc = (service['descripcion'] ?? 'Servicio profesional').toString();

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
                              serviceName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              serviceDesc,
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
                                  '$duration min',
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
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final lastDay = DateTime(now.year, now.month, now.day).add(const Duration(days: 90));
    final focusedDay = _focusedDay.isBefore(firstDay)
        ? firstDay
        : (_focusedDay.isAfter(lastDay) ? lastDay : _focusedDay);

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
            locale: 'es_ES',
            firstDay: firstDay,
            lastDay: lastDay,
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, newFocusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = newFocusedDay;
                _selectedTimeStr = null; // Reset time when date changes
              });
            },
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Color(0x4D1976D2),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(color: Colors.white),
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
                  'Fecha seleccionada: ${_selectedDay.day.toString().padLeft(2, '0')}/${_selectedDay.month.toString().padLeft(2, '0')}/${_selectedDay.year}',
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
    List<String> filteredTimes = [];
    try {
      if (_selectedBarberMap != null && _selectedServiceMap != null) {
        filteredTimes = _availableTimes.where((time) => _isSlotAvailable(time, _selectedBarberMap!, _selectedDay, _selectedServiceMap!, _busySlots)).toList();
      }
    } catch (e) {
      debugPrint("Error filtering available times: $e");
      filteredTimes = _availableTimes;
    }

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
        if (_barbersList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Cargando barberos disponibles...', style: TextStyle(color: Colors.grey)),
          )
        else
          ..._barbersList.map((barber) {
            final barberMap = barber is Map<String, dynamic> ? barber : Map<String, dynamic>.from(barber as Map);
            final selectedId = (_selectedBarberMap?['id_barbero'] ?? _selectedBarberMap?['id_empleado'] ?? _selectedBarberMap?['id_usuario'] ?? _selectedBarberMap?['id'])?.toString();
            final bId = (barberMap['id_barbero'] ?? barberMap['id_empleado'] ?? barberMap['id_usuario'] ?? barberMap['id'])?.toString();
            final isSelected = selectedId != null && selectedId == bId;
            final barberName = _getBarberDisplayName(barberMap);
            final initial = barberName.isNotEmpty ? barberName[0].toUpperCase() : 'B';

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
                    initial,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  barberName,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(barberMap['email'] ?? 'Barbero profesional'),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppTheme.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedBarberMap = barberMap;
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
        if (_selectedBarberMap == null)
          const Text('Por favor, selecciona un barbero primero.', style: TextStyle(color: Colors.grey))
        else if (filteredTimes.isEmpty)
          const Text('No hay horarios disponibles para este barbero en la fecha seleccionada.', style: TextStyle(color: Colors.redAccent))
        else
          Wrap(
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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.user;

    final selectedClient = _clients.firstWhere(
      (c) => (c['id_cliente']?.toString() == _selectedClientId?.toString()) ||
             (c['id_usuario']?.toString() == _selectedClientId?.toString()),
      orElse: () => null,
    );

    final clientName = selectedClient?['nombre_final'] ??
        selectedClient?['nombre'] ??
        selectedClient?['name'] ??
        selectedClient?['nombre_completo'] ??
        currentUser?.name ??
        'Cliente General';

    final serviceName = _selectedServiceMap?['nombre'] ?? 'Servicio no seleccionado';
    final price = _selectedServiceMap?['precio_neto'] ?? 0;
    final barberName = _getBarberDisplayName(_selectedBarberMap);
    final dateStr = '${_selectedDay.day.toString().padLeft(2, '0')}/${_selectedDay.month.toString().padLeft(2, '0')}/${_selectedDay.year}';
    final timeStr = _selectedTimeStr ?? 'Hora no seleccionada';

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
          value: clientName,
        ),

        _buildSummaryItem(
          icon: Icons.content_cut,
          title: 'Servicio',
          value: serviceName,
        ),

        _buildSummaryItem(
          icon: Icons.calendar_today,
          title: 'Fecha',
          value: dateStr,
        ),

        _buildSummaryItem(
          icon: Icons.access_time,
          title: 'Hora',
          value: timeStr,
        ),

        _buildSummaryItem(
          icon: Icons.person_outline,
          title: 'Barbero',
          value: barberName,
        ),

        _buildSummaryItem(
          icon: Icons.attach_money,
          title: 'Precio Total',
          value: '\$$price',
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
    
    final int clientId = int.tryParse((selectedClient['id_cliente'] ?? _selectedClientId ?? 1).toString()) ?? 1;
    final int barberId = int.tryParse((_selectedBarberMap!['id_barbero'] ?? _selectedBarberMap!['id_usuario'] ?? _selectedBarberMap!['id_empleado'] ?? 1).toString()) ?? 1;
    final int serviceId = int.tryParse((_selectedServiceMap!['id_servicio'] ?? _selectedServiceMap!['id'] ?? 1).toString()) ?? 1;
    
    final dateStr = "${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}";
    final duration = int.tryParse((_selectedServiceMap!['duracion_minutos'] ?? 30).toString()) ?? 30;
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
        try {
          Provider.of<BarberAppointmentProvider>(context, listen: false).loadAppointments();
        } catch (_) {}
        showDialog(
          context: context,
          builder: (context) => BookingConfirmationDialog(
            clientName: (selectedClient['nombre_final'] ?? selectedClient['nombre'] ?? 'Cliente').toString(),
            serviceName: (_selectedServiceMap!['nombre'] ?? 'Servicio').toString(),
            dateStr: dateStr,
            timeStr: _selectedTimeStr!,
            barberName: _getBarberDisplayName(_selectedBarberMap),
            onSendWhatsApp: () async {
              final String barberPhone = (_selectedBarberMap!['telefono'] ?? _selectedBarberMap!['phone'] ?? '').toString();
              final String barberName = _getBarberDisplayName(_selectedBarberMap);
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
            onClose: () {
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
