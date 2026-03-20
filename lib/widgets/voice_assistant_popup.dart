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
  double _soundLevel = 0.0;
  String? _initError;

  final List<_ChatMessage> _messages = [];

  @override
  void dispose() {
    _speech.stop();
    _textController.dispose();
    super.dispose();
  }

  Future<String?> _preferredLocale() async {
    try {
      final locales = await _speech.locales();
      if (locales.isEmpty) return null;
      final vi = locales.firstWhere(
        (l) => l.localeId.toLowerCase().startsWith('vi'),
        orElse: () => locales.first,
      );
      return vi.localeId;
    } catch (_) {
      return null;
    }
  }

  Future<void> _startListening() async {
    final status = await Permission.microphone.request();

    if (status == PermissionStatus.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng cấp quyền micro để sử dụng!")),
      );
      return;
    }

    if (status == PermissionStatus.permanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Quyền micro bị chặn. Mở cài đặt để cấp quyền.'),
          action: SnackBarAction(
            label: 'Cài đặt',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
      return;
    }

    bool available = false;
    _initError = null;
    try {
      available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
        },
        onError: (error) {
          debugPrint('Speech error: $error');
          setState(() => _initError = error?.toString());
        },
      );
    } catch (e) {
      debugPrint('⚠️ Exception initializing speech: $e');
      _initError = e.toString();
    }

    if (!available) {
      final message =
          _initError ?? 'Không thể khởi tạo microphone trên thiết bị này.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    // show locales for debugging
    try {
      final locales = await _speech.locales();
      debugPrint(
        'Available locales: ${locales.map((l) => l.localeId).toList()}',
      );
    } catch (e) {
      debugPrint('Could not fetch locales: $e');
    }

    final localeId = await _preferredLocale();
    debugPrint('Selected localeId: $localeId');

    setState(() => _isListening = true);

    _speech.listen(
      onResult: (result) {
        debugPrint(
          '🗣 onResult final=${result.finalResult} words="${result.recognizedWords}"',
        );
        // some platforms may only provide final result at the end; log for debugging
        try {
          debugPrint('🗣 result obj: ${result.toString()}');
        } catch (_) {}

        setState(() {
          _textController.text = result.recognizedWords;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        });

        if (result.finalResult && result.recognizedWords.trim().isEmpty) {
          // final result empty — likely recognition failed; inform user
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Không nhận diện được giọng nói. Vui lòng thử lại.',
              ),
            ),
          );
        }
      },
      onSoundLevelChange: (level) {
        debugPrint('sound level: $level');
        setState(() => _soundLevel = level);
      },
      localeId: localeId,
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      onDevice: false,
      listenFor: const Duration(seconds: 30),
    );
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[_messages.length - 1 - index];
                      final isUser = message.sender == 'user';
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                                debugPrint('❌ Không mở được link: $e');
                              }
                            },
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                color: isUser ? Colors.white : Colors.black87,
                                fontSize: 15,
                              ),
                              a: TextStyle(
                                color: isUser
                                    ? Colors.yellowAccent
                                    : Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              strong: TextStyle(
                                color: isUser ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              h2: TextStyle(
                                color: isUser
                                    ? Colors.white
                                    : Colors.blue.shade700,
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
                // small diagnostics row so you can see init error / sound level on device
                if (_initError != null || _soundLevel > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        if (_initError != null)
                          Expanded(
                            child: Text(
                              'Mic init error: ${_initError}',
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Container(
                          width: 120,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (_soundLevel / 15).clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _soundLevel > 2
                                    ? Colors.green
                                    : Colors.orange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          onSubmitted: (v) => _sendMessage(v),
                          decoration: InputDecoration(
                            hintText: 'Nhập tin nhắn hoặc nói...',
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
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () =>
                                        setState(() => _textController.clear()),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _isListening ? _stopListening : _startListening,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening
                                ? Colors.redAccent
                                : Colors.blue.shade600,
                            boxShadow: [
                              if (_isListening)
                                BoxShadow(
                                  color: Colors.redAccent.withOpacity(0.28),
                                  blurRadius: 12,
                                  spreadRadius: 3,
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
  _ChatMessage({required this.sender, required this.text});
}
