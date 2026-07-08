import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

class ReportDetailPage extends StatelessWidget {
  final Map<String, dynamic> request;
  const ReportDetailPage({super.key, required this.request});

  Future<void> _downloadPdf(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2538) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(strokeWidth: 2.5),
              const SizedBox(height: 16),
              Text(
                'Generating PDF...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final pdfDoc = pw.Document();
      final resultSummary = request['result_summary'] ?? 'No analysis summary stored.';
      final hasFracture = resultSummary.contains('DETECTED');

      // Decode image if available
      pw.MemoryImage? xrayImage;
      final String? imgB64 = request['annotated_image_b64'];
      if (imgB64 != null && imgB64.isNotEmpty) {
        try {
          final bytes = base64Decode(imgB64);
          xrayImage = pw.MemoryImage(bytes);
        } catch (_) {}
      }

      pdfDoc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (pw.Context ctx) => _buildPdfHeader(),
          footer: (pw.Context ctx) => _buildPdfFooter(ctx),
          build: (pw.Context ctx) => [
            // Patient Info
            pw.SizedBox(height: 20),
            _pdfSectionTitle('Patient Information'),
            pw.SizedBox(height: 8),
            _pdfInfoRow('Name', request['patient_name'] ?? 'N/A'),
            if (request['age'] != null) _pdfInfoRow('Age', '${request['age']} years'),
            if (request['height'] != null) _pdfInfoRow('Height', '${request['height']} cm'),
            if (request['weight'] != null) _pdfInfoRow('Weight', '${request['weight']} kg'),
            _pdfInfoRow('Date', request['date'] ?? 'N/A'),
            _pdfInfoRow('Body Part', request['body_part'] ?? 'N/A'),
            _pdfInfoRow('Status', request['status'] ?? 'N/A'),
            pw.SizedBox(height: 20),

            // AI Analysis
            _pdfSectionTitle('AI Analysis Result'),
            pw.SizedBox(height: 8),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: hasFracture ? const PdfColor.fromInt(0xFFFFF7ED) : const PdfColor.fromInt(0xFFF0FDF4),
                border: pw.Border.all(
                  color: hasFracture ? const PdfColor.fromInt(0xFFF59E0B) : const PdfColor.fromInt(0xFF10B981),
                  width: 0.5,
                ),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                resultSummary,
                style: pw.TextStyle(fontSize: 10, lineSpacing: 5, font: pw.Font.courier()),
              ),
            ),
            pw.SizedBox(height: 20),

            // Doctor Notes
            if (request['doctor_notes'] != null && request['doctor_notes'].toString().isNotEmpty) ...[
              _pdfSectionTitle("Doctor's Notes"),
              pw.SizedBox(height: 8),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFEFF6FF),
                  border: pw.Border.all(color: const PdfColor.fromInt(0xFF2563EB), width: 0.5),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  request['doctor_notes'].toString(),
                  style: const pw.TextStyle(fontSize: 10, lineSpacing: 5),
                ),
              ),
              pw.SizedBox(height: 20),
            ],

            // X-Ray Image
            if (xrayImage != null) ...[
              pw.SizedBox(height: 20),
              _pdfSectionTitle('Annotated X-Ray Image'),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Container(
                  constraints: const pw.BoxConstraints(maxHeight: 340),
                  child: pw.Image(xrayImage, fit: pw.BoxFit.contain),
                ),
              ),
            ],
          ],
        ),
      );

      final pdfBytes = await pdfDoc.save();

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Use printing package to share/save
      final patientName = (request['patient_name'] ?? 'report').toString().replaceAll(RegExp(r'[^\w]'), '_');
      final bodyPart = (request['body_part'] ?? 'xray').toString().replaceAll(RegExp(r'[^\w]'), '_');
      final fileName = 'XRBone_${patientName}_${bodyPart}_Report.pdf';

      await Printing.sharePdf(bytes: Uint8List.fromList(pdfBytes), filename: fileName);
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // close loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  static pw.Widget _buildPdfHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF2563EB), width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('XRBone', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF2563EB))),
              pw.SizedBox(height: 2),
              pw.Text('AI-Powered X-Ray Analysis Report', style: const pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF64748B))),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFEFF6FF),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text('Medical Report', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF2563EB))),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0), width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Generated by XRBone AI Diagnostics', style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF94A3B8))),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF94A3B8))),
        ],
      ),
    );
  }

  static pw.Widget _pdfSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF1F5F9),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0F172A))),
    );
  }

  static pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text('$label:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF475569))),
          ),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xFF0F172A))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Uint8List? imageBytes;
    final String? imgB64 = request['annotated_image_b64'];
    if (imgB64 != null && imgB64.isNotEmpty) {
      try {
        imageBytes = base64Decode(imgB64);
      } catch (_) {}
    }

    final resultSummary = request['result_summary'] ?? 'No analysis summary stored.';
    final hasFracture = resultSummary.contains('DETECTED');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F1A) : const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text('${request['body_part'] ?? 'Unknown'} X-Ray Report'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Download PDF button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _downloadPdf(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Download PDF',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Patient info header
                _SectionCard(
                  isDark: isDark,
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person_rounded, color: Color(0xFF2563EB), size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request['patient_name'] ?? 'Patient',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (request['age'] != null)
                                  _InfoBadge(icon: Icons.cake_rounded, label: '${request['age']} yrs', isDark: isDark),
                                if (request['height'] != null)
                                  _InfoBadge(icon: Icons.height_rounded, label: '${request['height']} cm', isDark: isDark),
                                if (request['weight'] != null)
                                  _InfoBadge(icon: Icons.monitor_weight_rounded, label: '${request['weight']} kg', isDark: isDark),
                                _InfoBadge(icon: Icons.calendar_today_rounded, label: request['date'] ?? '', isDark: isDark),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _StatusChip(status: request['status'] ?? '', isDark: isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Result panel
                    Expanded(
                      child: _SectionCard(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (hasFracture ? const Color(0xFFF59E0B) : const Color(0xFF10B981)).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    hasFracture ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                                    color: hasFracture ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'AI Analysis Result',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF1E2D3D) : const Color(0xFFF1F5F9),
                                ),
                              ),
                              child: Text(
                                resultSummary,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.7,
                                  fontFamily: 'monospace',
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                ),
                              ),
                            ),
                            if (request['doctor_notes'] != null && request['doctor_notes'].toString().isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.notes_rounded, color: Color(0xFF2563EB), size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Doctor's Notes",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.15)),
                                ),
                                child: Text(
                                  request['doctor_notes'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.6,
                                    color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Image panel
                    if (imageBytes != null) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SectionCard(
                          isDark: isDark,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.image_rounded, color: Color(0xFF6366F1), size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Annotated X-Ray',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (_, __, ___) => FullScreenXrayPage(imageBytes: imageBytes!, isDark: isDark),
                                      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Stack(
                                      children: [
Container(
  width: double.infinity,
  constraints: const BoxConstraints(maxHeight: 520),
  color: Colors.black,
  child: Image.memory(
    imageBytes,
    fit: BoxFit.contain,
    width: double.infinity,
  ),
),                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.7),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.fullscreen_rounded, size: 14, color: Colors.white),
                                                SizedBox(width: 4),
                                                Text('Full Screen', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _SectionCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2538) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9)),
      ),
      child: child,
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _InfoBadge({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final bool isDark;
  const _StatusChip({required this.status, required this.isDark});

  Color get _color {
    switch (status) {
      case 'Completed': return const Color(0xFF10B981);
      case 'In Progress': return const Color(0xFF2563EB);
      case 'Pending Review': return const Color(0xFFF59E0B);
      default: return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.25)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

// Full screen viewer
class FullScreenXrayPage extends StatelessWidget {
  final Uint8List imageBytes;
  final bool isDark;
  const FullScreenXrayPage({super.key, required this.imageBytes, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('X-Ray Viewer', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 6.0,
        child: Center(
          child: Image.memory(imageBytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
