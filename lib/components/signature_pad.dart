import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import '../core/theme.dart';

class SignaturePad extends StatefulWidget {
  final Function(String filePath) onSave;

  const SignaturePad({super.key, required this.onSave});

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  late SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _exportSignature() async {
    if (_controller.isEmpty) return;

    final Uint8List? data = await _controller.toPngBytes();
    if (data != null) {
      final directory = await getTemporaryDirectory();
      final pathOfFile = "${directory.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png";
      final file = File(pathOfFile);
      await file.writeAsBytes(data);
      widget.onSave(pathOfFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.surfaceBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Signature(
              controller: _controller,
              height: 250,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton.icon(
              onPressed: () => _controller.clear(),
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar'),
            ),
            ElevatedButton.icon(
              onPressed: _exportSignature,
              icon: const Icon(Icons.check),
              label: const Text('Confirmar Firma'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
