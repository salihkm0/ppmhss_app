import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../utils/file_download_helper.dart';

class PdfViewerScreen extends StatefulWidget {
  final String fileName;
  final Uint8List bytes;
  final bool isLandscape;
  final String? title;

  const PdfViewerScreen({
    super.key,
    required this.fileName,
    required this.bytes,
    this.isLandscape = false,
    this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late bool _isLandscapeMode;
  bool _isScreenRotated = false;

  @override
  void initState() {
    super.initState();
    _isLandscapeMode = widget.isLandscape;
  }

  @override
  void dispose() {
    // Restore default orientation permissions on exit
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _toggleOrientation() {
    setState(() {
      _isLandscapeMode = !_isLandscapeMode;
    });
  }

  void _toggleScreenRotation() {
    setState(() {
      _isScreenRotated = !_isScreenRotated;
      if (_isScreenRotated) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = widget.title ??
        widget.fileName
            .replaceAll('.pdf', '')
            .replaceAll('_', ' ');

    final activeFormat = _isLandscapeMode
        ? PdfPageFormat.a4.landscape
        : PdfPageFormat.a4;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: _isLandscapeMode
                        ? const Color(0xFF059669).withOpacity(0.2)
                        : const Color(0xFF3B82F6).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _isLandscapeMode
                          ? const Color(0xFF059669)
                          : const Color(0xFF3B82F6),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    _isLandscapeMode ? 'ISO A4 LANDSCAPE' : 'ISO A4 PORTRAIT',
                    style: TextStyle(
                      color: _isLandscapeMode
                          ? const Color(0xFF34D399)
                          : const Color(0xFF60A5FA),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(widget.bytes.lengthInBytes / 1024).toStringAsFixed(1)} KB',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Rotate device screen button
          IconButton(
            tooltip: _isScreenRotated ? 'Portrait Screen' : 'Widescreen (Rotate Phone)',
            icon: Icon(
              _isScreenRotated ? Icons.screen_lock_portrait_rounded : Icons.screen_rotation_rounded,
              color: _isScreenRotated ? const Color(0xFF38BDF8) : Colors.white70,
            ),
            onPressed: _toggleScreenRotation,
          ),
          // Toggle document orientation button
          IconButton(
            tooltip: _isLandscapeMode ? 'Switch to Portrait' : 'Switch to Landscape',
            icon: Icon(
              _isLandscapeMode ? Icons.crop_portrait_rounded : Icons.crop_landscape_rounded,
              color: Colors.white70,
            ),
            onPressed: _toggleOrientation,
          ),
          // Save to device
          IconButton(
            tooltip: 'Save to Device',
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () => FileDownloadHelper.saveToDevice(
              context: context,
              fileName: widget.fileName,
              bytes: widget.bytes,
              isPdf: true,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: PdfPreview(
          key: ValueKey('pdf_preview_$_isLandscapeMode'),
          build: (format) async => widget.bytes,
          initialPageFormat: activeFormat,
          pageFormats: _isLandscapeMode
              ? {
                  'A4 Landscape': PdfPageFormat.a4.landscape,
                  'A4 Portrait': PdfPageFormat.a4,
                  'Letter Landscape': PdfPageFormat.letter.landscape,
                }
              : {
                  'A4 Portrait': PdfPageFormat.a4,
                  'A4 Landscape': PdfPageFormat.a4.landscape,
                  'Letter Portrait': PdfPageFormat.letter,
                },
          canChangeOrientation: true,
          canChangePageFormat: true,
          canDebug: false,
          pdfFileName: widget.fileName,
          allowPrinting: true,
          allowSharing: true,
          dynamicLayout: false,
          scrollViewDecoration: const BoxDecoration(
            color: Color(0xFF0F172A),
          ),
          pdfPreviewPageDecoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          actions: [
            PdfPreviewAction(
              icon: const Icon(Icons.download_rounded),
              onPressed: (ctx, build, pageFormat) async {
                await FileDownloadHelper.saveToDevice(
                  context: context,
                  fileName: widget.fileName,
                  bytes: widget.bytes,
                  isPdf: true,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

