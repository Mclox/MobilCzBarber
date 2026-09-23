import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/app_theme.dart';
import '../../services/appointment_service.dart';

class ModifyAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const ModifyAppointmentScreen({super.key, required this.appointment});

  @override
  State<ModifyAppointmentScreen> createState() => _ModifyAppointmentScreenState();
}

class _ModifyAppointmentScreenState extends State<ModifyAppointmentScreen> {
  final AppointmentService _appointmentService = AppointmentService();

  late DateTime _selectedDay;
  late DateTime _focusedDay;
  
  Map<String, dynamic>? _selectedBarberMap;
  Map<String, dynamic>? _selectedServiceMap;
  String? _selectedTimeStr;

  List<dynamic> _barbersList = [];
  List<dynamic> _services = [];
  List<dynamic> _busySlots = [];
  bool _isLoading = false;

  final List<String> _availableTimes = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30', '15:00', '15:30',
    '16:00', '16:30', '17:00', '17:30', '18:00', '18:30', '19:00', '19:30',
    '20:00', '20:30', '21:00'
  ];

  @override
  void initState() {
    super.initState();
    final rawDate = widget.appointment['date'];
    if (rawDate is DateTime) {
      _selectedDay = rawDate;
    } else if (rawDate != null) {
      try {
        _selectedDay = DateTime.parse(rawDate.toString());
      } catch (_) {
        _selectedDay = DateTime.now();
      }
    } else {
      _selectedDay = DateTime.now();
    }
    _focusedDay = _selectedDay;
    _selectedTimeStr = (widget.appointment['time'] ?? widget.appointment['hora_inicio'])?.toString();
    _loadInitialData();
  }

  String _getBarberDisplayName(Map<String, dynamic>? barber) {
    if (barber == null) return widget.appointment['barber']?.toString() ?? 'Barbero no seleccionado';

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
      for (final b in _barbersList) {
        if (b is Map) {
          final bId = (b['id_barbero'] ?? b['id_empleado'] ?? b['id_usuario'] ?? b['id'])?.toString();
          if (bId == selId) {
            for (final cand in [
              b['nombre'], b['name'], b['nombre_completo'], b['nombre_final'],
              if (b['usuario'] is Map) b['usuario']['nombre']
            ]) {
              if (cand != null && cand.toString().trim().isNotEmpty && cand.toString().trim().toLowerCase() != 'null') {
                return cand.toString().trim();
              }
            }
          }
        }
      }
    }

    return widget.appointment['barber']?.toString() ?? 'Barbero';
  }

  String _getServiceDisplayName(Map<String, dynamic>? service) {
    if (service == null) return widget.appointment['service']?.toString() ?? 'Servicio';
    final name = service['nombre'] ?? service['name'] ?? service['titulo'] ?? widget.appointment['service'];
    return (name ?? 'Servicio').toString();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final barbersList = await _appointmentService.getBarberos();
      final servicesList = await _appointmentService.getServicios();
      final busy = await _appointmentService.getPublicBusySlots();

      if (!mounted) return;

      setState(() {
        _barbersList = barbersList;
        _services = servicesList;
        _busySlots = busy;

        // Resolve selected barber
        final barberIdTarget = widget.appointment['id_barbero']?.toString();
        if (barberIdTarget != null) {
          _selectedBarberMap = _barbersList.firstWhere(
            (b) {
              if (b == null || b is! Map) return false;
              final id = (b['id_barbero'] ?? b['id_usuario'] ?? b['id_empleado'] ?? b['id'])?.toString();
              return id != null && id == barberIdTarget;
            },
            orElse: () => null,
          );
        }
        if (_selectedBarberMap == null && widget.appointment['barber'] != null) {
          final barberNameStr = widget.appointment['barber'].toString().toLowerCase();
          _selectedBarberMap = _barbersList.firstWhere(
            (b) {
              if (b == null || b is! Map) return false;
              final bName = _getBarberDisplayName(b is Map<String, dynamic> ? b : Map<String, dynamic>.from(b)).toLowerCase();
              return bName.contains(barberNameStr) || barberNameStr.contains(bName);
            },
            orElse: () => _barbersList.isNotEmpty ? Map<String, dynamic>.from(_barbersList.first) : null,
          );
        }
        if (_selectedBarberMap == null && _barbersList.isNotEmpty) {
          _selectedBarberMap = Map<String, dynamic>.from(_barbersList.first);
        }

        // Resolve selected service
        final serviceIdTarget = widget.appointment['id_servicio']?.toString();
        if (serviceIdTarget != null) {
          _selectedServiceMap = _services.firstWhere(
            (s) {
              if (s == null || s is! Map) return false;
              final id = (s['id_servicio'] ?? s['id'])?.toString();
              return id != null && id == serviceIdTarget;
            },
            orElse: () => null,
          );
        }
        if (_selectedServiceMap == null && widget.appointment['service'] != null) {
          final serviceNameStr = widget.appointment['service'].toString().toLowerCase();
          _selectedServiceMap = _services.firstWhere(
            (s) {
              if (s == null || s is! Map) return false;
              final sName = _getServiceDisplayName(s is Map<String, dynamic> ? s : Map<String, dynamic>.from(s)).toLowerCase();
              return sName.contains(serviceNameStr) || serviceNameStr.contains(sName);
            },
            orElse: () => _services.isNotEmpty ? Map<String, dynamic>.from(_services.first) : null,
          );
        }
        if (_selectedServiceMap == null && _services.isNotEmpty) {
          _selectedServiceMap = Map<String, dynamic>.from(_services.first);
        }
      });
    } catch (e) {
      debugPrint("Error loading modification data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _extractYMD(String? s) {
    if (s == null || s.isEmpty) return '';
    if (s.contains('T')) return s.split('T')[0];
    if (s.length >= 10) return s.substring(0, 10);
    return s;
  }

  bool _isSlotAvailable(String timeStr, Map<String, dynamic> barber, DateTime date, Map<String, dynamic> service, List<dynamic> busySlots) {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    if (dateStr.compareTo(todayStr) < 0) {
      return false;
    }
    
    final parts = timeStr.split(':');
    if (parts.length < 2) return false;
    final hh = int.tryParse(parts[0]) ?? 0;
    final mm = int.tryParse(parts[1]) ?? 0;
    final slotStart = hh * 60 + mm;
    
    if (dateStr == todayStr) {
      final currentMins = now.hour * 60 + now.minute;
      if (slotStart <= currentMins) {
        return false; 
      }
    }
    
    final barberId = (barber['id_barbero'] ?? barber['id_usuario'] ?? barber['id_empleado'] ?? barber['id'])?.toString();
    final duration = service['duracion_minutos'] ?? 30;
    final slotEnd = slotStart + duration;
    
    for (final busy in busySlots) {
      if (busy == null || busy is! Map) continue;
      
      // Excluir la cita actual que se está editando para que no bloquee su propia hora/fecha original
      final busyCitaId = (busy['id_cita'] ?? busy['id'])?.toString();
      final currentCitaId = (widget.appointment['id_cita'] ?? widget.appointment['id'])?.toString();
      if (busyCitaId != null && currentCitaId != null && busyCitaId == currentCitaId) {
        continue;
      }

      final busyDateStr = _extractYMD(busy['fecha']?.toString());
      final busyBarberId = (busy['id_barbero'] ?? busy['id_usuario'] ?? busy['id_empleado'] ?? busy['id'])?.toString();
      
      if (busyDateStr == dateStr && busyBarberId != null && barberId != null && busyBarberId == barberId) {
        final bStartStr = (busy['hora_inicio'] ?? busy['hora'])?.toString();
        final bEndStr = busy['hora_fin']?.toString();
        if (bStartStr == null || bEndStr == null) continue;

        final bStartParts = bStartStr.split(':');
        final bEndParts = bEndStr.split(':');
        if (bStartParts.length < 2 || bEndParts.length < 2) continue;

        final bStartH = int.tryParse(bStartParts[0]);
        final bStartM = int.tryParse(bStartParts[1]);
        final bEndH = int.tryParse(bEndParts[0]);
        final bEndM = int.tryParse(bEndParts[1]);

        if (bStartH == null || bStartM == null || bEndH == null || bEndM == null) continue;
        
        final bStart = bStartH * 60 + bStartM;
        final bEnd = bEndH * 60 + bEndM;
        
        if (slotStart < bEnd && slotEnd > bStart) {
          return false; 
        }
      }
    }
    return true;
  }

  String calculateHoraFin(String horaInicio, int durationMinutes) {
    final parts = horaInicio.split(':');
    int hour = int.tryParse(parts[0]) ?? 9;
    int minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    minute += durationMinutes;
    while (minute >= 60) {
      hour += 1;
      minute -= 60;
    }
    return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Modificar Cita'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildServiceSelection(),
                    const SizedBox(height: 24),
                    _buildBarberSelection(),
                    const SizedBox(height: 24),
                    _buildDateSelection(),
                    const SizedBox(height: 24),
                    _buildTimeSelection(),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Guardar Cambios',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      );
    } catch (e, stack) {
      debugPrint("Error in ModifyAppointmentScreen.build: $e\n$stack");
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Modificar Cita'),
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
                  'Ocurrió un problema al abrir el formulario de modificación.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Detalle del error: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Regresar a Mis Citas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildServiceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Servicio:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (_services.isEmpty)
          const Text('Cargando servicios...', style: TextStyle(color: Colors.grey))
        else
          ..._services.map((service) {
            if (service == null || service is! Map) return const SizedBox.shrink();
            final serviceMap = service is Map<String, dynamic> ? service : Map<String, dynamic>.from(service as Map);
            final serviceId = (serviceMap['id_servicio'] ?? serviceMap['id'])?.toString();
            final selectedServiceId = (_selectedServiceMap?['id_servicio'] ?? _selectedServiceMap?['id'])?.toString();
            final isSelected = serviceId != null && serviceId == selectedServiceId;
            final name = _getServiceDisplayName(serviceMap);
            final price = serviceMap['precio'] ?? serviceMap['precio_neto'] ?? 0;
            final duration = serviceMap['duracion_minutos'] ?? 30;

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
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.content_cut, color: AppTheme.primary, size: 20),
                ),
                title: Text(
                  name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text('\$$price · $duration min'),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppTheme.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedServiceMap = serviceMap;
                    _selectedTimeStr = null; // Reset time when service changes
                  });
                },
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildBarberSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Barbero:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (_barbersList.isEmpty)
          const Text(
            'Cargando barberos...',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          )
        else
          ..._barbersList.map((barber) {
            if (barber == null || barber is! Map) return const SizedBox.shrink();
            final barberMap = barber is Map<String, dynamic> ? barber : Map<String, dynamic>.from(barber as Map);
            final barberId = (barberMap['id_barbero'] ?? barberMap['id_usuario'] ?? barberMap['id_empleado'] ?? barberMap['id'])?.toString();
            final selectedBarberId = (_selectedBarberMap?['id_barbero'] ?? _selectedBarberMap?['id_usuario'] ?? _selectedBarberMap?['id_empleado'] ?? _selectedBarberMap?['id'])?.toString();
            final isSelected = barberId != null && barberId == selectedBarberId;
            final name = _getBarberDisplayName(barberMap);
            final initial = name.isNotEmpty ? name[0].toUpperCase() : 'B';

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
                  name,
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
                    _selectedTimeStr = null; // Reset time slot when barber changes
                  });
                },
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
          'Nueva Fecha:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
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
            firstDay: DateTime.now().subtract(const Duration(days: 1)),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _focusedDay,
            currentDay: DateTime.now(),
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
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelection() {
    final List<String> filteredTimes = _selectedBarberMap != null && _selectedServiceMap != null
        ? _availableTimes.where((time) => _isSlotAvailable(time, _selectedBarberMap!, _selectedDay, _selectedServiceMap!, _busySlots)).toList()
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nueva Hora:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (filteredTimes.isEmpty)
          const Text(
            'No hay horarios disponibles para esta fecha con el barbero seleccionado.',
            style: TextStyle(color: Colors.red, fontSize: 14),
          )
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

  void _saveChanges() async {
    if (_selectedBarberMap == null || _selectedServiceMap == null || _selectedTimeStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona servicio, barbero, fecha y hora')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dateStr = "${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}";
      final duration = int.tryParse((_selectedServiceMap!['duracion_minutos'] ?? 30).toString()) ?? 30;
      final endTimeStr = calculateHoraFin(_selectedTimeStr!, duration);

      final int clientId = int.tryParse((widget.appointment['id_cliente'] ?? 1).toString()) ?? 1;
      final int barberId = int.tryParse((_selectedBarberMap!['id_barbero'] ?? _selectedBarberMap!['id_usuario'] ?? _selectedBarberMap!['id_empleado'] ?? _selectedBarberMap!['id'] ?? 1).toString()) ?? 1;
      final int serviceId = int.tryParse((_selectedServiceMap!['id_servicio'] ?? _selectedServiceMap!['id'] ?? 1).toString()) ?? 1;
      final int appointmentId = int.tryParse((widget.appointment['id_cita'] ?? widget.appointment['id'] ?? 0).toString()) ?? 0;

      final payload = {
        'id_cliente': clientId,
        'id_barbero': barberId,
        'id_servicio': serviceId,
        'fecha': dateStr,
        'hora_inicio': _selectedTimeStr,
        'hora_fin': endTimeStr,
        'estado': widget.appointment['status'] ?? 'pendiente',
        'detalles_json': {
          'servicios': [serviceId],
          'productos': []
        }
      };

      final success = await _appointmentService.update(appointmentId, payload);
      
      if (success && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al modificar la cita. Por favor intenta de nuevo.')),
        );
      }
    } catch (e) {
      debugPrint("Error updating appointment: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocurrió un error. Verifica la disponibilidad del barbero e intenta de nuevo.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
