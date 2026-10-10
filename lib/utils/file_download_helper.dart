import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class FileDownloadHelper {
  /// Detects whether a PDF is in landscape orientation by inspecting
  /// its filename or the PDF /MediaBox dimensions in its header.
  static bool isPdfLandscape(Uint8List bytes, [String? fileName]) {
    // 1. Check filename hints
    if (fileName != null) {
      final lower = fileName.toLowerCase();
      if (lower.contains('class_marks') ||
          lower.contains('classmarks') ||
          lower.contains('landscape') ||
          lower.contains('marks_overview') ||
          lower.contains('mark_sheet') ||
          lower.contains('marklist') ||
          lower.contains('rank_list')) {
        return true;
      }
    }

    // 2. Inspect PDF bytes for /MediaBox [ x y width height ] or /Rotate
    try {
      final sampleLen = bytes.length < 8192 ? bytes.length : 8192;
      final headerSample = utf8.decode(bytes.sublist(0, sampleLen), allowMalformed: true);

      if (headerSample.contains('/Rotate 90') || headerSample.contains('/Rotate 270')) {
        return true;
      }

      // Match /MediaBox [ 0 0 841.89 595.28 ] or similar
      final mediaBoxRegex = RegExp(r'/MediaBox\s*\[\s*([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\s*\]');
      final match = mediaBoxRegex.firstMatch(headerSample);
      if (match != null) {
        final x0 = double.tryParse(match.group(1) ?? '') ?? 0;
        final y0 = double.tryParse(match.group(2) ?? '') ?? 0;
        final x1 = double.tryParse(match.group(3) ?? '') ?? 0;
        final y1 = double.tryParse(match.group(4) ?? '') ?? 0;
        final width = (x1 - x0).abs();
        final height = (y1 - y0).abs();
        if (width > height) {
          return true;
        }
      }
    } catch (_) {}

    return false;
  }

  /// Shows a modal bottom sheet allowing the user to:
  /// 1. Save to Device / Files (via native system file picker / Storage Access Framework)
  /// 2. Open in PDF Viewer (opens full-screen landscape/portrait in native PDF viewer app - identical to web)
  /// 3. Print / Print Preview (uses ISO A4 Landscape or Portrait based on document)
  /// 4. Share File (via WhatsApp, Gmail, Drive, Bluetooth, etc.)
  static Future<void> showDownloadOptions({
    required BuildContext context,
    required String fileName,
    required Uint8List bytes,
    bool isExcel = false,
    bool isPdf = false,
    bool? isLandscape,
  }) async {
    final fileSizeKb = (bytes.lengthInBytes / 1024).toStringAsFixed(1);
    final isDocPdf = isPdf || fileName.toLowerCase().endsWith('.pdf');
    final isDocExcel = isExcel || fileName.toLowerCase().endsWith('.xlsx') || fileName.toLowerCase().endsWith('.xls');
    final isDocLandscape = isLandscape ?? (isDocPdf ? isPdfLandscape(bytes, fileName) : false);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // File preview header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDocExcel
                          ? const Color(0xFFE8F5E9)
                          : (isDocPdf ? const Color(0xFFFFEBEE) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDocExcel
                          ? Icons.table_chart_rounded
                          : (isDocPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded),
                      color: isDocExcel
                          ? const Color(0xFF2E7D32)
                          : (isDocPdf ? const Color(0xFFC62828) : const Color(0xFF475569)),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${isDocExcel ? "Excel Spreadsheet" : (isDocPdf ? (isDocLandscape ? "PDF Document • Landscape A4" : "PDF Document • Portrait A4") : "File")} • $fileSizeKb KB',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 10),

              // Option 1: Save to Device
              _buildOptionTile(
                icon: Icons.download_rounded,
                iconColor: const Color(0xFF059669),
                iconBgColor: const Color(0xFFECFDF5),
                title: 'Save to Device / Files',
                subtitle: 'Save to Downloads or choose any folder on your phone',
                onTap: () {
                  Navigator.pop(ctx);
                  saveToDevice(
                    context: context,
                    fileName: fileName,
                    bytes: bytes,
                    isExcel: isDocExcel,
                    isPdf: isDocPdf,
                  );
                },
              ),

              // Option 2 (PDF): Open in PDF Viewer (native full-screen landscape, same as web)
              if (isDocPdf)
                _buildOptionTile(
                  icon: Icons.visibility_rounded,
                  iconColor: const Color(0xFF2563EB),
                  iconBgColor: const Color(0xFFEFF6FF),
                  title: 'Open in PDF Viewer',
                  subtitle: isDocLandscape
                      ? 'Full screen landscape view (same as web PDF)'
                      : 'View document in your default PDF reader',
                  onTap: () {
                    Navigator.pop(ctx);
                    openFile(
                      context: context,
                      fileName: fileName,
                      bytes: bytes,
                      isExcel: false,
                      isPdf: true,
                      isLandscape: isDocLandscape,
                    );
                  },
                ),

              // Option 3 (PDF): Print / Print Preview with Landscape format
              if (isDocPdf)
                _buildOptionTile(
                  icon: Icons.print_rounded,
                  iconColor: const Color(0xFF4F46E5),
                  iconBgColor: const Color(0xFFEEF2FF),
                  title: 'Print / Print Preview',
                  subtitle: isDocLandscape
                      ? 'Print or preview in ISO A4 Landscape'
                      : 'Print or save via system printer dialog',
                  onTap: () {
                    Navigator.pop(ctx);
                    printPdf(
                      context: context,
                      fileName: fileName,
                      bytes: bytes,
                      isLandscape: isDocLandscape,
                    );
                  },
                ),

              // Option 2 (Excel): Open in Excel / Sheets
              if (isDocExcel)
                _buildOptionTile(
                  icon: Icons.open_in_new_rounded,
                  iconColor: const Color(0xFF2563EB),
                  iconBgColor: const Color(0xFFEFF6FF),
                  title: 'Open in Excel / Sheets',
                  subtitle: 'Open directly in your spreadsheet app',
                  onTap: () {
                    Navigator.pop(ctx);
                    openFile(
                      context: context,
                      fileName: fileName,
                      bytes: bytes,
                      isExcel: true,
                      isPdf: false,
                    );
                  },
                ),

              // Option 4: Share File
              _buildOptionTile(
                icon: Icons.share_rounded,
                iconColor: const Color(0xFFD97706),
                iconBgColor: const Color(0xFFFFFBEB),
                title: 'Share File',
                subtitle: 'Send via WhatsApp, Gmail, Quick Share, etc.',
                onTap: () {
                  Navigator.pop(ctx);
                  shareFile(
                    fileName: fileName,
                    bytes: bytes,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Triggers the native system document picker (ACTION_CREATE_DOCUMENT on Android / Save to Files on iOS)
  static Future<void> saveToDevice({
    required BuildContext context,
    required String fileName,
    required Uint8List bytes,
    bool isExcel = false,
    bool isPdf = false,
  }) async {
    try {
      final dotIndex = fileName.lastIndexOf('.');
      final nameWithoutExt = dotIndex != -1 ? fileName.substring(0, dotIndex) : fileName;
      final ext = dotIndex != -1 ? fileName.substring(dotIndex + 1) : (isExcel ? 'xlsx' : (isPdf ? 'pdf' : ''));

      final mimeType = isExcel
          ? MimeType.microsoftExcel
          : (isPdf ? MimeType.pdf : MimeType.other);

      final savedPath = await FileSaver.instance.saveAs(
        name: nameWithoutExt,
        bytes: bytes,
        fileExtension: ext,
        mimeType: mimeType,
      );

      if (savedPath != null && savedPath.isNotEmpty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Saved to device: $fileName')),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save file: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Opens the document directly in its associated application (Drive PDF Viewer, Acrobat, Excel, etc.)
  static Future<void> openFile({
    required BuildContext context,
    required String fileName,
    required Uint8List bytes,
    bool isExcel = false,
    bool isPdf = false,
    bool? isLandscape,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      final openResult = await OpenFilex.open(file.path);
      if (openResult.type != ResultType.done && context.mounted) {
        // Fallback to print preview if no default viewer handled the file
        if (isPdf || fileName.toLowerCase().endsWith('.pdf')) {
          await printPdf(
            context: context,
            fileName: fileName,
            bytes: bytes,
            isLandscape: isLandscape ?? isPdfLandscape(bytes, fileName),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(openResult.message),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Opens the system print spooler with the PDF document.
  /// When [isLandscape] is true, sets format to [PdfPageFormat.a4.landscape] and dynamicLayout to false
  /// so Android Print Spooler defaults to horizontal Landscape ISO A4.
  static Future<void> printPdf({
    required BuildContext context,
    required String fileName,
    required Uint8List bytes,
    bool isLandscape = false,
  }) async {
    try {
      await Printing.layoutPdf(
        name: fileName,
        format: isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
        dynamicLayout: false,
        onLayout: (PdfPageFormat format) async => bytes,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not print file: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Opens the system share sheet
  static Future<void> shareFile({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)], text: fileName);
  }
}
