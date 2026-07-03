import 'package:flutter/material.dart';

import '../../network/ProfileService.dart';

class ClinicDetailsScreen extends StatefulWidget {
  const ClinicDetailsScreen({super.key});

  @override
  State<ClinicDetailsScreen> createState() => _ClinicDetailsScreenState();
}

class _ClinicDetailsScreenState extends State<ClinicDetailsScreen> {
  static const _teal = Color(0xFF1A9882);
  static const _textDark = Color(0xFF1C2B47);
  static const _textMuted = Color(0xFF7A8399);
  static const _bg = Color(0xFFF5F6FA);

  final _profileService = ProfileService();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _details = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = await _profileService.getClinic();
      if (!mounted) return;
      setState(() {
        _name.text = c.clinicName ?? '';
        _address.text = c.clinicAddress ?? '';
        _details.text = c.clinicDetails ?? '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load clinic details';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await _profileService.updateClinic(
      clinicName: _name.text.trim().isEmpty ? null : _name.text.trim(),
      clinicAddress: _address.text.trim().isEmpty ? null : _address.text.trim(),
      clinicDetails: _details.text.trim().isEmpty ? null : _details.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? _teal : const Color(0xFFE57373),
      ),
    );
    if (result.success) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Clinic Details',
            style: TextStyle(
                color: _textDark, fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _error != null
              ? _errorView()
              : _form(),
    );
  }

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, style: const TextStyle(color: _textMuted)),
          const SizedBox(height: 12),
          TextButton(
              onPressed: _load,
              child: const Text('Retry', style: TextStyle(color: _teal))),
        ],
      ),
    );
  }

  Widget _form() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.apartment_outlined, color: _teal, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Patients see this on your profile and when booking.',
                  style: TextStyle(fontSize: 13, color: _textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _field('Clinic name', _name, hint: 'e.g. HealthConnect Clinic'),
          const SizedBox(height: 16),
          _field('Address', _address,
              hint: 'Street, city, postal code', maxLines: 2),
          const SizedBox(height: 16),
          _field('Details', _details,
              hint: 'Opening hours, floor, directions, services…', maxLines: 5),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
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
                  : const Text('Save Clinic Details',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {String? hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14, color: _textDark),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
