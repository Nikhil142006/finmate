import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../widgets/glass_card.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final List<Map<String, String>> messages = [];
  bool isLoading = false;
  String _apiKey = "ADD_API_KEYS_HERE";

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('gemini_api_key');
    if (savedKey != null && savedKey.isNotEmpty) {
      setState(() {
        _apiKey = savedKey;
      });
    }
  }

  Future<void> _showApiKeyDialog() async {
    _apiKeyController.text = _apiKey;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Enter Gemini API Key", style: TextStyle(fontWeight: FontWeight.w900)),
          content: TextField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              hintText: "AIzaSy...",
              labelText: "API Key",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('gemini_api_key', _apiKeyController.text.trim());
                setState(() {
                  _apiKey = _apiKeyController.text.trim();
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    if (_apiKey.isEmpty || _apiKey.startsWith("AQ.") || !_apiKey.startsWith("AIza")) {
      setState(() {
        messages.add({"role": "user", "text": message});
        messages.add({
          "role": "bot",
          "text": "Please tap the 🔑 icon in the top right corner to add a valid Google AI Studio API key (it must start with 'AIza').",
        });
      });
      _controller.clear();
      return;
    }

    setState(() {
      messages.add({"role": "user", "text": message});
      isLoading = true;
    });

    _controller.clear();

    try {
      final model = GenerativeModel(model: 'gemini-3.5-flash', apiKey: _apiKey);
      final stream = model.generateContentStream([Content.text(message)]);
      
      setState(() {
        messages.add({"role": "bot", "text": ""});
      });
      
      final botIndex = messages.length - 1;

      await for (final chunk in stream) {
        if (chunk.text != null) {
          setState(() {
            messages[botIndex] = {
              "role": "bot",
              "text": messages[botIndex]["text"]! + chunk.text!
            };
          });
        }
      }
    } catch (e) {
      setState(() => messages.add({"role": "bot", "text": "Error: $e"}));
    }

    setState(() => isLoading = false);
  }

  Widget buildMessage(Map<String, String> msg, Color primaryColor) {
    bool isUser = msg["role"] == "user";
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? primaryColor : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
        ),
        child: Text(
          msg["text"]!,
          style: TextStyle(
            color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("FinMate AI", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key_rounded),
            onPressed: _showApiKeyDialog,
            tooltip: "Set API Key",
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: messages.length,
              itemBuilder: (_, index) => buildMessage(messages[index], primaryColor),
            ),
          ),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor)),
                  const SizedBox(width: 12),
                  const Text('AI is thinking...', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90, top: 12), // Extra bottom padding for floating navbar
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Ask FinMate AI...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      onSubmitted: (val) => sendMessage(val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => sendMessage(_controller.text),
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
