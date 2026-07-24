import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linkedfarm/l10n/app_localizations.dart';
import 'package:linkedfarm/Services/gemini_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AiAgronomistProTab extends StatefulWidget {
  const AiAgronomistProTab({super.key});

  @override
  State<AiAgronomistProTab> createState() => _AiAgronomistProTabState();
}

class _AiAgronomistProTabState extends State<AiAgronomistProTab> {
  final TextEditingController _questionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  Uint8List? _selectedImage;
  String _aiResponse = "";
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = bytes;
        _aiResponse = "Image selected. Ask a question or click 'Analyze' for general diagnosis.";
      });
    }
  }

  Future<void> _analyze() async {
    if (_selectedImage == null && _questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide a question or an image.")));
      return;
    }

    setState(() {
      _isLoading = true;
      _aiResponse = "AI is thinking...";
    });

    try {
      String response;
      if (_selectedImage != null) {
        response = await GeminiService.analyzeCropImage(
          _selectedImage!, 
          _questionController.text.isEmpty ? "Directly analyze this crop image for pests or diseases." : _questionController.text
        );
      } else {
        response = await GeminiService.getChatResponse(_questionController.text);
      }

      setState(() {
        _aiResponse = response;
      });
    } catch (e) {
      setState(() {
        _aiResponse = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(l10n),
          const SizedBox(height: 20),
          
          // Image Selection Area
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
                image: _selectedImage != null 
                  ? DecorationImage(image: MemoryImage(_selectedImage!), fit: BoxFit.cover) 
                  : null,
              ),
              child: _selectedImage == null 
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey),
                      SizedBox(height: 10),
                      Text("Upload Crop Photo for Identification", style: TextStyle(color: Colors.grey)),
                    ],
                  )
                : const Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.edit, size: 20)),
                    ),
                  ),
            ),
          ),
          
          const SizedBox(height: 20),

          // Question Input
          TextField(
            controller: _questionController,
            decoration: InputDecoration(
              hintText: "Ask about infections, pesticides, or treatments...",
              prefixIcon: const Icon(Icons.help_outline),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: Colors.green),
                onPressed: _analyze,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 2,
            minLines: 1,
          ),

          const SizedBox(height: 25),

          // Response Area
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.purple[300], size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.aiAnalysisResult, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (_isLoading) ...[
                      const SizedBox(width: 15),
                      const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
                    ]
                  ],
                ),
                const Divider(height: 30),
                _aiResponse.isEmpty 
                  ? Text(l10n.aiDiagnosisIntro, style: const TextStyle(color: Colors.grey, fontSize: 13))
                  : MarkdownBody(data: _aiResponse, selectable: true),
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildInfoCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.purple[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.science_outlined, color: Colors.purple[800]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.visionAnalysisInfo,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
