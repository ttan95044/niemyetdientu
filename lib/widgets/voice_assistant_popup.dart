import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:niemyetdientu/model/category_model.dart';
import 'package:niemyetdientu/model/chatbot_result.dart';
import 'package:niemyetdientu/screens/sub_category_screen.dart';
import 'package:niemyetdientu/service/category_service.dart';
import 'package:niemyetdientu/service/chatbot_service.dart';
import 'package:niemyetdientu/service/native_voice_service.dart';
import 'package:url_launcher/url_launcher.dart';

class VoiceAssistantPopup extends StatefulWidget {
  const VoiceAssistantPopup({super.key});

  @override
  State<VoiceAssistantPopup> createState() => _VoiceAssistantPopupState();
}

class _VoiceAssistantPopupState extends State<VoiceAssistantPopup> {
  final TextEditingController _textController = TextEditingController();

  final List<_ChatMessage> _messages = [];

  List<CategoryModel> categories = [];

  bool _isLoading = false;

  bool _isListening = false;

  @override
  void initState() {
    super.initState();

    loadCategories();
  }

  Future<void> loadCategories() async {
    categories = await CategoryService.fetchCategories();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _buildMarkdown(ChatbotResult data) {
    final sb = StringBuffer();

    if (data.name.isNotEmpty) {
      sb.writeln("### ${data.name}");
    }

    if (data.decision.isNotEmpty) {
      sb.writeln("- Số quyết định: ${data.decision}");
    }

    if (data.typeName.isNotEmpty) {
      sb.writeln("- Loại: ${data.typeName}");
    }

    if (data.fieldName.isNotEmpty) {
      sb.writeln("- Lĩnh vực: ${data.fieldName}");
    }

    sb.writeln("- Đã phát hành: ${data.isPublished ? "Có" : "Không"}");

    return sb.toString();
  }

  Future<void> _startVoice() async {
    if (_isListening) return;

    setState(() {
      _isListening = true;
    });

    try {
      final text = await NativeVoiceService.start();

      debugPrint("VOICE TEXT = $text");

      if (!mounted) return;

      setState(() {
        _textController.text = text;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
      });
    } catch (e) {
      debugPrint(e.toString());
    }

    if (!mounted) return;

    setState(() {
      _isListening = false;
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(sender: "user", text: text.trim()));

      _isLoading = true;
      _textController.clear();
    });

    try {
      final results = await ChatbotService.sendPrompt(text);

      if (!mounted) return;

      setState(() {
        for (final result in results) {
          _messages.add(
            _ChatMessage(
              sender: "ai",
              text: _buildMarkdown(result),
              field: result.fieldName,
            ),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.add(_ChatMessage(sender: "ai", text: "❌ Lỗi:\n$e"));
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  CategoryModel? findCategoryByField(
    String field,
    List<CategoryModel> categories,
  ) {
    String normalize(String text) {
      return text.toLowerCase().replaceAll("-", "").replaceAll(" ", "").trim();
    }

    try {
      return categories.firstWhere(
        (item) => normalize(item.title) == normalize(field),
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildMessageWithClickableField(_ChatMessage message, bool isUser) {
    final lines = message.text.split("\n");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.contains("Lĩnh vực:")) {
          final field = message.field ?? "";

          return Row(
            children: [
              Text(
                "• Lĩnh vực: ",
                style: TextStyle(color: isUser ? Colors.white : Colors.black87),
              ),
              GestureDetector(
                onTap: () {
                  final category = findCategoryByField(field, categories);

                  if (category == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Không tìm thấy lĩnh vực")),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubCategoryScreen(category: category),
                    ),
                  );
                },
                child: Text(
                  field,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            line,
            style: TextStyle(color: isUser ? Colors.white : Colors.black87),
          ),
        );
      }).toList(),
    );
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[_messages.length - 1 - index];

                      final isUser = message.sender == "user";

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.blue.shade600
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: message.field != null
                              ? _buildMessageWithClickableField(message, isUser)
                              : MarkdownBody(
                                  data: message.text,
                                  onTapLink: (text, href, title) async {
                                    if (href == null) return;

                                    final uri = Uri.tryParse(href);

                                    if (uri == null) return;

                                    await launchUrl(uri);
                                  },
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
                          onSubmitted: _sendMessage,
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
                            suffixIcon: _textController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _textController.clear();
                                      });
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      GestureDetector(
                        onTap: _startVoice,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening
                                ? Colors.red
                                : Colors.blue.shade600,
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
                        icon: Icon(
                          Icons.send,
                          color: _isLoading
                              ? Colors.grey
                              : Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String sender;
  final String text;
  final String? field;

  const _ChatMessage({required this.sender, required this.text, this.field});
}
