import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../db_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'index.dart';

class ApplyXrayPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ApplyXrayPage({super.key, required this.userData});

  @override
  State<ApplyXrayPage> createState() => _ApplyXrayPageState();
}

class _ApplyXrayPageState extends State<ApplyXrayPage> {
  File? _selectedImage;
  String? _analysisResult;
  bool _isAnalyzing = false;
  Uint8List? _resultImageBytes;
  String? _annotatedImageB64;

  bool? _hasFracture;
  double? _pFracture;
  bool? _ranDetector;
  int? _numBoxes;
  double? _maxBoxConf;
  String? _finalDecision;

  String? _patientName;
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  final _patientIdController = TextEditingController();
  final _xrayNameController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _patientIdController.addListener(_lookupPatient);
  }

  void _lookupPatient() async {
    final text = _patientIdController.text.trim();
    if (text.isEmpty) {
      if (_patientName != null) setState(() => _patientName = null);
      return;
    }

    final id = int.tryParse(text);
    if (id == null) return;

    final user = await DatabaseHelper.instance.fetchUserById(id);
    if (!mounted) return;

    if (user != null && user['role'] == 'Patient') {
      if (_patientName != user['username']) {
        setState(() => _patientName = user['username']);
      }
    } else {
      if (_patientName != null) setState(() => _patientName = null);
    }
  }

  @override
  void dispose() {
    _patientIdController.removeListener(_lookupPatient);
    _patientIdController.dispose();
    _xrayNameController.dispose();
    _notesController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveReportToHistory() async {
    if (_analysisResult == null) return;

    final text = _patientIdController.text.trim();
    if (text.isNotEmpty) {
      final id = int.tryParse(text);
      bool patientExists = false;

      if (id != null) {
        final user = await DatabaseHelper.instance.fetchUserById(id);
        if (user != null && user['role'] == 'Patient') {
          patientExists = true;
        }
      }

      if (!patientExists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Patient ID does not exist'),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }
    }

    try {
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

      await DatabaseHelper.instance.insertRequest({
        'patient_id': int.tryParse(_patientIdController.text) ?? 0,
        'doctor_id': widget.userData['id'],
        'patient_name': _patientName ?? 'Patient',
        'body_part': _xrayNameController.text.isNotEmpty ? _xrayNameController.text : 'Unknown',
        'date': formattedDate,
        'status': 'Completed',
        'result_summary': _analysisResult!,
        'annotated_image_b64': _annotatedImageB64,
        'doctor_notes': _notesController.text,
        'age': int.tryParse(_ageController.text),
        'height': double.tryParse(_heightController.text),
        'weight': double.tryParse(_weightController.text),
      });

      if (!mounted) return;

      setState(() {
        _patientIdController.clear();
        _xrayNameController.clear();
        _notesController.clear();
        _ageController.clear();
        _heightController.clear();
        _weightController.clear();
        _patientName = null;
        _clearImage();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Report saved to history'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
          _analysisResult = null;
          _resultImageBytes = null;
          _annotatedImageB64 = null;
          _hasFracture = null;
          _pFracture = null;
          _ranDetector = null;
          _numBoxes = null;
          _maxBoxConf = null;
          _finalDecision = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an image first'),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
      _resultImageBytes = null;
      _annotatedImageB64 = null;
      _hasFracture = null;
      _pFracture = null;
      _ranDetector = null;
      _numBoxes = null;
      _maxBoxConf = null;
      _finalDecision = null;
    });

    try {
      final uri = Uri.parse('http://127.0.0.1:8000/predict');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', _selectedImage!.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['error'] != null) {
          setState(() {
            _analysisResult = 'AI server error: ${data['error']}';
          });
        } else {
          final bool hasFracture = data['has_fracture'] ?? false;
          final double bestConf = (data['best_confidence'] ?? 0.0).toDouble();
          final int numBoxes = data['num_boxes'] ?? 0;

          final double pFracture = (data['p_fracture'] ?? 0.0).toDouble();
          final bool ranDetector = (data['ran_detector'] == 1 || data['ran_detector'] == true);
          final double maxBoxConf = (data['max_box_conf'] ?? bestConf).toDouble();
          final String finalDecision = data['final_decision'] ??
              (hasFracture ? 'fracture likely' : 'fracture unlikely');

          final String? imgB64 = data['annotated_image_b64'];

          Uint8List? bytes;
          if (imgB64 != null) {
            bytes = base64Decode(imgB64);
          }

          setState(() {
            _resultImageBytes = bytes;
            _annotatedImageB64 = imgB64;

            _hasFracture = hasFracture;
            _pFracture = pFracture;
            _ranDetector = ranDetector;
            _numBoxes = numBoxes;
            _maxBoxConf = maxBoxConf;
            _finalDecision = finalDecision;

            _analysisResult = [
              'AI Result:',
              hasFracture ? '⚠ Fracture DETECTED' : '✅ No fracture detected',
              'Final decision: $finalDecision',
              'Classifier probability: ${(pFracture * 100).toStringAsFixed(1)}%',
              'Detector ran: ${ranDetector ? "Yes" : "No"}',
              'Detected boxes: $numBoxes',
              'Best box confidence: ${(maxBoxConf * 100).toStringAsFixed(1)}%',
            ].join('\n');
          });
        }
      } else {
        setState(() {
          _analysisResult =
              'Error from AI server (status ${response.statusCode}):\n${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _analysisResult = 'Error contacting AI server:\n$e';
      });
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _analysisResult = null;
      _resultImageBytes = null;
      _annotatedImageB64 = null;
      _hasFracture = null;
      _pFracture = null;
      _ranDetector = null;
      _numBoxes = null;
      _maxBoxConf = null;
      _finalDecision = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _XPanel(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _XPanelHeader(
                    icon: Icons.upload_file_rounded,
                    title: 'Upload X-Ray',
                    color: const Color(0xFF2563EB),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),

                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 200,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedImage != null
                                ? const Color(0xFF2563EB)
                                : (isDark
                                    ? const Color(0xFF2D3748)
                                    : const Color(0xFFE2E8F0)),
                            width: _selectedImage != null ? 2 : 1.5,
                          ),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(_selectedImage!, fit: BoxFit.contain),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: _clearImage,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.6),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close_rounded,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Stack(
                                alignment: Alignment.center,
                                children: [
                                  const _ScanLineOverlay(),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2563EB).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.cloud_upload_rounded,
                                          size: 28,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Click to upload X-Ray image',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF475569),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'PNG, JPG, JPEG supported',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? const Color(0xFF64748B)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _XFieldLabel(label: 'Patient ID', isDark: isDark),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _patientIdController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: 'Enter patient ID',
                      prefixIcon: Icon(Icons.badge_rounded, size: 18),
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),

                  if (_patientName != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            color: Color(0xFF10B981),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Patient: $_patientName',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _XFieldLabel(label: 'Age', isDark: isDark),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(
                                hintText: 'Years',
                                prefixIcon: Icon(Icons.cake_rounded, size: 17),
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _XFieldLabel(label: 'Height', isDark: isDark),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))
                              ],
                              decoration: const InputDecoration(
                                hintText: 'cm',
                                prefixIcon: Icon(Icons.height_rounded, size: 17),
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _XFieldLabel(label: 'Weight', isDark: isDark),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))
                              ],
                              decoration: const InputDecoration(
                                hintText: 'kg',
                                prefixIcon: Icon(Icons.monitor_weight_rounded, size: 17),
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _XFieldLabel(label: 'X-Ray Name', isDark: isDark),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _xrayNameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Hand, Wrist, Ankle',
                      prefixIcon: Icon(Icons.label_rounded, size: 18),
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _XFieldLabel(label: 'Doctor Notes', isDark: isDark),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Optional clinical notes...',
                      prefixIcon: Icon(Icons.notes_rounded, size: 18),
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _analyzeImage,
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.analytics_rounded, size: 18),
                    label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze X-Ray'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),

          Expanded(
            child: _XPanel(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _XPanelHeader(
                    icon: Icons.analytics_rounded,
                    title: 'Analysis Results',
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),

                  Container(
                    constraints: const BoxConstraints(minHeight: 160),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: _isAnalyzing
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 20),
                              CircularProgressIndicator(strokeWidth: 2.5),
                              SizedBox(height: 14),
                              Text(
                                'Analyzing X-ray scan...',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              SizedBox(height: 20),
                            ],
                          )
                        : _finalDecision != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _ResultChip(
                                        label: _hasFracture == true
                                            ? 'Fracture detected'
                                            : 'No fracture detected',
                                        color: _hasFracture == true
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF10B981),
                                      ),
                                      _ResultChip(
                                        label: _ranDetector == true
                                            ? 'Detector ran'
                                            : 'Detector skipped',
                                        color: const Color(0xFF2563EB),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _ResultRow(
                                    title: 'Final decision',
                                    value: _finalDecision!,
                                    isDark: isDark,
                                  ),
                                  _ResultRow(
                                    title: 'Fracture probability',
                                    value:
                                        '${((_pFracture ?? 0) * 100).toStringAsFixed(1)}%',
                                    isDark: isDark,
                                  ),
                                  _ResultRow(
                                    title: 'Detected boxes',
                                    value: '${_numBoxes ?? 0}',
                                    isDark: isDark,
                                  ),
                                  _ResultRow(
                                    title: 'Best box confidence',
                                    value:
                                        '${((_maxBoxConf ?? 0) * 100).toStringAsFixed(1)}%',
                                    isDark: isDark,
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 20),
                                  Icon(
                                    Icons.pending_actions_rounded,
                                    size: 42,
                                    color: isDark
                                        ? const Color(0xFF2D3748)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Results will appear here after analysis',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                  ),

                  if (_resultImageBytes != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(
                            Icons.image_rounded,
                            size: 14,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Annotated X-Ray',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenXrayPage(
                              imageBytes: _resultImageBytes!,
                              isDark: isDark,
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(maxHeight: 520),
                                color: Colors.black,
                                child: Image.memory(
                                  _resultImageBytes!,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.65),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.fullscreen_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Full Screen',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
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

                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: _analysisResult != null ? _saveReportToHistory : null,
                    icon: const Icon(Icons.save_alt_rounded, size: 18),
                    label: const Text('Save Report to History'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared UI helpers ────────────────────────────────────────────────────────

class _XPanel extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _XPanel({
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2538) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9),
        ),
      ),
      child: child,
    );
  }
}

class _XPanelHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool isDark;

  const _XPanelHeader({
    required this.icon,
    required this.title,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _XFieldLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _XFieldLabel({
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String title;
  final String value;
  final bool isDark;

  const _ResultRow({
    required this.title,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  final String label;
  final Color color;

  const _ResultChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Scan Line Overlay ────────────────────────────────────────────────────────

class _ScanLineOverlay extends StatefulWidget {
  const _ScanLineOverlay();

  @override
  State<_ScanLineOverlay> createState() => _ScanLineOverlayState();
}

class _ScanLineOverlayState extends State<_ScanLineOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..repeat();
    _position = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AnimatedBuilder(
          animation: _position,
          builder: (_, __) {
            return Stack(
              children: [
                Positioned(
                  top: _position.value * 180,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF2563EB).withOpacity(0.6),
                          const Color(0xFF818CF8).withOpacity(0.8),
                          const Color(0xFF2563EB).withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.35),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: _position.value * 180,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF2563EB).withOpacity(0.04),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}