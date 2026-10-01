import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class FileDownloadHelper {
  /// Shows a modal bottom sheet allowing the user to:
  /// 1. Save to Device / Files (via native system file picker / Storage Access Framework)
  /// 2. Open / View Document (using default PDF viewer or Excel/Sheets app)
  /// 3. Share File (via WhatsApp, Gmail, Drive, Bluetooth, etc.)
  static Future<void> showDownloadOptions({
    required BuildContext context,
    required String fileName,
    required Uint8List bytes,
    bool isExcel = false,
    bool isPdf = false,
  }) async {
    final fileSizeKb = (bytes.lengthInBytes / 1024).toStringAsFixed(1);
    final isDocPdf = isPdf || fileName.toLowerCase().endsWith('.pdf');
    final isDocExcel = isExcel || fileName.toLowerCase().endsWith('.xlsx') || fileName.toLowerCase().endsWith('.xls');

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
                          '${isDocExcel ? "Excel Spreadsheet" : (isDocPdf ? "PDF Document" : "File")} • $fileSizeKb KB',
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

              // Option 2: Open / Preview
              _buildOptionTile(
                icon: isDocPdf ? Icons.visibility_rounded : Icons.open_in_new_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBgColor: const Color(0xFFEFF6FF),
                title: isDocPdf ? 'Preview / Print PDF' : 'Open in Excel / Sheets',
                subtitle: isDocPdf ? 'View document with print & save preview' : 'Open directly in your spreadsheet app',
                onTap: () {
                  Navigator.pop(ctx);
                  openFile(
                    context: context,
                    fileName: fileName,
                    bytes: bytes,
                    isExcel: isDocExcel,
                    isPdf: isDocPdf,
                  );
                },
              ),

              // Option 3: Share File
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

  /// Opens the document directly in its associated application
  static Future<void> openFile({
    required BuildContext context,
    required String fileName,
    required Uint8List bytes,
    bool isExcel = false,
    bool isPdf = false,
  }) async {
    try {
      if (isPdf) {
        await Printing.layoutPdf(
          onLayout: (format) async => bytes,
          name: fileName,
        );
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        final openResult = await OpenFilex.open(file.path);
        if (openResult.type != ResultType.done && context.mounted) {
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

  /// Opens the system share sheet
  static Future<void> shareFile({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: fileName);
  }
}
