import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../network/ReportService.dart';

/// Shows the patient self-upload sheet. Resolves to `true` if a report was added.
Future<bool?> showAddMyReportSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddMyReportSheet(),
  );
}

class _AddMyReportSheet extends StatefulWidget {
  const _AddMyReportSheet();

  @override
  State<_AddMyReportSheet> createState() => _AddMyReportSheetState();
}

class _AddMyReportSheetState extends State<_AddMyReportSheet> {
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

  final _reportService = ReportService();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedType = 'LAB_RESULT';
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: _teal, onPrimary: Colors.white, onSurface: _textDark),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
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

    final result = await _reportService.addMyReport(
      title: _titleController.text.trim(),
      type: _selectedType,
      reportDate: _selectedDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      filePath: _pickedFilePath,
    );

    if (!mounted) return;
    if (result.success) {
      Navigator.pop(context, true);
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
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Upload Report',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _textDark)),
            const SizedBox(height: 18),
            _fieldLabel('Title'),
            _textField(_titleController, 'e.g. Blood test from City Lab'),
            const SizedBox(height: 14),
            _fieldLabel('Type'),
            Container(
              decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  items: _types
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(_typeLabels[t]!)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _fieldLabel('Report Date'),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: _textMuted),
                    const SizedBox(width: 8),
                    Text(_formatDate(_selectedDate),
                        style: const TextStyle(fontSize: 14, color: _textDark)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _fieldLabel('Notes (optional)'),
            _textField(_notesController, 'Anything worth noting', maxLines: 3),
            const SizedBox(height: 14),
            _fieldLabel('Attachment (optional)'),
            _buildFilePicker(),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
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
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Upload',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
      );

  Widget _buildFilePicker() {
    if (_pickedFileName != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(12)),
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
              child: Text(_pickedFileName!,
                  style: const TextStyle(fontSize: 13, color: _textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            GestureDetector(
              onTap: () => setState(() {
                _pickedFilePath = null;
                _pickedFileName = null;
              }),
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
          border: Border.all(color: const Color(0xFFDDE1EA)),
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

  Widget _textField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(12)),
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

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
