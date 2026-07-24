import 'package:flutter/material.dart';
import 'package:linkedfarm/Services/gemini_service.dart';
import 'package:linkedfarm/l10n/app_localizations.dart';

class VendorAdvisoryScreen extends StatefulWidget {
  const VendorAdvisoryScreen({super.key});

  @override
  State<VendorAdvisoryScreen> createState() => _VendorAdvisoryScreenState();
}

class _VendorAdvisoryScreenState extends State<VendorAdvisoryScreen> {
  final List<Map<String, String>> _consultationHistory = [
    {
      "role": "ai",
      "content": "Hello! I am your Vendor Advisor. How can I help you optimize your business today? I can assist with product selection, pricing strategies, or local market demand analysis."
    }
  ];
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;

  Future<void> _handleSend() async {
    if (_controller.text.isEmpty) return;
    
    final userMessage = _controller.text;
    setState(() {
      _consultationHistory.add({"role": "user", "content": userMessage});
      _controller.clear();
      _isTyping = true;
    });

    try {
      final prompt = "Act as a professional retail and grocery business consultant in Ethiopia. Help this vendor with their query: $userMessage. Provide actionable advice on procurement, pricing, or storage.";
      final response = await GeminiService.getChatResponse(prompt);
      setState(() {
        _consultationHistory.add({"role": "ai", "content": response});
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _consultationHistory.add({"role": "ai", "content": "I apologize, but I'm having trouble connecting to my knowledge base. Please try again."});
        _isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("VENDOR ADVISOR", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(child: _buildChatList()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _consultationHistory.length,
      itemBuilder: (context, index) {
        final chat = _consultationHistory[index];
        final isAi = chat["role"] == "ai";
        return Align(
          alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isAi ? Colors.white.withOpacity(0.05) : Colors.orange[700]!.withOpacity(0.2),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isAi ? 0 : 20),
                bottomRight: Radius.circular(isAi ? 20 : 0),
              ),
              border: Border.all(color: isAi ? Colors.white.withOpacity(0.1) : Colors.orange[700]!.withOpacity(0.3)),
            ),
            child: Text(
              chat["content"]!,
              style: TextStyle(color: isAi ? Colors.grey[300] : Colors.white, height: 1.5),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Ask about pricing, stock...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.small(
            onPressed: _handleSend,
            backgroundColor: Colors.green[700],
            child: _isTyping ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
