import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

const apiKey = 'AIzaSyBqPs0oUQy162Y2V_D23pBmhdY5jzD2nKQ';

class FarmerChatScreen extends StatefulWidget {
  const FarmerChatScreen({super.key});

  @override
  _FarmerChatScreenState createState() => _FarmerChatScreenState();
}

class _FarmerChatScreenState extends State<FarmerChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  late Gemini gemini;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        gemini = Gemini.init(apiKey: apiKey);
      });
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _messages.add({"role": "user", "text": text});
    });

    final prompt = """
You are an intelligent farmer assistant AI named "AI Kissan". 
You ONLY answer questions related to farming, crops, weather, soil, irrigation, pests, seeds, agricultural tools, and other agricultural topics.
If someone asks a question unrelated to farming, politely reply:
"I'm here to help only with farming-related queries. Please ask something about crops, weather, or agriculture."

User: $text
""";

    try {
      final response = await gemini.text(prompt);

      setState(() {
        _messages.add({
          "role": "gemini",
          "text": response?.output ?? "No response from AI",
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({"role": "error", "text": "Error: ${e.toString()}"});
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _controller.text = result.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade50,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundImage: AssetImage("assets/images/aichat.jpg"),
              radius: 22,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI Kissan",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const Text(
                  "How can I help you?",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message["role"] == "user";
                final isError = message["role"] == "error";

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 10,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isError
                          ? Colors.red.shade300
                          : (isUser ? Colors.green : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      message["text"]!,
                      style: TextStyle(
                        color: isError ? Colors.black : Colors.black,
                        fontSize: 18,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(color: Colors.green),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _startListening,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.mic_off : Icons.mic,
                color: Colors.green,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  hintText: "Ask about crops, weather, etc...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (_controller.text.isNotEmpty) {
                _sendMessage(_controller.text);
                _controller.clear();
                FocusScope.of(context).unfocus();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
