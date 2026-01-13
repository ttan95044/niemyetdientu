import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:niemyetdientu/service/chatbot_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';

class VoiceAssistantPopup extends StatefulWidget {
  const VoiceAssistantPopup({super.key});

  @override
  State<VoiceAssistantPopup> createState() => _VoiceAssistantPopupState();
}

class _VoiceAssistantPopupState extends State<VoiceAssistantPopup> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _textController = TextEditingController();

  bool _isListening = false;
  bool _isLoading = false;

  final List<_ChatMessage> _messages = [];

  @override
  void dispose() {
    _speech.stop();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    // 🔹 Xin quyền microphone
    var status = await Permission.microphone.request();

    if (status != PermissionStatus.granted) {
      debugPrint("❌ Người dùng chưa cấp quyền micro");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng cấp quyền micro để sử dụng!")),
      );
      return;
    }

    // 🔹 Khởi tạo speech_to_text
    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint("Speech status: $status"),
      onError: (error) => debugPrint("Speech error: $error"),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          debugPrint("🗣 Nghe được: ${result.recognizedWords}");
          setState(() {
            _textController.text = result.recognizedWords;
          });
        },
        localeId: "vi_VN",
      );
    } else {
      debugPrint("⚠️ Không thể khởi tạo speech_to_text");
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(sender: "user", text: text.trim()));
      _isLoading = true;
      _textController.clear();
    });

    try {
      // 🔹 Gọi API nội bộ
      final response = await ChatbotService.sendPrompt(text);
      setState(() {
        _messages.add(_ChatMessage(sender: "ai", text: response));
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(sender: "ai", text: "❌ Lỗi: $e"));
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Trợ lý AI"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                final isUser = message.sender == "user";
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blue.shade600
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser
                            ? const Radius.circular(16)
                            : const Radius.circular(4),
                        bottomRight: isUser
                            ? const Radius.circular(4)
                            : const Radius.circular(16),
                      ),
                    ),
                    child: MarkdownBody(
                      data: message.text,
                      onTapLink: (text, href, title) async {
                        if (href == null) return;

                        final uri = Uri.tryParse(href);
                        if (uri == null) return;

                        try {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (e) {
                          debugPrint("❌ Không mở được link: $e");
                        }
                      },

                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                        a: TextStyle(
                          // style link
                          color: isUser ? Colors.yellowAccent : Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        strong: TextStyle(
                          color: isUser ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        h2: TextStyle(
                          color: isUser ? Colors.white : Colors.blue.shade700,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: "Nhập tin nhắn hoặc nói...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isListening ? _stopListening : _startListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? Colors.redAccent
                          : Colors.blue.shade600,
                      boxShadow: [
                        if (_isListening)
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: Colors.redAccent.withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading
                      ? null
                      : () => _sendMessage(_textController.text),
                  icon: const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String sender;
  final String text;
  _ChatMessage({required this.sender, required this.text});
}
