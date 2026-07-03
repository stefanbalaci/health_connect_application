import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../dto/DoctorAppointmentDTO.dart';
import '../../dto/DoctorPatientDTO.dart';
import '../../dto/ReportDTO.dart';
import '../../network/AppointmentService.dart';
import '../../network/ReportService.dart';
import '../PrescriptionScreen.dart';
import '../ReportViewerScreen.dart';

class DoctorPatientDetailScreen extends StatefulWidget {
  final DoctorPatientDTO patient;

  const DoctorPatientDetailScreen({super.key, required this.patient});

  @override
  State<DoctorPatientDetailScreen> createState() => _DoctorPatientDetailScreenState();
}

class _DoctorPatientDetailScreenState extends State<DoctorPatientDetailScreen> {
  static const _teal = Color(0xFF1A9882);
  static const _textDark = Color(0xFF1C2B47);
  static const _textMuted = Color(0xFF7A8399);
  static const _bg = Color(0xFFF5F6FA);

  final _reportService = ReportService();
  final _appointmentService = AppointmentService();

  bool _loading = false;
  String? _error;
  List<ReportDTO> _reports = [];

  bool _loadingAppointments = false;
  String? _appointmentError;
  List<DoctorAppointmentDTO> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
    _loadAppointments();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reports = await _reportService.getPatientReports(widget.patient.patientProfileId);
      reports.sort((a, b) => b.reportDate.compareTo(a.reportDate));
      setState(() {
        _reports = reports;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load reports';
        _loading = false;
      });
    }
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _loadingAppointments = true;
      _appointmentError = null;
    });
    try {
      final appointments =
          await _appointmentService.getPatientAppointments(widget.patient.patientProfileId);
      setState(() {
        _appointments = appointments;
        _loadingAppointments = false;
      });
    } catch (e) {
      setState(() {
        _appointmentError = 'Could not load appointments';
        _loadingAppointments = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadReports(), _loadAppointments()]);
  }

  void _openPrescription(DoctorAppointmentDTO a) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrescriptionScreen(
          appointmentId: a.id,
          patientName: widget.patient.fullName,
        ),
      ),
    );
  }

  void _openReport(ReportDTO r) {
    if (!r.hasFile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file attached to this report')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReportViewerScreen(report: r)),
    );
  }

  void _openAddReportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddReportSheet(
        patientProfileId: widget.patient.patientProfileId,
        reportService: _reportService,
        onAdded: _loadReports,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: _teal, size: 22),
        ),
        title: const Text(
          'Patient Details',
          style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        color: _teal,
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPatientHeader(p),
              const SizedBox(height: 24),
              const Text('Appointments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark)),
              const SizedBox(height: 12),
              _buildAppointmentsList(),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text('Reports',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark)),
                  ),
                  GestureDetector(
                    onTap: _openAddReportSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _teal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('Add Report',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildReportsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientHeader(DoctorPatientDTO p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0EEF8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person_outline, color: Color(0xFF5B8DB8), size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.fullName,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700, color: _textDark)),
                    const SizedBox(height: 2),
                    Text(
                      p.age != null ? '${p.age} years' : 'Age unknown',
                      style: const TextStyle(fontSize: 13, color: _textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF0F1F5)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _infoTile(
                  Icons.event_repeat_outlined,
                  'Total Visits',
                  '${p.totalAppointments}',
                ),
              ),
              Expanded(
                child: _infoTile(
                  Icons.history,
                  'Last Visit',
                  p.lastVisit != null ? _formatDate(p.lastVisit!) : '—',
                ),
              ),
              Expanded(
                child: _infoTile(
                  Icons.event_outlined,
                  'Next Visit',
                  p.nextAppointment != null ? _formatDate(p.nextAppointment!) : '—',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 18, color: _teal),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textDark)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: _textMuted)),
      ],
    );
  }

  Widget _buildAppointmentsList() {
    if (_loadingAppointments) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: _teal)),
      );
    }
    if (_appointmentError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(_appointmentError!, style: const TextStyle(color: _textMuted)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadAppointments,
              child: const Text('Retry', style: TextStyle(color: _teal)),
            ),
          ],
        ),
      );
    }
    if (_appointments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text('No appointments yet', style: TextStyle(color: _textMuted, fontSize: 13)),
        ),
      );
    }
    return Column(children: _appointments.map(_appointmentRow).toList());
  }

  Widget _appointmentRow(DoctorAppointmentDTO a) {
    final isCompleted = a.status == 'COMPLETED';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 13, color: _textMuted),
                  const SizedBox(width: 4),
                  Text(_formatDate(a.scheduledAt),
                      style: const TextStyle(fontSize: 12, color: _textMuted)),
                  const SizedBox(width: 10),
                  const Icon(Icons.schedule_outlined, size: 13, color: _textMuted),
                  const SizedBox(width: 4),
                  Text(_formatTime(a.scheduledAt),
                      style: const TextStyle(fontSize: 12, color: _textMuted)),
                ]),
                const SizedBox(height: 4),
                Text(
                  a.isVideoCall ? 'Video Call' : 'In-Person Visit',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark),
                ),
              ],
            ),
          ),
          _statusBadge(a.status),
          if (isCompleted) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _openPrescription(a),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _teal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.medication_outlined, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Prescription',
                        style: TextStyle(
                            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'CONFIRMED':
        bg = const Color(0xFFE3F6E8);
        fg = const Color(0xFF1F9D55);
        label = 'Confirmed';
        break;
      case 'IN_PROGRESS':
        bg = const Color(0xFFECF1FF);
        fg = const Color(0xFF4A6CF7);
        label = 'In Progress';
        break;
      case 'COMPLETED':
        bg = const Color(0xFFEDEFF3);
        fg = _textMuted;
        label = 'Completed';
        break;
      case 'CANCELLED':
        bg = const Color(0xFFFCE9E9);
        fg = const Color(0xFFD64545);
        label = 'Cancelled';
        break;
      case 'NO_SHOW':
        bg = const Color(0xFFFDEBD0);
        fg = const Color(0xFFC0392B);
        label = 'No-show';
        break;
      default:
        bg = const Color(0xFFFFF1E0);
        fg = const Color(0xFFE08A1F);
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  Widget _buildReportsList() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: _teal)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(_error!, style: const TextStyle(color: _textMuted)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadReports,
              child: const Text('Retry', style: TextStyle(color: _teal)),
            ),
          ],
        ),
      );
    }
    if (_reports.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text('No reports yet', style: TextStyle(color: _textMuted, fontSize: 14)),
        ),
      );
    }
    return Column(children: _reports.map(_reportCard).toList());
  }

  Widget _reportCard(ReportDTO r) {
    return GestureDetector(
      onTap: () => _openReport(r),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_outlined, color: _teal, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(r.title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700, color: _textDark)),
                    ),
                    if (r.isPdf)
                      _docFileBadge('PDF', Icons.picture_as_pdf_outlined,
                          const Color(0xFFD64545)),
                    if (r.isImage)
                      _docFileBadge('IMG', Icons.image_outlined, _teal),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEFF3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(r.typeLabel,
                          style: const TextStyle(
                              fontSize: 10.5, fontWeight: FontWeight.w700, color: _textMuted)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(_formatDate(r.reportDate),
                    style: const TextStyle(fontSize: 12, color: _textMuted)),
                if (r.notes != null && r.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(r.notes!, style: const TextStyle(fontSize: 13, color: _textDark)),
                ],
                const SizedBox(height: 4),
                Text(r.doctorSourceLabel,
                    style: const TextStyle(fontSize: 11, color: _textMuted)),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _docFileBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _AddReportSheet extends StatefulWidget {
  final int patientProfileId;
  final ReportService reportService;
  final VoidCallback onAdded;

  const _AddReportSheet({
    required this.patientProfileId,
    required this.reportService,
    required this.onAdded,
  });

  @override
  State<_AddReportSheet> createState() => _AddReportSheetState();
}

class _AddReportSheetState extends State<_AddReportSheet> {
  static const _teal = Color(0xFF1A9882);
  static const _textDark = Color(0xFF1C2B47);
  static const _textMuted = Color(0xFF7A8399);

  static const _types = [
    'BLOOD_TEST', 'MRI', 'CT_SCAN', 'X_RAY', 'ULTRASOUND', 'ECG', 'LAB_RESULT', 'OTHER',
  ];
  static const _typeLabels = {
    'BLOOD_TEST': 'Blood Test',
    'MRI': 'MRI',
    'CT_SCAN': 'CT Scan',
    'X_RAY': 'X-Ray',
    'ULTRASOUND': 'Ultrasound',
    'ECG': 'ECG',
    'LAB_RESULT': 'Lab Result',
    'OTHER': 'Other',
  };

  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedType = 'BLOOD_TEST';
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;
  String? _error;
  String? _pickedFilePath;
  String? _pickedFileName;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.path == null) return;
    setState(() {
      _pickedFilePath = file.path;
      _pickedFileName = file.name;
    });
  }

  void _removeFile() {
    setState(() {
      _pickedFilePath = null;
      _pickedFileName = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _teal, onPrimary: Colors.white, onSurface: _textDark),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Widget _buildFilePicker() {
    if (_pickedFileName != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              _pickedFileName!.toLowerCase().endsWith('.pdf')
                  ? Icons.picture_as_pdf_outlined
                  : Icons.image_outlined,
              size: 18,
              color: _teal,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _pickedFileName!,
                style: const TextStyle(fontSize: 13, color: _textDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: _removeFile,
              child: const Icon(Icons.close, size: 18, color: _textMuted),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE1EA), style: BorderStyle.solid),
        ),
        child: const Row(
          children: [
            Icon(Icons.attach_file, size: 18, color: _teal),
            SizedBox(width: 8),
            Text('Attach PDF, JPG or PNG',
                style: TextStyle(fontSize: 13, color: _textMuted)),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a title');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await widget.reportService.addReport(
      patientProfileId: widget.patientProfileId,
      title: _titleController.text.trim(),
      type: _selectedType,
      reportDate: _selectedDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      filePath: _pickedFilePath,
    );

    if (!mounted) return;

    if (result.success) {
      widget.onAdded();
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _error = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE1EA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Add Report',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark)),
            const SizedBox(height: 18),

            const Text('Title', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
            const SizedBox(height: 6),
            _textField(_titleController, 'e.g. Complete Blood Count'),
            const SizedBox(height: 14),

            const Text('Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  items: _types
                      .map((t) => DropdownMenuItem(value: t, child: Text(_typeLabels[t]!)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
              ),
            ),
            const SizedBox(height: 14),

            const Text('Report Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: _textMuted),
                    const SizedBox(width: 8),
                    Text(_formatPickedDate(_selectedDate),
                        style: const TextStyle(fontSize: 14, color: _textDark)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            const Text('Notes (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
            const SizedBox(height: 6),
            _textField(_notesController, 'Findings or summary', maxLines: 3),
            const SizedBox(height: 14),

            const Text('Attachment (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
            const SizedBox(height: 6),
            _buildFilePicker(),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Save Report',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  String _formatPickedDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
