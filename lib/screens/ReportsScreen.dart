import 'package:flutter/material.dart';

import '../dto/ReportDTO.dart';
import '../network/ReportService.dart';
import '../widgets/AddMyReportSheet.dart';
import 'ReportViewerScreen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _teal = Color(0xFF1A9882);
  static const _textDark = Color(0xFF1C2B47);
  static const _textMuted = Color(0xFF7A8399);
  static const _bg = Color(0xFFF5F6FA);

  static const _categories = ['All', 'Lab', 'Imaging', 'Other'];

  final _reportService = ReportService();
  final _searchController = TextEditingController();

  bool _loading = false;
  String? _error;
  List<ReportDTO> _reports = [];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reports = await _reportService.getMyReports();
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

  List<ReportDTO> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _reports.where((r) {
      final matchesCategory = _selectedCategory == 'All' || r.category == _selectedCategory;
      final matchesQuery = query.isEmpty ||
          r.title.toLowerCase().contains(query) ||
          (r.doctorName?.toLowerCase().contains(query) ?? false);
      return matchesCategory && matchesQuery;
    }).toList();
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
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Reports',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: _textDark),
                        ),
                      ),
                      GestureDetector(
                        onTap: _uploadReport,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _teal,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.upload_file_outlined,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text('Upload',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFilterPills(),
                  const SizedBox(height: 14),
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

  Widget _buildFilterPills() {
    return Row(
      children: _categories.map((c) {
        final selected = _selectedCategory == c;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: c != _categories.last ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? _teal : Colors.white,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(color: selected ? _teal : const Color(0xFFE0E3E8)),
                  boxShadow: selected
                      ? []
                      : [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2)),
                        ],
                ),
                child: Text(
                  c,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : _textDark,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
          hintText: 'Search reports',
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
              onPressed: _loadReports,
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
          _reports.isEmpty ? 'No reports yet' : 'No matches found',
          style: const TextStyle(color: _textMuted, fontSize: 14),
        ),
      );
    }

    return RefreshIndicator(
      color: _teal,
      onRefresh: _loadReports,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _reportCard(items[i]),
      ),
    );
  }

  Future<void> _uploadReport() async {
    final added = await showAddMyReportSheet(context);
    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report uploaded'), backgroundColor: _teal),
      );
      _loadReports();
    }
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

  Widget _reportCard(ReportDTO r) {
    return GestureDetector(
      onTap: () => _openReport(r),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_iconFor(r.type), color: _teal, size: 24),
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
                              fontSize: 15, fontWeight: FontWeight.w700, color: _textDark)),
                    ),
                    if (r.isPdf) _fileBadge('PDF', Icons.picture_as_pdf_outlined, const Color(0xFFD64545)),
                    if (r.isImage) _fileBadge('IMG', Icons.image_outlined, _teal),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F7F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(r.category,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700, color: _teal)),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 13, color: _textMuted),
                  const SizedBox(width: 4),
                  Text(_formatDate(r.reportDate),
                      style: const TextStyle(fontSize: 12, color: _textMuted)),
                  const SizedBox(width: 10),
                  const Icon(Icons.person_outline, size: 13, color: _textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(r.patientSourceLabel,
                        style: const TextStyle(fontSize: 12, color: _textMuted),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const Icon(Icons.chevron_right, color: _textMuted, size: 18),
                ]),
                if (r.notes != null && r.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(r.notes!,
                      style: const TextStyle(fontSize: 13, color: _textDark, height: 1.3)),
                ],
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _fileBadge(String label, IconData icon, Color color) {
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
          Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'BLOOD_TEST':
        return Icons.water_drop_outlined;
      case 'LAB_RESULT':
        return Icons.science_outlined;
      case 'MRI':
        return Icons.biotech_outlined;
      case 'CT_SCAN':
        return Icons.medical_information_outlined;
      case 'X_RAY':
        return Icons.image_outlined;
      case 'ULTRASOUND':
        return Icons.graphic_eq_outlined;
      case 'ECG':
        return Icons.monitor_heart_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
