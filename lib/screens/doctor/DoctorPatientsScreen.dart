import 'package:flutter/material.dart';

import '../../dto/DoctorPatientDTO.dart';
import '../../network/AppointmentService.dart';
import 'DoctorPatientDetailScreen.dart';

class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  static const _teal = Color(0xFF1A9882);
  static const _textDark = Color(0xFF1C2B47);
  static const _textMuted = Color(0xFF7A8399);
  static const _bg = Color(0xFFF5F6FA);

  final _appointmentService = AppointmentService();
  final _searchController = TextEditingController();

  bool _loading = false;
  String? _error;
  List<DoctorPatientDTO> _patients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final patients = await _appointmentService.getMyPatients();
      setState(() {
        _patients = patients;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load patients';
        _loading = false;
      });
    }
  }

  List<DoctorPatientDTO> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _patients;
    return _patients.where((p) => p.fullName.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Patients',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _textDark),
                  ),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                ],
              ),
            ),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: 'Search patients',
          hintStyle: TextStyle(color: _textMuted, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: _textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _teal));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: _textMuted)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadPatients,
              child: const Text('Retry', style: TextStyle(color: _teal)),
            ),
          ],
        ),
      );
    }

    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Text(
          _patients.isEmpty ? 'No patients yet' : 'No matches found',
          style: const TextStyle(color: _textMuted, fontSize: 14),
        ),
      );
    }

    return RefreshIndicator(
      color: _teal,
      onRefresh: _loadPatients,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _patientCard(items[i]),
      ),
    );
  }

  void _openPatientDetail(DoctorPatientDTO p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DoctorPatientDetailScreen(patient: p)),
    );
  }

  Widget _patientCard(DoctorPatientDTO p) {
    return GestureDetector(
      onTap: () => _openPatientDetail(p),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFE0EEF8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person_outline, color: Color(0xFF5B8DB8), size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.fullName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textDark)),
                  const SizedBox(height: 2),
                  Text(
                    p.age != null ? '${p.age} years' : '${p.totalAppointments} visit${p.totalAppointments == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 13, color: _textMuted),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(
                      p.nextAppointment != null ? Icons.event_outlined : Icons.history,
                      size: 13,
                      color: _textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      p.nextAppointment != null
                          ? 'Next: ${_formatDate(p.nextAppointment!)}'
                          : p.lastVisit != null
                              ? 'Last visit: ${_formatDate(p.lastVisit!)}'
                              : 'No visits yet',
                      style: const TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ]),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}
