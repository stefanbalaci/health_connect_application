import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

import '../dto/ReportDTO.dart';
import '../network/ReportService.dart';

/// In-app viewer for a report's attached file. Bytes are fetched from the
/// authenticated `/api/reports/{id}/file` endpoint (JWT attached by ApiClient):
/// images render zoomable in-memory, PDFs are cached to a temp file and shown
/// with the native viewer.
class ReportViewerScreen extends StatefulWidget {
  final ReportDTO report;

  const ReportViewerScreen({super.key, required this.report});

  @override
  State<ReportViewerScreen> createState() => _ReportViewerScreenState();
}

class _ReportViewerScreenState extends State<ReportViewerScreen> {
  static const _teal = Color(0xFF1A9882);
  static const _textDark = Color(0xFF1C2B47);
  static const _textMuted = Color(0xFF7A8399);
  static const _bg = Color(0xFFF5F6FA);

  final _reportService = ReportService();

  bool _loading = false;
  String? _error;
  Uint8List? _imageBytes;
  String? _pdfPath;
  int _pages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    if (widget.report.hasFile) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bytes = await _reportService.fetchReportFile(widget.report.id);

      if (widget.report.isPdf) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/report_${widget.report.id}.pdf');
        await file.writeAsBytes(bytes, flush: true);
        if (!mounted) return;
        setState(() {
          _pdfPath = file.path;
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _imageBytes = bytes;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not open this file';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
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
        title: Text(
          r.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: _textDark, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        bottom: (r.isPdf && _pages > 0)
            ? PreferredSize(
                preferredSize: const Size.fromHeight(22),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('Page ${_currentPage + 1} of $_pages',
                      style: const TextStyle(fontSize: 12, color: _textMuted)),
                ),
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final r = widget.report;

    if (!r.hasFile) {
      return _message(Icons.insert_drive_file_outlined, 'No file attached',
          'This report has no document to view.');
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _teal));
    }
    if (_error != null) {
      return _message(Icons.error_outline, _error!,
          'Please check your connection and try again.', onRetry: _load);
    }
    if (r.isImage && _imageBytes != null) {
      return InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Center(child: Image.memory(_imageBytes!, fit: BoxFit.contain)),
      );
    }
    if (r.isPdf && _pdfPath != null) {
      return PDFView(
        filePath: _pdfPath,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        onRender: (pages) => setState(() => _pages = pages ?? 0),
        onPageChanged: (page, total) => setState(() => _currentPage = page ?? 0),
        onError: (error) {
          if (mounted) setState(() => _error = 'Could not open this file');
        },
      );
    }
    if (!r.isImage && !r.isPdf) {
      return _message(Icons.help_outline, 'Unsupported file',
          'This file type can\'t be previewed in the app.');
    }
    return const SizedBox.shrink();
  }

  Widget _message(IconData icon, String title, String subtitle,
      {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: _textMuted),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _textMuted)),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry', style: TextStyle(color: _teal)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
