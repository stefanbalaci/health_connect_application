import 'package:flutter/material.dart';

import '../dto/PrescriptionDTO.dart';
import '../dto/medication_enums.dart';
import '../network/PrescriptionService.dart';

class _ItemForm {
  int? id;
  final medicationController = TextEditingController();
  final dosageController = TextEditingController(); // strength, e.g. "20 mg"
  final amountController = TextEditingController(); // units per dose, e.g. "1"
  final timesPerDayController = TextEditingController(); // doses per day
  final durationController = TextEditingController();
  final quantityController = TextEditingController(); // total to purchase
  final instructionsController = TextEditingController();

  String? form; // MedicationForm enum name
  String? mealRelation; // MealRelation enum name

  /// Whether the doctor pinned specific clock times for this medication.
  bool remind = false;
  List<TimeOfDay> doseTimes = [];

  _ItemForm();

  _ItemForm.fromItem(PrescriptionItemDTO item)
      : id = item.id {
    medicationController.text = item.medicationName;
    form = item.form;
    dosageController.text = item.dosage ?? '';
    amountController.text = item.amountPerDose ?? '';
    mealRelation = item.mealRelation;
    timesPerDayController.text = item.timesPerDay?.toString() ?? '';
    durationController.text = item.durationDays?.toString() ?? '';
    quantityController.text = item.quantityToPurchase?.toString() ?? '';
    instructionsController.text = item.instructions ?? '';
    doseTimes = item.doseTimes.map(_timeOfDayFromHhmm).toList();
    remind = doseTimes.isNotEmpty;
  }

  String? _trimOrNull(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  PrescriptionItemDTO toDTO() {
    final times = [...doseTimes]
      ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    return PrescriptionItemDTO(
      id: id,
      medicationName: medicationController.text.trim(),
      form: form,
      dosage: _trimOrNull(dosageController),
      amountPerDose: _trimOrNull(amountController),
      mealRelation: mealRelation,
      timesPerDay: int.tryParse(timesPerDayController.text.trim()),
      durationDays: int.tryParse(durationController.text.trim()),
      quantityToPurchase: int.tryParse(quantityController.text.trim()),
      instructions: _trimOrNull(instructionsController),
      doseTimes: remind ? times.map(_hhmmFromTimeOfDay).toList() : const [],
    );
  }

  void dispose() {
    medicationController.dispose();
    dosageController.dispose();
    amountController.dispose();
    timesPerDayController.dispose();
    durationController.dispose();
    quantityController.dispose();
    instructionsController.dispose();
  }
}

TimeOfDay _timeOfDayFromHhmm(String hhmm) {
  final bits = hhmm.split(':');
  return TimeOfDay(
    hour: int.tryParse(bits.isNotEmpty ? bits[0] : '') ?? 0,
    minute: int.tryParse(bits.length > 1 ? bits[1] : '') ?? 0,
  );
}

String _hhmmFromTimeOfDay(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

class PrescriptionScreen extends StatefulWidget {
  final int appointmentId;
  final String patientName;

  const PrescriptionScreen({
    super.key,
    required this.appointmentId,
    required this.patientName,
  });

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  static const _teal = Color(0xFF1A9882);
  static const _textDark = Color(0xFF1C2B47);
  static const _textMuted = Color(0xFF7A8399);
  static const _bg = Color(0xFFF5F6FA);

  final _prescriptionService = PrescriptionService();
  final _notesController = TextEditingController();
  final List<_ItemForm> _items = [];

  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _hadExisting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prescription = await _prescriptionService.getPrescription(widget.appointmentId);
      setState(() {
        if (prescription != null) {
          _hadExisting = true;
          _notesController.text = prescription.notes ?? '';
          _items.addAll(prescription.items.map((i) => _ItemForm.fromItem(i)));
        }
        if (_items.isEmpty) _items.add(_ItemForm());
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load prescription';
        _loading = false;
      });
    }
  }

  void _addItem() {
    setState(() => _items.add(_ItemForm()));
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  void _toggleRemind(int index, bool value) {
    setState(() => _items[index].remind = value);
  }

  Future<void> _addDoseTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: _teal, onPrimary: Colors.white, onSurface: _textDark),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      final times = _items[index].doseTimes;
      final exists =
          times.any((t) => t.hour == picked.hour && t.minute == picked.minute);
      if (!exists) times.add(picked);
    });
  }

  void _removeDoseTime(int itemIndex, TimeOfDay time) {
    setState(() => _items[itemIndex].doseTimes.remove(time));
  }

  Future<void> _save() async {
    final validItems = _items
        .where((i) => i.medicationController.text.trim().isNotEmpty)
        .map((i) => i.toDTO())
        .toList();

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one medication.')),
      );
      return;
    }

    setState(() => _saving = true);

    final result = await _prescriptionService.savePrescription(
      appointmentId: widget.appointmentId,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      items: validItems,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_hadExisting ? 'Prescription updated' : 'Prescription created'),
          backgroundColor: _teal,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: const Color(0xFFE57373)),
      );
    }
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
        title: const Text(
          'Prescription',
          style: TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: _textMuted)),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Retry', style: TextStyle(color: _teal)),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'For ${widget.patientName}',
                        style: const TextStyle(fontSize: 14, color: _textMuted),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(_items.length, (i) => _itemCard(i)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _addItem,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDDE1EA), width: 1.2),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: _teal, size: 18),
                              SizedBox(width: 6),
                              Text('Add Medication',
                                  style: TextStyle(
                                      color: _teal, fontSize: 14, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Notes (optional)',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'General notes for this prescription',
                            hintStyle: TextStyle(color: _textMuted, fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _teal,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(
                                  _hadExisting ? 'Update Prescription' : 'Save Prescription',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _itemCard(int index) {
    final item = _items[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Medication ${index + 1}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: _textDark)),
              const Spacer(),
              if (_items.length > 1)
                GestureDetector(
                  onTap: () => _removeItem(index),
                  child: const Icon(Icons.close, size: 18, color: _textMuted),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _field(item.medicationController, 'Medication name *'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _dropdown(
                  value: item.form,
                  hint: 'Form',
                  options: kMedicationForms,
                  label: medicationFormLabel,
                  onChanged: (v) => setState(() => item.form = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _field(item.dosageController, 'Strength (e.g. 20 mg)')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _field(item.amountController, 'Amount per dose (e.g. 1)',
                    keyboardType: TextInputType.number),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _field(item.timesPerDayController, 'Times per day (e.g. 2)',
                    keyboardType: TextInputType.number),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _dropdown(
                  value: item.mealRelation,
                  hint: 'Meal timing',
                  options: kMealRelations,
                  label: mealRelationLabel,
                  onChanged: (v) => setState(() => item.mealRelation = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _field(item.durationController, 'Duration (days)',
                    keyboardType: TextInputType.number),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _field(item.quantityController, 'Quantity to buy',
              keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          _field(item.instructionsController, 'Instructions (optional)', maxLines: 2),
          const SizedBox(height: 6),
          _doseTimesSection(index),
        ],
      ),
    );
  }

  Widget _doseTimesSection(int index) {
    final item = _items[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Reminder times',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _textDark)),
            ),
            Transform.scale(
              scale: 0.85,
              child: Switch(
                value: item.remind,
                activeColor: _teal,
                onChanged: (v) => _toggleRemind(index, v),
              ),
            ),
          ],
        ),
        if (item.remind) ...[
          const SizedBox(height: 2),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in item.doseTimes)
                _doseChip(t.format(context), () => _removeDoseTime(index, t)),
              GestureDetector(
                onTap: () => _addDoseTime(index),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F7F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 15, color: _teal),
                      SizedBox(width: 3),
                      Text('Add time',
                          style: TextStyle(
                              fontSize: 12,
                              color: _teal,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (item.doseTimes.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('No times added yet',
                  style: TextStyle(fontSize: 11, color: _textMuted)),
            ),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text("Off — the patient picks their own times for this medication.",
                style: TextStyle(fontSize: 11, color: _textMuted)),
          ),
      ],
    );
  }

  Widget _doseChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE1EA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12.5,
                  color: _textDark,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 15, color: _textMuted),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13, color: _textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<String> options,
    required String Function(String) label,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          hint: Text(hint,
              style: const TextStyle(color: _textMuted, fontSize: 13)),
          style: const TextStyle(fontSize: 13, color: _textDark),
          icon: const Icon(Icons.keyboard_arrow_down, color: _textMuted, size: 20),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(label(o))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
