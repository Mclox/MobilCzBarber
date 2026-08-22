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
    '16:00', '16:30', '17:00', '17:30', '18:00',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.appointment['date'] as DateTime;
    _focusedDay = _selectedDay;
    _selectedTimeStr = widget.appointment['time'] as String?;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final barbersList = await _appointmentService.getBarberos();
      final servicesList = await _appointmentService.getServicios();
      final busy = await _appointmentService.getPublicBusySlots();

      setState(() {
        _barbersList = barbersList;
        _services = servicesList;
        _busySlots = busy;

        // Resolve selected barber
        if (widget.appointment['id_barbero'] != null) {
          _selectedBarberMap = _barbersList.firstWhere(
            (b) => b['id_barbero'].toString() == widget.appointment['id_barbero'].toString(),
            orElse: () => null,
          );
        }
        if (_selectedBarberMap == null && _barbersList.isNotEmpty) {
          _selectedBarberMap = _barbersList.firstWhere(
            (b) => b['nombre'].toString().toLowerCase() == widget.appointment['barber'].toString().toLowerCase(),
            orElse: () => _barbersList.first,
          );
        }

        // Resolve selected service
        if (widget.appointment['id_servicio'] != null) {
          _selectedServiceMap = _services.firstWhere(
            (s) => s['id_servicio'].toString() == widget.appointment['id_servicio'].toString(),
            orElse: () => null,
          );
        }
        if (_selectedServiceMap == null && _services.isNotEmpty) {
          _selectedServiceMap = _services.firstWhere(
            (s) => s['nombre'].toString().toLowerCase() == widget.appointment['service'].toString().toLowerCase(),
            orElse: () => _services.first,
          );
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
      // Excluir la cita actual que se está editando para que no bloquee su propia hora/fecha original
      if (busy['id_cita']?.toString() == widget.appointment['id_cita']?.toString()) {
        continue;
      }
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
                  _buildServiceInfo(),
                  const SizedBox(height: 24),
                  _buildDateSelection(),
                  const SizedBox(height: 24),
                  _buildTimeSelection(),
                  const SizedBox(height: 24),
                  _buildBarberSelection(),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Guardar Cambios'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildServiceInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.content_cut, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Servicio contratado',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  _selectedServiceMap?['nombre'] ?? widget.appointment['service'] ?? 'Servicio',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            firstDay: DateTime.now(),
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
          const Center(child: CircularProgressIndicator())
        else
          ..._barbersList.map((barber) {
            final isSelected = _selectedBarberMap?['id_barbero'] == barber['id_barbero'] ||
                             _selectedBarberMap?['id_usuario'] == barber['id_usuario'];
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
                  barber['nombre'] ?? 'Barbero',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppTheme.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedBarberMap = barber;
                    _selectedTimeStr = null; // Reset time slot when barber changes
                  });
                },
              ),
            );
          }).toList(),
      ],
    );
  }

  void _saveChanges() async {
    if (_selectedBarberMap == null || _selectedServiceMap == null || _selectedTimeStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona hora y barbero')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dateStr = "${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}";
      final duration = _selectedServiceMap!['duracion_minutos'] ?? 30;
      final endTimeStr = calculateHoraFin(_selectedTimeStr!, duration);

      final payload = {
        'id_cliente': widget.appointment['id_cliente'] ?? 1,
        'id_barbero': _selectedBarberMap!['id_barbero'] ?? _selectedBarberMap!['id_usuario'] ?? 1,
        'id_servicio': _selectedServiceMap!['id_servicio'] ?? 1,
        'fecha': dateStr,
        'hora_inicio': _selectedTimeStr,
        'hora_fin': endTimeStr,
        'estado': widget.appointment['status'] ?? 'pendiente',
        'detalles_json': {
          'servicios': [_selectedServiceMap!['id_servicio']],
          'productos': []
        }
      };

      final success = await _appointmentService.update(widget.appointment['id_cita'], payload);
      
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
