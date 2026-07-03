import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../network/ProfileService.dart';
import '../../network/ProfileStore.dart';
import '../../widgets/UserAvatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _teal = Color(0xFF1A9882);
  static const _textDark = Color(0xFF1C2B47);
  static const _textMuted = Color(0xFF7A8399);
  static const _bg = Color(0xFFF5F6FA);

  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  final _profileService = ProfileService();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _allergies = TextEditingController();
  final _specialization = TextEditingController();
  final _bio = TextEditingController();

  int? _avatarId;
  String _role = 'PATIENT';
  DateTime? _dateOfBirth;
  String? _bloodType;

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
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _allergies.dispose();
    _specialization.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await _profileService.getMe();
      if (!mounted) return;
      setState(() {
        _role = p.role;
        _avatarId = p.avatarId;
        _firstName.text = p.firstName;
        _lastName.text = p.lastName;
        _email.text = p.email;
        _phone.text = p.phone ?? '';
        _dateOfBirth = p.dateOfBirth;
        _bloodType = p.bloodType;
        _allergies.text = p.allergies ?? '';
        _specialization.text = p.specialization ?? '';
        _bio.text = p.bio ?? '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your profile';
        _loading = false;
      });
    }
  }

  bool get _isDoctor => _role == 'DOCTOR';

  Future<void> _save() async {
    final first = _firstName.text.trim();
    final last = _lastName.text.trim();
    final email = _email.text.trim();

    if (first.isEmpty || last.isEmpty) {
      _toast('First and last name are required');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _toast('Please enter a valid email');
      return;
    }

    setState(() => _saving = true);
    final result = await _profileService.updateMe(
      firstName: first,
      lastName: last,
      email: email,
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      avatarId: _avatarId,
      dateOfBirth: _isDoctor ? null : _dateOfBirth,
      bloodType: _isDoctor ? null : _bloodType,
      allergies: _isDoctor || _allergies.text.trim().isEmpty
          ? null
          : _allergies.text.trim(),
      specialization: _isDoctor && _specialization.text.trim().isNotEmpty
          ? _specialization.text.trim()
          : null,
      bio: _isDoctor && _bio.text.trim().isNotEmpty ? _bio.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (!result.success) {
      _toast(result.message);
      return;
    }

    // Update the app-wide profile cache so every screen reflects it instantly,
    // and swap the JWT if the email changed.
    final p = result.profile!;
    await ProfileStore.setName(p.fullName);
    await ProfileStore.setAvatar(p.avatarId);
    if (p.token != null && p.token!.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', p.token!);
    }

    if (!mounted) return;
    _toast('Profile updated', success: true);
    Navigator.pop(context, true);
  }

  void _toast(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? _teal : const Color(0xFFE57373),
      ),
    );
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
        title: const Text('Edit Profile',
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: UserAvatar(
                avatarId: _avatarId,
                name: '${_firstName.text} ${_lastName.text}',
                size: 88),
          ),
          const SizedBox(height: 16),
          _label('Choose an avatar'),
          const SizedBox(height: 10),
          _avatarGallery(),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: _field('First name', _firstName)),
              const SizedBox(width: 12),
              Expanded(child: _field('Last name', _lastName)),
            ],
          ),
          const SizedBox(height: 14),
          _field('Email', _email, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _field('Phone', _phone, keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          if (_isDoctor) ..._doctorFields() else ..._patientFields(),
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
                  : const Text('Save Changes',
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

  Widget _avatarGallery() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var i = 0; i < kAvatarPresets.length; i++)
          GestureDetector(
            onTap: () => setState(() => _avatarId = i),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _avatarId == i ? _teal : Colors.transparent,
                  width: 3,
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: UserAvatar(avatarId: i, size: 48),
            ),
          ),
      ],
    );
  }

  List<Widget> _patientFields() {
    return [
      _label('Date of birth'),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: _pickDob,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: _textMuted),
              const SizedBox(width: 8),
              Text(
                _dateOfBirth == null ? 'Select date' : _formatDate(_dateOfBirth!),
                style: TextStyle(
                    fontSize: 14,
                    color: _dateOfBirth == null ? _textMuted : _textDark),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      _label('Blood type'),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _bloodType,
            isExpanded: true,
            hint: const Text('Select blood type',
                style: TextStyle(color: _textMuted, fontSize: 14)),
            items: _bloodTypes
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (v) => setState(() => _bloodType = v),
          ),
        ),
      ),
      const SizedBox(height: 14),
      _field('Allergies (optional)', _allergies, maxLines: 3),
    ];
  }

  List<Widget> _doctorFields() {
    return [
      _field('Specialization', _specialization),
      const SizedBox(height: 14),
      _field('Bio (optional)', _bio, maxLines: 4),
    ];
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: _teal, onPrimary: Colors.white, onSurface: _textDark),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: _textDark));

  Widget _field(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14, color: _textDark),
            onChanged: (_) {
              // Keep the live avatar initials preview in sync with the name.
              if (controller == _firstName || controller == _lastName) {
                setState(() {});
              }
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
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
